  <form name='{$request}' method='post' action='{$url_path}/{$request}'>
    <input type='hidden' name='form' value='{$request}'/>
    <div class='{$request}'>
      <input type='hidden' name='raw' value='{$raw_edition}'>
      <textarea id='raw' cols='100' rows='50' name='raw-yaml'{$raw_edition ? "" : " readonly"}>{$rawyaml}</textarea>
      <input class='submit' type='{$raw_edition ? "submit" : "hidden"}' name='update' value='{_"Update"}'>
    </div>
  </form>
