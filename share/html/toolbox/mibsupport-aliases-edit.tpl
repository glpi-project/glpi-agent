  <h2>{
    use Encode qw(encode);
    use HTML::Entities;
    $oid = $aliases{$edit} || "";
    $this = encode('UTF-8', encode_entities($edit));
    $oid ? sprintf(_("Edit &laquo;&nbsp;%s&nbsp;&raquo; alias"), $this) : _"Add new alias"}</h2>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='alias'>{_"Alias"}</label>
        <div class='form-edit-row'>
          <input class='input-row' type='text' id='alias' name='input/alias' value='{$this || $form{"input/alias"} }' pattern='^[A-Za-z0-9][A-Za-z0-9._-]*$' size='20' title='{_"Alias must be uniq, begin by a letter or digit and only contain letters, digits or eventually tirets, dots and underscores"}'>
        </div>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='oid'>{_"OID"}</label>
        <input class='input-row' type='text' id='oid' name='input/oid' value='{$oid || $form{"input/oid"} || ""}' pattern='^[A-Za-z0-9.-]*$' size='80' title='{_"OID can begin by a letter, a digit or a dot and only contain letters, digits, tirets and dots"}'>
      </div>
    </div>
    <input type='submit' class='big-button' name='submit/{
      $oid ? "update/alias' value='"._("Update") : "add/alias' value='"._("Add") }'>
