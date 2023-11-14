<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta content="text/html; charset=UTF-8" http-equiv="content-type" />
    <title>GLPI-Agent</title>
    <link rel="stylesheet" href="site.css" type="text/css" />
</head>
<body>
  <div id='background'>
    <p id='version' class='block'>This is GLPI Agent {$version}</p>
    <div id='status'>
      <p>The current status is {$status}</p>
      <div id='force' class='block'>{
    $OUT .= $trust && (@server_targets || @local_targets) ? "
        <a href='/now'>Force an Inventory</a>" : "";
  }
      </div>
    </div>{

  if (@server_targets || @local_targets || @httpd_plugins || @sessions) {
    $OUT .= "
    <div id='sections' class='section'>";
    if (@server_targets) {
      $OUT .= "
      <div id='servers'>
        <p>Next server target execution planned for:</p>
        <ul>";
      foreach my $target (@server_targets) {
        $OUT .= "
          <li>$target->{name}: $target->{date}</li>";
      }
      $OUT .= "
        </ul>
      </div>";
    }

    if (@local_targets) {
      $OUT .= "
      <div id='locals'>
        <p>Next local target execution planned for:</p>
        <ul>";
      foreach my $target (@local_targets) {
        $OUT .= "
          <li>$target->{name}: $target->{date}</li>";
      }
      $OUT .= "
        </ul>
      </div>";
    }

    if (@httpd_plugins) {
      $OUT .= "
      <div id='plugins'>
        <p>HTTPD plugins listening ports:</p>
        <ul>";
      foreach my $plugin (@httpd_plugins) {
        my $url = $plugins_url{$plugin->{name}};
        $OUT .= "
          <li>$plugin->{port}: ";
        $OUT .= "<a href='$url'>" if $url;
        $OUT .= $plugin->{name};
        $OUT .= "</a>" if $url;
        $OUT .= "</li>";
      }
      $OUT .= "
        </ul>
      </div>";
    }

    if (@sessions) {
      $OUT .= "
      <div id='sessions' class='sessions'>
        <p>Current HTTP client sessions:</p>
        <ul>";
      foreach my $session (@sessions) {
        $OUT .= "
          <li>$session</li>";
      }
      $OUT .= "
        </ul>
      </div>";
    }
    $OUT .= "
    </div>";
  } else {
    '';
  }
}
  </div>
</body>
</html>
