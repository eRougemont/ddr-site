<?php
// PHP Version 7.4.33
declare(strict_types=1);
ini_set('display_startup_errors', 1);
ini_set('display_errors', 1);
error_reporting(-1);

require __DIR__ . '/lib.php';

$documents = loadTsv(__DIR__ . '/data/ddr-docs.tsv', 'identifier');
$pairs = loadTsv(__DIR__ . '/data/reused.tsv');
$pairs = array_values(array_filter($pairs, static fn(array $p): bool => isset($documents[$p['file_a'] ?? ''], $documents[$p['file_b'] ?? ''])));
usort($pairs, static fn(array $a, array $b): int => (float)$b['score'] <=> (float)$a['score']);
$requestedA = $_GET['a'] ?? '';
$requestedB = $_GET['b'] ?? '';
$chosen = null;
foreach ($pairs as $pair) {
    if (($pair['file_a'] === $requestedA && $pair['file_b'] === $requestedB)
        || ($pair['file_a'] === $requestedB && $pair['file_b'] === $requestedA)) {
        $chosen = $pair;
        break;
    }
}
$chosen ??= $pairs[0] ?? null;
$error = null;
$left = null;
$right = null;
$counts = ['left' => 0, 'right' => 0];
if ($chosen) {
    $a = $documents[$chosen['file_a']];
    $b = $documents[$chosen['file_b']];
    if (compareDates($a, $b) > 0) {
        [$a, $b] = [$b, $a];
    }
    try {
        $left = readArticle($a);
        $right = readArticle($b);
        [$lChanged, $rChanged] = compareTokens($left['tokens'], $right['tokens']);
        $counts = ['left' => count($lChanged), 'right' => count($rChanged)];
        $left['html'] = renderBody($left, $lChanged, 'a');
        $right['html'] = renderBody($right, $rChanged, 'b');
    } catch (Throwable $e) {
        $error = $e->getMessage();
    }
}
function pairUrl(array $pair): string {
    return '?a=' . rawurlencode($pair['file_a']) . '&b=' . rawurlencode($pair['file_b']);
}
?><!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Réemplois textuels</title>
<link rel="stylesheet" href="style.css">
<script src="viewer.js" defer></script>
</head>
<body>
<div class="layout">
<aside class="sidebar">
  <header class="sidebar-head"><h1>Réemplois textuels</h1><span class="total"><?=count($pairs)?> paires</span></header>
  <div class="filters">
    <label class="sr-only" for="search">Rechercher</label>
    <input id="search" type="search" placeholder="Titre, recueil, identifiant…" autocomplete="off">
    <label class="threshold-label" for="threshold">Seuil <output id="threshold-value">0,80</output></label>
    <input id="threshold" type="range" min="0" max="1" step="0.001" value="0.8">
    <div class="count"><span id="visible-count"></span> paires affichées</div>
  </div>
  <nav class="pair-list" id="pair-list" aria-label="Documents à comparer">
  <?php foreach ($pairs as $pair):
      $da = $documents[$pair['file_a']];
      $db = $documents[$pair['file_b']];
      $active = $chosen && $pair['file_a'] === $chosen['file_a'] && $pair['file_b'] === $chosen['file_b'];
      $search = mbLower(implode(' ', [$pair['file_a'], $pair['file_b'], $da['title'], $db['title'], $da['work'], $db['work']]));
  ?>
  <a class="pair<?=$active ? ' active' : ''?>" href="<?=h(pairUrl($pair))?>" data-score="<?=h($pair['score'])?>" data-search="<?=h($search)?>" <?=$active?'aria-current="page"':''?>>
    <span class="pair-score"><?=h($pair['score'])?></span>
    <span class="pair-doc"><span class="pair-title"><?=h($da['title'])?></span><small><?=h($pair['file_a'])?></small></span>
    <span class="pair-doc"><span class="pair-title"><?=h($db['title'])?></span><small><?=h($pair['file_b'])?></small></span>
  </a>
  <?php endforeach; ?>
  </nav>
</aside>
<main class="main">
<?php if ($error): ?>
  <div class="error"><strong>Comparaison indisponible.</strong> <?=h($error)?><p>Les fichiers HTML manquants peuvent être ajoutés dans le dossier <code>html/</code>.</p></div>
<?php elseif (!$chosen): ?>
  <p>Aucune paire disponible.</p>
<?php else: ?>
  <div class="toolbar">
    <span class="score">Similarité <?=h($chosen['score'])?></span>
    <div class="toolbar-actions">
      <label class="toggle"><input id="only-diff" type="checkbox"> Différences seules</label>
      <label class="toggle"><input id="sync" type="checkbox" checked> Défilement synchronisé</label>
      <button id="prev" type="button" title="Différence précédente">←</button>
      <span id="diff-position">—</span>
      <button id="next" type="button" title="Différence suivante">→</button>
    </div>
  </div>
  <div class="panes">
    <?php foreach ([$left, $right] as $i => $doc): ?>
    <section class="pane" aria-label="<?=h($doc['meta']['title'])?>">
      <div class="doc-head">
        <h2><?=h($doc['meta']['title'])?></h2>
        <p><?=h($doc['meta']['work'])?></p>
        <div class="doc-meta"><span><?=h(documentDate($doc['meta']))?></span><small><?=h($doc['meta']['identifier'])?></small></div>
      </div>
      <div class="reading" id="reading-<?=$i?>"><div class="prose"><?=$doc['html']?></div></div>
    </section>
    <?php endforeach; ?>
  </div>
<?php endif; ?>
</main>
</div>
</body>
</html>
