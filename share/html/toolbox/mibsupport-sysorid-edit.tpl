  <h2>{
    use Encode qw(encode);
    use HTML::Entities;
    use URI::Escape;
    $sysorid = $mibsupport{$edit} || {};
    $oid = $sysorid->{oid} || $form{"input/oid"} || "";
    $ruleset = $sysorid->{rules} || [];
    $description = $sysorid->{description} || $form{"input/description"} || "";
    $this = encode('UTF-8', encode_entities($edit));
    $edit ? sprintf(_("Edit &laquo;&nbsp;%s&nbsp;&raquo; MIB support match"), $this) : _"Add MIB support match"}</h2>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='name'>{_"Name"}</label>
        <div class='form-edit-row'>
          <input class='input-row' type='text' id='rule' name='input/name' value='{$this || $form{"input/name"} }' pattern='^[A-Za-z0-9][A-Za-z0-9._-]*$' size='20' title='{_"Name must be uniq, begin by a letter or digit and only contain letters, digits or eventually tirets, dots and underscores"}' required>
        </div>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='oid'>{_"OID"}</label>
        <input class='input-row' type='text' id='oid' name='input/oid' value='{$oid || $form{"input/oid"} || ""}' pattern='^[A-Za-z0-9.-]*$' size='80' title='{_"OID can begin by a letter, a digit or a dot and only contain letters, digits, tirets and dots"}'>
      </div>
    </div>
    <div class='form-edit'>
      <label for='ruleset'>{_"Ruleset"}</label>
      <div id='ruleset'>
        <ul>{
        my @ruleset = ();
        my %checkbox = map { m{^checkbox/rules/(.*)$} => 1 } grep { m{^checkbox/rules/} && $form{$_} eq 'on' } keys(%form);
        map { $checkbox{$_} = 1 } @{$ruleset} if !keys(%checkbox) && @{$ruleset};
        @ruleset = sort { $a cmp $b } keys(%checkbox);
        foreach my $rule (@ruleset) {
          next unless $rules{$rule};
          $OUT .= "
          <li><input type='checkbox' name='checkbox/rules/$rule' checked><a href='$url_path/$request?edit=".uri_escape($rule)."&currenttab=rules'>$rule</a></li>";
          delete $rules{$rule};
        }
        if (keys(%rules)) {
          my $select = $form{"input/rule"} || "";
          $OUT .= "
          <li>
            <select name='input/rule'>
              <option".($select ? "" : " selected")."></option>".
            join("", map { "
              <option".(($select && $select eq $_)? " selected" : "").">$_</option>"
            } sort { $a cmp $b } keys(%rules))."
            </select>
            <button class='secondary' type='submit' name='submit/add/rule' value='1' alt='"._("Add rule")."'><i class='secondary ti ti-playlist-add'></i>"._("Add rule")."</button>
          </li>";
        }}
        </ul>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='description'>{_"Description"}</label>
        <input class='input-row' type='text' id='description' name='input/description' value='{$description || $form{"input/description"} || ""}' size='80'>
      </div>
    </div>
    <button type='submit' class='big-button' name='submit/{
      $this ? "update/sysorid' alt='"._("Update") : "add/sysorid' alt='"._("Add") }' value='1'><i class='primary ti ti-device-floppy'></i>{ $this ? _("Update") : _("Add") }</button>
