  <form name='config' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>{
  use Encode qw(encode);
  use HTML::Entities;
  sub _tips {
    return unless $_[0];
    # Support multiline translation & replace any apostroph by html entity
    return join("\n", map { _($_) } split(/\n\s*/s, $_[0]));
  }
  my @categories = sort(keys(%configuration_specs));
  my $notfirst = 0;
  while (@categories) {
    my $category = shift @categories;
    $OUT .= "
    <p class='config-section".($notfirst++ ? " notfirst-section" : "")."'>"._($category)."</p>";
    my @configs = sort(keys(%{$configuration_specs{$category}}));
    foreach my $config (@configs) {
      my $spec = $configuration_specs{$category}->{$config};
      my $value = encode('UTF-8', encode_entities($spec->{value}));
      $OUT .= "
      <div class='param'>
        <label class='config-param' for='$config'>"._($spec->{text})."</label>";
      if ($spec->{type} eq "bool") {
        $OUT .= "
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' name='$config' value='1'".
              ($value eq "yes" ? " checked" : "").">
              <span class='custom-checkbox'></span>
            </label>";
      } elsif ($spec->{type} eq "number") {
        $OUT .= "
            <input id='$config' style='text-align: center;' type='number' name='$config' value='$value'".
            ( $spec->{tips} ? " title='"._tips($spec->{tips})."'" : "" ).
            ( $spec->{min} ? " min='".$spec->{min}."'" : "" ).
            ( $spec->{max} ? " max='".$spec->{max}."'" : "" ).
            ">";
      } elsif ($spec->{type} eq "option") {
        next unless $spec->{options};
        if (!ref($spec->{options}->[0])) {
          $OUT .= "
              <select id='$config' name='$config'".
                ( $spec->{tips} ? " title='"._tips($spec->{tips})."'" : "" ).">
                <option".($value ? "" : " selected")." value=''>"._("[default]")."</option>".
                  join("", map { "
                    <option".
                      
                      ( $value && $value eq $_ ? " selected" : "" ).
                      ">"._($_)."</option>"
                  } @{$spec->{options}})."
              </select>";
        } else {
          $OUT .= "
              <select id='$config' name='$config'".
                ( $spec->{tips} ? " title='"._tips($spec->{tips})."'" : "" ).">
                <option".($value ? "" : " selected")." value=''>"._("[default]")."</option>".
                  join("", map { "
                    <option".
                      ( $value && $value eq $_->[1] ? " selected" : "" ).
                      " value='$_->[1]'>"._($_->[0])."</option>"
                  } @{$spec->{options}})."
              </select>";
        }
      } elsif ($spec->{type} eq "text") {
        $OUT .= "
            <input id='$config' type='text' name='$config' value='$value'"
              .( $spec->{style} ? " style='".$spec->{style}."'" : "" )
              .( $spec->{pattern} ? " pattern='".$spec->{pattern}."'" : "" )
              .( $spec->{size} ? " size='".$spec->{size}."'" : "" )
              .( $spec->{tips} ? " title='"._tips($spec->{tips})."'" : "" ).">";
      } elsif ($spec->{type} eq "textarea") {
        $OUT .= "
            <textarea id='$config' cols='".($spec->{cols}||40)."' rows='".($spec->{rows}||3)."' name='$config'"
              .( $spec->{tips} ? " title='"._tips($spec->{tips})."'" : "" )
              .">$value</textarea>";
      } elsif ($spec->{type} eq "readonly") {
        $OUT .= _($value);
      }
      $OUT .= "
      </div>";
    }
  }
  if ($update_support) {
    $OUT .= "
    <div class='config-inputs'>
      <input class='submit' type='submit' name='submit/update' value='"._("Update")."'>
      <input class='submit' type='submit' name='submit/backup' value='"._("Backup YAML")."'>
    </div>";
  }}
  </form>
