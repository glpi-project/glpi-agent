
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' name='edit' value='{$edit}'/>
    <div id='edit-header'>
      <p class='arrow'>{
        $index > 0 ? "
        <a href='$url_path/$request?edit=$devices_order[0]' class='arrow'>&LeftArrowBar;</a>
        " : "" ;}</p>
      <p class='arrow'>{
        $index > 0 ? "
        <a href='$url_path/$request?edit=$devices_order[$index-1]' class='arrow'>&LeftArrow;</a>
        " : "" }</p>
      <p class='name'><a href='{$url_path}/{$request}?edit={$edit}'>{$devices{$edit}->name}</a></p>
      <p class='return'>{$index+1}/{$list_count}</p>
      <p class='arrow'>{
        $index < $#devices_order ? "
        <a href='$url_path/$request?edit=$devices_order[$index+1]' class='arrow'>&RightArrow;</a>
        " : "" }</p>
      <p class='arrow'>{
        $index < $#devices_order ? "
        <a href='$url_path/$request?edit=$devices_order[$#devices_order]' class='arrow'>&RightArrowBar;</a>
        " : "" }</p>
    </div>{
  use Encode qw(encode);
  use HTML::Entities;
  $device = $devices{$edit};
  $select_fields = "";
  @has_selected_fields = ();
  $has_selected_fields = 0;
  foreach my $section (@sections) {
    my $name = $section->{name} || '';
    my $prefix = $section->{prefix} || '';
    $OUT .= "
    <p class='section'>"._($section->{title})."</p>" if $section->{title};
    $OUT .= "
    <table class='fields'>
      <tbody>";
    if ($prefix) {
      $select_fields .= "
      <p class='section'>"._($section->{title})."</p>" if $section->{title};
      $select_fields .= "
      <table class='fields'>
        <tbody>";
    }
    my %cols = map { $_->{editcol} => 1 } values(%{$section->{fields}});
    my @cols = sort { $a <=> $b } keys(%cols);
    my $sort1 = sub { $section->{fields}->{$_[0]}->{editcol}; };
    my $sort2 = sub { $section->{fields}->{$_[0]}->{index}; };
    my @fields = sort { &$sort1($a) <=> &$sort1($b) || &$sort2($a) <=> &$sort2($b) } keys(%{$section->{fields}});
    my @column = map {
      my $col = $_;
      [ grep { $section->{fields}->{$_}->{editcol} == $col } @fields ]
    } @cols;
    my ($maxcols) = sort { $b <=> $a } map { scalar(@{$_})-1 } @column;
    foreach my $index (0..$maxcols) {
      $OUT .= "
        <tr>";
      $select_fields .= "
          <tr>" if $prefix;
      foreach my $col (@cols) {
        my $fieldname = shift @{$column[$col]} || '';
        my $field = $fieldname && $section->{fields}->{$fieldname} || {};
        my $value = encode('UTF-8', encode_entities($device->get($prefix.$fieldname)));
        my $editname = "edit/$prefix$fieldname";
        if ($field->{type} eq 'header') {
          my $span = scalar(@cols) * 2;
          $OUT .= "
          <td class='headers $name-section-headr' title='"._("Field name").": $fieldname' colspan='$span'>".
            ($prefix ? $field->{text}||$fieldname : _($field->{text}||$fieldname))."</td>";
          if ($prefix) {
            $span = scalar(@cols) * 3;
            $select_fields .= "
            <td class='headers $name-section-headr' title='"._("Field name").": $fieldname' colspan='$span'>".
            ($prefix ? $field->{text}||$fieldname : _($field->{text}||$fieldname))."</td>";
          }
          last;
        }
        $OUT .= "
          <td class='fields $name-section-field' title='"._("Field name").": $fieldname'>".($prefix ? $field->{text}||$fieldname : _($field->{text}||$fieldname))."</td>
          <td class='values $name-section-value'>";
        if ($prefix && $fieldname) {
          my $text = $value;
          if ($field->{type} eq 'select') {
            my ($option) = grep { $_->{id} eq $value } @{$field->{options}};
            $text = encode('UTF-8', encode_entities($option->{value}))
              if $option && defined($option->{value});
          }
          $select_fields .= "
            <td class='checkbox'>
              <label class='checkbox'>
                <input class='checkbox' type='checkbox' name='field-checkbox/$prefix$fieldname'".
                (defined($checked_fields{$prefix.$fieldname}) ? " checked" : "")."/>
                <span class='custom-checkbox'></span>
              </label>
            </td>
            <td class='fields $name-section-field' title='"._("Field name").": $fieldname'>".($prefix ? $field->{text}||$fieldname : _($field->{text}||$fieldname))."</td>
            <td class='values $name-section-value'>$text</td>";
          $has_selected_fields[$col] = [] unless $has_selected_fields[$col];
          if (defined($checked_fields{$prefix.$fieldname})) {
            push @{$has_selected_fields[$col]}, [ $prefix.$fieldname, $field->{text}||$fieldname ];
            $has_selected_fields++;
          }
        }
        if ($fieldname && $fieldname eq 'credential') {
          $OUT .= $credentials{$value} ? "<a href='$url_path/credentials?edit=$value'>".($credentials{$value}->{name} || $value)."</a>" : "";
        } elsif ($fieldname && $fieldname eq 'ip_range') {
          $OUT .= $ip_range{$value} ? "<a href='$url_path/ip_range?edit=$value'>".($ip_range{$value}->{name} || $value)."</a>" : "";
        } elsif ($fieldname && ($device->noedit($prefix.$fieldname) || !$do)) {
          $OUT .= $fieldname =~ /^type|source$/ ? _($value) : $value;
        } elsif ($fieldname && $do eq 'edit') {
          $value = $field->{default} unless ((defined($value) && length($value)) || !defined($field->{default}));
          if ($fieldname eq 'type' && $device->source ne 'Local') {
            $OUT .= "
            <select name='$editname'>";
            unless ($device->type =~ /^NETWORKING|PRINTER|STORAGE$/) {
              $OUT .= "
              <option selected></option>";
            }
            foreach my $type (qw(NETWORKING PRINTER STORAGE)) {
              $OUT .= "
              <option value='$type'".($device->type eq $type ? " selected" : "").">"._($type)."</option>";
            }
            $OUT .= "
            </select>";
          } elsif ($field->{type} eq 'number') {
            $OUT .= "
            <input type='number' name='$editname' value='$value'/>";
          } elsif ($field->{type} eq 'date') {
            $OUT .= "
            <input type='text' id='dt_$fieldname' name='$editname' value='$value' onclick='opendatetime(\"dt_$fieldname\", false)'/>
            <input type='button' value='".(_"Reset")."' onclick='document.getElementById(\"dt_$fieldname\").value = \"$value\"'/>";
          } elsif ($field->{type} eq 'datetime') {
            $OUT .= "
            <input type='text' id='dt_$fieldname' name='$editname' value='$value' onclick='opendatetime(\"dt_$fieldname\", true)'/>
            <input type='button' value='".(_"Reset")."' onclick='document.getElementById(\"dt_$fieldname\").value = \"$value\"'/>";
          } elsif ($field->{type} eq 'textarea') {
            $OUT .= "
            <textarea class='custom-result $fieldname' name='$editname'>$value</textarea>";
          } elsif ($field->{type} eq 'select') {
            $OUT .= "
            <select name='$editname'>";
            foreach my $option (@{$field->{options}}) {
              my $title = ref($option) eq 'HASH' ? $option->{title} : '';
              my $opt   = ref($option) eq 'HASH' ? $option->{id}    : $option;
              my $text  = ref($option) eq 'HASH' ? encode('UTF-8', encode_entities($option->{value})) : $option;
              $OUT .= "
              <option value='$opt'".(defined($value) && $value eq $opt ? " selected" : "").
                ($title ? " title='$title'" : "").">$text</option>";
            }
            $OUT .= "
            </select>";
          } else {
            $OUT .= "
            <input type='text' name='$editname' value='$value'/>";
          }
        }
        $OUT .= "
          </td>";
      }
      $OUT .= "
        </tr>";
      $select_fields .= "
          </tr>" if $prefix;
    }
    $OUT .= "
      </tbody>
    </table>";
    $select_fields .= "
        </tbody>
      </table>" if $prefix;
    if ($name eq 'netscan' && $device->{ip} && $device->{ip_range} && $ip_range{$device->{ip_range}}) {
      if ($tasks{$device->{ip}} && $tasks{$device->{ip}}->{percent}<100) {
        my $task = $tasks{$device->{ip}}->{name};
        $OUT .= "
    <a href='$url_path/inventory' class='see-link'>".sprintf(_("See %s task"),$task.": ".$device->{ip}."/".encode('UTF-8', encode_entities($device->{ip_range})))."</a>";
      } elsif (!$device->isLocalInventory()) {
        $OUT .= "
    <input class='submit-secondary' type='submit' name='submit/scan' value='".(_"Scan this device")."'/>";
      }
    }
  }
  if ($select_fields) {
    $OUT .= "
    <div id='fields-overlay' class='overlay' onclick='cancel_select()'>
      <div class='overlay-frame fields-frame' onclick='event.stopPropagation()'>"
      .$select_fields."
        <hr/>
        <input type='button' class='big-button' onclick='toggle_all()' value='".(_"Reverse selection")."'/>
        <input type='submit' class='big-button' name='submit/select-fields' value='".(_"Save the selection")."'/>
        <input type='button' class='big-button' onclick='cancel_select()' value='".(_"Cancel")."'/>
      </div>
    </div>
    <script>
    var reset_cb = [];
    var all_cb = document.querySelectorAll('input[type=\"checkbox\"]');
    for ( var i = 0; i < all_cb.length; i++ )
      reset_cb[i] = all_cb[i].checked;
    function toggle_all() \{
      for ( var i = 0; i < all_cb.length; i++ )
        all_cb[i].checked = !all_cb[i].checked;
    \}
    function select_fields () \{
      document.getElementById('fields-overlay').style.display = 'block';
    \}
    function cancel_select () \{
      for ( var i = 0; i < all_cb.length; i++ )
        all_cb[i].checked = reset_cb[i];
      document.getElementById('fields-overlay').style.display = 'none';
    \}
    document.onkeydown = function(event) \{
      event = event || window.event;
      var isEscape = false;
      if ('key' in event) isEscape = (event.key === 'Escape' || event.key === 'Esc');
      else isEscape = (event.keyCode === 27);
      if (isEscape) document.getElementById('fields-overlay').style.display = 'none';
    \}
    </script>";
  }
  if (keys(%checked_fields)) {
    $OUT .= "
    <hr/>
    <div id='fields-propagation' class='fields-propagation'>
      <div id='left-propagation' class='big-nav'>";
    $OUT .= "
        <div class='big-arrow'>
          <a href='$url_path/$request?edit=$devices_order[$index-1]#fields-propagation' class='arrow'>&LeftArrow;</a>
        </div>
    " if $index > 0;
    $OUT .= "</div>
      <div class='selected-fields'>
        <p class='fields-propagation'>".($has_selected_fields ? _("Fields selected for propagation") : _("Fields can't be propagated on this device type"))."</p>
        <table class='fields'>
          <tbody>";
    my $count = $has_selected_fields;
    while ($count) {
      $OUT .= "
            <tr>";
      foreach my $col (@has_selected_fields) {
        my $field = shift @{$col};
        my ($fieldname, $text, $value) = ( "none", "", "");
        if (defined($field)) {
          ($fieldname, $text) = @{$field};
          $value = defined($checked_fields{$fieldname}) ? $value = encode('UTF-8', encode_entities($checked_fields{$fieldname})) : '';
          $count--;
        }
        $OUT .= "
              <td class='fields $name-section-field'>$text</td>
              <td class='values $name-section-value'>$value</td>";
      }
      $OUT .= "
            </tr>";
    }
    $OUT .= "
          </tbody>
        </table>
      </div>
      <div id='right-propagation' class='big-nav'>";
    $OUT .= "
        <div class='big-arrow'>
          <a href='$url_path/$request?edit=$devices_order[$index+1]#fields-propagation' class='arrow'>&RightArrow;</a>
        </div>
      " if $index < $#devices_order;
    $OUT .= "</div>
    </div>";
    if ($do eq 'edit' && $has_selected_fields) {
      $OUT .= "
    <div class='center'><input class='submit' type='submit' name='submit/set-selected-fields' value='".(_"Apply selected fields")."'/></div>";
    }
  }
  $OUT .= "
    <hr/>".($do eq 'edit' ? "
    <input class='submit' type='submit' name='submit/update' value='"._("Update")."'/>" : "")."
    <input class='submit' type='submit' name='submit/delete-device' value='"._("Delete")."'/>";
  if ($do eq 'edit') {
    if ($select_fields) {
      $OUT .= "
    <input class='submit' type='button' onclick='select_fields()' value='".(_"Select fields for propagation")."'/>";
    }
    if (keys(%checked_fields)) {
      $OUT .= "
    <input class='submit' type='submit' name='submit/stop-propagation' value='".(_"Stop fields propagation")."'/>";
    }
  }}
    <hr/>
    <div class='other-options'>
      <label class='checkbox'>
        <input class='checkbox' type='checkbox' name='next-on-deletion'{$next_on_deletion ? " checked" : ""}/>
        <span class='custom-checkbox'></span>
      </label>
      <input type='hidden' name='next-edit' value='{$index < $#devices_order ? $devices_order[$index+1] : ""}'/>
      <div class='other-option'>{_"Go to next device after deletion"}</div>
    </div>
  </form>{
  $need_datetime ? "
  <script src='$url_path/flatpickr.js'></script>
  <script>
    var dts =\{\};
    function opendatetime(id, time) \{
      var input = document.getElementById(id);
      var dt = dts[id];
      if (!dt) \{
        dt = flatpickr(input, \{
          'allowInput': true,
          'enableTime': time,
          'time_24hr': true,
          'defaultHour': new Date().getHours(),
          'defaultMinute': new Date().getMinutes(),
        \});
        dts[id] = dt;
      \}
      if (input.value) dt.setDate(input.value);
      dt.open();
    \}
  </script>" : ""
}
