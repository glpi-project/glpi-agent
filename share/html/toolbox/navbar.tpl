  <div id="navbar">
    <ul>{
    my $li_style = " style='background-color: #3a5693; color: #fff;'";
    my $a_style = " style='color: #fff;'";
    foreach my $navbar (@navbar) {
      my ( $text, $link ) = @{$navbar};
      $OUT .= "
      <li".($request eq $link ? $li_style : "").
        "><a href=\"$url_path/$link\"".($request eq $link ? $a_style : "").
        "><div class='nav'>"._($text)."</div></a></li>";
      }
      $OUT .= "
      <li><a href=\"$addnavlink[0]\">$addnavlink[1]</a></li>" if @addnavlink>1;
    }
    </ul>
  </div>
