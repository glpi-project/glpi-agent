    <p class='infos'>
      <br/>{
  use URI::Escape;
  Text::Template::fill_in_file("$template_path/mibsupport-rules-infos.tpl", HASH => $hash)
    || "Error loading mibsupport-rules-infos.tpl template: $Text::Template::ERROR"
}      <br/>
    </p>
    <table>
      <thead>
        <tr>
        <tr>
          <th class='checkbox' title='{_"Revert selection"}'>{ @ordered_rules ? "
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' name='checkbox/rules' onclick='toggle_all(this)'>
              <span class='custom-checkbox all_cb'></span>
            </label>
          ": "&nbsp;"
          }</th>
          <th>{_"Rule name"}</th>
          <th width='5%' align='center'>{_"Rule type"}</th>
          <th align='center'>{_"Value"}</th>
          <th width='5%' align='center'>{_"Value type"}</th>
          <th>{_"Description"}</th>
        </tr>
      </thead>
      <tbody>{
  $count = 0;
  foreach my $name (@ordered_rules) {
    my $rule = $rules{$name}
      or next;
    my $type        = $rule->{type} || "";
    my $value       = $rule->{value} || "";
    my $valuetype   = $rule->{valuetype} || "raw";
    my $description = $rule->{description} || "";
    $OUT .= "
        <tr class='$request'>
          <td class='checkbox'>
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' name='checkbox/rules/$name'>
              <span class='custom-checkbox'></span>
            </label>
          </td>
          <td class='list'><a href='$url_path/$request?edit=".uri_escape($name)."&currenttab=rules'>$name</a></td>
          <td class='list' align='center'>$type</td>
          <td class='list'>$value</td>
          <td class='list' align='center'>$valuetype</td>
          <td class='list'>$description</td>
        </tr>
      ";
    $count++;
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
      <input class='submit-secondary' type='submit' name='submit/delete' value='{_"Delete"}'>
    </div>
    <hr/>
    <input class='big-button' type='submit' name='submit/add/rule' value='{_"Add new rule"}'>
