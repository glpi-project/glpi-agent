  <h2>{
    use Encode qw(encode);
    use HTML::Entities;
    use URI::Escape;
    $range = $ip_range{$edit} || {};
    $this = encode('UTF-8', encode_entities($edit));
    $name = $range->{name} || $this || $form{"input/name"} || "";
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
          <input class='input-row' type='text' id='name' name='input/name' value='{$name}' size='20' required />
        </div>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='ip_start'>{_"IP range start"}</label>
        <input class='input-row' type='text' id='ip_start' name='input/ip_start' placeholder='A.B.C.D' value='{$range->{ip_start} || $form{"input/ip_start"} || ""}' size='15'/>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='ip_end'>{_"IP range end"}</label>
        <input class='input-row' type='text' id='ip_end' name='input/ip_end' placeholder='W.X.Y.Z' value='{$range->{ip_end} || $form{"input/ip_end"} || ""}' size='15'/>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label>{_"Associated credentials"}</label>
        <div class='form-edit-row' id='credentials'>
          <ul>{
        my @credentials = ();
        my %checkbox = map { m{^checkbox/cred/(.*)$} => 1 } grep { m{^checkbox/cred/} && $form{$_} eq 'on' } keys(%form);
        map { $checkbox{$_} = 1 } @{$range->{credentials}} if !keys(%checkbox) && @{$range->{credentials}};
        @credentials = sort { $a cmp $b } keys(%checkbox);
        foreach my $credential (@credentials) {
          my $cred = $credentials{$credential}
            or next;
          my $credname = encode('UTF-8', encode_entities($cred->{name} || $credential));
          $OUT .= "
            <li>
              <input type='checkbox' name='checkbox/cred/$credname' checked />
              <div class='with-tooltip'>
                <a href='$url_path/credentials?edit=".uri_escape($credname)."'>$credname
                  <div class='tooltip right-tooltip'>".($cred->{type} ? "
                    <p>"._("Type").":&nbsp;".$cred->{type}."</p>" : "").((!$cred->{type} || $cred->{type} eq "snmp") && $cred->{snmpversion} ? "
                    <p>"._("SNMP version").":&nbsp;".$cred->{snmpversion}."</p>" : "")."
                    <p>".((!$cred->{type} || $cred->{type} eq "snmp") && $cred->{snmpversion} && $cred->{snmpversion} ne "v3" ? _("Community").":&nbsp;".$cred->{community} : _("Username").":&nbsp;".$cred->{username})."</p>".($cred->{description} ? "
                    <p>"._("Description").":&nbsp;".encode('UTF-8', $cred->{description})."</p>" : "")."
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
                <option".($select ? "" : " selected")."></option>";
          foreach my $credential (sort { $a cmp $b } keys(%credentials)) {
            my $cred = $credentials{$credential}
              or next;
            my $credname = encode('UTF-8', encode_entities($cred->{name} || $credential));
            my $title = $cred->{type} ? _("Type").":&nbsp;".$cred->{type} : "";
            $title .= (length($title) ? "\n" : "")._("SNMP version").":&nbsp;".$cred->{snmpversion}
              if (!$cred->{type} || $cred->{type} eq "snmp") && $cred->{snmpversion};
            $title .= (length($title) ? "\n" : "").((!$cred->{type} || $cred->{type} eq "snmp") && $cred->{snmpversion} && $cred->{snmpversion} ne "v3" ? _("Community").":&nbsp;".$cred->{community} : _("Username").":&nbsp;".$cred->{username});
            my $description = $cred->{description};
            if ($description) {
              $description =~ s/[']/\\'/g;
              $title .= "\n"._("Description").": ".encode('UTF-8', $description);
            }
            $OUT .= "
                <option".(($select && $select eq $credential)? " selected" : "")." value='$credname' title='$title'>$credname
                </option>";
          }
          $OUT .= "
              </select>
              <input class='input-row credentials' type='submit' name='submit/addcredential' value='".(_"Add credential")."'/>
            </li>";
        }
        '';}
          </ul>
        </div>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
      <label for='desc'>{_"Description"}</label>
      <input class='input-row' type='text' id='desc' name='input/description' value='{$range->{description} || $form{"input/description"} || ""}' size='40'/>
      </div>
    </div>
    <input type='submit' class='big-button' name='submit/{
      $ip_range{$edit} ?
        "update' value='"._("Update") :
        "add' value='"._("Add") }'/>
    <input type='submit' class='big-button secondary-button' name='submit/cancel' value='{_("Cancel")}'/>
  </form>
