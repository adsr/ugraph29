<?php
declare(strict_types=1);

// Print data structures necessary for finding grapheme cluster breaks
// https://unicode.org/reports/tr29/

function prop_table_for_url($prefix, $url, $filter, $prop_strip, &$all_props) {
    $lines = explode("\n", trim(file_get_contents($url)));
    $ranges = [];
    foreach ($lines as $line) {
        $m = [];
        if (!preg_match('/^([0-9A-F]+)(?:\.\.([0-9A-F]+))?\s+;\s+([^#]+)/', $line, $m)) continue;
        if ($filter) if (!preg_match($filter, $line)) continue;
        $prop = $m[3];
        if ($prop_strip) $prop = preg_replace($prop_strip, ' ', $prop);
        $prop = preg_replace('/\W+/', ' ', $prop);
        $prop = trim(sprintf('ugraph29_prop_%s %s', $prefix, $prop));
        $prop = preg_replace('/ +/', '_', strtoupper($prop));
        $ranges[] = [ hexdec($m[1]), hexdec($m[2] ?: $m[1]), $prop ];
    }

    $props = array_unique(array_map(fn ($e) => $e[2], $ranges));
    $all_props = array_merge($all_props, $props);

    $code = '';

    $code .= sprintf("#define ugraph29_table_%s_count %d\n", $prefix, count($ranges));
    usort($ranges, fn ($a, $b) => $a[0] <=> $b[0]);
    $code .= "struct ugraph29_table ugraph29_table_{$prefix}[] = {\n";

    foreach ($ranges as $r) {
        $code .= sprintf("    { 0x%05x, 0x%05x, %s },\n", $r[0], $r[1], $r[2]);
    }
    $code .= "};\n\n";
    return $code;
}

function prop_enum($props) {
    $code = '';
    $code .= "enum ugraph29_prop {\n";
    static $enum_v = 1;
    foreach ($props as $prop) {
        $code .= sprintf("    %s = 0x%05x,\n", $prop, $enum_v);
        $enum_v = $enum_v << 1;
    }
    $code .= "};\n\n";
    return $code;
}

$code = '';
$props = [];

$code .= "struct ugraph29_table {\n" .
    "    uint32_t range_start;\n" .
    "    uint32_t range_end;\n" .
    "    enum ugraph29_prop;\n" .
    "};\n\n";

$code .= prop_table_for_url(
    'grapheme_break',
    'http://www.unicode.org/Public/UCD/latest/ucd/auxiliary/GraphemeBreakProperty.txt',
    null,
    null,
    $props,
);

$code .= prop_table_for_url(
    'incb',
    'http://www.unicode.org/Public/UCD/latest/ucd/DerivedCoreProperties.txt',
    '/\bInCB\b/',
    '/InCB/',
    $props,
);

$code .= prop_table_for_url(
    'ext_picto',
    'http://www.unicode.org/Public/UCD/latest/ucd/emoji/emoji-data.txt',
    '/\bExtended_Pictographic\b/',
    '/Extended_Pictographic/',
    $props,
);

$code = prop_enum($props) . $code;

echo $code;
