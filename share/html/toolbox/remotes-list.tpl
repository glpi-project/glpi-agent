  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' id='display' name='display' value='{$display}'/>{
    use Encode qw(encode);
    use HTML::Entities;
    use URI::Escape;
    $listnav = Text::Template::fill_in_file($template_path."/list-navigation.tpl", HASH => $hash)
      || "Error loading list-navigation.tpl template: $Text::Template::ERROR" }
    <table class="remotes">
      <thead>
        <tr>
          <th class='checkbox' title='{_"Revert selection"}'>
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' name='checkbox-remotes' onclick='toggle_all(this)'>
              <span class='custom-checkbox all_cb'></span>
            </label>
          </th>
          <th width='20%'>{_"DeviceId"}</th>
          <th width='5%'>{_"Target"}</th>
          <th width='10%'>{_"Hostname"}</th>
          <th width='5%'>{_"Port"}</th>
          <th width='5%'>{_"Protocol"}</th>
          <th width='5%'>{_"User"}</th>{ $show_password ? "
          <th width='5%'>"._"Password"."</th>" : "" }
          <th width='5%'>{_"Modes"}</th>{ $has_expiration ? "
          <th width='15%'>"._"Expiration"."</th>" : "" }
          <th>{_"Remote URL"}</th>
        </tr>
      </thead>
      <tbody>{
    my $span = 8 + $show_password + $has_expiration;
    my $index = -$start;
    $listed = 0;
    foreach my $id (@remotes_list) {
      next unless $index++>=0;
      $listed++;
      my $remote = $remotes{$id};
      $OUT .= "
        <tr class='$request'>
          <td class='checkbox'>
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' name='checkbox-remotes/$id'".
              ($edit && $edit eq $entry ? " checked" : "").">
              <span class='custom-checkbox'></span>
            </label>
          </td>
          <td class='list' width='20%'>".($remotes_admin ? "<a href='$url_path/$request?edit=$id'>$remote->{deviceid}</a>" : $remote->{deviceid})."</td>
          <td class='list' width='5%' >$remote->{target}</td>
          <td class='list' width='10%'>$remote->{host}</td>
          <td class='list' width='5%'>$remote->{port}</td>
          <td class='list' width='5%'>$remote->{protocol}</td>
          <td class='list' width='5%'>$remote->{user}</td>".( $show_password ? "
          <td class='list' width='5%'>$remote->{pass}</td>" : "")."
          <td class='list' width='5%'>$remote->{modes}</td>".( $has_expiration ? "
          <td class='list' width='15%' >".($remote->{expiration} || _("Expired"))."</td>" : "")."
          <td class='list'>$remote->{url}</td>
        </tr>";
      last if $display && $index >= $display;
    }
    # Handle disabled case & empty list case
    unless ($enabled) {
      $OUT .= "
      <tr class='$request'>
        <td width='20px'>&nbsp;</td>
        <td class='list' colspan='$span'>"._("Not supported because remote option is used")."</td>
      </tr>";
    }
    unless (!$enabled || $count) {
      $OUT .= "
      <tr class='$request'>
        <td width='20px'>&nbsp;</td>
        <td class='list' colspan='$span'>"._("empty list")."</td>
      </tr>";
    }
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
        </tr>";
    }
  }
      </tbody>
    </table>{
    $listed >= 50 ? $listnav : "" }
    <div class='select-row'>
      <div class='arrow-left'></div>{ $remotes_admin ? "
      <input class='submit-secondary' type='submit' name='submit/delete-remote' value='"._("Delete")."'>
      <div class='separation'></div>" : "" }
      <label class='selection-option'>{_"Remotes workers"}:</label>
      <select id='workers' class='selection-option' name='workers'>{
      foreach my $opt (@workers_options) {
        $OUT .= "
        <option" .
          ($workers_option && $workers_option eq $opt ? " selected" : "") .
          ">$opt</option>";
      }}
      </select>
      <input class='submit-secondary' type='submit' name='submit/expire-remotes' value='{_"Mark remotes as expired"}'>
      <input class='submit-secondary' type='submit' name='submit/start-task' value='{_"Start remoteinventory task"}'{ $disable_start ? " disabled" : "" }>
    </div>
    <hr/>{ $remotes_admin ? "
    <input class='big-button' type='submit' name='submit/add-remote' value='"._("Add Remote")."'>" : "" }
  </form>
  <script>
  function toggle_all(from) \{
    var all_cb = document.querySelectorAll('input[type="checkbox"]');
    var filter = from.name + "/";
    for ( var i = 0; i < all_cb.length; i++ )
      if (all_cb[i] != from && all_cb[i].name.startsWith(filter))
        all_cb[i].checked = !all_cb[i].checked;
  \}
  </script>
