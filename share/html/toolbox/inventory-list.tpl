
  <h2>{_"Inventory jobs"}</h2>
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
              <input class='checkbox' type='checkbox' onclick='toggle_all(this)'>
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
  $listed = 0;
  foreach my $entry (@jobs_order) {
    next unless $count++>=0;
    $listed++;
    my $job         = $jobs{$entry};
    my $this        = encode('UTF-8', encode_entities($entry));
    my $name        = $job->{name} || $this;
    my $enabled     = $job->{enabled} && $job->{enabled} eq 'true';
    my $type        = $job->{type} || "";
    $type = $job->{type} eq 'local' ? _"Local inventory" : _"Network scan"
        if $job->{type} && $job->{type} =~ /^local|netscan$/;
    my $ip_range    = $job->{ip_range} || "";
    my $scheduling  = $job->{scheduling} || "";
    my $lastrun     = $job->{last_run_date} ? localtime($job->{last_run_date}) : "";
    my $nextrun     = ($enabled ? $job->{next_run_date} : _"Job is disabled") || "";
    my $description = $job->{description} || "";
    my $class = "list".($enabled ? "" : " disabled");
    $OUT .= "
        <tr class='$request'$tips>
          <td class='checkbox'>
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' name='checkbox/".encode_entities($entry)."'".
              ($form{"checkbox/".$entry} eq "on" ? " checked" : "").">
              <span class='custom-checkbox'></span>
            </label>
          </td>
          <td class='list' width='10%'><a href='$url_path/$request?edit=".uri_escape($this)."'>$name</a></td>
          <td class='list' width='10%'>$type</td>
          <td class='list' width='10%'>$ip_range</td>
          <td class='$class' width='10%'>$scheduling</td>
          <td class='$class' width='15%'>$lastrun</td>
          <td class='$class' width='15%'>$nextrun</td>
          <td class='list'>$description</td>
        </tr>";
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
              <input class='checkbox' type='checkbox' onclick='toggle_all(this)'>
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
      <input class='submit-secondary' type='submit' name='submit/delete' value='{_"Delete"}'>
      <div class='separation'></div>
      <label class='selection-option'>{_"Associated ip range"}:</label>
      <select class='selection-option' name='input/ip_range'>
        <option{
          $ip_range = $form{"input/credentials"} || "";
          $ip_range ? "" : " selected"}></option>{
          join("", map { "
        <option".(($ip_range && $ip_range eq $_)? " selected" : "").
          " value='$_'>".($ip_range{$_}->{name} || $_)."</option>"
        } @iprange_options)}
      </select>
      <input class='submit-secondary' type='submit' name='submit/add-iprange' value='{_"Add ip range"}'>
      <input class='submit-secondary' type='submit' name='submit/rm-iprange' value='{_"Remove ip range"}'>
      <div class='separation'></div>
      <input class='submit-secondary' type='submit' name='submit/disable' value='{_"Disable"}'>
      <input class='submit-secondary' type='submit' name='submit/enable' value='{_"Enable"}'>
      <div class='separation'></div>
      <input class='submit-secondary' type='submit' name='submit/run-now' value='{_"Run now"}'>
    </div>
    <br/>
    <input class='big-button' type='submit' name='submit/add' value='{_"Add new inventory job"}'>
  </form>
  <script>
  function toggle_all(from) \{
    var all_cb = document.querySelectorAll('input[type="checkbox"]');
    for ( var i = 0; i < all_cb.length; i++ )
      if (all_cb[i] != from)
        all_cb[i].checked = !all_cb[i].checked;
  \}
  </script>
