  <!-- {$edit?'edit':'list'} results -->{
  $edit ?
    Text::Template::fill_in_file($template_path."/results-edit.tpl", HASH => $hash)
      || "Error loading results-edit.tpl template: $Text::Template::ERROR"
    :
    Text::Template::fill_in_file($template_path."/results-list.tpl", HASH => $hash)
      || "Error loading results-list.tpl template: $Text::Template::ERROR";
}  <!-- {$edit?'edit':'list'} results end -->
