{
  my %text = ();

  if ($default_lang && $default_lang ne 'en') {
    _parse("$template_path/common-language-$default_lang.txt");
    _parse("$template_path/infos-language-$default_lang.txt") if @infos;
    _parse("$template_path/errors-language-$default_lang.txt") if @errors;
    _parse("$template_path/$request-language-$default_lang.txt");
  }

  if ($lang && $lang ne $default_lang) {
    _parse("$template_path/common-language-$lang.txt");
    _parse("$template_path/infos-language-$lang.txt") if @infos;
    _parse("$template_path/errors-language-$lang.txt") if @errors;
    _parse("$template_path/$request-language-$lang.txt");
  }

  sub _parse {
    return unless -e $_[0];
    open LANG, "<", $_[0] or return;
    while (<LANG>) {
      chomp;
      next unless $_;
      next if m|^\s*[#;/-]|;
      my ($text, $trad) = split(/\s*:\s*/, $_)
        or next;
      $text{$text} = $trad;
    }
    close(LANG);
  }

  sub _ {
    my $text = $text{$_[0]} || $_[0];
    # Always protect apostroph to not break any javascript code
    $text =~ s/[']/&#39;/g,
    return $text;
  }
}
