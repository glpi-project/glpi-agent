
  <hr/>{
    use Encode qw(encode);
    use HTML::Entities;
  }
  <ul class='tasks'>
    <li class='task'>
      <div class='name-col' title='{_"Run inventory task"}'>
        <input id='expand-runtask' class='expand-task' type='checkbox' onchange='expand_runtask()'{$form{expanded} ? " checked" : ""}>
        <label id='runtask-expand-label' for='expand-runtask' class='{$form{expanded} ? " opened" : "closed"}'>{_"Run inventory task"}</label>
      </div>
      <form name='{$request}' method='post' action='{$url_path}/{$request}'>
        <input type='hidden' name='form' value='{$request}'/>
        <input type='hidden' name='expanded' value='{$form{expanded} ? "1" : "0"}' id='runtask-expand'/>
        <input type='hidden' name='edit' value='{encode("UTF-8", encode_entities($edit))}'/>{
          $form{empty} ? "
        <input type='hidden' name='empty' value='1'/>" : "" }
        <div class='run-tasks' style='display: {$form{expanded} ? "flex" : "none"}' id='runtask'>
          <div class='run-task'>
            <label class='task'>{_"Local inventory"}</label>
            <label for='tag' class='tag'>{_"Use a tag"}:</label>
            <div class='tag'>
              <select id='tag' class='tag' name='input/tag'>
                <option value=''{!$current_tag ? " selected" : ""}>{_"None"}</option>{
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
            <br />
            <input type='submit' class='big-button' name='submit/localinventory' value='{_"Run local inventory for this computer"}'>
            <!--label class='task'>{_"Create a new inventory task"}</label-->
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
              <option{$form{'input/ip_range'} ? "" : " selecetd"}></option>{
                foreach my $range (sort keys(%ip_range)) {
                  my $name = encode('UTF-8', encode_entities($ip_range{$range}->{name} || $range));
                  $range = encode('UTF-8', encode_entities($range));
                  $OUT .= "
              <option id='option-$range'".
                    ( $form{'input/ip_range'} && $form{'input/ip_range'} eq $range ? " selected" : "" ).
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
    </li>
  </ul>
  <script>
    function expand_runtask() \{
      var expand = document.getElementById('expand-runtask');
      document.getElementById("runtask").style.display = expand.checked ? "flex" : "none";
      document.getElementById("runtask-expand-label").className = expand.checked ? 'opened' : 'closed';
      document.getElementById("runtask-expand").value = expand.checked ? "1" : "0";
    \}
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
      if (isEscape) \{
        document.getElementById("newtag-overlay").style.display = "none";
        document.getElementById("config-newtag-overlay").style.display = "none";
      \}
    \}
  </script>
