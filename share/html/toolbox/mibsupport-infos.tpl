{
  my $file = "mibsupport-infos-en.tpl";
  $file = "mibsupport-infos-$lang.tpl" if -e "$template_path/mibsupport-infos-$lang.tpl";
  Text::Template::fill_in_file("$template_path/$file", HASH => $hash)
    || "Error loading $file template: $Text::Template::ERROR";
}
