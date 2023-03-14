  <!-- inventory {$edit || $form{empty}?'edit':'list'} -->{
  $edit || $form{empty} ?
    Text::Template::fill_in_file($template_path."/inventory-edit.tpl", HASH => $hash)
      || "Error loading inventory-edit.tpl template: $Text::Template::ERROR"
    :
    Text::Template::fill_in_file($template_path."/inventory-list.tpl", HASH => $hash)
      || "Error loading inventory-list.tpl template: $Text::Template::ERROR";
}  <!-- inventory {$edit || $form{empty}?'edit':'list'} end -->
