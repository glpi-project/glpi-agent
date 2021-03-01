  <!-- ip_range {$edit || $form{empty}?'edit':'list'} -->{
  $edit || $form{empty} ?
    Text::Template::fill_in_file($template_path."/ip_range-edit.tpl", HASH => $hash)
      || "Error loading ip_range-edit.tpl template: $Text::Template::ERROR"
    :
    Text::Template::fill_in_file($template_path."/ip_range-list.tpl", HASH => $hash)
      || "Error loading ip_range-list.tpl template: $Text::Template::ERROR";
}  <!-- ip_range {$edit || $form{empty}?'edit':'list'} end -->
