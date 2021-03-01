{
  my $file = $lang ? "mibsupport-sysorid-infos-$lang.tpl" : "";
  if ($file && -e "$template_path/$file") {
    $OUT .= Text::Template::fill_in_file("$template_path/$file", HASH => $hash)
      || "Error loading $file template: $Text::Template::ERROR";
  } else {
    $OUT .= "
      Here is the list of MIB Support rules to handle.<br/>
      Name must be uniq, begin by a letter or digit and only contain letters, digits
      or eventually tirets, dots and underscores.<br/>
      Oid is a MIB OID that could be found in provided by device sysortable.<br/>
      Rules is the list of rules to trigger when the device announces via its
      sysortable it supports the given MIB.<br/>
      <br/>
      These rules can only be applied if a device is recognized by a sysObjectID
      match.<br/>";
  }
}
