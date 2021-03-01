  <!-- mibsupport {$edit?'edit':'tabs'} -->{
  $edit || $form{empty} ?
    Text::Template::fill_in_file($template_path."/mibsupport-edit.tpl", HASH => $hash)
      || "Error loading mibsupport-edit.tpl template: $Text::Template::ERROR"
    :
    Text::Template::fill_in_file($template_path."/mibsupport-tabs.tpl", HASH => $hash)
      || "Error loading mibsupport-tabs.tpl template: $Text::Template::ERROR";
}  <!-- mibsupport {$edit?'edit':'tabs'} end -->
