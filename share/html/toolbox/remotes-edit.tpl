  <h2>{
    use Encode qw(encode);
    use HTML::Entities;
    $remote = $remotes{$edit};
    $target = $form{"input/target"} || "";
    ($target) = $edit =~ /^(\w+)\// unless $target || !$edit;
    $deviceid = encode('UTF-8', encode_entities($remote ? $remote->{deviceid} : $edit));
    $this = encode('UTF-8', encode_entities($edit));
    $remote ? sprintf(_("Edit &laquo;&nbsp;%s&nbsp;&raquo; remote for %s"), $deviceid, $target)
      : _"Add new remote"}</h2>
  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <input type='hidden' name='edit' value='{$this}'/>{ $form{empty} ? "
    <input type='hidden' name='empty' value='1'/>" : "" }
    <div class='form-edit-row'>
      <div class='form-edit'>
        <label for='selection-option'>{_"Target"}</label>
        <select class='selection-option' name='input/target'>{
            join("", map { "
          <option".(($target && $target eq $_->[0])? " selected" : "").
            " value='$_->[0]'>$_->[0]: $_->[1]</option>"
          } @targets)}
        </select>
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
      <label for='url'>{_"Remote URL"}</label>
      <input class='input-row' type='text' id='url' name='input/url' value='{($remote && $remote->{url}) || $form{"input/url"} || ""}' size='60' required />
      </div>
    </div>
    <div class='form-edit-row'>
      <div class='form-edit'>
      <label for='deviceid'>{_"DeviceId"}</label>
      <input class='input-row' type='text' id='deviceid' name='input/deviceid' value='{($remote && $remote->{deviceid}) || $form{"input/deviceid"} || ""}' size='60'/>
      </div>
    </div>
    <button type='submit' class='big-button' name='submit/{ $remote ?
        "update-remote' value='1' alt='"._("Update")."'><i class='primary ti ti-device-floppy'></i>"._("Update") :
        "add-remote' value='1' alt='"._("Add")."'><i class='primary ti ti-plus'></i>"._("Add") }</button>
    <button type='submit' class='big-button secondary-button' name='submit/cancel' value='1' alt='{_("Cancel")}'><i class='primary ti ti-x'></i>{_("Cancel")}</button>
  </form>
