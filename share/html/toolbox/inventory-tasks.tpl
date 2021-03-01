
  <hr/>
  <h2>{_"Inventory tasks"}</h2>
  <ul class='tasks'>{
  use Encode qw(encode);
  use HTML::Entities;
  @tasks = sort { $tasks{$b}->{time} <=> $tasks{$a}->{time} } keys(%tasks);
  @running = ();
  foreach my $task (@tasks) {
    my $opened = $opened_task && $opened_task eq $task;
    my $ip_range = encode('UTF-8', encode_entities($tasks{$task}->{ip_range} || ''));
    my $value = $tasks{$task}->{name};
    $value .= ": ".($tasks{$task}->{ip} ? $tasks{$task}->{ip}."/":"").$ip_range if $ip_range;
    my $percent = $tasks{$task}->{percent} || 0;
    my $done    = $tasks{$task}->{done}    || 0;
    my $aborted = $tasks{$task}->{aborted} || 0;
    push @running, $task
      unless ($done || $percent == 100 || $aborted);
    $OUT .= "
    <li class='task'>
      <div class='task'>
        <div class='name-col'".($ip_range ? " title='".sprintf(_("%s network scan"), $ip_range)."'" : "").">
          <input id='expand-$task' class='expand-task' type='checkbox' onchange='expand_task(\"$task\")'>
          <label id='$task-expand-label' for='expand-$task' class='closed'>$value</label>
        </div>
        <div class='progress-col'>
          <div class='progress-bar'>
            <div id='$task-scanned-bar' class='".($percent == 100 ? "completed" : $aborted ? "aborted" : "scanning")."'>
              <span id='$task-progress-bar-text' class='progressbar-text'>".(
                $percent == 100 ? _("Completed") : $aborted ? _("Aborted") : "")."</span>
            </div>
          </div>
        </div>
      </div>";
    $OUT .= "
      <div id='$task-counters' class='task-details'>
        <div class='progress-col'>
          <div class='counters-row'>
            <div class='counter-cell'>
              <label>";
    if ($tasks{$task}->{ip_range}) {
      $OUT .= _("Created inventories")."</label>
              <div class='counters-row'>
                <span class='counter' id='$task-inventory-count' title='"._("Should match devices with SNMP support count")."'>
                  ".($tasks{$task}->{inventory_count} || 0).($tasks{$task}->{inventory_count} && $tasks{$task}->{snmp_support} ? "/".$tasks{$task}->{snmp_support} : "")."
                </span>
              </div>
            </div>
            <div class='counter-cell'>
              <label>"._("Scanned IPs")."</label>
              <div class='counters-row'>
                <span class='counter' id='$task-scanned' title='"._("Scanned IPs for this IP range")."'>
                  ".($tasks{$task}->{count} || 0).($tasks{$task}->{count} && $tasks{$task}->{count} < $tasks{$task}->{maxcount} ? "/".$tasks{$task}->{maxcount} : "")."
                </span>
              </div>
            </div>
            <div class='counter-cell'>
              <label>"._("Devices with SNMP support")."</label>
              <div class='counters-row'>
                <span class='counter' id='$task-snmp' title='"._("IPs for which we found a device supporting SNMP with provided credentials")."'>
                  ".($tasks{$task}->{snmp_support} || 0).($tasks{$task}->{snmp_support} && $tasks{$task}->{count} ? "/".$tasks{$task}->{count} : "")."
                </span>
              </div>
            </div>
            <div class='counter-cell'>
              <label>"._("IPs without SNMP response")."</label>
              <div class='counters-row'>
                <span class='counter' id='$task-others' title='"._("These IPs are responding to ping or are found in ARP table")."\n".
                  _("But we didn't find any device supporting SNMP with provided credentials")."'>
                  ".($tasks{$task}->{others_support} || 0).($tasks{$task}->{others_support} && $tasks{$task}->{count} ? "/".$tasks{$task}->{count} : "")."
                </span>
              </div>
            </div>
            <div class='counter-cell'>
              <label>"._("IPs without PING response")."</label>
              <div class='counters-row'>
                <span class='counter' id='$task-unknown' title='"._("IPs not responding to ping and not seen in ARP table")."'>
                  ".($tasks{$task}->{unknown} || 0).($tasks{$task}->{unknown} && $tasks{$task}->{count} ? "/".$tasks{$task}->{count} : "")."
                </span>
              </div>
            </div>";
    } else {
      $OUT .= _("Local inventory")."</label>
              <div class='counters-row'>
                <span class='counter' id='$task-inventory-count'>".($tasks{$task}->{inventory_count} || 0)."</span>
              </div>
            </div>";
    }
    $OUT .= "
          </div>
          <div class='output-header'>
            <label class='switch'>
              <input id='show-log-$task' class='switch' type='checkbox' onclick='show_log(\"$task\")'>
              <span class='slider'></span>
            </label>
            <label for='show-log-$task' class='text'>".sprintf( _("Show &laquo;&nbsp;%s&nbsp;&raquo; task log"), $tasks{$task}->{name}.($ip_range ? ": $ip_range" : ""))."</label>
            <div class='abort-button' id='$task-abort-button'>".(($done || $percent == 100 || $aborted)? "" :
              "<input class='submit-secondary' type='button' name='abort/$task' value='"._("Abort")."' onclick='abort_task(\"$task\")'>")."
            </div>
            <div class='log-freezer' id='$task-freeze-log-option'>
              <label class='switch'>
                <input id='freeze-log-$task' class='freezer-switch' type='checkbox'".(($done || $percent == 100)? " disabled" : " onclick='toggle_freeze_log(\"$task\")'").">
                <span class='slider slider-fix'></span>
              </label>
              <label for='freeze-log-$task' class='text text-fix'>"._("Freeze log output")."</label>
            </div>
            <div class='verbosity-option' id='$task-verbosity-option'>
              "._("Verbosity").":
              <select id='$task-verbosity' class='verbosity-options' onchange='verbosity_change(\"$task\");'>";
    foreach my $opt (qw(info debug debug2)) {
      $OUT .= "
              <option".($verbosity && $verbosity eq $opt ? " selected" : "").">$opt</option>";
    }
    $OUT .= "
              </select>
            </div>
          </div>
          <textarea id='$task-output' class='output' wrap='off' readonly style='display: none'></textarea>
        </div>
      </div>
    </li>";
  }}
  </ul>
  <script>
  var outputids = [{ join(", ", map { "'$_'" } @running) }];
  var output_index = \{{ join(", ", map { "'$_': 0" } @running) }\};
  var freezed_log = \{{ join(", ", map { "'$_': false" } @running) }\};
  var whats = \{{ join(", ", map { "'$_': 'full'" } @running) }\};
  var ajax_trigger;
  var xhttp = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject('Microsoft.XMLHTTP');
  function expand_task(task) \{
    var expand = document.getElementById('expand-'+task);
    document.getElementById(task+'-counters').style.display = expand.checked ? "flex" : "none";
    document.getElementById(task+'-expand-label').className = expand.checked ? 'opened' : 'closed';
  \}
  function show_log(task) \{
    var output, checked, completed, aborted;
    checked = document.getElementById('show-log-'+task).checked;
    output = document.getElementById(task+'-output');
    completed = document.getElementById(task+'-scanned-bar').className == "completed";
    aborted = document.getElementById(task+'-scanned-bar').className == "aborted";
    if (completed || aborted) \{
      document.getElementById(task+'-freeze-log-option').innerHTML = '';
      document.getElementById(task+'-abort-button').innerHTML = '';
    \}
    document.getElementById(task+'-freeze-log-option').style.display = checked ? 'block' : 'none';
    document.getElementById(task+'-verbosity-option').style.display = checked ? 'block' : 'none';
    output.style.display = checked ? 'block' : 'none';
    if (checked && output.innerHTML == '') ajax_load('full', task);
  \}
  function toggle_freeze_log(task) \{
    var checked = document.getElementById('freeze-log-'+task).checked;
    freezed_log[task] = checked;
    if (!checked) ajax_load('full', task);
  \}
  xhttp.onreadystatechange = function() \{
    if (this.readyState == 4 && this.status == 200) \{
      var index, running, inventory_count, percent, task, output, aborted;
      task = this.getResponseHeader('X-Inventory-Task');
      output = document.getElementById(task+'-output');
      index = this.getResponseHeader('X-Inventory-Index');
      if (!freezed_log[task]) \{
        if (this.getResponseHeader('X-Inventory-Output')=='full') \{
          output.innerHTML = this.responseText;
          output.scrollTop = 0;
        \} else \{
          output.innerHTML += this.responseText;
          if (index && output_index[task] != index ) output.scrollTop = output.scrollHeight;
        \}
        if (index) output_index[task] = index;
      \}
      running = this.getResponseHeader('X-Inventory-Status')=='running' ? true : false;
      aborted = this.getResponseHeader('X-Inventory-Status')=='aborted' ? true : false;
      inventory_count = this.getResponseHeader('X-Inventory-Count');
      if (!this.getResponseHeader('X-Inventory-IsLocal')) \{
        var scanned, maxcount, permax, percount, snmp, others, unknown;
        scanned = this.getResponseHeader('X-Inventory-Scanned');
        maxcount = this.getResponseHeader('X-Inventory-MaxCount');
        permax = maxcount && Number(scanned)<Number(maxcount)? "/"+maxcount : "";
        document.getElementById(task+'-scanned').innerHTML = scanned ? scanned+permax : 0;
        percount = scanned ? "/"+scanned : "";
        others = this.getResponseHeader('X-Inventory-With-Others');
        snmp = this.getResponseHeader('X-Inventory-With-SNMP');
        document.getElementById(task+'-others').innerHTML = others ? others+percount : 0;
        document.getElementById(task+'-snmp').innerHTML = snmp ? snmp+percount : 0;
        unknown = this.getResponseHeader('X-Inventory-Unknown');
        document.getElementById(task+'-unknown').innerHTML = unknown ? unknown+percount : 0;
        inventory_count = inventory_count+(Number(snmp)?"/"+snmp:"")
      \}
      document.getElementById(task+'-inventory-count').innerHTML = inventory_count ? inventory_count : 0;
      percent = this.getResponseHeader('X-Inventory-Percent');
      document.getElementById(task+'-scanned-bar').style.width = percent+"%";
      if (percent == 100) \{
        document.getElementById(task+'-scanned-bar').className = "completed";
        if (freezed_log[task]) \{
          whats[task] = 'full';
          outputids.push(task);
          freezed_log[task] = false;
        \}
        document.getElementById(task+'-freeze-log-option').innerHTML = '';
        document.getElementById(task+'-abort-button').innerHTML = '';
      \}
      if (aborted) \{
        document.getElementById(task+'-progress-bar-text').innerHTML = '{_"Aborted"}';
        document.getElementById(task+'-scanned-bar').className = "aborted";
        document.getElementById(task+'-scanned-bar').style.width = "100%";
      \} else \{
        document.getElementById(task+'-progress-bar-text').innerHTML = percent == 100 ? '{_"Completed"}' : '';
      \}
      if (running || (!aborted && (!percent || percent < 100))) \{
        outputids.push(task);
        if (this.responseText != '...') whats[task] = 'more';
      \}
      if (outputids.length) \{
        ajax_trigger = setTimeout(ajax_load, outputids.length > 2 ? 10 : 250);
      \}
    \}
  \}
  function ajax_load(what, task) \{
    var url, verbosity;
    if (!task) task = outputids.shift();
    if (task) \{
      if (!what) what = whats[task];
      url = '{$url_path}/{$request}/ajax?id='+task+'&what='+what;
      verbosity = document.getElementById(task+'-verbosity').value;
      if (verbosity) url += '&'+verbosity
      if (output_index[task] && what != 'full') url += '&index=' + output_index[task];
      xhttp.open('GET', url, true);
      xhttp.send();
    \}
  \}
  function verbosity_change(task) \{
    if (ajax_trigger) clearTimeout(ajax_trigger);
    ajax_load('full', task);
  \}
  function abort_task(task) \{
    if (ajax_trigger) clearTimeout(ajax_trigger);
    ajax_load('abort', task);
  \}
  function htmldecode(str) \{
    var txt = document.createElement('textarea');
    txt.innerHTML = str;
    return txt.value;
  \}
  function check_all_expandable() \{
    var all_cb = document.querySelectorAll('input[type="checkbox"]');
    for ( var cb = all_cb[0], i = 0; i < all_cb.length; ++i, cb = all_cb[i] )
      if (cb.className == 'expand-task' && cb.checked) expand_task(cb.id.slice(7));
      else if (cb.className == 'switch' && cb.checked) show_log(cb.id.slice(9));
  \}
  check_all_expandable();
  ajax_load();
  </script>
