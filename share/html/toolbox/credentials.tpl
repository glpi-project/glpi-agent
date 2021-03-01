  <!-- credentials {$edit || $form{empty}?'edit':'list'} -->{
  $edit || $form{empty} ?
    Text::Template::fill_in_file($template_path."/credentials-edit.tpl", HASH => $hash)
      || "Error loading credentials-edit.tpl template: $Text::Template::ERROR"
    :
    Text::Template::fill_in_file($template_path."/credentials-list.tpl", HASH => $hash)
      || "Error loading credentials-list.tpl template: $Text::Template::ERROR";
}  <!-- credentials {$edit || $form{empty}?'edit':'list'} end -->
