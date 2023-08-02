  <div id="navbar">
    <ul>{
    my $li_style = " style='background-color: #3a5693; color: #fff;'";
    my $a_style = " style='color: #fff;'";
    foreach my $navbar (@navbar) {
      my ( $text, $link, $icon ) = @{$navbar};
      $OUT .= "
      <li".($request eq $link ? $li_style : "").
        '><a href="'.$url_path."/".$link.
        '"'.($request eq $link ? $a_style : "").
        " id='navbar-$link'><div class='nav'>".($icon ? "<i class='ti ti-$icon'></i>" : "")._($text)."</div></a></li>";
      }
      $OUT .= "
      <li><a href=\"$addnavlink[0]\"><div class='nav'><i class='ti ti-".($addnavlink[2] ? $addnavlink[2] : "link")."'></i>$addnavlink[1]</div></a></li>" if @addnavlink>1;
    }
    </ul>
  </div>
