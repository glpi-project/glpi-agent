{ # This comment to keep a line feed at the beginning of this template inclusion }
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' id='display' name='display' value='{$display}'/>{
use Encode qw(encode);
use HTML::Entities;
use URI::Escape;

if (@credentials_order) {
  my $listnav = Text::Template::fill_in_file($template_path."/list-navigation.tpl", HASH => $hash);
  chomp($listnav) if defined($listnav);
  $OUT .= $listnav ? $listnav : "
    <div id='errors'><p>Error loading list-navigation.tpl template: $Text::Template::ERROR</p></div>";
  $OUT .= "
    <table class='$request'>
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
  foreach my $entry (@credentials_order) {
    next unless $count++>=0;
    $listed++;
    my $credential = $credentials{$entry};
    my $this = encode('UTF-8', encode_entities($entry));
    my $name = $credential->{name} || $this ;
    my $tips = $credential->{id} ? " title='id=".$credential->{id}."'": "";
    my $type = $credential->{type} || 'snmp';
    my $port = int($credential->{port}) || 0;
    # Don't show port in config if it's the default one
    undef $port if $type eq 'snmp' && $port == 161;
    undef $port if $type eq 'ssh' && $port == 222;
    undef $port if $type eq 'winrm' && (($port == 5985 && (!$credential->{mode} || $credential->{mode} !~ /ssl/))
      || ($port == 5986 && $credential->{mode} && $credential->{mode} =~ /ssl/));
    if ($type eq 'snmp' && $credential->{snmpversion}) {
      $type = $credential->{snmpversion} eq 'v3'  ? "snmp v3"  :
              $credential->{snmpversion} eq 'v2c' ? "snmp v2c" : "snmp v1";
    }
    my $community = $type =~ /^snmp v(?:1|2c)$/ && $credential->{community} || "";
    my $username  = $credential->{username} // "";
    my $protocol  = $type =~ /^snmp/ && $credential->{protocol} && $credential->{protocol} ne 'udp' ? $credential->{protocol} : "";
    my $mode      = $credential->{mode} // "";
    my $authprotocol = $type eq "snmp v3" && $credential->{authprotocol} || "";
    my $privprotocol = $type eq "snmp v3" && $credential->{privprotocol} || "";
    my $checked   = $form{"checkbox/$entry"} eq "on" ? " checked" : "";
    my $description = $credential->{description} || "";
    $OUT .= "
        <tr class='$request'$tips>
          <td class='checkbox'>
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' name='checkbox/$this'$checked/>
              <span class='custom-checkbox'></span>
            </label>
          </td>
          <td class='list' width='10%'><a href='$url_path/$request?edit=".uri_escape($this)."'>$name</a></td>
          <td class='list' width='10%'>$type</td>
          <td class='list' width='40%'>
            <ul class='config'>
              <li class='config'>
                <div class='with-tooltip'>
                  ".($community ? _("Community").":&nbsp;".$community : _("Username").":&nbsp;".$username)."
                    <div class='tooltip right-tooltip'>
                      <p>".($community ? _("Community").":&nbsp;".$community : _("Username").":&nbsp;".$username)."</p>".($authprotocol ? "
                      <p>"._("Authentication protocol").":&nbsp;".$authprotocol."</p>" : "").($privprotocol ? "
                      <p>"._("Privacy protocol").":&nbsp;".$privprotocol."</p>" : "").($port ? "
                      <p>"._("Port").":&nbsp;".$port."</p>" : "").($protocol ? "
                      <p>"._("Protocol").":&nbsp;".$protocol."</p>" : "").($mode ? "
                      <p>"._("Mode").":&nbsp;".$mode."</p>" : "")."
                      <i></i>
                    </div>
                </div>
              </li>
            </ul>
          </td>
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
      <p>"._("No credential defined")."</p>
    </div>";
}}
      <hr/>
      <button class='big-button' type='submit' name='submit/add' value='1' alt='{_"Add Credential"}'><i class='primary ti ti-plus'></i>{_"Add Credential"}</button>
    </div>
  </form>
  <script>
  function toggle_all(from) \{
    var all_cb = document.querySelectorAll('input[type="checkbox"]');
    for ( var i = 0; i < all_cb.length; i++ )
      if (all_cb[i] != from)
        all_cb[i].checked = !all_cb[i].checked;
  \}
  </script>
