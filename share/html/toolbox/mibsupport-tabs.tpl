
  <div class='tab'>
    <button class="mibsupporttab{
      !$form{currenttab} || $form{currenttab} =~ /^infos$/ ? " active" : ""
      }" id='infos' onclick="show(event)">{_"Infos"}</button>
    <button class="mibsupporttab{
      $form{currenttab} && $form{currenttab} =~ /^sysobjectid$/ ? " active" : ""
      }" id='sysobjectid' onclick="show(event)">{_"SysObjectID"}</button>
    <button class="mibsupporttab{
      $form{currenttab} && $form{currenttab} =~ /^sysorid$/ ? " active" : ""
      }" id='sysorid' onclick="show(event)">{_"MibSupport"}</button>
    <button class="mibsupporttab{
      $form{currenttab} && $form{currenttab} =~ /^rules$/ ? " active" : ""
      }" id='rules' onclick="show(event)">{_"Rules"}</button>
    <button class="mibsupporttab{
      $form{currenttab} && $form{currenttab} =~ /^aliases$/ ? " active" : ""
      }" id='aliases' onclick="show(event)">{_"Aliases"}</button>
  </div>
  <div id='infos-tab' class="tabcontent"{!$form{currenttab} || $form{currenttab} =~ /^infos$/ ? " style='display: block;'" : ""}>{
    Text::Template::fill_in_file($template_path."/mibsupport-infos.tpl", HASH => $hash)
      || "Error loading mibsupport-infos.tpl template: $Text::Template::ERROR"
}  </div>
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' id='currenttab' name='currenttab' value='{$form{currenttab}||"infos"}'/>
    <div id='aliases-tab' class="tabcontent"{$form{currenttab} && $form{currenttab} =~ /^aliases$/ ? " style='display: block;'" : ""}>{
      Text::Template::fill_in_file($template_path."/mibsupport-aliases.tpl", HASH => $hash)
        || "Error loading mibsupport-aliases.tpl template: $Text::Template::ERROR"
}    </div>
    <div id='rules-tab' class="tabcontent"{$form{currenttab} && $form{currenttab} =~ /^rules$/ ? " style='display: block;'" : ""}>{
      Text::Template::fill_in_file($template_path."/mibsupport-rules.tpl", HASH => $hash)
        || "Error loading mibsupport-rules.tpl template: $Text::Template::ERROR"
}    </div>
    <div id='sysobjectid-tab' class="tabcontent"{$form{currenttab} && $form{currenttab} =~ /^sysobjectid$/ ? " style='display: block;'" : ""}>{
      Text::Template::fill_in_file($template_path."/mibsupport-sysobjectid.tpl", HASH => $hash)
        || "Error loading mibsupport-sysobjectid.tpl template: $Text::Template::ERROR"
}    </div>
    <div id='sysorid-tab' class="tabcontent"{$form{currenttab} && $form{currenttab} =~ /^sysorid$/ ? " style='display: block;'" : ""}>{
      Text::Template::fill_in_file($template_path."/mibsupport-sysorid.tpl", HASH => $hash)
        || "Error loading mibsupport-sysorid.tpl template: $Text::Template::ERROR"
}    </div>
  </form>
  <script>
  function toggle_all(from) \{
    var all_cb = document.querySelectorAll('input[type="checkbox"]');
    var filter = from.name + "/";
    for ( var i = 0; i < all_cb.length; i++ )
      if (all_cb[i] != from && all_cb[i].name.startsWith(filter))
        all_cb[i].checked = !all_cb[i].checked;
  \}
  function show(evt) \{
    var target = evt.currentTarget;
    var tabcontent = document.getElementsByClassName("tabcontent");
    for ( var i = 0; i < tabcontent.length; i++ )
      if (tabcontent[i].id != target.id+'-tab')
        tabcontent[i].style.display = "none";
    var tab = document.getElementsByClassName("mibsupporttab");
    for ( var i = 0; i < tab.length; i++ )
      tab[i].className = tab[i].className.replace(" active", "");
    document.getElementById(target.id+'-tab').style.display = "block";
    target.className += " active";
    document.getElementById("currenttab").value = target.id;
  \}
  </script>
