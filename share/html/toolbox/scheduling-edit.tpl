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
          <input class='input-row' type='text' id='name' name='input/name' placeholder='{_"Name"}' value='{ $schedule->{name} || $this || $form{"input/name"} }' size='20'{$form{empty} ? "" : " disabled"}>
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
          <label for='delay'>delay</label>
          <input type="radio" name="input/type" id="timeslot" value="timeslot"{$type eq "timeslot" ? " checked" : ""}{$form{empty} ? ' onchange="type_change()"' : ' disabled'}>
          <label for='timeslot'>timeslot</label>
        </div>
      </div>
    </div>
    <div class='form-edit'>
      <label>{_"Configuration"}</label>
      <div id='configuration'>
      </div>
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
    <div class='form-edit-row'>
      <div class='form-edit'>
      <label for='desc'>{_"Description"}</label>
      <input class='input-row' type='text' id='desc' name='input/description' placeholder='{_"Description"}' value='{$schedule->{description} || $form{"input/description"} || ""}' size='40'>
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
        document.getElementById("delay-config").style = "display: flex";
        document.getElementById("delaytime").disabled = false;
        document.getElementById("delayunit").disabled = false;
      \} else \{
        document.getElementById("delay-config").style = "display: none";
        document.getElementById("timeslot").style = "display: flex";
        document.getElementById("delaytime").disabled = true;
        document.getElementById("delayunit").disabled = true;
      \}
    \}
  </script>
