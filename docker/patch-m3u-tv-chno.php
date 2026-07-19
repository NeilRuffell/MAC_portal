<?php

if ($argc < 2) {
    fwrite(STDERR, "Usage: php patch-m3u-tv-chno.php <TvChannelsController.php>\n");
    exit(1);
}

$file = $argv[1];
$code = file_get_contents($file);

if ($code === false) {
    fwrite(STDERR, "Unable to read {$file}\n");
    exit(1);
}

$parseMarker = 'M3U tv-chno channel number support';
if (strpos($code, $parseMarker) === false) {
    $parseStart = strpos($code, 'private function parseInfoRow($row)');
    if ($parseStart === false) {
        fwrite(STDERR, "Unable to patch M3U tv-chno import: parseInfoRow function not found\n");
        exit(1);
    }

    $nextFunction = strpos($code, 'public function save_m3u_item()', $parseStart);
    if ($nextFunction === false) {
        fwrite(STDERR, "Unable to patch M3U tv-chno import: save_m3u_item boundary not found\n");
        exit(1);
    }

    $parseBody = substr($code, $parseStart, $nextFunction - $parseStart);
    $returnInBody = strrpos($parseBody, 'return $result;');
    if ($returnInBody === false) {
        fwrite(STDERR, "Unable to patch M3U tv-chno import: parseInfoRow return not found\n");
        exit(1);
    }

    $insertAt = $parseStart + $returnInBody;
    $parsePatch =
        "        // {$parseMarker}.\n" .
        "        if (!isset(\$result['number']) && isset(\$result['chno'])) {\n" .
        "            \$result['number'] = \$result['chno'];\n" .
        "        }\n" .
        "        if (!isset(\$result['number']) && preg_match('/(?:^|\\s)(?:tv-chno|tvg-chno|chno)\\s*=\\s*[\"\\']?(\\d+)[\"\\']?/i', \$row, \$matches)) {\n" .
        "            \$result['number'] = \$matches[1];\n" .
        "        }\n";

    $code = substr($code, 0, $insertAt) . $parsePatch . substr($code, $insertAt);
}

$outputMarker = 'M3U parsed channel number output';
if (strpos($code, $outputMarker) === false) {
    $channelsStart = strpos($code, "\$data['data']['channels']");
    if ($channelsStart === false) {
        fwrite(STDERR, "Unable to patch M3U tv-chno import: channels assignment not found\n");
        exit(1);
    }

    $errorAssignment = strpos($code, "\$error = '';", $channelsStart);
    if ($errorAssignment === false) {
        $snippet = substr($code, $channelsStart, 1200);
        fwrite(STDERR, "Unable to patch M3U tv-chno import: success point not found near:\n{$snippet}\n");
        exit(1);
    }

    $outputPatch =
        "            // {$outputMarker}.\n" .
        "            \$m3u_rows = array_values(\$m3u_data);\n" .
        "            foreach (\$m3u_rows as \$m3u_index => \$m3u_row) {\n" .
        "                if (isset(\$m3u_row['number']) && isset(\$data['data']['channels'][\$m3u_index])) {\n" .
        "                    \$data['data']['channels'][\$m3u_index]['number'] = \$m3u_row['number'];\n" .
        "                }\n" .
        "            }\n";

    $code = substr($code, 0, $errorAssignment) . $outputPatch . substr($code, $errorAssignment);
}

if (file_put_contents($file, $code) === false) {
    fwrite(STDERR, "Unable to write {$file}\n");
    exit(1);
}

passthru('php -l ' . escapeshellarg($file), $lintStatus);
if ($lintStatus !== 0) {
    exit($lintStatus);
}

