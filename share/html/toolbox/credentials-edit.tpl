  <h2>{
    use Encode qw(encode);
    use HTML::Entities;
    ( $name, $start, $end, $credential, $description ) = ( "", "", "", "", "" );
    $cred = $credentials{$edit} || {};
    $this = encode('UTF-8', encode_entities($edit));
    $name         = $cred->{name} || $this || $form{"input/name"} || "";
    $id           = $cred->{id}   || "";
    $version      = $cred->{snmpversion}  || $form{"input/snmpversion"}  || "";
    $community    = $cred->{community}    || $form{"input/community"}    || "";
    $username     = $cred->{username}     || $form{"input/username"}     || "";
    $authprotocol = $cred->{authprotocol} || $form{"input/authprotocol"} || "";
    $authpassword = $cred->{authpassword} || $form{"input/authpassword"} || "";
    $privprotocol = $cred->{privprotocol} || $form{"input/privprotocol"} || "";
    $privpassword = $cred->{privpassword} || $form{"input/privpassword"} || "";
    $description  = $cred->{description}  || $form{"input/description"}  || "";
    $credentials{$edit} ? sprintf(_("Edit &laquo;&nbsp;%s&nbsp;&raquo; credential"), ($cred->{name} || $this))
      : _"Add new credential"}</h2>
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' name='edit' value='{$this}'/>{
      $form{empty} ? "
    <input type='hidden' name='empty' value='1'/>" : "" }
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
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label>{_"Version"}</label>
        <div class='form-edit-row' id='radio-options'>
          <input type="radio" name="input/snmpversion" id="v1" value="v1" onchange="version_change()"{$version && $version eq "v1" ? " checked" : ""}>
          <label for='v1'>v1</label>
          <input type="radio" name="input/snmpversion" id="v2c" value="v2c" onchange="version_change()"{!$version || $version eq "v2c" ? " checked" : ""}>
          <label for='v2c'>v2c</label>
          <input type="radio" name="input/snmpversion" id="v3" value="v3" onchange="version_change()"{$version && $version eq "v3" ? " checked" : ""}>
          <label for='v3'>v3</label>
        </div>
      </div>
    </div>
    <div class='form-edit-row' id='v1-v2c-option' style='display: {!$version || $version =~ /v1|v2c/ ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='community'>{_"Community"}</label>
        <input class='input-row' type='text' id='community' name='input/community' placeholder='{_"Community"}' value='{$community}' {$version eq "v3" ? " disabled" : ""}>
      </div>
    </div>
    <div class='form-edit-row' id='v3-options' style='display: {$version && $version eq "v3" ? "flex" : "none"}'>
      <div class='form-edit'>
        <label for='username'>{_"Username"}</label>
        <input class='input-row' type='text' id='username' name='input/username' placeholder='{_"Username"}' value='{$username}' size='12' {!$version || $version ne "v3" ? " disabled" : ""}>
      </div>
      <div class='form-edit'>
        <label for='authproto'>{_"Authentication protocol"}</label>
        <div class='form-edit-row'>
          <select class='input-row' id='authproto' name='input/authprotocol' {!$version || $version ne "v3" ? " disabled" : ""}>
            <option{$authprotocol ? "" : " selected"}></option>
            <option{$authprotocol eq "md5" ? " selected" : ""}>md5</option>
            <option{$authprotocol eq "sha" ? " selected" : ""}>sha</option>
          </select>
        </div>
        <label for='authpass'>{_"Authentication password"}</label>
        <div class='form-edit-row'>
          <input class='input-row' id='authpass' type='text' name='input/authpassword' placeholder='{_"Authentication password"}' value='{$authpassword}' size='20' {!$version || $version ne "v3" ? " disabled" : ""}>
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
          <input class='input-row' id='privpass' type='text' name='input/privpassword' placeholder='{_"Privacy password"}' value='{$privpassword}' size='20' {!$version || $version ne "v3" ? " disabled" : ""}>
        </div>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='description'>{_"Description"}</label>
        <input class='input-row' type='text' id='description' name='input/description' placeholder='{_"Description"}' value='{$description}' size='40'>
      </div>
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
  </script>
