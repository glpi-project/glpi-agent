    <p class='infos'>
      <br/>
      {_"Here is the list of known aliases"}.<br/>
      {_"Alias must be uniq, begin by a letter or digit and only contain letters, digits or eventually tirets, dots and underscores"}.<br/>
      {_"Aliases are used to fully resolve symbolic OID to plain numeric OID"}.<br/>
      <br/>
    </p>
    <table>
      <thead>
        <tr>
          <th class='checkbox' title='{_"Revert selection"}'>{ @ordered_aliases ? "
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' name='checkbox/aliases' onclick='toggle_all(this)'>
              <span class='custom-checkbox all_cb'></span>
            </label>
          ": "&nbsp;"
          }</th>
          <th>{_"Alias"}</th>
          <th width='80%'>{_"OID"}</th>
        </tr>
      </thead>
      <tbody>{
  use URI::Escape;
  $count = 0;
  foreach (@ordered_aliases) {
    my ($alias, $oid) = @{$_} ;
    $OUT .= "
        <tr class='$request'>
          <td class='checkbox'>
            <label class='checkbox'>
              <input class='checkbox' type='checkbox' name='checkbox/aliases/$alias'>
              <span class='custom-checkbox'></span>
            </label>
          </td>
          <td class='list'><a href='$url_path/$request?edit=".uri_escape($alias)."&currenttab=aliases'>$alias</a></td>
          <td width='80%' class='list'>$oid</td>
        </tr>
      ";
    $count++;
  }
  # Handle empty list case
  unless ($count) {
    $OUT .= "
        <tr class='$request'>
          <td width='20px'>&nbsp;</td>
          <td class='list' colspan='3'>"._("empty list")."</td>
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
    <p>{_"Agent still supports following aliases"}:</p>
    <table>
      <tbody>
        <tr class='$request'>
          <td width='20px'>&nbsp;</td><td class='list'>iso</td><td width='80%' class='list'>.1</td>
        </tr>
        <tr class='$request'>
          <td width='20px'>&nbsp;</td><td class='list'>private</td><td width='80%' class='list'>.1.3.6.1.4</td>
        </tr>
        <tr class='$request'>
          <td width='20px'>&nbsp;</td><td class='list'>enterprises</td><td width='80%' class='list'>.1.3.6.1.4.1</td>
        </tr>
        <tr class='$request'>
          <td width='20px'>&nbsp;</td><td class='list'>mib-2</td><td width='80%' class='list'>.1.3.6.1.2.1</td>
        </tr>
      </tbody>
    </table>
    <hr/>
    <input class='big-button' type='submit' name='submit/add/alias' value='{_"Add new alias"}'>
