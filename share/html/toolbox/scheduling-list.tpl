{ # This comment to keep a line feed at the beginning of this template inclusion }
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' id='display' name='display' value='{$display}'/>{
use Encode qw(encode);
use HTML::Entities;
use URI::Escape;

if (@scheduling_order) {
  my $listnav = Text::Template::fill_in_file($template_path."/list-navigation.tpl", HASH => $hash);
  chomp($listnav) if defined($listnav);
  $OUT .= $listnav ? $listnav : "
    <div id='errors'><p>Error loading list-navigation.tpl template: $Text::Template::ERROR</p></div>";
  $OUT .= "<table class='scheduling'>
      <thead>
        <tr>
          <th class='checkbox' title='"._("Revert selection")."'>
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' onclick='toggle_all(this)'/>
              <span class='custom-checkbox all_cb'></span>
            </label>
          </th>";
  $other_order = $order eq 'ascend' ? 'descend' : 'ascend';
  foreach my $column (@columns) {
    my ($name, $text) = @{$column};
    my $order_req = $name eq $ordering_column ? $other_order : $order;
    $OUT .= "
          <th".($name eq $ordering_column ? " class='col-sort-$order'" : "").">
            <a class='noline' href='$url_path/$request?col=$name&order=$order_req'";
    $OUT .= "&start=$start" if $start;
    $OUT .= ">"._($text)."</a>
          </th>";
  }
  $OUT .= "
        </tr>
      </thead>
      <tbody>";
  my $count = -$start;
  my $listed = 0;
  foreach my $entry (@scheduling_order) {
    next unless $count++>=0;
    $listed++;
    my $schedule = $scheduling{$entry};
    my $this     = encode('UTF-8', encode_entities($entry));
    my $name     = $schedule->{name} || $this;
    my $type     = $schedule->{type} || "delay";
    my $checked  = $form{"checkbox/$entry"} eq "on" ? " checked" : "";
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
              <input class='checkbox' type='checkbox' name='checkbox/$this'$checked/>
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
  }
  $OUT .= "
    </table>
    <div class='select-row'>
      <i class='ti ti-corner-left-up arrow-left'></i>
      <button class='secondary' type='submit' name='submit/delete' value='1' alt='"._("Delete")."'><i class='primary ti ti-trash'></i>"._("Delete")."</button>
    </div>";
  $OUT .= $listnav if $listed >= 50 && $listnav;
} else {
  # Handle empty list case
  $OUT .= "
    <div id='empty-list'>
      <p>"._("No scheduling defined")."</p>
    </div>";
}}
    <hr/>
    <button class='big-button' type='submit' name='submit/add' value='1' alt='{_"Add new scheduling"}'><i class='primary ti ti-plus'></i>{_"Add new scheduling"}</button>
  </form>
  <script>
  function toggle_all(from) \{
    var all_cb = document.querySelectorAll('input[type="checkbox"]');
    for ( var i = 0; i < all_cb.length; i++ )
      if (all_cb[i] != from)
        all_cb[i].checked = !all_cb[i].checked;
  \}
  </script>
