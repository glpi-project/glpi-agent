#!/usr/bin/perl

use strict;
use warnings;

use lib 'contrib/unix/installer';

use Test::More;
use RpmDistro;

my @commands;
my @extracted;

{
    no warnings 'redefine';
    local *RpmDistro::_extract_rpm = sub {
        my $package = $_[1];
        push @extracted, $package;
        return "$package.rpm";
    };
    local *RpmDistro::_prepareDistro = sub { $_[0]->{_dnf} = 1; };
    local *LinuxDistro::install = sub { return; };
    local *LinuxDistro::getDeps = sub { return; };
    local *LinuxDistro::verbose = sub { return; };
    local *LinuxDistro::system = sub {
        push @commands, $_[1];
        $? = 0;
        return 0;
    };

    foreach my $signed (0, 1) {
        my $distro = bless {
            _options => { 'deploy-public-key' => $signed ? ('a' x 64) : '' },
            _skip => { dmidecode => 1 },
            _type => 'inventory,deploy,collect',
            _name => 'Fedora',
            _version => 'test',
            _release => 'Fedora test',
        }, 'RpmDistro';
        $distro->install();
    }
}

unlike($commands[0], qr/Crypt::PK::Ed25519/, 'Unsigned installation does not require crypto');
like($commands[1], qr/'perl\(Crypt::PK::Ed25519\)'/, 'Signed installation requests the quoted repository capability');
ok(!grep(/Crypt::PK::Ed25519/, @extracted), 'Crypto dependency is not extracted as an embedded agent RPM');
is(scalar(@commands), 2, 'Both installations execute the package manager');

done_testing();
