  <div id="header"{ $headercolor ? ' style="background-color: '.$headercolor.';"' : ''}>
    <div id="logo" style='background: url("{$url_path}/logo.png") 0 0 no-repeat;'>
      <a href="{$url_path}/" title="{_"Home"}"></a>
    </div>
    <div id="pagetitle"><b>{_($title)}</b></div>
    <div id="configmenu">
      <a href="{$url_path}/configuration" title="{_"Configuration"}" style='background: url("{$url_path}/config.png") 0 0 no-repeat;'></a>
    </div>
  </div>
