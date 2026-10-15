<?php
declare(strict_types=1);

define("DOCS", __DIR__ . "/../ddr/");

function h(string $value): string { return htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8'); }
function mbLower(string $value): string { return function_exists('mb_strtolower') ? mb_strtolower($value, 'UTF-8') : strtolower($value); }

/** @return array<int|string,array<string,string>> */
function loadTsv(string $path, ?string $key = null): array {
    $f = fopen($path, 'rb');
    if ($f === false) { throw new RuntimeException("Fichier introuvable : $path"); }
    $columns = fgetcsv($f, 0, "\t", '"', '');
    if (!$columns) { fclose($f); return []; }
    $out = [];
    while (($values = fgetcsv($f, 0, "\t", '"', '')) !== false) {
        if (count($values) !== count($columns)) { continue; }
        $row = array_combine($columns, $values);
        if ($key !== null) { $out[$row[$key]] = $row; }
        else { $out[] = $row; }
    }
    fclose($f);
    return $out;
}

function documentDate(array $meta): string {
    return $meta['issued'] !== '' ? $meta['issued'] : ($meta['created'] ?: 'Date inconnue');
}
/** Only order when both available date intervals are disjoint. */
function compareDates(array $a, array $b): int {
    $da = dateInterval(documentDate($a));
    $db = dateInterval(documentDate($b));
    if (!$da || !$db) { return 0; }
    if ($da[1] < $db[0]) { return -1; }
    if ($db[1] < $da[0]) { return 1; }
    return 0;
}
function dateInterval(string $date): ?array {
    if (preg_match('/^(\d{4})$/', $date, $m)) { return [$m[1].'-01-01', $m[1].'-12-31']; }
    if (preg_match('/^(\d{4})-(\d{2})$/', $date, $m) && checkdate((int)$m[2], 1, (int)$m[1])) {
        return [$date.'-01', $date.'-'.date('t', strtotime($date.'-01'))];
    }
    if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $date) && strtotime($date) !== false) { return [$date,$date]; }
    return null;
}

/** Load the publication XHTML, selecting only its text body. */
function readArticle(array $meta): array {
    $id = $meta['identifier'];
    if (!preg_match('/^[a-zA-Z0-9_-]+$/', $id)) { throw new RuntimeException('Identifiant de document invalide'); }
    $file = DOCS . $id . '.html';
    if (!is_file($file)) { throw new RuntimeException("HTML absent : $file"); }
    if (!class_exists('DOMDocument')) { throw new RuntimeException('Extension PHP DOM/XML requise'); }
    $dom = new DOMDocument();
    $old = libxml_use_internal_errors(true);
    $loaded = $dom->loadXML(file_get_contents($file), LIBXML_NONET);
    libxml_clear_errors();
    libxml_use_internal_errors($old);
    if (!$loaded) { throw new RuntimeException("XHTML invalide : $id.html"); }
    $xpath = new DOMXPath($dom);
    $body = $xpath->query('//*[contains(concat(" ",normalize-space(@class)," ")," body ")]')->item(0);
    if (!$body) { throw new RuntimeException("Corps .body absent : $id.html"); }
    // Footnote callouts and pagination markers are not part of the word comparison.
    foreach (iterator_to_array($xpath->query('.//*[contains(concat(" ",normalize-space(@class)," ")," noteref ") or contains(concat(" ",normalize-space(@class)," ")," pb ") or contains(concat(" ",normalize-space(@class)," ")," bookmark ")]', $body)) as $node) {
        $node->parentNode?->removeChild($node);
    }
    $tokens = []; $nodes = [];
    $walk = function (DOMNode $node) use (&$walk, &$tokens, &$nodes): void {
        if ($node instanceof DOMText) {
            $value = $node->nodeValue;
            $index = count($nodes);
            $nodes[] = $node;
            if (preg_match_all('/[\p{L}\p{N}]+|[^\s\p{L}\p{N}]/u', $value, $matches, PREG_OFFSET_CAPTURE)) {
                foreach ($matches[0] as [$word, $offset]) {
                    $tokens[] = ['v' => mbLower($word), 'node' => $index, 'start' => $offset, 'end' => $offset + strlen($word)];
                }
            }
        } else {
            foreach ($node->childNodes as $child) { $walk($child); }
        }
    };
    $walk($body);
    $publicUrl = '';
    foreach ($xpath->query('//*[local-name()="meta" and @name="citation_fulltext_html_url"]') as $tag) {
        $url = $tag->getAttribute('content');
        if (filter_var($url, FILTER_VALIDATE_URL) && str_starts_with($url, 'https://')) { $publicUrl = $url; }
        break;
    }
    return compact('meta','dom','body','tokens','nodes','publicUrl');
}

/**
 * Diff token streams using unique four-token anchors, LIS ordering, and bounded LCS in gaps.
 * Returns token-index sets that differ in each version; the original tokens are never rewritten.
 */
function compareTokens(array $a, array $b): array {
    $va = array_column($a, 'v'); $vb = array_column($b, 'v');
    $anchors = anchorPairs($va, $vb);
    array_unshift($anchors, [-1,-1]);
    $anchors[] = [count($va),count($vb)];
    $ca = []; $cb = [];
    for ($k=1; $k<count($anchors); $k++) {
        [$pa,$pb] = $anchors[$k-1];
        [$na,$nb] = $anchors[$k];
        markGap($va,$vb,$pa+1,$na,$pb+1,$nb,$ca,$cb);
    }
    return [$ca,$cb];
}
function anchorPairs(array $a, array $b): array {
    // Single-token anchors are unreliable in prose; unique 4-grams are much more stable.
    $n = 4; $mapA = []; $mapB = [];
    for ($i=0;$i<=count($a)-$n;$i++) { $key = implode("\x1F",array_slice($a,$i,$n)); $mapA[$key] = isset($mapA[$key]) ? -1 : $i; }
    for ($i=0;$i<=count($b)-$n;$i++) { $key = implode("\x1F",array_slice($b,$i,$n)); $mapB[$key] = isset($mapB[$key]) ? -1 : $i; }
    $candidates = [];
    foreach ($mapA as $key=>$i) { if ($i >= 0 && isset($mapB[$key]) && $mapB[$key] >= 0) { $candidates[] = [$i,$mapB[$key]]; } }
    usort($candidates, static fn($x,$y) => $x[0] <=> $y[0]);
    // Longest increasing subsequence of right-hand positions.
    $tails=[]; $tailIds=[]; $previous=[];
    foreach ($candidates as $idx=>$pair) {
        $v=$pair[1]; $lo=0; $hi=count($tails);
        while ($lo<$hi) { $mid=intdiv($lo+$hi,2); if ($tails[$mid]<$v) { $lo=$mid+1; } else { $hi=$mid; } }
        $previous[$idx]=$lo>0 ? $tailIds[$lo-1] : -1;
        $tails[$lo]=$v; $tailIds[$lo]=$idx;
    }
    $result=[]; $idx=$tailIds[count($tails)-1] ?? -1;
    while ($idx>=0) { $result[]=$candidates[$idx]; $idx=$previous[$idx]; }
    $result=array_reverse($result);
    // Avoid overlapping anchors (a four-token anchor implies four exact tokens).
    $out=[]; $endA=-1; $endB=-1;
    foreach ($result as [$i,$j]) {
        if ($i<=$endA || $j<=$endB) { continue; }
        for ($k=0;$k<$n;$k++) { $out[]=[$i+$k,$j+$k]; }
        $endA=$i+$n-1; $endB=$j+$n-1;
    }
    return $out;
}
function markGap(array $a, array $b, int $as, int $ae, int $bs, int $be, array &$ca, array &$cb): void {
    while ($as<$ae && $bs<$be && $a[$as]===$b[$bs]) { $as++;$bs++; }
    while ($as<$ae && $bs<$be && $a[$ae-1]===$b[$be-1]) { $ae--; $be--; }
    $n=$ae-$as; $m=$be-$bs;
    if (!$n && !$m) { return; }
    if (!$n || !$m || $n*$m>150000) {
        for ($i=$as;$i<$ae;$i++) { $ca[$i]=true; }
        for ($j=$bs;$j<$be;$j++) { $cb[$j]=true; }
        return;
    }
    // LCS for short gaps; large changes stay as whole highlighted passages.
    $dp=array_fill(0,$n+1,array_fill(0,$m+1,0));
    for ($i=$n-1;$i>=0;$i--) {
        for ($j=$m-1;$j>=0;$j--) {
            $dp[$i][$j]=$a[$as+$i]===$b[$bs+$j] ? 1+$dp[$i+1][$j+1] : max($dp[$i+1][$j],$dp[$i][$j+1]);
        }
    }
    $i=0;$j=0;
    while ($i<$n || $j<$m) {
        if ($i<$n && $j<$m && $a[$as+$i]===$b[$bs+$j]) { $i++;$j++; }
        elseif ($i<$n && ($j===$m || $dp[$i+1][$j]>=$dp[$i][$j+1])) { $ca[$as+$i]=true; $i++; }
        else { $cb[$bs+$j]=true; $j++; }
    }
}

/** Add <mark> elements to a cloned document DOM, preserving existing typographic elements. */
function renderBody(array $article, array $changed, string $prefix): string {
    $body=$article['body']; $nodes=$article['nodes']; $ranges=[];
    foreach ($changed as $idx=>$_) {
        $t=$article['tokens'][$idx]; $ranges[$t['node']][]=[$t['start'],$t['end']];
    }
    foreach ($ranges as $nodeIndex=>$intervals) {
        $node=$nodes[$nodeIndex]; $value=$node->nodeValue; $pos=0;
        $fragment=$article['dom']->createDocumentFragment();
        foreach ($intervals as [$start,$end]) {
            if ($start>$pos) { $fragment->appendChild($article['dom']->createTextNode(substr($value,$pos,$start-$pos))); }
            $mark=$article['dom']->createElement('mark');
            $mark->setAttribute('class', 'diff');
            $mark->appendChild($article['dom']->createTextNode(substr($value,$start,$end-$start)));
            $fragment->appendChild($mark); $pos=$end;
        }
        if ($pos<strlen($value)) { $fragment->appendChild($article['dom']->createTextNode(substr($value,$pos))); }
        $node->parentNode?->replaceChild($fragment,$node);
    }
    // Prefix any remaining local fragment identifiers to avoid collisions between panes.
    $xpath=new DOMXPath($article['dom']);
    foreach ($xpath->query('.//*[@id or @href]', $body) as $element) {
        if ($element->hasAttribute('id')) { $element->setAttribute('id',$prefix.'-'.$element->getAttribute('id')); }
        if ($element->hasAttribute('href') && str_starts_with($element->getAttribute('href'),'#')) {
            $element->setAttribute('href','#'.$prefix.'-'.substr($element->getAttribute('href'),1));
        }
    }
    $html='';
    foreach ($body->childNodes as $child) { $html.=$article['dom']->saveXML($child); }
    return $html;
}
