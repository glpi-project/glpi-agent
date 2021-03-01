    <div class='list-nav'>
      <div class='arrow'>{
        $display && $start ? "
        <a href='$url_path/$request?start=1' class='arrow'>&LeftArrowBar;</a>" : ""}
      </div>
      <div class='arrow'>{
        $newstart = $display && $page > 1 ? ($page-2)*$display+1 : 0;
        $OUT .= $display && $start ? "
        <a href='$url_path/$request?start=$newstart' class='arrow'>&LeftArrow;</a>" : "" }
      </div>
      <div class='list-count'>{
        $list_count ?
          _("From")." ".($start+1)." "._("to")." ".($display ?
            $start+$display > $list_count ? $list_count :
            $start+$display : $list_count)." "._("of")." ".$list_count
          : ""
        }</div>
      <div class='arrow'>{
        $newstart = $pages > $page ? $page*$display+1 : 0;
        $display && $newstart ? "
        <a href='$url_path/$request?start=$newstart' class='arrow'>&RightArrow;</a>" : "" }
      </div>
      <div class='arrow'>{
        $newstart = $pages > $page ? ($pages-1)*$display+1 : 0;
        $display && $newstart ? "
        <a href='$url_path/$request?start=$newstart' class='arrow'>&RightArrowBar;</a>" : "" }
      </div>
      <div class='display-option list-option'>
        {_"Display (number of items)"}
        <select class='display-option' onchange="document.getElementById('display').value = this.value; submit();">{
        foreach my $opt (@display_options) {
          $OUT .= "
          <option".($display && $display eq $opt ? " selected" : "").
              " value='$opt'>".($opt||_"no limit")."</option>";
        }}
        </select>
      </div>
    </div>
