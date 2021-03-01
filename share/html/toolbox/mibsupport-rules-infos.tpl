{
  my $file = $lang ? "mibsupport-rules-infos-$lang.tpl" : "";
  if ($file && -e "$template_path/$file") {
    $OUT .= Text::Template::fill_in_file("$template_path/$file", HASH => $hash)
      || "Error loading $file template: $Text::Template::ERROR";
  } else {
    $OUT .= "
      Here is the list of known rules.<br/>
      Name must be uniq, begin by a letter or digit and only contain letters, digits
      or eventually tirets, dots and underscores.<br/>
      The type can be a <b>typedef</b> to set device type, essentially 'NETWORKING'
      or 'PRINTER'. It can also be <b>serial</b>, <b>model</b>, <b>manufacturer</b>, <b>mac</b>,
      <b>ip</b>, <b>firmware</b> or <b>firmwaredate</b> to tell the agent which OID
      should be used to retrieve the corresponding information.<br/>
      The value type should always be <b>raw</b> for <b>typedef</b> rules, otherwise is should be used in
      some case to normalized the output to a MAC address, a serial number or just a string.<br/>";
  }
}
