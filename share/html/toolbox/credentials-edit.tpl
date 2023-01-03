  <h2>{
    use Encode qw(encode);
    use HTML::Entities;
    ( $name, $start, $end, $credential, $description ) = ( "", "", "", "", "" );
    $cred = $credentials{$edit} || {};
    $this = encode('UTF-8', encode_entities($edit));
    $name         = $cred->{name} || $this || $form{"input/name"} || "";
    $id           = $cred->{id}   || "";
    $version      = $cred->{snmpversion}  || $form{"input/snmpversion"}  || $form{snmpversion} || $snmpversion || "";
    $community    = $cred->{community}    || $form{"input/community"}    || "";
    $username     = $cred->{username}     || $form{"input/username"}     || "";
    $remoteuser   = $cred->{username}     || $form{"input/remoteuser"}   || "";
    $remotepass   = $cred->{password}     || $form{"input/remotepass"}   || "";
    $type         = $cred->{type}         || $form{"input/type"}         || ($form{remotecreds} ? "ssh" : "snmp");
    $authprotocol = $cred->{authprotocol} || $form{"input/authprotocol"} || "";
    $authpassword = $cred->{authpassword} || $form{"input/authpassword"} || "";
    $privprotocol = $cred->{privprotocol} || $form{"input/privprotocol"} || "";
    $privpassword = $cred->{privpassword} || $form{"input/privpassword"} || "";
    $description  = $cred->{description}  || $form{"input/description"}  || "";
    $port         = $cred->{port}         || $form{"input/port"}         || "";
    $protocol     = $cred->{protocol}     || $form{"input/protocol"}     || "";
    $mode         = $cred->{mode}         || $form{"input/mode"}         || "";
    $showpass     = $form{"show-password"} && $form{"show-password"} eq "on" ? 1 : 0;
    $credentials{$edit} ? sprintf(_("Edit &laquo;&nbsp;%s&nbsp;&raquo; credential"), ($cred->{name} || $this))
      : _"Add new credential"}</h2>
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' name='edit' value='{$this}'/>{
      $form{empty} ? "
    <input type='hidden' name='empty' value='1'/>" : "" }
    <input type='hidden' name='remotecreds' id='remotecreds' value='{$form{remotecreds}||""}'/>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='name'>{_"Name"}</label>
        <div class='form-edit-row'>
          <input class='input-row' type='text' id='name' name='input/name' placeholder='{_"Name"}' value='{$name}' size='20'{
            ($id ? " title='Id: $id'" : "").($form{allow_name_edition} ? ">" : " disabled>
          <input class='input-row' type='submit' name='submit/rename' value='"._("Allow renaming")."'>")}
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='type-option' style='display: flex'>
      <div class='form-edit'>
        <label>{_"Type"}</label>
        <div class='form-edit-row' id='type-options'>
          <input type="radio" name="input/type" id="snmp" value="snmp" onchange="type_change()"{$type eq "snmp" ? " checked" : ""}>
          <label for='snmp'>snmp</label>
          <input type="radio" name="input/type" id="ssh" value="ssh" onchange="type_change()"{$type eq "ssh" ? " checked" : ""}>
          <label for='ssh'>ssh</label>
          <input type="radio" name="input/type" id="winrm" value="winrm" onchange="type_change()"{$type eq "winrm" ? " checked" : ""}>
          <label for='winrm'>winrm</label>
          <input type="radio" name="input/type" id="esx" value="esx" onchange="type_change()"{$type eq "esx" ? " checked" : ""}>
          <label for='esx'>esx</label>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='snmp-version-option' style='display: {$type eq "snmp" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label>{_"Version"}</label>
        <div class='form-edit-row' id='snmp-version-options'>
          <input type="radio" name="input/snmpversion" id="v1" value="v1" onchange="version_change()"{$version && $version eq "v1" ? " checked" : ""}{$type ne "snmp" ? " disabled" : ""}>
          <label for='v1'>v1</label>
          <input type="radio" name="input/snmpversion" id="v2c" value="v2c" onchange="version_change()"{!$version || $version eq "v2c" ? " checked" : ""}{$type ne "snmp" ? " disabled" : ""}>
          <label for='v2c'>v2c</label>
          <input type="radio" name="input/snmpversion" id="v3" value="v3" onchange="version_change()"{$version && $version eq "v3" ? " checked" : ""}{$type ne "snmp" ? " disabled" : ""}>
          <label for='v3'>v3</label>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='v1-v2c-option' style='display: {$type eq "snmp" && (!$version || $version =~ /v1|v2c/) ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='community'>{_"Community"}</label>
        <input class='input-row' type='text' id='community' name='input/community' placeholder='{_"Community"}' value='{$community}' {$type ne "snmp" || $version eq "v3" ? " disabled" : ""}>
      </div>
    </div>
    <div class='form-edit-row' id='v3-options' style='display: {$type eq "snmp" && $version && $version eq "v3" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='username'>{_"Username"}</label>
        <input class='input-row' type='text' id='username' name='input/username' placeholder='{_"Username"}' value='{$username}' size='12' {$type ne "snmp" || $version ne "v3" ? " disabled" : ""}>
      </div>
      <div class='form-edit'>
        <label for='authproto'>{_"Authentication protocol"}</label>
        <div class='form-edit-row'>
          <select class='input-row' id='authproto' name='input/authprotocol' {$type eq "snmp" && (!$version || $version ne "v3") ? " disabled" : ""}>
            <option{$authprotocol ? "" : " selected"}></option>
            <option{$authprotocol eq "md5" ? " selected" : ""}>md5</option>
            <option{$authprotocol eq "sha" ? " selected" : ""}>sha</option>
          </select>
        </div>
        <label for='authpass'>{_"Authentication password"}</label>
        <div class='form-edit-row'>
          <input class='input-row' id='authpass' type='{$showpass ? "text" : "password"}' name='input/authpassword' placeholder='{_"Authentication password"}' value='{$authpassword}' size='20' {!$version || $version ne "v3" ? " disabled" : ""}>
        </div>
      </div>
      <div class='form-edit'>
        <label for='privproto'>{_"Privacy protocol"}</label>
        <div class='form-edit-row'>
          <select class='input-row' id='privproto' name='input/privprotocol' {!$version || $version ne "v3" ? " disabled" : ""}>
            <option{$privprotocol ? "" : " selected"}></option>
            <option{$privprotocol eq "des" ? " selected" : ""}>des</option>
            <option{$privprotocol eq "aes" ? " selected" : ""}>aes</option>
            <option{$privprotocol eq "3des" ? " selected" : ""}>3des</option>
          </select>
        </div>
        <label for='authpass'>{_"Privacy password"}</label>
        <div class='form-edit-row'>
          <input class='input-row' id='privpass' type='{$showpass ? "text" : "password"}' name='input/privpassword' placeholder='{_"Privacy password"}' value='{$privpassword}' size='20' {!$version || $version ne "v3" ? " disabled" : ""}>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='remote-options' style='display: {$type ne "snmp" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='remoteuser'>{_"Username"}</label>
        <input class='input-row' type='text' id='remoteuser' name='input/remoteuser' placeholder='{_"Username"}' value='{$remoteuser}' size='12'>
      </div>
      <div class='form-edit'>
        <label for='remotepass'>{_"Authentication password"}</label>
        <div class='form-edit-row'>
          <input class='input-row'  type='{$showpass ? "text" : "password"}' id='remotepass' name='input/remotepass' placeholder='{_"Authentication password"}' value='{$remotepass}' size='24'>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='advanced-options' style='display: {$type ne "esx" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='port'>{_"Port"}</label>
        <input class='input-row' type='text' id='port' name='input/port' placeholder='{
            $type eq "snmp" ? 161 : $type eq "ssh" ? 22 : $type eq "winrm" && $mode eq "ssl" ? 5986 : $type eq "winrm" ? 5985 : 0
        }' value='{$port}' size='6'{$type eq "esx" ? " disabled" : ""}>
      </div>
      <div class='form-edit' id='advanced-options-protocol' style='display: {$type eq "snmp" ? "flex" : "none"}'>
        <label for='protocol'>{_"Protocol"}</label>
        <div class='form-edit-row'>
          <select class='input-row' id='protocol' name='input/protocol'{$type ne "snmp" ? " disabled" : ""}>
            <option{!protocol || $protocol eq "udp" ? " selected" : ""}>udp</option>
            <option{$protocol eq "tcp" ? " selected" : ""}>tcp</option>
          </select>
        </div>
      </div>
      <div class='form-edit' id='advanced-options-ssh-mode' style='display: {$type eq "ssh" ? "flex" : "none"}'>
        <label>{_"Remote SSH Mode"}</label>
        <div class='form-edit-row'>
          <ul>
            <li><input type='checkbox' id='ssh-mode' name='checkbox/mode/ssh'{(grep { $_ eq "ssh" } split(/,/, $mode) ? " checked" : "").($type ne "ssh" ? " disabled" : "")}>ssh</li>
            <li><input type='checkbox' id='libssh2-mode' name='checkbox/mode/libssh2'{(grep { $_ eq "libssh2" } split(/,/, $mode) ? " checked" : "").($type ne "ssh" ? " disabled" : "")}>libssh2</li>
            <li><input type='checkbox' id='perl-mode' name='checkbox/mode/perl'{(grep { $_ eq "perl" } split(/,/, $mode) ? " checked" : "").($type ne "ssh" ? " disabled" : "")}>perl</li>
          </ul>
        </div>
      </div>
      <div class='form-edit' id='advanced-options-winrm-mode' style='display: {$type eq "winrm" ? "flex" : "none"}'>
        <label>{_"Remote WinRM Mode"}</label>
        <div class='form-edit-row'>
          <ul>
            <li><input type='checkbox' id='ssl' name='checkbox/mode/ssl' onchange="type_change()"{($mode eq "ssl" ? " checked" : "").($type ne "winrm" ? " disabled" : "")}>ssl</li>
          </ul>
        </div>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='description'>{_"Description"}</label>
        <input class='input-row' type='text' id='description' name='input/description' placeholder='{_"Description"}' value='{$description}' size='40'>
      </div>
    </div>
    <div class='form-edit-row' id='show-password' style='display: {$type ne "snmp" || $version eq "v3" ? "flex" : "none"}'>
      <label class='switch'>
        <input name='show-password' id='show-password-switch' class='switch' type='checkbox'{$showpass ? " checked" : ""} onclick='show_password()'>
        <span class='slider'></span>
      </label>
      <label for='show-password-switch' class='text'>{_"Show password"}</label>
    </div>
    <input type='submit' class='big-button' name='submit/{
      $credentials{$edit} ?
        "update' value='"._("Update") :
        "add' value='"._("Create Credential")}'>
    <input type='submit' class='big-button' name='submit/cancel' value='{_("Cancel")}'>
  </form>
  <script>
  function version_change() \{
    if (document.getElementById("v3").checked) \{
      document.getElementById("v1-v2c-option").style = "display: none";
      document.getElementById("v3-options").style = "display: flex";
      change_disabled_in_form(true);
    \} else \{
      document.getElementById("v3-options").style = "display: none";
      document.getElementById("v1-v2c-option").style = "display: flex";
      change_disabled_in_form(false);
    \}
  \}
  function change_disabled_in_form(b) \{
      document.getElementById("community").disabled=b;
      document.getElementById("username").disabled=!b;
      document.getElementById("authproto").disabled=!b;
      document.getElementById("authpass").disabled=!b;
      document.getElementById("privproto").disabled=!b;
      document.getElementById("privpass").disabled=!b;
  \}
  function type_change() \{
    if (document.getElementById("snmp").checked) \{
      document.getElementById("remote-options").style = "display: none";
      document.getElementById("snmp-version-option").style = "display: flex";
      document.getElementById("remotecreds").value = "0";
      document.getElementById("port").placeholder = "161";
      document.getElementById("advanced-options-protocol").style = "display: flex";
      document.getElementById("protocol").disabled = false;
      document.getElementById("v1").disabled = false;
      document.getElementById("v2c").disabled = false;
      document.getElementById("v3").disabled = false;
      document.getElementById("community").disabled = false;
      document.getElementById("username").disabled = false;
      document.getElementById("authproto").disabled = false;
      document.getElementById("authpass").disabled = false;
      document.getElementById("privproto").disabled = false;
      document.getElementById("privpass").disabled = false;
      version_change();
    \} else \{
      document.getElementById("v3-options").style = "display: none";
      document.getElementById("v1-v2c-option").style = "display: none";
      document.getElementById("snmp-version-option").style = "display: none";
      document.getElementById("remote-options").style = "display: flex";
      document.getElementById("remotecreds").value = "1";
      document.getElementById("advanced-options-protocol").style = "display: none";
      document.getElementById("protocol").disabled = true;
      document.getElementById("v1").disabled = true;
      document.getElementById("v2c").disabled = true;
      document.getElementById("v3").disabled = true;
      document.getElementById("community").disabled = true;
      document.getElementById("username").disabled = true;
      document.getElementById("authproto").disabled = true;
      document.getElementById("authpass").disabled = true;
      document.getElementById("privproto").disabled = true;
      document.getElementById("privpass").disabled = true;
    \}
    if (document.getElementById("ssh").checked) \{
      document.getElementById("advanced-options-ssh-mode").style = "display: flex";
      document.getElementById("port").placeholder = "22";
      document.getElementById("ssh-mode").disabled = false;
      document.getElementById("libssh2-mode").disabled = false;
      document.getElementById("perl-mode").disabled = false;
    \} else \{
      document.getElementById("advanced-options-ssh-mode").style = "display: none";
      document.getElementById("ssh-mode").disabled = true;
      document.getElementById("libssh2-mode").disabled = true;
      document.getElementById("perl-mode").disabled = true;
    \}
    if (document.getElementById("winrm").checked) \{
      document.getElementById("advanced-options-winrm-mode").style = "display: flex";
      document.getElementById("ssl").disabled = false;
      if (document.getElementById("ssl").checked) \{
        document.getElementById("port").placeholder = "5986";
      \} else \{
        document.getElementById("port").placeholder = "5985";
      \}
    \} else \{
      document.getElementById("advanced-options-winrm-mode").style = "display: none";
      document.getElementById("ssl").disabled = true;
    \}
    if (document.getElementById("esx").checked) \{
      document.getElementById("advanced-options").style = "display: none";
      document.getElementById("port").disabled = true;
    \} else \{
      document.getElementById("advanced-options").style = "display: flex";
      document.getElementById("port").disabled = false;
    \}
  \}
  function show_password() \{
    var checked;
    checked = document.getElementById('show-password-switch').checked;
    document.getElementById('remotepass').type = checked ? 'text' : 'password';
    document.getElementById('authpass').type = checked ? 'text' : 'password';
    document.getElementById('privpass').type = checked ? 'text' : 'password';
    document.getElementById('navbar-credentials').href = '{$url_path."/credentials"}'+(checked ? '?show-password=on' : '');
  \}
  </script>
