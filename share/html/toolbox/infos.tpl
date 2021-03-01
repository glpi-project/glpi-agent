{ @infos ? "
  <div id='info'>
    <p>
      "._("INFO")." ! ".join("<br/>\n"._("INFO")." ! ", map {
          join(": ", map { _($_) } split(": ", $_))
        } @infos)."
    </p>
  </div>" : "" }
