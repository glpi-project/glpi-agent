
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' name='edit' value='{$edit}'/>
    <input type='hidden' id='currenttab' name='currenttab' value='{$form{currenttab}||""}'/>{
      if ($form{currenttab} && $form{currenttab} =~ /^aliases|sysobjectid|sysorid|rules$/) {
        my $tpl = "mibsupport-".$form{currenttab}."-edit.tpl";
        $OUT .= Text::Template::fill_in_file("$template_path/$tpl", HASH => $hash)
          || "Error loading $tpl template: $Text::Template::ERROR";
      }}
    <button type='submit' class='big-button secondary-button' name='submit/back-to-list' formnovalidate='1' value='1' alt='{_("Go back to list")}'><i class='primary ti ti-list'></i>{_("Go back to list")}</button>
  </form>
