<?php declare(strict_types=1);

include_once(dirname(__DIR__) . '/vendor/autoload.php');
use Psr\Log\LogLevel;
use Oeuvres\Kit\{Cliglob, Filesys, Log, Xt};
use Oeuvres\Kit\Logger\{LoggerCli};

use Oeuvres\Teinte\Format\{Tei};

class Tei_site extends Cliglob {
    private static Tei $tei;
    private static $ids=[];
    public static $dstDir = "";
    /** work */
    static public function cli()
    {
        $home = dirname(__DIR__);
        Log::setLogger(new LoggerCli(LogLevel::DEBUG));
        self::$globs = [
            $home . "/../ddr-livres/*.xml",
            $home . "/../ddr-articles/*.xml",
            $home . "/../ddr-inedits/*.xml",
        ];
        self::args();
        self::$tei = new Tei();
        if (isset(self::$options["d"])) {
            self::$dstDir = realpath(self::$options["d"]) . "/";
        }
        else {
            self::$dstDir = realpath($home . "/ddr/") . "/";
        }
        // TODO update illustrations
        <<<END
        self::rcopy(
            [
                dirname(__DIR__) . "/piaget-xml/*/*.{gif,jpg,jpeg,png,svg}",
                dirname(__DIR__) . "/piaget-textes/6_xml/*/*.{gif,jpg,jpeg,png,svg}",
            ],
            __DIR__ . "/../piaget-site/ill/",
            true
        );
        END;
        // Filesys::cleandir(self::$dstDir); // no clean
        echo "Process:\n" . implode("\n", self::$globs) . "\nto " . self::$dstDir . "\n";
        self::glob([__CLASS__, 'export']);
        self::glob([__CLASS__, 'duplicates']);
    }

    static public function rcopy(array $patterns, string $dstDir, bool $onlyNewer = true): void
    {
        // Ensure target directory exists
        if (!is_dir($dstDir) && !mkdir($dstDir, 0777, true) && !is_dir($dstDir)) {
            throw new RuntimeException("Cannot create directory: $dstDir");
        }
        $dstDir = rtrim($dstDir, '/\\') . DIRECTORY_SEPARATOR;

        foreach ($patterns as $pattern) {
            echo "Copying $pattern to $dstDir\n";
            foreach (glob($pattern, GLOB_BRACE ) ?: [] as $src) {
                if (!is_file($src)) {
                    continue;
                }

                // Flatten: only keep the file name
                $dst = $dstDir . basename($src);

                // Freshness test
                if ($onlyNewer && is_file($dst) && filemtime($dst) >= filemtime($src)) {
                    continue;
                }
                echo "copy $dst\n";

                if (!copy($src, $dst)) {
                    throw new RuntimeException("Copy failed: $src -> $dst");
                }
            }
        }
    }

    static function duplicates(string $tei_file, string $dst_file)
    {
        $docid = strtok(pathinfo($tei_file, PATHINFO_FILENAME), '_');
        if (isset(self::$ids[$docid])) {
            Log::warning("DUPLICATE " . $tei_file);
            return;
        }
        self::$ids[$docid] = true;
    }

    static function export(string $teiFile, string $dst_file)
    {
        $teiFile = str_replace('\\', '/', realpath($teiFile));
        Log::info($teiFile);
        $filename = pathinfo($teiFile, PATHINFO_FILENAME);
        if (strpos(pathinfo($teiFile, PATHINFO_FILENAME), '_') === false) {
            $docid = $filename;
        }
        else {
            $docid = strtok($filename, '_');
        }
        $dom = Xt::load($teiFile);
        $pars = [
                'docid' => $docid,
                'dstDir' => "file:///" . self::$dstDir,
                "images" => "ill/",
        ];
        $xml = Xt::transformToXml(
            __DIR__ . "/ddr-site.xsl",
            $dom,
            $pars,
        );
    }
        
}
if (Tei_site::isCli()) {
    Tei_site::cli();
}
