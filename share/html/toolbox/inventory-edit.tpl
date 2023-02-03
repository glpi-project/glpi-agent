
  <h2>{
    use Encode qw(encode);
    use HTML::Entities;
    $job  = $jobs{$edit} || {};
    $this = encode('UTF-8', encode_entities($edit));
    $name          = $job->{name} || $this || $form{"input/name"} || "";
    $type          = $job->{type}          || $form{"input/type"} || "netscan";
    $edit_tag      = $job->{tag}           || $form{"input/tag"}  || $current_tag || "";
    $configuration = $job->{config}        || "";
    $scheduling    = $job->{scheduling}    || $form{"input/scheduling"} || "";
    $description   = $job->{description}   || $form{"input/description"}  || "";
    $jobs{$edit} ? sprintf(_("Edit &laquo;&nbsp;%s&nbsp;&raquo; inventory job"), ($job->{name} || $this))
      : _"Add new inventory job"}</h2>
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' name='edit' value='{$this}'/>{
      $form{empty} ? "
    <input type='hidden' name='empty' value='1'/>" : "" }
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='name'>{_"Name"}</label>
        <div class='form-edit-row'>
          <input class='input-row' type='text' id='name' name='input/name' placeholder='{_"Name"}' value='{$name}' size='20'{
            ($id ? " title='Id: $id'" : "").($form{allow_name_edition} ? ">" : " disabled>
          <input class='input-row' type='submit' name='submit/rename' value='"._("Allow renaming")."'>")}
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='type-option' style='display: {$jobs{$edit} && $type ? "none" : "flex"}'>
      <div class='form-edit'>
        <label>{_"Type"}</label>
      </div>
      <div class='form-edit'>
        <ul>
          <li>
            <input type="radio" name="input/type" id="type/local" value="local" onchange="jobtype_change()"{$type eq "local" ? " checked" : ""}>
            <label for='local'>{_"Local inventory"}</label>
          </li>
          <li>
            <input type="radio" name="input/type" id="type/netscan" value="netscan" onchange="jobtype_change()"{$type eq "netscan" ? " checked" : ""}>
            <label for='netscan'>{_"Network scan"}</label>
          </li>
        </ul>
      </div>
    </div>
    <div class='form-edit-row' id='tag-option' style='display: {$type eq "local" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label>{_"Local inventory"}</label>
        <label for='tag' class='tag'>{_"Use a tag"}:</label>
        <div class='tag'>
          <select id='tag-config' class='tag' name='input/tag'{$type eq "local" ? "" : " disabled"}>
            <option value=''{!$edit_tag ? " selected" : ""}>{_"None"}</option>{
            use Encode qw(encode);
            use HTML::Entities;
            foreach my $tag (@tag_options) {
              my $encoded = encode('UTF-8', encode_entities($tag));
              $OUT .= "
            <option id='option-$tag'".
                  ( $edit_tag && $edit_tag eq $tag ? " selected" : "" ).
                  " value='$encoded'>$encoded</option>"
            }}
          </select>
          <a class='tag' onclick='config_new_tag()'>{_"Add new tag"}</a>
          </div>
          <div id='config-newtag-overlay' class='overlay' onclick='cancel_config_newtag()'>
            <div class='overlay-frame' onclick='event.stopPropagation()'>
              <label for='newtag' class='newtag' title='{_"New tag will be automatically selected"}'>{_"New tag"}:</label>
              <input id='config-newtag' class='newtag' type='text' name='input/newtag' placeholder='{_"tag"}' value='' size='20' title='{_"New tag will be automatically selected"}'>
              <input type='submit' class='big-button' name='submit/newtag' value='{_"Add"}'>
              <input type='button' class='big-button' name='submit/newtag-cancel' value='{_"Cancel"}' onclick='cancel_config_newtag()'>
            </div>
          </div>
      </div>
    </div>
    <input type='submit' class='big-button' name='submit/{
      $jobs{$edit} ?
        "update' value='"._("Update") :
        "add' value='"._("Create inventory job")}'>
    <input type='submit' class='big-button' name='submit/cancel' value='{_("Cancel")}'>
  </form>
  <script>
    function jobtype_change() \{
      if (document.getElementById("type/local").checked) \{
        document.getElementById("tag-option").style = "display: flex";
        document.getElementById("tag-config").disabled = false;
        document.getElementById("config-newtag").disabled = false;
      \} else \{
        document.getElementById("tag-option").style = "display: none";
        document.getElementById("tag-config").disabled = true;
        document.getElementById("config-newtag").disabled = true;
      \}
    \}
    function config_new_tag () \{
      document.getElementById("config-newtag-overlay").style.display = "block";
    \}
    function cancel_config_newtag () \{
      document.getElementById("config-newtag-overlay").style.display = "none";
    \}
  </script>
