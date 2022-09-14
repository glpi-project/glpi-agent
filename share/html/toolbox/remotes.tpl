  <!-- remotes {$edit || $form{empty}?'edit':'list'} -->{
  $edit || $form{empty} ?
    Text::Template::fill_in_file($template_path."/remotes-edit.tpl", HASH => $hash)
      || "Error loading remotes-edit.tpl template: $Text::Template::ERROR"
    :
    Text::Template::fill_in_file($template_path."/remotes-list.tpl", HASH => $hash)
      || "Error loading remotes-list.tpl template: $Text::Template::ERROR";
}  <!-- remotes {$edit || $form{empty}?'edit':'list'} end -->
