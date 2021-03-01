{ @errors ? "
  <div id='errors'>
    <p>
      "._("ERROR")." ! ".join("<br/>\n"._("ERROR")." ! ", map {
          join(": ", map { _($_) } split(": ", $_))
        } @errors)."
    </p>
  </div>" : "" }
