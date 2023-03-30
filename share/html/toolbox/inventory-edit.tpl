
  <h2>{
    use Encode qw(encode);
    use HTML::Entities;
    use URI::Escape;
    $job  = $jobs{$edit} || {};
    $this = encode('UTF-8', encode_entities($edit));
    $name          = $job->{name} || $this || $form{"input/name"} || "";
    $type          = $job->{type}          || $form{"input/type"} || "netscan";
    $configuration = $job->{config}        || {};
    $edit_tag      = $configuration->{tag} || $form{"input/tag"}  || $current_tag || "";
    $scheduling    = $job->{scheduling}    || $form{"input/scheduling"} || "";
    $description   = $job->{description}   || $form{"input/description"}  || "";
    $jobs{$edit} ? sprintf(_("Edit &laquo;&nbsp;%s&nbsp;&raquo; inventory task"), ($job->{name} || $this))
      : _"Add new inventory task"}</h2>
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' name='edit' value='{$this}'/>{
      $form{empty} ? "
    <input type='hidden' name='empty' value='1'/>" : "" }
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='name'>{_"Name"}</label>
        <div class='form-edit-row'>
          <input class='input-row' type='text' id='name' name='input/name' placeholder='{_"Name"}' value='{$name}' size='20' {($id ? " title='Id: $id'" : "").($form{empty} ? "" : " disabled")}/>
          <input type='button' class='button' value='{_"Rename"}' onclick='handle_rename()'{$form{empty} ? " style='display:none'" : ""}/>
        </div>
        <div id='rename-overlay' class='overlay' onclick='cancel_rename()'>
          <div class='overlay-frame' onclick='event.stopPropagation()'>
            <label for='rename' class='newtag'>{_"Rename"}:</label>
            <input id='input-rename' type='text' class='newtag' name='input/new-name' value='{$name}' size='30' disabled/>
            <input type='submit' class='big-button' name='submit/rename' value='{_"Rename"}'/>
            <input type='button' class='big-button' name='submit/rename-cancel' value='{_"Cancel"}' onclick='cancel_rename()'/>
          </div>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='type-option' style='display: {$jobs{$edit} && $type ? "flex" : "flex"}'>
      <div class='form-edit'>
        <label>{_"Type"}</label>
      </div>
      <div class='form-edit'>
        <ul class='type-options'>
          <li style='display: {$jobs{$edit} && $type ne "local" ? "none" : "flex"}'>
            <input type="radio" name="input/type" id="type/local" value="local" onchange="jobtype_change()"{$type eq "local" ? " checked" : ""}/>
            <label for='local'>{_"Local inventory"}</label>
          </li>
          <li style='display: {$jobs{$edit} && $type ne "netscan" ? "none" : "flex"}'>
            <input type="radio" name="input/type" id="type/netscan" value="netscan" onchange="jobtype_change()"{$type eq "netscan" ? " checked" : ""}/>
            <label for='netscan'>{_"Network scan"}</label>
          </li>
        </ul>
      </div>
    </div>
    <div class='form-edit-row' id='local-options' style='display: {$type eq "local" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='tag' class='tag'>{_"Use a tag"}:</label>
        <div class='tag'>
          <select id='tag-config' class='tag' name='input/tag'{$type eq "local" ? "" : " disabled"}>
            <option value=''{!$edit_tag ? " selected" : ""}>{_"None"}</option>{
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
              <input id='config-newtag' class='newtag' type='text' name='input/newtag' placeholder='{_"tag"}' value='' size='20' title='{_"New tag will be automatically selected"}' disabled/>
              <input type='submit' class='big-button' name='submit/newtag' value='{_"Add"}'/>
              <input type='button' class='big-button' name='submit/newtag-cancel' value='{_"Cancel"}' onclick='cancel_config_newtag()'/>
            </div>
          </div>
      </div>
    </div>
    <div class='form-edit-row' id='netscan-options' style='display: {$type ne "local" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label>{_"Associated ip ranges"}</label>
        <div id='ip-ranges'>
          <ul>{
          my @ipranges = ();
          my %selected = ();
          my %checkbox = map { m{^checkbox/ip_range/(.*)$} => 1 } grep { m{^checkbox/ip_range/} && $form{$_} eq 'on' } keys(%form);
          map { $checkbox{$_} = 1 } @{$job->{config}->{ip_range}} if @{$job->{config} ? $job->{config}->{ip_range} // [] : []};
          @ipranges = sort { $a cmp $b } keys(%checkbox);
          foreach my $name (@ipranges) {
            my $range = $ip_range{$name}
              or next;
            $OUT .= "
            <li>
              <input type='checkbox' name='checkbox/ip_range/".encode('UTF-8', encode_entities($name))."' checked/>
              <div class='with-tooltip'>
                <a href='$url_path/ip_range?edit=".uri_escape(encode("UTF-8", $name))."'>".encode('UTF-8', encode_entities($range->{name} || $name))."
                  <div class='tooltip right-tooltip'>
                    <p>"._("First ip").": ".$range->{ip_start}."</p>
                    <p>"._("Last ip").": ".$range->{ip_end}."</p>
                    <p>"._("Credentials").": ".join(",", map { encode('UTF-8', encode_entities($_)) } @{$range->{credentials}//[]})."</p>
                    <i></i>
                  </div>
                </a>
              </div>
            </li>";
            $selected{$name} = 1;
          }
          my @remains = grep { !exists($selected{$_}) } keys(%ip_range);
          if (@remains) {
            my $select = $form{"input/ip_range"} || "";
            $OUT .= "
            <li>
              <input id='add-iprange' type='hidden' name='add-iprange' value='".(@remains == 1 ? encode('UTF-8', encode_entities($remains[0])) : "").($type eq "local" ? "" : " disabled")."'/>
              <select id='select-iprange' onchange='updateSelectIprange(this)' size='".
                (@remains > 5 ? 5 : scalar(@remains))."'".
                ($type ne "local" ? "" : " disabled").
                (@ipranges ? "" : " required").(@remains > 1 ? " multiple" : "").">".
            join("", map { "
                <option".(($select && $select eq $_) || @remains == 1 ? " selected" : "").
            " value='".encode('UTF-8', encode_entities($_))."'>".encode('UTF-8', encode_entities($ip_range{$_}->{name} || $_))."</option>"
          } sort { $a cmp $b } @remains)."
              </select>".(@remains > 1 ? "
              <br/>" : "").($form{empty} ? "" : "
              <input type='submit' name='submit/add-iprange' value='".(_"Add ip range")."'/>")."
            </li>";
          }
          '';}
          </ul>
        </div>
      </div>
    </div>
    <div class='form-edit' id='netscan-options-2' style='display: {$type ne "local" ? "flex" : "none"}'>
      <label>{_"Options"}:</label>
      <div class='form-edit-row'>
        <div class='form-edit-row'>
          <label for='threads' class='run-options'>{_"Threads"}:</label>
          <select id='threads' name='input/threads' class='run-options'{$type ne "local" ? "" : " disabled"}>{
            foreach my $opt (@threads_options) {
              $OUT .= "
            <option" .
                ($threads_option && $threads_option eq $opt ? " selected" : "") .
                ">$opt</option>";
            }}
          </select>
        </div>
        <div class='form-edit-row'>
          <label for='timeout' class='run-options'>{_"SNMP Timeout"}:</label>
          <select id='timeout' name='input/timeout' class='run-options'{$type ne "local" ? "" : " disabled"}>{
            foreach my $opt (@timeout_options) {
              $OUT .= "
            <option".
                ($timeout_option && $timeout_option eq $opt ? " selected" : "").
                ">$opt</option>";
            }}
          </select>
        </div>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='desc'>{_"Description"}</label>
        <input class='input-row' type='text' id='desc' name='input/description' placeholder='{_"Description"}' value='{$job->{description} || $form{"input/description"} || ""}' size='40'>
      </div>
    </div>
    <input type='submit' class='big-button' name='submit/{
      $jobs{$edit} ?
        "update' value='"._("Update") :
        "add' value='"._("Create inventory task")}'/>
    <input type='submit' class='big-button' name='submit/cancel' value='{_("Cancel")}'/>
  </form>
  <script>
    function jobtype_change() \{
      var islocal = document.getElementById("type/local").checked;
      var localshow   = islocal ? "display: flex" : "display: none";
      var netscanshow = islocal ? "display: none" : "display: flex";
      // Local form
      document.getElementById("local-options").style = localshow;
      document.getElementById("tag-config").disabled = !islocal;
      document.getElementById("config-newtag").disabled = !islocal;
      // Netscan form
      document.getElementById("netscan-options-2").style = netscanshow;
      document.getElementById("netscan-options").style = netscanshow;
      document.getElementById("add-iprange").disabled = islocal;
      document.getElementById("select-iprange").disabled = islocal;
      document.getElementById("threads").disabled = islocal;
      document.getElementById("timeout").disabled = islocal;
    \}
    function config_new_tag () \{
      document.getElementById("config-newtag").disabled = false;
      document.getElementById("config-newtag-overlay").style.display = "block";
    \}
    function cancel_config_newtag () \{
      document.getElementById("config-newtag-overlay").style.display = "none";
      document.getElementById("config-newtag").disabled = true;
    \}
    function handle_rename () \{
      document.getElementById("input-rename").disabled = false;
      document.getElementById("rename-overlay").style.display = "block";
    \}
    function cancel_rename () \{
      document.getElementById("rename-overlay").style.display = "none";
      document.getElementById("input-rename").disabled = true;
    \}
    function updateSelectIprange (select) \{
      var input = document.getElementById("add-iprange-select")
      var options = select.options;
      input.value = '';
      for (var i = 0; i < options.length; i++) \{
        if (options[i].selected) \{
          if (input.value[0] != null)
            input.value += "&";
          input.value += encodeURIComponent(options[i].value);
          options[i].selected = true;
        \}
      \}
    \}
  </script>
