  <!-- scheduling {$edit || $form{empty}?'edit':'list'} -->{
  $edit || $form{empty} ?
    Text::Template::fill_in_file($template_path."/scheduling-edit.tpl", HASH => $hash)
      || "Error loading scheduling-edit.tpl template: $Text::Template::ERROR"
    :
    Text::Template::fill_in_file($template_path."/scheduling-list.tpl", HASH => $hash)
      || "Error loading scheduling-list.tpl template: $Text::Template::ERROR";
}  <!-- scheduling {$edit || $form{empty}?'edit':'list'} end -->
