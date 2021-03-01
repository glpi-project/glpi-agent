  <h2>{
    use Encode qw(encode);
    use HTML::Entities;
    $rule = $rules{$edit} || {};
    $type = $rule->{type} || $form{"input/type"} || "";
    $value = $rule->{value} || $form{"input/value"} || "";
    $valuetype = $rule->{valuetype} || $form{"input/valuetype"} || $valuetype_options[0];
    $description = $rule->{description} || $form{"input/description"} || "";
    $this = encode('UTF-8', encode_entities($edit));
    $rules{$edit} ? sprintf(_("Edit &laquo;&nbsp;%s&nbsp;&raquo; rule"), $this) : _"Add new rule"}</h2>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='rule'>{_"Rule"}</label>
        <div class='form-edit-row'>
          <input class='input-row' type='text' id='rule' name='input/rule' value='{$this || $form{"input/rule"} }' pattern='^[A-Za-z0-9][A-Za-z0-9._-]*$' size='20' title='{_"Rule name must be uniq, begin by a letter or digit and only contain letters, digits or eventually tirets, dots and underscores"}'>
        </div>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='type'>{_"Type"}</label>
        <select id='type' name='input/type'>
          <option{$type ? "" : " selected"}></option>{
    foreach my $option (@type_options) {
        $OUT .= "
          <option".($type eq $option ? " selected" : "").">$option</option>";
    }
}        </select>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='value'>{_"Value"}</label>
        <input class='input-row' type='text' id='value' name='input/value' value='{$value || $form{"input/value"} || ""}' size='60'>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='valuetype'>{_"Value type"}</label>
        <select id='type' name='input/valuetype'>{
    foreach my $option (@valuetype_options) {
        $OUT .= "
          <option".($type eq $option ? " selected" : "").">$option</option>";
    }
}        </select>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='description'>{_"Description"}</label>
        <input class='input-row' type='text' id='description' name='input/description' value='{$description || $form{"input/description"} || ""}' size='80'>
      </div>
    </div>
    <input type='submit' class='big-button' name='submit/{
      $this ? "update/rule' value='"._("Update") : "add/rule' value='"._("Add") }'>
