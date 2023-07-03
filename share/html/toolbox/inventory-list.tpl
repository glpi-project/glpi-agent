
  <h2>{_"Inventory tasks"}</h2>
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' id='display' name='display' value='{$display}'/>{
    use Encode qw(encode);
    use HTML::Entities;
    use URI::Escape;
    $listnav = Text::Template::fill_in_file($template_path."/list-navigation.tpl", HASH => $hash)
      || "Error loading list-navigation.tpl template: $Text::Template::ERROR" }
    <table class='inventory'>
      <thead>
        <tr>
          <th class='checkbox' title='{_"Revert selection"}'>{ @jobs_order ? "
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' onclick='toggle_all(this)'/>
              <span class='custom-checkbox all_cb'></span>
            </label>
          ": "&nbsp;"
          }</th>{
  $other_order = $order eq 'ascend' ? 'descend' : 'ascend';
  foreach my $column (@columns) {
    my ($name, $text) = @{$column};
    my $order_req = $name eq $ordering_column ? $other_order : $order;
    $OUT .= "
          <th".($name eq $ordering_column ? " class='col-sort-$order'" : "").">
            <a class='noline' href='$url_path/$request?col=$name&order=$order_req'";
    $OUT .= "&start=$start" if $start;
    $OUT .= ">"._($text)."</a></th>";
  }}
        </tr>
      </thead>
      <tbody>{
  my $count = -$start;
  @running = ();
  $listed = 0;
  foreach my $entry (@jobs_order) {
    next unless $count++>=0;
    $listed++;
    my $job         = $jobs{$entry};
    my $this        = encode('UTF-8', encode_entities($entry));
    my $name        = $job->{name} || $this;
    my $enabled     = $job->{enabled};
    my $type        = $job->{type} || "";
    $type = $job->{type} eq 'local' ? _"Local inventory" : _"Network scan"
        if $job->{type} && $job->{type} =~ /^local|netscan$/;
    my $config      = $job->{config} || "";
    my $scheduling  = $job->{scheduling} || [];
    my $lastrun     = $job->{last_run_date} ? localtime($job->{last_run_date}) : "";
    my $nextrun     = ($enabled ? localtime($job->{next_run_date}) : _"Disabled task") || "";
    my $description = $job->{description} || "";
    $enabled        = $enabled ? "" : " disabled";
    my @runs        = sort { $tasks{$b}->{time} <=> $tasks{$a}->{time} } grep { defined($tasks{$_}->{name}) && $tasks{$_}->{name} eq $entry } keys(%tasks);
    # A new running task starts with index=0, we should always show it
    my $eyeshow     = @runs && (!$tasks{$runs[0]}->{index} || (defined($form{"show-run/$entry"}) && $form{"show-run/$entry"} eq "on")) ? " checked" : "";
    $OUT .= "
        <tr class='$request'>
          <td class='checkbox'>
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' name='checkbox/".encode_entities($entry)."'".
              ($form{"checkbox/".$entry} eq "on" ? " checked" : "")."/>
              <span class='custom-checkbox'></span>
            </label>
          </td>
          <td class='list' width='10%'>";
    $OUT .= "
          <div class='flex'>"
      if @runs;
    $OUT .= "<a href='$url_path/$request?edit=".uri_escape($this)."'>$name</a>";
    $OUT .= "
            <div class='grow'></div>
            <label class='eye'>
              <input id='show-run-$this' name='show-run/$this' class='eye' type='checkbox' onclick='visibility(\"$this\")'$eyeshow/>
              <span id='eye-$this' class='".($eyeshow ? "eye-hide" : "eye-show")."'/>
            </label>
          "
      if @runs;
    my @configuration;
    my $target = $config->{target};
    my @target_tooltip;
    if ($target && $targets{$target}) {
      @target_tooltip = ( $targets{$target}->[0], encode('UTF-8', encode_entities($targets{$target}->[1])));
    } else {
      $target = _("Agent folder");
      @target_tooltip = ( local => $target );
    }
    push @configuration, _("Target").":&nbsp;
            <div class='with-tooltip'>$target
              <div class='tooltip bottom-tooltip'>
                <p>".join("</p><p>", @target_tooltip)."</p>
                <i></i>
              </div>
            </div>";
    if ($job->{type} eq 'netscan' && ref($config->{ip_range}) eq 'ARRAY') {
      push @configuration, _("IP range").": ".join(",", map { "
            <div class='with-tooltip'>
              <a href='$url_path/ip_range?edit=".uri_escape(encode("UTF-8", $_))."'>".encode('UTF-8', encode_entities($_))."
                <div class='tooltip bottom-tooltip'>
                  <p>"._("First ip").": ".$ip_range{$_}->{ip_start}."</p>
                  <p>"._("Last ip").": ".$ip_range{$_}->{ip_end}."</p>
                  <p>"._("Credentials").": ".join(",", map { encode('UTF-8', encode_entities($_)) } @{$ip_range{$_}->{credentials}//[]})."</p>
                  <i></i>
                </div>
              </a>
            </div>"
        } @{$config->{ip_range}});
      push @configuration, _("Threads").": ".$config->{threads}
        if $config->{threads};
      push @configuration, _("Timeout").sprintf(": %ds", $config->{timeout})
        if $config->{timeout};
    }
    push @configuration, _("Tag").": ".$config->{tag}
      if defined($config->{tag}) && length($config->{tag});
    my @scheduling;
    if (ref($scheduling) eq 'ARRAY') {
      foreach my $sched (sort @{$scheduling}) {
        if ($scheduling{$sched}->{type} eq 'delay') {
          my %units = qw( s second m minute h hour d day w week);
          my $delay = $scheduling{$sched}->{delay} || "24h";
          my ($number, $unit) = $delay =~ /^(\d+)([smhdw])?$/;
          $number = 24 unless $number;
          $unit = "h" unless $unit;
          $unit = $units{$unit};
          $unit .= "s" if $number > 1;
          $delay = $number." "._($unit);
          push @scheduling, "
            <div class='with-tooltip'>
              <a href='$url_path/scheduling?edit=".uri_escape(encode("UTF-8", $sched))."'>".encode('UTF-8', encode_entities($sched))."
                <div class='tooltip bottom-tooltip'>
                  <p>"._("Delay").": ".$delay."</p>".($scheduling{$sched}->{description} ? "
                  <p>"._("Description").": ".encode('UTF-8', encode_entities($scheduling{$sched}->{description}))."</p>" : "")."
                  <i></i>
                </div>
              </a>
            </div>";
        } elsif ($scheduling{$sched}->{type} eq 'timeslot') {
          my $weekday  = $scheduling{$sched}->{weekday}
            or next;
          my $start    = $scheduling{$sched}->{start}
            or next;
          my $duration = $scheduling{$sched}->{duration}
            or next;
          my ($hour, $minute) = $start =~ /^(\d{2}):(\d{2})$/
            or next;
          my ($dhour, $dminute) = $duration =~ /^(\d{2}):(\d{2})$/
            or next;
          push @scheduling, "
            <div class='with-tooltip'>
              <a href='$url_path/scheduling?edit=".uri_escape(encode("UTF-8", $sched))."'>".encode('UTF-8', encode_entities($sched))."
                <div class='tooltip bottom-tooltip'>
                  <p>"._("day").": ".($weekday eq '*' ? _("all") : _($weekday))."</p>
                  <p>"._("start").": ".$hour."h".$minute."</p>
                  <p>"._("duration").": ".$dhour."h".$dminute."</p>".($scheduling{$sched}->{description} ? "
                  <p>"._("Description").": ".encode('UTF-8', encode_entities($scheduling{$sched}->{description}))."</p>" : "")."
                  <i></i>
                </div>
              </a>
            </div>";
        }
      }
    }
    $OUT .= "</td>
          <td class='list' width='10%'>$type</td>
          <td class='list$enabled' width='10%'>".join(",", @scheduling)."</td>
          <td class='list$enabled' width='15%'>$lastrun</td>
          <td class='list$enabled' width='15%'>$nextrun</td>
          <td class='list'>
            <ul class='config'>
              ".join("\n", map { "<li class='config'>$_</li>" } @configuration)."
            </ul>
          </td>
          <td class='list'>$description</td>
        </tr>";
    $OUT .= "
        <tr class='sub-row' id='run-$this' style='display: ".($eyeshow ? "table-row" : "none")."'>
          <td class='checkbox'>&nbsp;</td>
          <td class='list' colspan='7'>"
      if @runs;
    foreach my $run (@runs) {
      my $task = $tasks{$run};
      my $ip_ranges = $tasks{$run}->{ip_ranges} || [];
      my $percent = $task->{percent} || 0;
      my $done    = $task->{done}    || 0;
      my $aborted = $task->{aborted} || 0;
      my $failed  = $task->{failed}  || 0;
      push @running, $run
        unless ($done || $percent == 100 || $aborted);
      $OUT .= "
            <div class='task'>
              <div class='name-col'>
                <input id='expand-$run' name='expand/$run' class='expand-task' type='checkbox' onchange='expand_task(\"$run\")'".($form{"expand/$run"} && $form{"expand/$run"} eq "on" ? " checked" : "")."/>
                <label id='$run-expand-label' for='expand-$run' class='closed'>$this</label>
              </div>
              <div class='progress-col'>
                <div class='progress-bar'>
                  <div id='$run-scanned-bar' class='".($failed ? "failed" : $aborted ? "aborted" : ($percent == 100) ? "completed" : "scanning")."'>
                    <span id='$run-progress-bar-text' class='progressbar-text'>".(
                      $failed ? _("Failure") : $aborted ? _("Aborted") : ($percent == 100) ? _("Completed") : "")."</span>
                  </div>
                </div>
              </div>
            </div>";
      $OUT .= "
            <div id='$run-counters' class='task-details'>
              <div class='progress-col'>
                <div class='counters-row'>
                  <div class='counter-cell'>
                    <label>";
      if ($task->{islocal}) {
        $OUT .= _("Local inventory")."</label>
                  <div class='counters-row'>
                    <span class='counter' id='$run-inventory-count'>".($task->{inventory_count} || 0)."</span>
                  </div>
                </div>";
      } else {
        $OUT .= _("Created inventories")."</label>
                  <div class='counters-row'>
                    <span class='counter' id='$run-inventory-count' title='"._("Should match devices with SNMP support count")."'>
                      ".($task->{inventory_count} || 0).($task->{inventory_count} && $task->{snmp_support} ? "/".$task->{snmp_support} : "")."
                    </span>
                  </div>
                </div>
                <div class='counter-cell'>
                  <label>"._("Scanned IPs")."</label>
                  <div class='counters-row'>
                    <span class='counter' id='$run-scanned' title='"._("Scanned IPs for this IP range")."'>
                      ".($task->{count} || 0).($task->{count} && $task->{count} < $task->{maxcount} ? "/".$task->{maxcount} : "")."
                    </span>
                  </div>
                </div>
                <div class='counter-cell'>
                  <label>"._("Devices with SNMP support")."</label>
                  <div class='counters-row'>
                    <span class='counter' id='$run-snmp' title='"._("IPs for which we found a device supporting SNMP with provided credentials")."'>
                      ".($task->{snmp_support} || 0).($task->{snmp_support} && $task->{count} ? "/".$task->{count} : "")."
                    </span>
                  </div>
                </div>
                <div class='counter-cell'>
                  <label>"._("IPs without SNMP response")."</label>
                  <div class='counters-row'>
                    <span class='counter' id='$run-others' title='"._("These IPs are responding to ping or are found in ARP table")."\n".
                      _("But we didn't find any device supporting SNMP with provided credentials")."'>
                      ".($task->{others_support} || 0).($task->{others_support} && $task->{count} ? "/".$task->{count} : "")."
                    </span>
                  </div>
                </div>
                <div class='counter-cell'>
                  <label>"._("IPs without PING response")."</label>
                  <div class='counters-row'>
                    <span class='counter' id='$run-unknown' title='"._("IPs not responding to ping and not seen in ARP table")."'>
                      ".($task->{unknown} || 0).($task->{unknown} && $task->{count} ? "/".$task->{count} : "")."
                    </span>
                  </div>
                </div>";
      }
      my $freeze_status = " disabled";
      unless ($done || $percent == 100) {
        $freeze_status = " onclick='toggle_freeze_log(\"$run\")'";
        $freeze_status .= " checked" if $form{"freeze-log/$run"} && $form{"freeze-log/$run"} eq 'on';
      }
      my $verbosity = $form{"verbosity/$run"} // "debug";
      $OUT .= "
            </div>
            <div class='output-header'>
              <label class='switch'>
                <input id='show-log-$run' name='show-log/$run' class='switch' type='checkbox' onclick='show_log(\"$run\")'".($form{"show-log/$run"} && $form{"show-log/$run"} eq "on" ? " checked" : "")."/>
                <span class='slider'></span>
              </label>
              <label for='show-log-$run' class='text'>".sprintf( _("Show &laquo;&nbsp;%s&nbsp;&raquo; task log"), $this)."</label>
              <div class='abort-button' id='$run-abort-button'>".(($done || $percent == 100 || $aborted)? "" :
                "<input class='submit-secondary' type='button' name='abort/$run' value='"._("Abort")."' onclick='abort_task(\"$run\")'/>")."
              </div>
              <div class='log-freezer' id='$run-freeze-log-option'>
                <label class='switch'>
                  <input id='freeze-log-$run' name='freeze-log/$run' class='freezer-switch' type='checkbox'$freeze_status/>
                  <span class='slider'></span>
                </label>
                <label for='freeze-log-$run' class='text text-fix'>"._("Freeze log output")."</label>
              </div>
              <div class='verbosity-option' id='$run-verbosity-option'>
                "._("Verbosity").":
                <select id='$run-verbosity' name='verbosity/$run' class='verbosity-options' onchange='verbosity_change(\"$run\");'>";
      foreach my $opt (qw(info debug debug2)) {
        $OUT .= "
                <option".($verbosity && $verbosity eq $opt ? " selected" : "").">$opt</option>";
      }
      $OUT .= "
                </select>
              </div>
            </div>
            <textarea id='$run-output' class='output' wrap='off' readonly style='display: none'></textarea>
          </div>
        </div>
      </li>";
      last;
    }
    $OUT .= "
          </td>
        </tr>"
      if @runs;
    last if $display && $count >= $display;
  }
  # Handle empty list case
  unless (@jobs_order) {
    $OUT .= "
        <tr class='$request'>
          <td width='20px'>&nbsp;</td>
          <td class='list' colspan='7'>"._("empty list")."</td>
        </tr>";
  }
  $OUT .= "
      </tbody>";
  if ($listed >= 50) {
    $OUT .= "
      <tbody>
        <tr>
          <th class='checkbox' title='"._("Revert selection")."'>
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' onclick='toggle_all(this)'/>
              <span class='custom-checkbox all_cb'></span>
            </label>
          </th>";
    foreach my $column (@columns) {
      my ($name, $text) = @{$column};
      my $other_order = $order eq 'ascend' ? 'descend' : 'ascend';
      my $order_req = $name eq $ordering_column ? $other_order : $order;
      $OUT .= "
          <th".($name eq $ordering_column ? " class='col-sort-$order'" : "").">
            <a class='noline' href='$url_path/$request?col=$name&order=$order_req'";
      $OUT .= "&start=$start" if $start;
      $OUT .= ">"._($text)."</a></th>";
    }
    $OUT .= "
        </tr>
      </tbody>";
  }}
    </table>{
    $listed >= 50 ? $listnav : "" }
    <div class='select-row'>
      <div class='arrow-left'></div>
      <input class='submit-secondary' type='submit' name='submit/run-now' value='{_"Run task"}'/>
      <div class='separation'></div>
      <input class='submit-secondary' type='submit' name='submit/disable' value='{_"Disable"}'/>
      <input class='submit-secondary' type='submit' name='submit/enable' value='{_"Enable"}'/>
      <div class='separation'></div>
      <label class='selection-option'>{_"IP range"}:</label>
      <select class='selection-option' name='input/ip_range'>
        <option{
          $ip_range = $form{"input/credentials"} || "";
          $ip_range ? "" : " selected"}></option>{
          join("", map { "
        <option".(($ip_range && $ip_range eq $_)? " selected" : "").
          " value='$_'>".($ip_range{$_}->{name} || $_)."</option>"
        } @iprange_options)}
      </select>
      <input class='submit-secondary' type='submit' name='submit/add-iprange' value='{_"Add ip range"}'/>
      <input class='submit-secondary' type='submit' name='submit/rm-iprange' value='{_"Remove ip range"}'/>
      <div class='separation'></div>
      <input class='submit-secondary' type='submit' name='submit/delete' value='{_"Delete"}'/>
    </div>
    <hr/>
    <input class='big-button' type='submit' name='submit/add' value='{_"Add new inventory task"}'/>
  </form>
  <script>
  var outputids = [{ join(", ", map { "'$_'" } @running) }];
  var output_index = \{{ join(", ", map { "'$_': 0" } @running) }\};
  var freezed_log = \{{ join(", ", map { "'$_': false" } @running) }\};
  var whats = \{{ join(", ", map { "'$_': 'full'" } @running) }\};
  var ajax_queue = [];
  var ajax_trigger;
  var xhttp = window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject('Microsoft.XMLHTTP');
  function toggle_all(from) \{
    var all_cb = document.querySelectorAll('input[type="checkbox"]');
    for ( var i = 0; i < all_cb.length; i++ )
      if (all_cb[i].className === 'checkbox' && all_cb[i] != from)
        all_cb[i].checked = !all_cb[i].checked;
  \}
  function visibility(task) \{
    eye = document.getElementById('eye-'+task);
    if (eye.className === 'eye-show') \{
      eye.className = 'eye-hide';
      document.getElementById('run-'+task).style.display = "table-row";
    \} else \{
      eye.className = 'eye-show';
      document.getElementById('run-'+task).style.display = "none";
    \}
  \}
  function expand_task(task) \{
    var expand = document.getElementById('expand-'+task);
    document.getElementById(task+'-counters').style.display = expand.checked ? "flex" : "none";
    document.getElementById(task+'-expand-label').className = expand.checked ? 'opened' : 'closed';
  \}
  function show_log(task) \{
    var output, checked, completed, aborted;
    checked = document.getElementById('show-log-'+task).checked;
    output = document.getElementById(task+'-output');
    completed = document.getElementById(task+'-scanned-bar').className === "completed";
    aborted = document.getElementById(task+'-scanned-bar').className === "aborted";
    failed = document.getElementById(task+'-scanned-bar').className === "failed";
    if (completed || aborted || failed) \{
      document.getElementById(task+'-freeze-log-option').innerHTML = '';
      document.getElementById(task+'-abort-button').innerHTML = '';
    \}
    document.getElementById(task+'-freeze-log-option').style.display = checked ? 'block' : 'none';
    document.getElementById(task+'-verbosity-option').style.display = checked ? 'block' : 'none';
    output.style.display = checked ? 'block' : 'none';
    if (checked && output.innerHTML === '') ajax_load('full', task);
  \}
  function toggle_freeze_log(task) \{
    var checked = document.getElementById('freeze-log-'+task).checked;
    freezed_log[task] = checked;
    if (!checked) ajax_load('full', task);
  \}
  xhttp.onreadystatechange = function() \{
    if (this.readyState === 4 && this.status === 200) \{
      var index, running, inventory_count, percent, task, output, aborted;
      task = this.getResponseHeader('X-Inventory-Task');
      output = document.getElementById(task+'-output');
      index = this.getResponseHeader('X-Inventory-Index');
      if (!freezed_log[task]) \{
        if (this.getResponseHeader('X-Inventory-Output') === 'full') \{
          output.innerHTML = this.responseText;
          output.scrollTop = 0;
        \} else \{
          output.innerHTML += this.responseText;
          if (index && output_index[task] != index ) output.scrollTop = output.scrollHeight;
        \}
        if (index) output_index[task] = index;
      \}
      running = this.getResponseHeader('X-Inventory-Status') === 'running' ? true : false;
      aborted = this.getResponseHeader('X-Inventory-Status') === 'aborted' ? true : false;
      failed  = this.getResponseHeader('X-Inventory-Status') === 'failed'  ? true : false;
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
      if (percent === '100') \{
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
      \} else if (failed) \{
        document.getElementById(task+'-progress-bar-text').innerHTML = '{_"Failure"}';
        document.getElementById(task+'-scanned-bar').className = "failed";
      \} else \{
        document.getElementById(task+'-progress-bar-text').innerHTML = percent === '100' ? '{_"Completed"}' : '';
      \}
      if (running || (!aborted && (!percent || percent != '100'))) \{
        outputids.push(task);
        if (this.responseText != '...') whats[task] = 'more';
      \}
      if (ajax_queue.length) \{
        ajax_trigger = setTimeout(ajax_request, 100);
      \} else if (outputids.length) \{
        ajax_trigger = setTimeout(ajax_load, 100);
      \}
    \}
  \}
  function ajax_request() \{
    var url;
    if (ajax_queue.length) \{
      if (xhttp.readyState == 0 || xhttp.readyState == 4) \{
        url = ajax_queue.shift();
        xhttp.open('GET', url, true);
        xhttp.send();
      \} else \{
        ajax_trigger = setTimeout(ajax_request, 100);
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
      ajax_queue.push(url);
      ajax_trigger = setTimeout(ajax_request, 10);
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
      if (cb.className === 'expand-task' && cb.checked && cb.id != 'expand-runtask') expand_task(cb.id.slice(7));
      else if (cb.className === 'switch' && cb.checked) show_log(cb.id.slice(9));
  \}
  check_all_expandable();
  ajax_load();
  </script>
