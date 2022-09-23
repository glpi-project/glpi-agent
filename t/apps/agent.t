#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use File::Temp;
use Test::More;

use GLPI::Agent::Tools;
use GLPI::Agent::XML;
use GLPI::Test::Utils;
use GLPI::Agent::Version;

my $PROVIDER = $GLPI::Agent::Version::PROVIDER;

plan tests => 36;

my ($content, $out, $err, $rc);

($out, $err, $rc) = run_executable('glpi-agent', '--help');
ok($rc == 0, '--help exit status');
is($err, '', '--help stderr');
like(
    $out,
    qr/^Usage:/,
    '--help stdout'
);

($out, $err, $rc) = run_executable('glpi-agent', '--version');
ok($rc == 0, '--version exit status');
is($err, '', '--version stderr');
like(
    $out,
    qr/^$PROVIDER/,
    '--version stdout'
);

($out, $err, $rc) = run_executable('glpi-agent', '--config none');
ok($rc == 1, 'no target exit status');
like(
    $err,
    qr/No target defined/,
    'no target stderr'
);
is($out, '', 'no target stdout');

($out, $err, $rc) = run_executable(
    'glpi-agent',
    '--config none --conf-file /foo/bar'
);
ok($rc == 1, 'incompatible options exit status');
like(
    $err,
    qr/don't use --conf-file/,
    'incompatible options stderr'
);
is($out, '', 'incompatible options stdout');

my $base_options = "--debug --no-task ocsdeploy,wakeonlan,snmpquery,netdiscovery --config none";

# Use a temporary vardir to not fail in development environment
my $vardir = File::Temp->newdir(CLEANUP => 1);
$base_options .= " --vardir $vardir";

# first inventory
($out, $err, $rc) = run_executable(
    'glpi-agent',
    "$base_options --local - --no-category printer"
);

subtest "first inventory execution and content" => sub {
    check_execution_ok($err, $rc);
    check_content_ok($out);
};

SKIP: {
    # On MacOSX, skip test as system_profiler may return no software in container, CircleCI case
    if ($OSNAME eq "darwin") {
        my @hasSoftwareOutput = getAllLines(
            command => "/usr/sbin/system_profiler SPApplicationsDataType"
        );
        skip "No installed software seen on this system", 1
            if @hasSoftwareOutput == 0;
    }
    ok(
        exists $content->{REQUEST}->{CONTENT}->{SOFTWARES},
        'inventory has software'
    );
}

ok(
    exists $content->{REQUEST}->{CONTENT}->{ENVS},
    'inventory has environment variables'
);

# second inventory, without software
($out, $err, $rc) = run_executable(
    'glpi-agent',
    "$base_options --local - --no-category printer,software"
);

subtest "second inventory execution and content" => sub {
    check_execution_ok($err, $rc);
    check_content_ok($out);
};

ok(
    !exists $content->{REQUEST}->{CONTENT}->{SOFTWARES},
    "output doesn't have any software"
);

ok(
    exists $content->{REQUEST}->{CONTENT}->{ENVS},
    'inventory has environment variables'
);

# third inventory, without software, but additional content

my $file = File::Temp->new(UNLINK => $ENV{TEST_DEBUG} ? 0 : 1, SUFFIX => '.xml');
print $file <<EOF;
<?xml version="1.0" encoding="UTF-8" ?>
<REQUEST>
  <CONTENT>
      <SOFTWARES>
          <NAME>foo</NAME>
          <VERSION>bar</VERSION>
      </SOFTWARES>
  </CONTENT>
</REQUEST>
EOF
close($file);

($out, $err, $rc) = run_executable(
    'glpi-agent',
    "$base_options --local - --no-category printer,software --additional-content $file"
);
subtest "third inventory execution and content" => sub {
    check_execution_ok($err, $rc);
    check_content_ok($out);
};

ok(
    exists $content->{REQUEST}->{CONTENT}->{SOFTWARES},
    'inventory has softwares'
);

ok(
    ref $content->{REQUEST}->{CONTENT}->{SOFTWARES} eq 'HASH',
    'inventory contains only one software'
);

ok(
    $content->{REQUEST}->{CONTENT}->{SOFTWARES}->{NAME} eq 'foo' &&
    $content->{REQUEST}->{CONTENT}->{SOFTWARES}->{VERSION} eq 'bar',
    'inventory contains the expected software'
);

ok(
    exists $content->{REQUEST}->{CONTENT}->{ENVS},
    'inventory has environment variables'
);

# PATH through WMI appears with %SystemRoot% templates, preventing direct
# comparaison with %ENV content, OS seems to be a more reliable test then
my $name = $OSNAME eq 'MSWin32' ? 'OS' : 'PATH';
my $value = $ENV{$name};

($out, $err, $rc) = run_executable(
    'glpi-agent',
    "$base_options --local - --no-category printer,software"
);

subtest "fourth inventory execution and content" => sub {
    check_execution_ok($err, $rc);
    check_content_ok($out);
};

ok(
    !exists $content->{REQUEST}->{CONTENT}->{SOFTWARES},
    "inventory doesn't have any software"
);

ok(
    exists $content->{REQUEST}->{CONTENT}->{ENVS},
    'inventory has environment variables'
);

ok(
    (any
        { $_->{KEY} eq $name && $_->{VAL} eq $value }
        @{$content->{REQUEST}->{CONTENT}->{ENVS}}
    ),
    'inventory has expected environment variable value'
);

($out, $err, $rc) = run_executable(
    'glpi-agent',
    "$base_options --local - --no-category printer,software,environment"
);

subtest "fifth inventory execution and content" => sub {
    check_execution_ok($err, $rc);
    check_content_ok($out);
};

ok(
    !exists $content->{REQUEST}->{CONTENT}->{SOFTWARES},
    "inventory doesn't have any software"
);

ok(
    !exists $content->{REQUEST}->{CONTENT}->{ENVS},
    "inventory doesn't have any environment variables"
);

# output location tests
my $dir = File::Temp->newdir(CLEANUP => 1);
($out, $err, $rc) = run_executable(
    'glpi-agent',
    "$base_options --local $dir"
);
subtest "--local <directory> inventory execution" => sub {
    check_execution_ok($err, $rc);
};
ok(<$dir/*.xml>, '--local <directory> result file presence');

($out, $err, $rc) = run_executable(
    'glpi-agent', "$base_options --local $dir/foo"
);
subtest "--local <file> inventory execution" => sub {
    check_execution_ok($err, $rc);
};
ok(-f "$dir/foo", '--local <file> result file presence');

# consecutive lazy inventory with fake server target, no inventory and no failure
($out, $err, $rc) = run_executable(
    'glpi-agent',
    "$base_options --lazy --server=http://localhost/plugins/fusioninventory"
);

subtest "second inventory execution and content" => sub {
    check_execution_ok($err, $rc);
};

($out, $err, $rc) = run_executable(
    'glpi-agent',
    "$base_options --lazy --server=http://localhost/plugins/fusioninventory"
);

subtest "second inventory execution and content" => sub {
    check_execution_ok($err, $rc);
};

sub check_execution_ok {
    my ($err, $rc) = @_;

    ok($rc == 0, 'exit status');

    unlike(
        $err,
        qr/module \S+ disabled: failure to load/,
        'no broken module (loading)'
    );

    unlike(
        $err,
        qr/unexpected error in \S+/,
        'no broken module (execution)'
    );

    unlike(
        $err,
        qr/Use of uninitialized value/,
        'no failure on uninitialized value'
    );
}

sub check_content_ok {
    my ($out) = @_;

    like(
        $out,
        qr/^<\?xml version="1.0" encoding="UTF-8"\s*\?>/,
        'output has correct encoding'
    );

    $content = GLPI::Agent::XML->new(string => $out)->dump_as_hash();
    ok($content, 'output is valid XML');
}
