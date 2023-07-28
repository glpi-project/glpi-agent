
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
    $edit_target   = $configuration->{target} || $form{"input/target"}  || ($form{empty} ? $default_target : "");
    $scheduling    = $job->{scheduling}    || [];
    $first_sched   = @{$scheduling} ? $scheduling->[0] : undef;
    $schedtype     = $first_sched ? $scheduling{$first_sched}->{type} : $form{"input/scheduling-type"} || "delay";
    $description   = $job->{description}   || $form{"input/description"}  || "";
    # Check timeslots count to decide how to show delay & timeslot select
    $timeslots     = scalar(grep { $scheduling{$_}->{type} eq 'timeslot' } keys(%scheduling));
    $delays        = scalar(grep { $scheduling{$_}->{type} eq 'delay' } keys(%scheduling));
    $delaysize     = $timeslots > 1 ? $timeslots < 5 ? $timeslots : 5 : 0;
    $delaysize     = $delays < 5 ? $delays : 5
      if $delays > $delaysize;
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
          <input class='input-row' type='text' id='name' name='input/name' value='{$name}' size='20'{($id ? " title='Id: $id'" : "")} required />
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='type-option'>
      <div class='form-edit'>
        <label>{_"Type"}</label>
        <div class='form-edit-row'>
          <ul class='options'>
            <li style='display: {$jobs{$edit} && $type ne "local" ? "none" : "block"}'>
              <input type="radio" name="input/type" id="type/local" value="local" onchange="jobtype_change()"{$type eq "local" ? " checked" : ""}/>
              <label for='local'>{_"Local inventory"}</label>
            </li>
            <li style='display: {$jobs{$edit} && $type ne "netscan" ? "none" : "block"}'>
              <input type="radio" name="input/type" id="type/netscan" value="netscan" onchange="jobtype_change()"{$type eq "netscan" ? " checked" : ""}/>
              <label for='netscan'>{_"Network scan"}</label>
            </li>
          </ul>
        </div>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='target-config' class='tag'>{_"Target"}</label>
        <select id='target-config' class='tag' name='input/target'>
          <option value=''{$edit_target ? "" : " selected"} title='local = {_"Agent folder"}'>{_"Agent folder"}</option>{
          foreach my $target (keys(%targets)) {
            my $encoded = $targets{$target}->[0]." = ".encode('UTF-8', encode_entities($targets{$target}->[1]));
            $OUT .= "
          <option id='target-$target'".
                ( $edit_target && $edit_target eq $target ? " selected" : "" )." title='$encoded'>$target</option>"
          }}
        </select>
      </div>
    </div>
    <div class='form-edit-row' id='scheduling-option'>
      <div class='form-edit'>
        <label for='input/scheduling/type'>{_"Scheduling type"}</label>
        <div class='form-edit-row'>
          <ul class='options'>
            <li>
              <input type="radio" name="input/scheduling/type" id="scheduling/type/delay" value="delay" onchange="schedtype_change()"{$schedtype eq "delay" ? " checked" : ""}/>
              <label for='scheduling/type/delay'>{_"Delay"}</label>
            </li>
            <li>
              <input type="radio" name="input/scheduling/type" id="scheduling/type/timeslot" value="timeslot" onchange="schedtype_change()"{$schedtype eq "timeslot" ? " checked" : ""}/>
              <label for='scheduling/type/timeslot'>{_"Timeslot"}</label>
            </li>
          </ul>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='delay-option' style='display: {$schedtype eq "delay" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='delay-config' class='tag'>{_"Delay"}</label>
        <div class='tag'>
          <select id='delay-config' class='tag' name='input/delay'{$delaysize ? " size='$delaysize'" : ""}{$schedtype ne 'delay' ? " disabled" : " required"}>{
            my %units = qw( s second m minute h hour d day w week);
            foreach my $delay (sort grep { $scheduling{$_}->{type} eq 'delay' } keys(%scheduling)) {
              my $value = $scheduling{$delay}->{delay} || "24h";
              my ($number, $unit) = $value =~ /^(\d+)([smhdw])?$/;
              $number = 24 unless $number;
              $unit = "h" unless $unit;
              $unit = $units{$unit};
              $unit .= "s" if $number > 1;
              my $title = _("Delay").": ".$number." "._($unit);
              my $description = $scheduling{$delay}->{description};
              if ($description) {
                $description =~ s/[']/\\'/g;
                $title .= "\n"._("Description").": ".encode('UTF-8', $description);
              }
              my $encoded = encode('UTF-8', encode_entities($delay));
              $OUT .= "
            <option id='option-$delay' title='$title'".
                  ( $first_sched && $first_sched eq $delay ? " selected" : "" ).
                  " value='$encoded'>$encoded</option>"
            }}
          </select>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='timeslot-option' style='display: {$schedtype eq "timeslot" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='timeslot-config' class='tag'>{_"Timeslots"}</label>
        <div class='tag'>{
            @timeslots = ();
            foreach my $timeslot (sort grep { $scheduling{$_}->{type} eq 'timeslot' } keys(%scheduling)) {
              my $weekday  = $scheduling{$timeslot}->{weekday}
                or next;
              my $start    = $scheduling{$timeslot}->{start}
                or next;
              my $duration = $scheduling{$timeslot}->{duration}
                or next;
              my ($hour, $minute) = $start =~ /^(\d{2}):(\d{2})$/
                or next;
              my ($dhour, $dminute) = $duration =~ /^(\d{2}):(\d{2})$/
                or next;
              my $title = _("Timeslot").":\n - ".ucfirst(_("day")).": ".ucfirst(($weekday eq '*' ? _("all") : _($weekday)));
              $title .= "\n - ".ucfirst(_("start")).": ".$hour."h".$minute."\n - ".ucfirst(_("duration")).": ".$dhour."h".$dminute;
              my $description = $scheduling{$delay}->{description};
              if ($description) {
                $description =~ s/[']/\\'/g;
                $title .= "\n"._("Description").": ".encode('UTF-8', $description);
              }
              push @timeslots, [ $timeslot, $title ];
            }
            $OUT .= "";
          }
          <input id='set-timeslot' type='hidden' name='set-timeslot' value='{ join("&", map { encode('UTF-8', encode_entities($_)) } grep { $scheduling{$_}->{type} eq 'timeslot' } @{$scheduling}) }'{$schedtype ne 'timeslot' ? " disabled" : ""}/>
          <select id='timeslot-config'{$delaysize ? " multiple size='$delaysize'" : "" } onchange='updateSelectTimeslot(this)' class='tag' name='input/timeslot'{$schedtype ne 'timeslot' ? " disabled" : " required"}>{
            foreach my $timeslot (@timeslots) {
              my ($name, $title) = @{$timeslot};
              my $encoded = encode('UTF-8', encode_entities($name));
              $OUT .= "
            <option id='option-$name' title='$title'".((grep { $_ eq $name } @{$scheduling}) ? " selected" : "" )." value='$encoded'>$encoded</option>";
            }}
          </select>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='tag-option'>
      <div class='form-edit'>
        <label for='tag' class='tag'>{_"Use a tag"}</label>
        <em class='hint' id='tag-option-condition' style='display: {$type eq "local" ? "none" : "flex"}'>{_"Only for remote inventory and ESX tasks"}</em>
        <div class='tag'>
          <select id='tag-config' class='tag' name='input/tag'>
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
              <input id='config-newtag' class='newtag' type='text' name='input/newtag' value='' size='20' title='{_"New tag will be automatically selected"}' disabled />
              <button type='submit' class='big-button' name='submit/newtag' alt='{_"Add"}'><i class='primary ti ti-plus'></i>{_"Add"}</button>
              <button type='button' class='big-button' name='submit/newtag-cancel' alt='{_"Cancel"}' onclick='cancel_config_newtag()'><i class='primary ti ti-x'></i>{_"Cancel"}</button>
            </div>
          </div>
      </div>
    </div>
    <div class='form-edit-row' id='netscan-options' style='display: {$type ne "local" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label>{_"Associated ip ranges"}</label>
        <div id='ip-ranges'>
          <ul class='options'>{
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
              <input type='checkbox' name='checkbox/ip_range/".encode('UTF-8', encode_entities($name))."' checked />
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
              <input id='add-iprange' type='hidden' name='add-iprange' value='".(@remains == 1 ? encode('UTF-8', encode_entities($remains[0])) : "")."'".($type ne "local" ? "" : " disabled")."/>
              <select id='select-iprange' class='iprange' onchange='updateSelectIprange(this)' size='".
                (@remains > 5 ? 5 : scalar(@remains))."'".
                ($type ne "local" ? "" : " disabled").
                (@ipranges ? "" : " required").(@remains > 1 ? " multiple" : "").">".
            join("", map { "
                <option".(($select && $select eq $_) || @remains == 1 ? " selected" : "").
                " title='"._("First ip").": ".$ip_range{$_}->{ip_start}."\n"._("Last ip").": ".$ip_range{$_}->{ip_end}."\n"._("Credentials").": ".join(",", map { encode('UTF-8', encode_entities($_)) } @{$ip_range{$_}->{credentials}//[]})."' ".
            " value='".encode('UTF-8', encode_entities($_))."'>".encode('UTF-8', encode_entities($ip_range{$_}->{name} || $_))."</option>"
          } sort { $a cmp $b } @remains)."
              </select>".(@remains > 1 ? "
              <br/>" : "").($form{empty} ? "" : "
              <button type='submit' class='secondary' name='submit/add-iprange' alt='".(_"Add ip range")."'><i class='secondary ti ti-plus'></i>".(_"Add ip range")."</button>")."
            </li>";
          }
          '';}
          </ul>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='netscan-options-2' style='display: {$type ne "local" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='threads'>{_"Threads"}</label>
        <select id='threads' name='input/threads' class='run-options'{$type ne "local" ? "" : " disabled"}>{
          foreach my $opt (@threads_options) {
            $OUT .= "
          <option" .
              ($threads_option && $threads_option eq $opt ? " selected" : "") .
              ">$opt</option>";
          }}
        </select>
      </div>
    </div>
    <div class='form-edit-row' id='netscan-options-3' style='display: {$type ne "local" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='timeout'>{_"SNMP Timeout"}</label>
        <select id='timeout' name='input/timeout' class='run-options'{$type ne "local" ? "" : " disabled"}>{
          foreach my $opt (@timeout_options) {
            $OUT .= "
          <option".
              ($timeout_option && $timeout_option eq $opt ? " selected" : "").
              " value='$opt'>${opt}s</option>";
          }}
        </select>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='desc'>{_"Description"}</label>
        <input class='input-row' type='text' id='desc' name='input/description' value='{$job->{description} || $form{"input/description"} || ""}' size='40'/>
      </div>
    </div>
    <button type='submit' class='big-button' name='submit/{
      $jobs{$edit} ?
        "update' alt='"._("Update") :
        "add' alt='"._("Create inventory task")}'><i class='primary ti ti-device-floppy'></i>{$jobs{$edit} ? _("Update") : _("Create inventory task")}</button>
    <button type='submit' class='big-button secondary-button' name='submit/cancel' formnovalidate='1' alt='{_("Cancel")}'><i class='primary ti ti-x'></i>{_("Cancel")}</button>
  </form>
  <script>
    function jobtype_change() \{
      var islocal = document.getElementById("type/local").checked;
      var netscanshow = islocal ? "display: none" : "display: flex";
      // Tag option
      document.getElementById("tag-option-condition").style = netscanshow;
      // Netscan form
      document.getElementById("netscan-options-2").style = netscanshow;
      document.getElementById("netscan-options-3").style = netscanshow;
      document.getElementById("netscan-options").style = netscanshow;
      document.getElementById("add-iprange").disabled = islocal;
      document.getElementById("select-iprange").disabled = islocal;
      document.getElementById("threads").disabled = islocal;
      document.getElementById("timeout").disabled = islocal;
    \}
    function schedtype_change() \{
      var isdelay = document.getElementById("scheduling/type/delay").checked;
      var delayshow = isdelay ? "display: flex" : "display: none";
      var timeslotshow = isdelay ? "display: none" : "display: flex";
      // Delay options
      document.getElementById("delay-option").style = delayshow;
      document.getElementById("delay-config").disabled = !isdelay;
      document.getElementById("delay-config").required = isdelay;
      document.getElementById("timeslot-option").style = timeslotshow;
      document.getElementById("timeslot-config").disabled = isdelay;
      document.getElementById("timeslot-config").required = !isdelay;
      document.getElementById("set-timeslot").disabled = isdelay;
    \}
    function config_new_tag () \{
      document.getElementById("config-newtag").disabled = false;
      document.getElementById("config-newtag-overlay").style.display = "block";
    \}
    function cancel_config_newtag () \{
      document.getElementById("config-newtag-overlay").style.display = "none";
      document.getElementById("config-newtag").disabled = true;
    \}
    function updateSelectIprange (select) \{
      var input = document.getElementById("add-iprange")
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
    function updateSelectTimeslot (select) \{
      var input = document.getElementById("set-timeslot")
      var options = select.options;
      input.value = '';
      for (var i = 0; i < options.length; i++) \{
        if (options[i].selected && options[i].value != '') \{
          if (input.value[0] != null)
            input.value += "&";
          input.value += encodeURIComponent(options[i].value);
          options[i].selected = true;
        \}
      \}
    \}
  </script>
