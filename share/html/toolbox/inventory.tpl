  <h2>{_"Create a new inventory task"}</h2>
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <label for='tag' class='tag'>{_"Use a tag"}:</label>
    <div class='tag'>
      <select id='tag' class='tag' name='input/tag'>
        <option value=''{!$current_tag ? " selected" : ""}>{_"None"}</option>{
        use Encode qw(encode);
        use HTML::Entities;
        foreach my $tag (@tag_options) {
          my $encoded = encode('UTF-8', encode_entities($tag));
          $OUT .= "
        <option id='option-$tag'".
              ( $current_tag && $current_tag eq $tag ? " selected" : "" ).
              " value='$encoded'>$encoded</option>"
        }}
      </select>
      <a class='tag' onclick='new_tag()'>{_"Add new tag"}</a>
    </div>
    <div id='newtag-overlay' class='overlay' onclick='cancel_newtag()'>
      <div class='overlay-frame' onclick='event.stopPropagation()'>
        <label for='newtag' class='newtag' title='{_"New tag will be automatically selected"}'>{_"New tag"}:</label>
        <input id='newtag' class='newtag' type='text' name='input/newtag'  placeholder='{_"tag"}' value='' size='20' title='{_"New tag will be automatically selected"}'>
        <input type='submit' class='big-button' name='submit/newtag' value='{_"Add"}'>
        <input type='button' class='big-button' name='submit/newtag-cancel' value='{_"Cancel"}' onclick='cancel_newtag()'>
      </div>
    </div>
    <div class='run-tasks'>
      <div class='run-task'>
        <label class='task'>{_"Local inventory"}</label>
        <input type='submit' class='big-button' name='submit/localinventory' value='{_"Run local inventory for this computer"}'>
      </div>
      <div class='run-task'>
        <label class='task'>{_"Network scan"}</label>{
            $msg = $missingdeps == 1 ? _"netdiscovery task not installed" :
                $missingdeps == 2 ? _"netinventory task not installed" :
                    _"netdiscovery and netinventory tasks not installed"
                if $missingdeps;
            $OUT = $missingdeps ? "<div class='missing-deps'>$msg</div>" : "";
        }
        <label for='ip_range'>{_"Choose IP range"}:</label>
        <select id='ip_range' name='input/ip_range'{$missingdeps ? " disabled" : ""}>
          <option></option>{
            foreach my $range (sort keys(%ip_range)) {
              my $name = encode('UTF-8', encode_entities($ip_range{$range}->{name} || $range));
              $range = encode('UTF-8', encode_entities($range));
              $OUT .= "
          <option id='option-$range'".
                ( $set_range && $set_range eq $range ? " selected" : "" ).
                " value='$range'>$name</option>"
            }}
        </select>
        <br/>
        <label class='task-options'>{_"Options"}:&nbsp;</label>
        <div class='task-options'>
          <label class='run-options'>{_"Threads"}:</label>
          <select id='threads' name='input/threads' class='run-options'{$missingdeps ? " disabled" : ""}>{
            foreach my $opt (@threads_options) {
              $OUT .= "
            <option" .
                ($threads_option && $threads_option eq $opt ? " selected" : "") .
                ">$opt</option>";
            }}
          </select>
          <label class='run-options'>{_"SNMP Timeout"}:</label>
          <select id='timeout' name='input/timeout' class='run-options'{$missingdeps ? " disabled" : ""}>{
            foreach my $opt (@timeout_options) {
              $OUT .= "
            <option".
                ($timeout_option && $timeout_option eq $opt ? " selected" : "").
                ">$opt</option>";
            }}
          </select>
        </div>
        <br/>
        <input type='submit' class='big-button' name='submit/netscan' value='{_"Run network scan"}'{$missingdeps ? " disabled" : ""}>
      </div>
    </div>
  </form>
  <script>
    function new_tag () \{
      document.getElementById("newtag-overlay").style.display = "block";
    \}
    function cancel_newtag () \{
      document.getElementById("newtag-overlay").style.display = "none";
    \}
    document.onkeydown = function(event) \{
      event = event || window.event;
      var isEscape = false;
      if ("key" in event) isEscape = (event.key === "Escape" || event.key === "Esc");
      else isEscape = (event.keyCode === 27);
      if (isEscape) document.getElementById("newtag-overlay").style.display = "none";
    \}
  </script>{
  $outputid ?
    Text::Template::fill_in_file($template_path."/inventory-tasks.tpl", HASH => $hash)
    : ""}
