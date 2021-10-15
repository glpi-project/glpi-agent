<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta content="text/html; charset=UTF-8" http-equiv="content-type" />
  <meta name='viewport' content='width=device-width, initial-scale=1'>
  <title>{
    Text::Template::fill_in_file($template_path."/language.tpl", HASH => $hash)
        || die "Error loading language.tpl template: $Text::Template::ERROR\n";
    _($title);
  }</title>
  <link rel="stylesheet" href="{$url_path}/toolbox.css" type="text/css" />{
    -e "$template_path/$request.css" ? "
  <link rel='stylesheet' href='$url_path/$request.css' type='text/css' />"
    : "" }{
    $request eq 'results' && $edit && $need_datetime ? "
  <link rel='stylesheet' href='$url_path/flatpickr.min.css' type='text/css' />"
    : "" }{
    -e "$template_path/custom.css" ? "
  <link rel='stylesheet' href='$url_path/custom.css' type='text/css' />"
    : "" }
  <link rel="shortcut icon" type="images/x-icon" href="{$url_path}/favicon.ico" >
</head>
<body>
  <!-- header -->
{
  Text::Template::fill_in_file($template_path."/header.tpl", HASH => $hash);
}{
  @infos ?
    Text::Template::fill_in_file($template_path."/infos.tpl", HASH => { infos => \@infos })
    : "";
}{
  @errors ?
    Text::Template::fill_in_file($template_path."/errors.tpl", HASH => { errors => \@errors })
    : "";
}  <!-- navbar -->
{
  Text::Template::fill_in_file($template_path."/navbar.tpl", HASH => $hash);
}  <div id="page">
  <!-- {$request} -->
{
    Text::Template::fill_in_file($template_path."/".$request.".tpl", HASH => $hash);
}  </div>
  <!-- footer -->
{
    Text::Template::fill_in_file($template_path."/footer.tpl", HASH => {
        agent   => _($GLPI::Agent::Version::PROVIDER." Agent").
            " v".$GLPI::Agent::Version::VERSION,
        url     => "https://github.com/glpi-project/glpi-agent",
        plugin  => _("ToolBox Plugin").
            " v".$GLPI::Agent::HTTP::Server::ToolBox::VERSION,
    })
}
