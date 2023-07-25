  <h2>{
    use Encode qw(encode);
    use HTML::Entities;
    use URI::Escape;
    $timeunit = 'hour';
    $schedule = $scheduling{$edit} || {};
    $this = encode('UTF-8', encode_entities($edit));
    $type = $schedule->{type} || $form{"input/type"} || "delay";
    ($weekday, $start, $dstring, $duration_time, $duration_unit) = qw(* 00:00 1h00 1 hour);
    if ($type eq 'delay' || $type ne 'timeslot') {
      $delay = $schedule->{delay} || $form{"input/delay"} || "24";
      my ($number, $unit) = $delay =~ /^(\d+)([smhdw])?$/;
      $delay = $number || "24";
      my %units = qw( s second m minute h hour d day w week );
      $timeunit = $units{$unit} if $unit && $units{$unit};
    } else { # timeslot type
      $weekday = $schedule->{weekday} || $form{"input/weekday"}
        if $schedule->{weekday} || $form{"input/weekday"};
      $start = $schedule->{start} || $form{"input/start"}
        if $schedule->{start} || $form{"input/start"};
      my $duration = $schedule->{duration} || "01:00";
      my ($dhour, $dminute) = $duration =~ /^(\d{2}):(\d{2})$/;
      if (int($dminute)) {
        $duration_unit = "minute";
        $duration_time = int($dhour) * 60 + int($dminute);
      } else {
        $duration_unit = "hour";
        $duration_time = int($dhour);
      }
      $duration_time = $form{"input/duration/value"}
        if $form{"input/duration/value"};
      if ($form{"input/duration/unit"}) {
        $duration_unit = $form{"input/duration/unit"};
        if ($duration_unit eq "minute") {
          $dhour = int($duration_time/60);
          $dminute = $duration_time%60;
        } else {
          $dhour = int($duration_time);
          $dminute = 0;
        }
      }
      $dstring = sprintf('%dh%02d', $dhour, $dminute);
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
          <input class='input-row' type='text' id='name' name='input/name' value='{ $schedule->{name} || $this || $form{"input/name"} }' size='20' required />
        </div>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label>{_"Type"}</label>
        <div class='form-edit-row' id='type-options'>
          <input type="radio" name="input/type" id="delay" value="delay"{$type eq "delay" ? " checked" : ""}{$form{empty} ? ' onchange="type_change()"' : ' disabled'}/>
          <label for='delay'>{_("delay")}</label>
          <input type="radio" name="input/type" id="timeslot" value="timeslot"{$type eq "timeslot" ? " checked" : ""}{$form{empty} ? ' onchange="type_change()"' : ' disabled'}/>
          <label for='timeslot'>{_("timeslot")}</label>
        </div>
      </div>
    </div>
    <div class='form-edit'>
      <label>{_"Configuration"}</label>
      <em class='hint' id='delay-description' style='display: {$type eq "delay" ? "flex" : "none"}'>{_"The approximate delay time between two tasks runs"}</em>
      <em class='hint' id='timeslot-description' style='display: {$type eq "timeslot" ? "flex" : "none"}'>{_"Week day, day time and duration of a time slot during which a task will be executed once"}</em>
    </div>
    <div class='form-edit-row' id='delay-config' style='display: {$type eq "delay" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='delaytime'>{_"Delay"}</label>
        <input class='input-row input-number' type='number' id='delaytime' name='input/delay' value='{$delay}'{$type ne "delay" ? " disabled" : ""}/>
      </div>
      <div class='form-edit'>
        <label for='delayunit'>{_"Time unit"}</label>
        <div class='form-edit-row'>
          <select class='input-row' id='delayunit' name='input/timeunit' onchange='delay_unit_change(this.value)'{$type ne "delay" ? " disabled" : ""}>
            <option{$timeunit eq "second" ? " selected" : ""} value="second">{_("second")}</option>
            <option{$timeunit eq "minute" ? " selected" : ""} value="minute">{_("minute")}</option>
            <option{$timeunit eq "hour"   ? " selected" : ""} value="hour">{_("hour")}</option>
            <option{$timeunit eq "day"    ? " selected" : ""} value="day">{_("day")}</option>
            <option{$timeunit eq "week"   ? " selected" : ""} value="week">{_("week")}</option>
          </select>
          <input type='hidden' id='prev/delayunit' value='{$timeunit}'/>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='timeslot-config' style='display: {$type eq "timeslot" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='week-day'>{_"Week day"}</label>
        <div class='form-edit-row'>
          <select class='input-row' id='weekday' name='input/weekday'{$type eq "delay" ? " disabled" : ""}>
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
        <label for='start'>{_("Start")}</label>
        <div class='form-edit-row'>
          <input class='input-row input-time' type='time' id='start' name='input/start' value='{$start}' title='{_("Day time")}'{$type eq "delay" ? " disabled" : ""}>
        </div>
      </div>
      <div class='form-edit'>
        <label for='duration-time'>{_("Duration")}</label>
        <div class='form-edit-row'>
          <input class='input-row input-number' type='number' id='duration-time' min='1' max='{$duration_unit eq "minute" ? 1440 : 24}' name='input/duration/value' value='{$duration_time}' onchange='duration_change(this.value)'{$type eq "delay" ? " disabled" : ""}/>
        </div>
      </div>
      <div class='form-edit'>
        <label for='duration-unit'>{_("Time unit")}</label>
        <div class='form-edit-row'>
          <select class='input-row' id='duration-unit' name='input/duration/unit' onchange='duration_unit_change(this.value)'{$type eq "delay" ? " disabled" : ""}>
            <option{$duration_unit eq "minute" ? " selected" : ""} value="minute">{_("minute")}</option>
            <option{$duration_unit eq "hour"   ? " selected" : ""} value="hour">{_("hour")}</option>
          </select>
          <input class='input-row input-time' type='text' id='duration' value='{$dstring}' disabled />
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
        "add' value='"._("Add") }'/>
    <input type='submit' class='big-button secondary-button' name='submit/cancel' value='{_("Cancel")}'/>
  </form>
  <script>
    function type_change() \{
      if (document.getElementById("delay").checked) \{
        document.getElementById("delay-description").style = "display: flex";
        document.getElementById("delay-config").style = "display: flex";
        document.getElementById("delaytime").disabled = false;
        document.getElementById("delayunit").disabled = false;
        document.getElementById("timeslot-config").style = "display: none";
        document.getElementById("timeslot-description").style = "display: none";
        document.getElementById("weekday").disabled = true;
        document.getElementById("start").disabled = true;
        document.getElementById("duration-time").disabled = true;
        document.getElementById("duration-unit").disabled = true;
      \} else \{
        document.getElementById("delay-description").style = "display: none";
        document.getElementById("delay-config").style = "display: none";
        document.getElementById("delaytime").disabled = true;
        document.getElementById("delayunit").disabled = true;
        document.getElementById("timeslot-config").style = "display: flex";
        document.getElementById("timeslot-description").style = "display: flex";
        document.getElementById("weekday").disabled = false;
        document.getElementById("start").disabled = false;
        document.getElementById("duration-time").disabled = false;
        document.getElementById("duration-unit").disabled = false;
      \}
    \}
    function delay_unit_change(unit) \{
      var delay = document.getElementById("delaytime").value;
      var prev  = document.getElementById("prev/delayunit").value;
      if (prev === 'minute') delay *= 60;
      else if (prev === 'hour') delay *= 3600;
      else if (prev === 'day') delay *= 86400;
      else if (prev === 'week') delay *= 604800;
      if (unit === 'minute') delay /= 60;
      else if (unit === 'hour') delay /= 3600;
      else if (unit === 'day') delay /= 86400;
      else if (unit === 'week') delay /= 604800;
      document.getElementById("prev/delayunit").value = unit;
      document.getElementById("delaytime").value = Math.round(delay);
    \}
    function duration_change(duration) \{
      var unit = document.getElementById("duration-unit").value;
      if (unit==='minute') \{
        var minutes = duration%60;
        let minute = minutes.toString();
        if (minute.length<2) minute = "0"+minute;
        let hour = ((duration-minute)/60).toString();
        document.getElementById("duration").value = hour+"h"+minute;
      \} else \{
        document.getElementById("duration").value = duration+"h00";
      \}
    \}
    function duration_unit_change(unit) \{
      var duration = document.getElementById("duration-time").value;
      if (unit === 'minute') \{
        duration *= 60;
        document.getElementById("duration-time").max = 1440;
      \} else \{
        duration = Math.round(duration/60);
        document.getElementById("duration-time").max = 24;
      \}
      document.getElementById("duration-time").value = duration;
      duration_change(duration);
    \}
  </script>
