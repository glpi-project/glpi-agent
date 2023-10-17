{ # This comment to keep a line feed at the beginning of this template inclusion }
    <div class='list-nav'>
      <div class='arrow'>{
        $display && $start ? "<a href='$url_path/$request?start=1' class='arrow'><i class='ti ti-chevron-left-pipe'></i></a>" : "";
      }</div>
      <div class='arrow'>{
        $newstart = $display && $page > 1 ? ($page-2)*$display+1 : 0;
        $OUT .= $display && $start ? "<a href='$url_path/$request?start=$newstart' class='arrow'><i class='ti ti-chevron-left'></i></a>" : "";
      }</div>
      <div class='list-count'>{
        $OUT .= $list_count ? sprintf(
            _("From %d to %d of %s"),
            $start+1,
            $display ? ($start+$display > $list_count ? $list_count : $start+$display) : $list_count,
            $list_count
        ) : "";
      }</div>
      <div class='arrow'>{
        $newstart = $pages > $page ? $page*$display+1 : 0;
        $display && $newstart ? "<a href='$url_path/$request?start=$newstart' class='arrow'><i class='ti ti-chevron-right'></i></a>" : "";
      }</div>
      <div class='arrow'>{
        $newstart = $pages > $page ? ($pages-1)*$display+1 : 0;
        $display && $newstart ? "<a href='$url_path/$request?start=$newstart' class='arrow'><i class='ti ti-chevron-right-pipe'></i></a>" : "";
      }</div>
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
