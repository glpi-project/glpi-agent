  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' id='display' name='display' value='{$display}'/>{
    use Encode qw(encode);
    use HTML::Entities;
    use URI::Escape;
    $listnav = Text::Template::fill_in_file($template_path."/list-navigation.tpl", HASH => $hash)
      || "Error loading list-navigation.tpl template: $Text::Template::ERROR" }
    <table class='ip_range'>
      <thead>
        <tr>
          <th class='checkbox' title='{_"Revert selection"}'>{ @ranges_order ? "
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
  foreach my $entry (@ranges_order) {
    next unless $count++>=0;
    $listed++;
    my $range    = $ip_range{$entry};
    my $this     = encode('UTF-8', encode_entities($entry));
    my $name     = $range->{name} || $this;
    my $ip_start = $range->{ip_start} || "";
    my $ip_end   = $range->{ip_end} || "";
    my $tips     = $range->{id} ? " title='id=".$range->{id}."'": "";
    my $description = $range->{description} || "";
    my $thiscredentials = join("<br/>", map {
            encode('UTF-8', encode_entities($credentials{$_}->{name} || $_))
        } @{$range->{credentials}});
    $OUT .= "
        <tr class='$request'$tips>
          <td class='checkbox'>
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' name='checkbox/".encode_entities($entry)."'".
              ($edit && $edit eq $entry ? " checked" : "").">
              <span class='custom-checkbox'></span>
            </label>
          </td>
          <td class='list' width='10%'><a href='$url_path/$request?edit=".uri_escape($this)."'>$name</a></td>
          <td class='list' width='10%'>$ip_start</td>
          <td class='list' width='10%'>$ip_end</td>
          <td class='list' width='10%'>$thiscredentials</td>
          <td class='list'>$description</td>
        </tr>";
    last if $display && $count >= $display;
  }
  # Handle empty list case
  unless (@ranges_order) {
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
      <label class='selection-option'>{_"Associated credentials"}:</label>
      <select class='selection-option' name='input/credentials'>
        <option{
          $credential = $form{"input/credentials"} || "";
          $credential ? "" : " selected"}></option>{
          join("", map { "
        <option".(($credential && $credential eq $_)? " selected" : "").
          " value='$_'>".($credentials{$_}->{name} || $_)."</option>"
        } @cred_options)}
      </select>
      <input class='submit-secondary' type='submit' name='submit/addcredential' value='{_"Add credential"}'>
      <input class='submit-secondary' type='submit' name='submit/rmcredential' value='{_"Remove credential"}'>
    </div>
    <hr/>
    <input class='big-button' type='submit' name='submit/add' value='{_"Add new IP range"}'>
  </form>
  <script>
  function toggle_all(from) \{
    var all_cb = document.querySelectorAll('input[type="checkbox"]');
    for ( var i = 0; i < all_cb.length; i++ )
      if (all_cb[i] != from)
        all_cb[i].checked = !all_cb[i].checked;
  \}
  </script>
