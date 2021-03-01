{
  my $file = $lang ? "mibsupport-sysobjectid-infos-$lang.tpl" : "";
  if ($file && -e "$template_path/$file") {
    $OUT .= Text::Template::fill_in_file("$template_path/$file", HASH => $hash)
      || "Error loading $file template: $Text::Template::ERROR";
  } else {
    $OUT .= "
      Here is the list of sysObjectID matches to handle.<br/>
      Name must be uniq, begin by a letter or digit and only contain letters, digits
      or eventually tirets, dots and underscores.<br/>
      Oid is the base OID searched by the agent in the sysObjectID SNMP entry
      (match can be partial from the beginning part).<br/>
      Ruleset is the list of rules to trigger when the sysObjectID matches.<br/>";
  }
}
