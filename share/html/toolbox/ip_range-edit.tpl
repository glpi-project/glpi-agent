  <h2>{
    use Encode qw(encode);
    use HTML::Entities;
    use URI::Escape;
    $range = $ip_range{$edit} || {};
    $this = encode('UTF-8', encode_entities($edit));
    $ip_range{$edit} ? sprintf(_("Edit &laquo;&nbsp;%s&nbsp;&raquo; ip range"), ($range->{name} || $this))
      : _"Add new IP range"}</h2>
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' name='edit' value='{$this}'/>{
      $form{empty} ? "
    <input type='hidden' name='empty' value='1'/>" : "" }
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='name'>{_"Name"}</label>
        <div class='form-edit-row'>
          <input class='input-row' type='text' id='name' name='input/name' value='{ $range->{name} || $this || $form{"input/name"} }' size='20'{$form{empty} ? "" : " disabled"}>
          <input type='button' class='button' value='{_"Rename"}' onclick='handle_rename()'{$form{empty} ? " style='display:none'" : ""}/>
        </div>
        <div id='rename-overlay' class='overlay' onclick='cancel_rename()'>
          <div class='overlay-frame' onclick='event.stopPropagation()'>
            <label for='rename' class='newtag'>{_"Rename"}:</label>
            <input id='input-rename' type='text' class='newtag' name='input/new-name' value='{ $form{"input/new-name"} || $range->{name} || $this }' size='30' disabled/>
            <input type='submit' class='big-button' name='submit/rename' value='{_"Rename"}'/>
            <input type='button' class='big-button' name='submit/rename-cancel' value='{_"Cancel"}' onclick='cancel_rename()'/>
          </div>
        </div>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='ip_start'>{_"IP range start"}</label>
        <input class='input-row' type='text' id='ip_start' name='input/ip_start' placeholder='A.B.C.D' value='{$range->{ip_start} || $form{"input/ip_start"} || ""}' size='15'>
      </div>
      <div class='form-edit'>
        <label for='ip_end'>{_"IP range end"}</label>
        <input class='input-row' type='text' id='ip_end' name='input/ip_end' placeholder='W.X.Y.Z' value='{$range->{ip_end} || $form{"input/ip_end"} || ""}' size='15'>
      </div>
    </div>
    <div class='form-edit'>
      <label>{_"Associated credentials"}</label>
      <div id='credentials'>
        <ul>{
        my @credentials = ();
        my %checkbox = map { m{^checkbox/cred/(.*)$} => 1 } grep { m{^checkbox/cred/} && $form{$_} eq 'on' } keys(%form);
        map { $checkbox{$_} = 1 } @{$range->{credentials}} if !keys(%checkbox) && @{$range->{credentials}};
        @credentials = sort { $a cmp $b } keys(%checkbox);
        foreach my $credential (@credentials) {
          my $cred = $credentials{$credential}
            or next;
          $OUT .= "
          <li>
            <input type='checkbox' name='checkbox/cred/".encode('UTF-8', encode_entities($credential))."' checked>
            <div class='with-tooltip'>
              <a href='$url_path/credentials?edit=".uri_escape(encode("UTF-8", $credential))."'>".encode('UTF-8', encode_entities($cred->{name} || $credential))."
                <div class='tooltip right-tooltip'>
                  <p>".($cred->{type} ? _("Type").":&nbsp;".$cred->{type} : _("SNMP version").":&nbsp;".$cred->{snmpversion})."</p>
                  <p>".(!$cred->{type} && $cred->{snmpversion} ne "v3" ? _("Community").":&nbsp;".$cred->{community} : _("Username").":&nbsp;".$cred->{username})."</p>
                  <i></i>
                </div>
              </a>
            </div>
          </li>";
          delete $credentials{$credential};
        }
        if (keys(%credentials)) {
          my $select = $form{"input/credentials"} || "";
          $OUT .= "
          <li>
            <select name='input/credentials'>
              <option".($select ? "" : " selected")."></option>".
          join("", map { "
              <option".(($select && $select eq $_)? " selected" : "").
          " value='".encode('UTF-8', encode_entities($_))."'>".encode('UTF-8', encode_entities($credentials{$_}->{name} || $_))."</option>"
        } sort { $a cmp $b } keys(%credentials))."
            </select>
            <input class='input-row' type='submit' name='submit/addcredential' value='".(_"Add credential")."'>
          </li>";
        }
        '';}
        </ul>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
      <label for='desc'>{_"Description"}</label>
      <input class='input-row' type='text' id='desc' name='input/description' value='{$range->{description} || $form{"input/description"} || ""}' size='40'>
      </div>
    </div>
    <input type='submit' class='big-button' name='submit/{
      $ip_range{$edit} ?
        "update' value='"._("Update") :
        "add' value='"._("Add") }'>
    <input type='submit' class='big-button' name='submit/cancel' value='{_("Cancel")}'>
  </form>
  <script>
    function handle_rename () \{
      document.getElementById("input-rename").disabled = false;
      document.getElementById("rename-overlay").style.display = "block";
    \}
    function cancel_rename () \{
      document.getElementById("rename-overlay").style.display = "none";
      document.getElementById("input-rename").disabled = true;
    \}
  </script>
