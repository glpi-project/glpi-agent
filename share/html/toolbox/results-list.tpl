
  <div class='counters-row'>
    <div class='counter-cell' title='{_"Number of devices seen by network scan other all results"}
{_"A seen device is identified by its IPs and tag"}
{_"A local inventory can be included as seen if its IP has been scanned by a network scan task"}'>
      <label>{_"IPs seen by Network Scan"}</label>
      <div class='counters-row'>
        <span class='counter'>{$netscan_count}/{$list_count}</span>
      </div>
    </div>
    <div class='counter-cell' title='{_"Number of Network Inventory other all scanned IPs"}'>
      <label>{_"Network Scan Inventory count"}</label>
      <div class='counters-row'>
        <span class='counter'>{$netscan_inventory_count}/{$list_count}</span>
      </div>
    </div>
    <div class='counter-cell' title='{_"Number of local inventory other all scanned IPs"}'>
      <label>{_"Local Inventory count"}</label>
      <div class='counters-row'>
        <span class='counter'>{$local_inventory_count}/{$list_count}</span>
      </div>
    </div>
  </div>
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' id='display' name='display' value='{$display}'/>
{
    $list_nav = Text::Template::fill_in_file($template_path."/list-navigation.tpl", HASH => $hash)
      || "Error loading list-navigation.tpl template: $Text::Template::ERROR"
}    <table>
      <thead>
        <tr>
          <th class='checkbox' title='{_"Revert selection"}'>{ @columns ? "
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' onclick='toggle_all(this)'>
              <span class='custom-checkbox all_cb'></span>
            </label>
          ": "&nbsp;"
          }</th>{
  use Encode qw(encode);
  use HTML::Entities;
  foreach my $column (@columns) {
    my ($name, $text) = @{$column};
    my $other_order = $order eq 'ascend' ? 'descend' : 'ascend';
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
  foreach my $entry (@devices_order) {
    next unless $count++>=0;
    $listed++;
    $OUT .= "
        <tr>
          <td class='checkbox'>
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' name='checkbox/$entry'".
              ($edit && $edit eq $entry ? " checked" : "").">
              <span class='custom-checkbox'></span>
            </label>
          </td>";
    foreach my $column (@columns) {
      my ($name, $text) = @{$column};
      $OUT .= "
          <td class='list list-$name'>";
      $OUT .= "<a href='$url_path/$request?edit=$entry'>"
        if $name eq 'name';
      $OUT .= $name =~ /^type|source$/ ? _($devices{$entry}->{$name})
        : encode('UTF-8', encode_entities($devices{$entry}->{$name}));
      $OUT .= "</a>" if $name eq 'name';
      $OUT .= "</td>";
    }
    $OUT .= "
        </tr>";
    last if $display && $count >= $display;
  }
  # Handle empty list case
  unless (@devices_order) {
    $OUT .= "
        <tr class='$request'>
          <td width='20px'>&nbsp;</td>
          <td class='list list-name' colspan='".@columns."'>"._("empty list")."</td>
        </tr>";
  }
  $OUT .= "
      </tbody>";
  if ($listed >= 50) {
    $OUT .= "
      <thead>
        <tr>
          <th class='checkbox'>
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
      </thead>";
  }}
    </table>{
    $listed >= 50 ? $list_nav : "" }
    <div class='select-row'>
      <div class='arrow-left'></div>
      <input class='submit-secondary' type='submit' name='submit/delete' value='{_"Delete"}'>
      <input class='submit-secondary' type='submit' name='submit/scan' value='{_"Scan again"}'>{
    if (@tags||"") { # The test avoids to render a 0 when no tag is defined
      $OUT .= "
      <div class='separation'></div>
      <label class='selection-option'>"._("Filter results by tag").":</label>
      <select class='selection-option' name='input/tag_filter' onchange='submit();'>
        <option".(defined($tag_filter) && length($tag_filter) ? "" : " selected")."></option>".
          join("", map { "
        <option".((defined($tag_filter) && $tag_filter eq $_)? " selected" : "").">$_</option>"
            } @tags)."
      </select>";
    }}
    </div>
    <hr/>
    <input class='big-button' type='submit' name='submit/export' value='{_"Download results"}' title='{_"Results will be filtered by tag if set"}'>
    <input class='big-button' type='submit' name='submit/full-export' value='{_"Download full scan datas"}' title='{_"No filtering by tag will be applied"}'>
  </form>
  <script>
  function toggle_all(from) \{
    var all_cb = document.querySelectorAll('input[type="checkbox"]');
    for ( var i = 0; i < all_cb.length; i++ )
      if (all_cb[i] != from)
        all_cb[i].checked = !all_cb[i].checked;
  \}
  </script>
