<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta content="text/html; charset=UTF-8" http-equiv="content-type" />
    <title>GLPI-Agent</title>
    <link rel="stylesheet" href="site.css" type="text/css" />
</head>
<body>
<div id="background">
<br />
<br />
This is GLPI Agent {$version}<br />
The current status is {$status}<br />

{
    if ($trust && (@server_targets||@local_targets)) {
        $OUT .= '<a href="/now">Force an Inventory</a>';
    } else {
        '';
    }
}

<br />
{
    if (@server_targets) {
        $OUT .=  "Next server target execution planned for:\n";
        $OUT .=  "<ul>\n";
        foreach my $target (@server_targets) {
           $OUT .= "<li>$target->{name}: $target->{date}</li>\n";
        }
        $OUT .=  "</ul>\n";
    } else {
        '';
    }
}

{
    if (@local_targets) {
        $OUT .=  "Next local target execution planned for:\n";
        $OUT .=  "<ul>\n";
        foreach my $target (@local_targets) {
           $OUT .= "<li>$target->{name}: $target->{date}</li>\n";
        }
        $OUT .=  "</ul>\n";
    } else {
        '';
    }
}

{
    if ($trust && @httpd_plugins) {
        $OUT .=  "HTTPD plugins listening ports:\n";
        foreach my $plugin (@httpd_plugins) {
           $OUT .= "<li>$plugin->{port}: $plugin->{name}</li>\n";
        }
        $OUT .=  "</ul>\n";
    } else {
        '';
    }
}

<br />{
    if (@sessions) {
        my $style = "text-align: left; font-size: 8px;";
        $OUT .= "<div class='sessions'>\n";
        $OUT .= "Current HTTP client sessions:\n";
        $OUT .= "<ul>\n";
        foreach my $session (@sessions) {
           $OUT .= "    <li class='sessions'>$session</li>\n";
        }
        $OUT .= "</ul>\n</div>\n";
    } else {
        '';
    }
}
</div>
</body>
</html>
