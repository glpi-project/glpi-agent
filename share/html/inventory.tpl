<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta content="text/html; charset=UTF-8" http-equiv="content-type" />
    <title>GLPI-Agent {$deviceid}</title>
    <style type="text/css">
<!--/* <![CDATA[ */
 tr.odd \{ 
    background-color:white;
\}
tr.even \{ 
    background-color:silver;
\}
/* ]]> */-->
    </style>
</head>
<body>
<div id="background">
<h1>Inventory for {$deviceid}</h1>
GLPI Agent {$version}<br />
<small>DEVICEID {$deviceid}</small>

{
    foreach my $section (sort keys %data) {
        next if $section eq 'VERSIONCLIENT';

        $OUT .= "<h2>$section</h2>\n";

        my $content = $data{$section};

        if (ref($content) eq 'ARRAY') {
            my @fields = keys %{$fields{$section}};
            $OUT .= "<table width=\"100\%\">\n";
            $OUT .= "<tr>\n";
            foreach my $field (@fields) {
                $OUT .= "<th>" . lc($field). "</th>\n";
            }
            $OUT .= "</tr>\n";
            my $count = 0;
            foreach my $item (@$content) {
                my $class = $count++ % 2 ? 'odd' : 'even';      
                $OUT .= "<tr class=\"$class\">\n";
                foreach my $field (@fields) {
                    $OUT .= "<td>" . ($item->{$field} || "" ). "</td>\n";
                }
                $OUT .= "</tr>\n";

            }
            $OUT .= "</table>\n";
        } else {
            $OUT .= "<ul>\n";
            foreach my $key (sort keys %{$content}) {
                $OUT .= "<li>$key: $content->{$key}</li>\n";
            }
            $OUT .= "</ul>\n<br />\n";
        }
    }
}
</div>
</body>
</html>
