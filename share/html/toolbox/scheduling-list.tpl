  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' id='display' name='display' value='{$display}'/>{
    use Encode qw(encode);
    use HTML::Entities;
    use URI::Escape;
    $listnav = Text::Template::fill_in_file($template_path."/list-navigation.tpl", HASH => $hash)
      || "Error loading list-navigation.tpl template: $Text::Template::ERROR" }
    <table class='scheduling'>
      <thead>
        <tr>
          <th class='checkbox' title='{_"Revert selection"}'>{ @scheduling_order ? "
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
  $listed = 0;
  foreach my $entry (@scheduling_order) {
    next unless $count++>=0;
    $listed++;
    my $schedule = $scheduling{$entry};
    my $this     = encode('UTF-8', encode_entities($entry));
    my $name     = $schedule->{name} || $this;
    my $type     = $schedule->{type} || "delay";
    my $description = $schedule->{description} || "";
    my $configuration;
    if ($type eq "delay") {
      my %units = qw( s second m minute h hour d day w week);
      my $delay = $schedule->{delay} || "24h";
      my ($number, $unit) = $delay =~ /^(\d+)([smhdw])?$/;
      $number = 24 unless $number;
      $unit = "h" unless $unit;
      $unit = $units{$unit};
      $unit .= "s" if $number > 1;
      $configuration = $number." "._($unit);
    } else {
      my @config;
      my $weekday = $schedule->{weekday};
      push @config, _("day").": ".($weekday eq "*" ? _("all") : _($weekday)) if $weekday;
      foreach my $key (qw(start duration)) {
        next unless $schedule->{$key} && $schedule->{$key} =~ /^(\d{2}):(\d{2})$/;
        push @config, _($key).": $1h$2";
      }
      $configuration = join(", ", @config) if @config;
    }
    $OUT .= "
        <tr class='$request'>
          <td class='checkbox'>
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' name='checkbox/".encode_entities($entry)."'".
              ($form{"checkbox/".$entry} eq "on" ? " checked" : "")."/>
              <span class='custom-checkbox'></span>
            </label>
          </td>
          <td class='list' width='10%'><a href='$url_path/$request?edit=".uri_escape($this)."'>$name</a></td>
          <td class='list' width='10%'>"._($type)."</td>
          <td class='list' width='20%'>$configuration</td>
          <td class='list'>$description</td>
        </tr>";
    last if $display && $count >= $display;
  }
  # Handle empty list case
  unless (@scheduling_order) {
    $OUT .= "
        <tr class='$request'>
          <td width='20px'>&nbsp;</td>
          <td class='list' colspan='5'>"._("empty list")."</td>
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
      <input class='submit-secondary' type='submit' name='submit/delete' value='{_"Delete"}'/>
    </div>
    <hr/>
    <input class='big-button' type='submit' name='submit/add' value='{_"Add new scheduling"}'/>
  </form>
  <script>
  function toggle_all(from) \{
    var all_cb = document.querySelectorAll('input[type="checkbox"]');
    for ( var i = 0; i < all_cb.length; i++ )
      if (all_cb[i] != from)
        all_cb[i].checked = !all_cb[i].checked;
  \}
  </script>
