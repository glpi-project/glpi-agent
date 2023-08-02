  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <div class='{$request}'>
      <input type='hidden' name='raw' value='{$raw_edition}'>
      <textarea id='raw' cols='100' rows='50' name='raw-yaml'{$raw_edition ? "" : " readonly"}>{$rawyaml}</textarea>{
      $raw_edition ? "
      <div class='yaml'>
        <button class='big-button' type='submit' name='update' value='1' alt='"._("Update")."'><i class='primary ti ti-device-floppy'></i>"._("Update")."</button>
      </div>" : "" }
    </div>
  </form>
