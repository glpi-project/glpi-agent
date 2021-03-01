  <div class='tab'>
    <button class="credtab{
      !$form{snmpversion} || $form{snmpversion} =~ /^v1|v2c$/ ? " active" : ""
      }" id='snmp-v1-v2c' onclick="show(event)">{_"SNMP Credentials v1 and v2c"}</button>
    <button class="credtab{
      $form{snmpversion} && $form{snmpversion} =~ /^v3$/ ? " active" : ""
      }" id='snmp-v3' onclick="show(event)">{_"SNMP Credentials v3"}</button>
  </div>
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' id='snmpversion' name='snmpversion' value='{$form{snmpversion}||"v2c"}'/>
    <div id='snmp-v1-v2c-tab' class="tabcontent"{
        !$form{snmpversion} || $form{snmpversion} =~ /^v1|v2c$/ ? " style='display: block;'" : ""}>
      <table>
        <thead>
          <tr>
            <th class='checkbox' title='{_"Revert selection"}'>
              <label class='checkbox'>
                <input class='checkbox' type='checkbox' name='checkbox-v1-v2c' onclick='toggle_all(this)'>
                <span class='custom-checkbox all_cb'></span>
              </label>
            </th>
            <th width='10%'>{_"Credential name"}</th>
            <th width='10%'>{_"Version"}</th>
            <th width='10%'>{_"Community"}</th>
            <th width>{"Description"}</th>
          </tr>
        </thead>
        <tbody>{
  use Encode qw(encode);
  use HTML::Entities;
  use URI::Escape;
  $count = 0;
  foreach my $entry (sort keys(%credentials)) {
    my $version = $credentials{$entry}->{snmpversion};
    next unless $version && $version =~ /^v1|v2c$/;
    $count++;
    my $this = encode('UTF-8', encode_entities($entry));
    my $id = $credentials{$entry}->{id};
    my $community = $credentials{$entry}->{community};
    my $description = $credentials{$entry}->{description} || "";
    my $name = $credentials{$entry}->{name} || $this ;
    $OUT .= "
          <tr class='$request'>
            <td class='checkbox'>
              <label class='checkbox'>
                <input class='checkbox' type='checkbox' name='checkbox-v1-v2c/$this'".
                ($edit && $edit eq $entry ? " checked" : "").">
                <span class='custom-checkbox'></span>
              </label>
            </td>
            <td class='list' width='10%'".($id ?" title='id = $id'":"")."><a href='$url_path/$request?edit=".uri_escape($this)."'>$name</a></td>
            <td class='list' width='10%'>$version</td>
            <td class='list' width='10%' >$community</td>
            <td class='list'>$description</td>
          </tr>";
  }
  # Handle empty list case
  unless ($count) {
    $OUT .= "
        <tr class='$request'>
          <td width='20px'>&nbsp;</td>
          <td class='list' colspan='4'>"._("empty list")."</td>
        </tr>";
  }
}
        </tbody>
      </table>
      <div class='select-row'>
        <div class='arrow-left'></div>
        <input class='submit-secondary' type='submit' name='submit/delete-v1-v2c' value='{_"Delete"}'>
      </div>
      <hr/>
      <input class='big-button' type='submit' name='submit/add-v1-v2c' value='{_"Add Credential"}'>
    </div>
    <div id='snmp-v3-tab' class="tabcontent"{
        $form{snmpversion} && $form{snmpversion} =~ /^v3$/ ? " style='display: block;'" : ""}>
      <table>
        <thead>
          <tr>
            <th class='checkbox' title='{_"Revert selection"}'>
              <label class='checkbox'>
                <input class='checkbox' type='checkbox' name='checkbox-v3' onclick='toggle_all(this)'>
                <span class='custom-checkbox all_cb'></span>
              </label>
            </th>
            <th width='10%'>{_"Credential name"}</th>
            <th width='10%'>{_"Username"}</th>
            <th width='10%'>{_"Authentication"}</th>
            <th width='10%'>{_"Privacy"}</th>
            <th width>{_"Description"}</th>
          </tr>
        </thead>
        <tbody>{
  $count = 0;
  foreach my $entry (sort keys(%credentials)) {
    my $version = $credentials{$entry}->{snmpversion};
    next unless $version && $version =~ /^v3$/;
    $count++;
    my $this = encode('UTF-8', encode_entities($entry));
    my $id = $credentials{$entry}->{id};
    my $user = $credentials{$entry}->{username};
    my $aproto = $credentials{$entry}->{authprotocol};
    my $apass = $credentials{$entry}->{authpassword} || "";
    my $pproto = $credentials{$entry}->{privprotocol};
    my $ppass = $credentials{$entry}->{privpassword} || "";
    my $description = $credentials{$entry}->{description} || "";
    my $name = $credentials{$entry}->{name} || $this ;
    $OUT .= "
          <tr class='$request'>
            <td class='checkbox'>
              <label class='checkbox'>
                <input class='checkbox' type='checkbox' name='checkbox-v3/$this'".
                ($edit && $edit eq $entry ? " checked" : "").">
                <span class='custom-checkbox'></span>
              </label>
            </td>
            <td class='list' width='10%'".($id ?" title='id = $id'":"")."><a href='$url_path/$request?edit=".uri_escape($this)."'>$name</a></td>
            <td class='list' width='10%' >$user</td>
            <td class='list' width='10%' >".($aproto?"[$aproto] ":"")."$apass</td>
            <td class='list' width='10%' >".($pproto?"[$pproto] ":"")."$ppass</td>
            <td class='list'>$description</td>
          </tr>";
  }
  # Handle empty list case
  unless ($count) {
    $OUT .= "
        <tr class='$request'>
          <td width='20px'>&nbsp;</td>
          <td class='list' colspan='5'>"._("empty list")."</td>
        </tr>";
  }
}
        </tbody>
      </table>
      <div class='select-row'>
        <div class='arrow-left'></div>
        <input class='submit-secondary' type='submit' name='submit/delete-v3' value='{_"Delete"}'>
      </div>
      <hr/>
      <input class='big-button' type='submit' name='submit/add-v3' value='{_"Add Credential"}'>
    </div>
  </form>
  <script>
  function toggle_all(from) \{
    var all_cb = document.querySelectorAll('input[type="checkbox"]');
    var filter = from.name + "/";
    for ( var i = 0; i < all_cb.length; i++ )
      if (all_cb[i] != from && all_cb[i].name.startsWith(filter))
        all_cb[i].checked = !all_cb[i].checked;
  \}
  function show(evt) \{
    var target = evt.currentTarget;
    var tabcontent = document.getElementsByClassName("tabcontent");
    for ( var i = 0; i < tabcontent.length; i++ )
      if (tabcontent[i].id != target.id)
        tabcontent[i].style.display = "none";
    var credtab = document.getElementsByClassName("credtab");
    for ( var i = 0; i < credtab.length; i++ )
      credtab[i].className = credtab[i].className.replace(" active", "");
    document.getElementById(target.id+'-tab').style.display = "block";
    target.className += " active";
    document.getElementById("snmpversion").value = target.id === "snmp-v1-v2c" ?
      "v2c" : "v3";
  \}
  </script>
