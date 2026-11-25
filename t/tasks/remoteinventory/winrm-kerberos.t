#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::MockModule;

use GLPI::Agent::Logger;
use GLPI::Agent::Task::RemoteInventory::Remote;

plan tests => 6;

my $logger = GLPI::Agent::Logger->new(
    logger  => [ 'Test' ],
    debug   => 2,
);

my $winrm_module = Test::MockModule->new('GLPI::Agent::Task::RemoteInventory::Remote::Winrm');
$winrm_module->mock(_resolveHostname => sub {
    my ($ip) = @_;
    return $ip eq '192.168.1.10' ? 'winhost.domain.tld' : undef;
});

sub _remote {
    my ($url) = @_;
    my $remote = GLPI::Agent::Task::RemoteInventory::Remote->new(
        url     => $url,
        logger  => $logger,
        config  => {},
    );
    $remote->prepare();
    return $remote;
}

subtest "basic authentication by default" => sub {
    plan tests => 6;
    my $remote = _remote("winrm://user:pass\@winhost.domain.tld");
    ok(!$remote->mode('kerberos'), "kerberos mode not enabled");
    my $wsman = $remote->{_winrm};
    is($wsman->{user}, "user", "user passed to wsman client");
    is($wsman->{password}, "pass", "password passed to wsman client");
    ok(!$wsman->{kerberos}, "kerberos not enabled in wsman client");
    is($wsman->{_noauth}, 0, "wsman authenticated");
    is($wsman->url(), "http://winhost.domain.tld:5985/wsman/", "wsman url");
};

subtest "kerberos mode" => sub {
    plan tests => 6;
    my $remote = _remote("winrm://winhost.domain.tld?mode=kerberos");
    ok($remote->mode('kerberos'), "kerberos mode enabled");
    ok(!$remote->mode('ssl'), "ssl mode not enabled");
    my $wsman = $remote->{_winrm};
    ok($wsman->{kerberos}, "kerberos enabled in wsman client");
    ok(!$wsman->{user} && !$wsman->{password}, "no basic credentials in wsman client");
    is($wsman->{_noauth}, 0, "wsman authenticated");
    is($wsman->url(), "http://winhost.domain.tld:5985/wsman/", "wsman url");
};

subtest "kerberos mode ignores url password" => sub {
    plan tests => 2;
    my $remote = _remote("winrm://user:pass\@winhost.domain.tld?mode=kerberos");
    my $wsman = $remote->{_winrm};
    ok($wsman->{kerberos}, "kerberos enabled in wsman client");
    ok(!$wsman->{password}, "password not passed to wsman client");
};

subtest "ssl and kerberos modes separated by underscore" => sub {
    plan tests => 3;
    my $remote = _remote("winrm://winhost.domain.tld?mode=ssl_kerberos");
    ok($remote->mode('kerberos'), "kerberos mode enabled");
    ok($remote->mode('ssl'), "ssl mode enabled");
    is($remote->{_winrm}->url(), "https://winhost.domain.tld:5986/wsman/", "wsman url");
};

subtest "ssl and kerberos modes separated by comma as stored by toolbox" => sub {
    plan tests => 2;
    my $remote = _remote("winrm://winhost.domain.tld?mode=ssl,kerberos");
    ok($remote->mode('kerberos'), "kerberos mode enabled");
    ok($remote->mode('ssl'), "ssl mode enabled");
};

subtest "kerberos mode with ip resolved as fqdn" => sub {
    plan tests => 3;
    my $remote = _remote("winrm://192.168.1.10?mode=kerberos");
    is($remote->host(), "winhost.domain.tld", "host resolved");
    is($remote->{_winrm}->url(), "http://winhost.domain.tld:5985/wsman/", "wsman url uses fqdn");

    $remote = _remote("winrm://192.168.1.11?mode=kerberos");
    is($remote->{_winrm}->url(), "http://192.168.1.11:5985/wsman/", "ip kept if not resolved");
};
