  <h2>{
    use Encode qw(encode);
    use HTML::Entities;
    use URI::Escape;
    $timeunit = 'hour';
    $schedule = $scheduling{$edit} || {};
    $this = encode('UTF-8', encode_entities($edit));
    $type = $schedule->{type} || $form{"input/type"} || "delay";
    if ($type eq 'delay' || $type ne 'timeslot') {
      $delay = $schedule->{delay} || $form{"input/delay"} || "24";
      my ($number, $unit) = $delay =~ /^(\d+)([smhdw])?$/;
      $delay = $number || "24";
      my %units = qw( s second m minute h hour d day w week );
      $timeunit = $units{$unit} if $unit && $units{$unit};
    } else { # timeslot type
      $weekday = $schedule->{weekday} || $form{"input/weekday"} || "*";
      my $start = $schedule->{start} || "00:00";
      my $duration = $schedule->{duration} || "00:00";
      ($hour, $minute) = $start =~ /^(\d{2}):(\d{2})$/;
      $hour = $form{"input/start/hour"} || "00"
        unless defined($hour);
      $minute = $form{"input/start/minute"} || "00"
        unless defined($minute);
      ($dhour, $dminute) = $duration =~ /^(\d{2}):(\d{2})$/;
      $dhour = $form{"input/duration/hour"} || "00"
        unless defined($dhour);
      $dminute = $form{"input/duration/minute"} || "00"
        unless defined($dminute);
    }
    $scheduling{$edit} ? sprintf(_("Edit &laquo;&nbsp;%s&nbsp;&raquo; scheduling"), ($schedule->{name} || $this))
      : _"Add new scheduling"}</h2>
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' name='edit' value='{$this}'/>{
      $form{empty} ? "
    <input type='hidden' name='empty' value='1'/>" : "" }
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='name'>{_"Name"}</label>
        <div class='form-edit-row'>
          <input class='input-row' type='text' id='name' name='input/name' value='{ $schedule->{name} || $this || $form{"input/name"} }' size='20'{$form{empty} ? "" : " disabled"}>
          <input type='button' class='button' value='{_"Rename"}' onclick='handle_rename()'{$form{empty} ? " style='display:none'" : ""}/>
        </div>
        <div id='rename-overlay' class='overlay' onclick='cancel_rename()'>
          <div class='overlay-frame' onclick='event.stopPropagation()'>
            <label for='rename' class='newtag'>{_"Rename"}:</label>
            <input id='input-rename' type='text' class='newtag' name='input/new-name' value='{ $form{"input/new-name"} || $schedule->{name} || $this }' size='30' disabled/>
            <input type='submit' class='big-button' name='submit/rename' value='{_"Rename"}'/>
            <input type='button' class='big-button' name='submit/rename-cancel' value='{_"Cancel"}' onclick='cancel_rename()'/>
          </div>
        </div>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label>{_"Type"}</label>
        <div class='form-edit-row' id='type-options'>
          <input type="radio" name="input/type" id="delay" value="delay"{$type eq "delay" ? " checked" : ""}{$form{empty} ? ' onchange="type_change()"' : ' disabled'}>
          <label for='delay'>{_("delay")}</label>
          <input type="radio" name="input/type" id="timeslot" value="timeslot"{$type eq "timeslot" ? " checked" : ""}{$form{empty} ? ' onchange="type_change()"' : ' disabled'}>
          <label for='timeslot'>{_("timeslot")}</label>
        </div>
      </div>
    </div>
    <div class='form-edit'>
      <label>{_"Configuration"}</label>
    </div>
    <div class='form-edit-row description' id='delay-description' style='display: {$type eq "delay" ? "flex" : "none"}'>
      {_"The approximate delay time between two tasks runs"}
    </div>
    <div class='form-edit-row description' id='timeslot-description' style='display: {$type eq "timeslot" ? "flex" : "none"}'>
      {_"Week day, day time and duration of a time slot during which a task will be executed once"}
    </div>
    <div class='form-edit-row' id='delay-config' style='display: {$type eq "delay" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='delaytime'>{_"Delay"}</label>
        <input class='input-row' type='number' id='delaytime' name='input/delay' value='{$delay || 24}' {$type ne "delay" ? " disabled" : ""}>
      </div>
      <div class='form-edit'>
        <label for='delayunit'>{_"Time unit"}</label>
        <div class='form-edit-row'>
          <select class='input-row' id='delayunit' name='input/timeunit' {$type ne "delay" ? " disabled" : ""}>
            <option{$timeunit eq "second" ? " selected" : ""} value="second">{_("second")}</option>
            <option{$timeunit eq "minute" ? " selected" : ""} value="minute">{_("minute")}</option>
            <option{$timeunit eq "hour"   ? " selected" : ""} value="hour">{_("hour")}</option>
            <option{$timeunit eq "day"    ? " selected" : ""} value="day">{_("day")}</option>
            <option{$timeunit eq "week"   ? " selected" : ""} value="week">{_("week")}</option>
          </select>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='timeslot-config' style='display: {$type eq "timeslot" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='week-day'>{_"Week day"}</label>
        <div class='form-edit-row'>
          <select class='input-row' id='weekday' name='input/weekday' {$type eq "delay" ? " disabled" : ""}>
            <option{$weekday eq "*"         ? " selected" : ""} value="*">{_("all")}</option>
            <option{$weekday eq "mon"    ? " selected" : ""} value="mon">{_("monday")}</option>
            <option{$weekday eq "tue"   ? " selected" : ""} value="tues">{_("tuesday")}</option>
            <option{$weekday eq "wed" ? " selected" : ""} value="wed">{_("wednesday")}</option>
            <option{$weekday eq "thu"  ? " selected" : ""} value="thu">{_("thursday")}</option>
            <option{$weekday eq "fri"    ? " selected" : ""} value="fri">{_("friday")}</option>
            <option{$weekday eq "sat" ? " selected" : ""} value="sat">{_("saturday")}</option>
            <option{$weekday eq "sun"    ? " selected" : ""} value="sun">{_("sunday")}</option>
          </select>
        </div>
      </div>
      <div class='form-edit'>
        <label for='hour'>{_("Day time")." (hh:mm)"}</label>
        <div class='form-edit-row'>
          <select class='input-row' id='hour' name='input/start/hour' {$type eq "delay" ? " disabled" : ""}>{
          join("", map { "
            <option".($hour eq $_ ? " selected" : "")." value='$_'>$_</option>"
          } map { sprintf("%02d", $_) } 0..23)
          }
          </select>
          :
          <select class='input-row' id='minute' name='input/start/minute' {$type eq "delay" ? " disabled" : ""}>{
            join("", map { "
            <option".($minute eq $_ ? " selected" : "")." value='$_'>$_</option>"
            } map { sprintf("%02d", $_) } 0..59)
          }
          </select>
        </div>
      </div>
      <div class='form-edit'>
        <label for='duration-hour'>{_("Duration")." (hh:mm)"}</label>
        <div class='form-edit-row'>
          <select class='input-row' id='duration-hour' name='input/duration/hour' {$type eq "delay" ? " disabled" : ""}>{
          join("", map { "
            <option".($dhour eq $_ ? " selected" : "")." value='$_'>$_</option>"
          } map { sprintf("%02d", $_) } 0..24)
          }
          </select>
          :
          <select class='input-row' id='duration-minute' name='input/duration/minute' {$type eq "delay" ? " disabled" : ""}>{
            join("", map { "
            <option".($dminute eq $_ ? " selected" : "")." value='$_'>$_</option>"
            } map { sprintf("%02d", $_) } 0..59)
          }
          </select>
        </div>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
      <label for='desc'>{_"Description"}</label>
      <input class='input-row' type='text' id='desc' name='input/description' value='{$schedule->{description} || $form{"input/description"} || ""}' size='40'>
      </div>
    </div>
    <input type='submit' class='big-button' name='submit/{
      $scheduling{$edit} ?
        "update' value='"._("Update") :
        "add' value='"._("Add") }'>
    <input type='submit' class='big-button' name='submit/cancel' value='{_("Cancel")}'>
  </form>
  <script>
    function handle_rename () \{
      document.getElementById("input-rename").disabled = false;
      document.getElementById("rename-overlay").style.display = "block";
    \}
    function cancel_rename () \{
      document.getElementById("rename-overlay").style.display = "none";
      document.getElementById("input-rename").disabled = true;
    \}
    function type_change() \{
      if (document.getElementById("delay").checked) \{
        document.getElementById("delay-description").style = "display: flex";
        document.getElementById("delay-config").style = "display: flex";
        document.getElementById("delaytime").disabled = false;
        document.getElementById("delayunit").disabled = false;
        document.getElementById("timeslot-config").style = "display: none";
        document.getElementById("timeslot-description").style = "display: none";
        document.getElementById("weekday").disabled = true;
        document.getElementById("hour").disabled = true;
        document.getElementById("minute").disabled = true;
        document.getElementById("duration-hour").disabled = true;
        document.getElementById("duration-minute").disabled = true;
      \} else \{
        document.getElementById("delay-description").style = "display: none";
        document.getElementById("delay-config").style = "display: none";
        document.getElementById("delaytime").disabled = true;
        document.getElementById("delayunit").disabled = true;
        document.getElementById("timeslot-config").style = "display: flex";
        document.getElementById("timeslot-description").style = "display: flex";
        document.getElementById("weekday").disabled = false;
        document.getElementById("hour").disabled = false;
        document.getElementById("minute").disabled = false;
        document.getElementById("duration-hour").disabled = false;
        document.getElementById("duration-minute").disabled = false;
      \}
    \}
  </script>
