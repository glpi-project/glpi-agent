#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use English qw(-no_match_vars);
use Test::Deep qw(cmp_deeply);
use Test::Exception;
use Test::More;
use Test::NoWarnings;
use Test::MockModule;

use GLPI::Test::Utils;
use GLPI::Agent::Tools;
use GLPI::Agent::Tools::USB;
use GLPI::Agent::Tools::USB::Gertec;

BEGIN {
    # use mock modules for non-available ones
    push @INC, 't/lib/fake/windows' if $OSNAME ne 'MSWin32';
}

our $OSNAME;
my $RealOSNAME = $OSNAME;

my %tests = (
    "00-template" => {
        setup   => sub {},  # Can be used to fake environment
        config  => {},      # hash to configure device
        code    => sub {
            my ($dev) = shift;
            # Do something on device
        },
        dump    => {},      # Expected dump result
        reset   => sub {},  # Should be used to revert setup call
    },
    "01-empty-new" => {
        dump    => {},
    },
    "02-vendorid-getter-is-always-defined" => {
        config  => {},
        code    => sub {
            my ($dev) = shift;
            defined($dev->vendorid) or die "not defined vendorid\n";
            $dev->vendorid eq '' or die "not empty vendorid\n";
        },
        dump    => {},
    },
    "02-vendorid-getter" => {
        config  => { qw{ vendorid 0000 } },
        code    => sub {
            my ($dev) = shift;
            $dev->vendorid eq '0000' or die "missing vendorid\n";
        },
        dump    => { VENDORID => "0000" },
    },
    "02-productid-getter-is-always-defined" => {
        config  => {},
        code    => sub {
            my ($dev) = shift;
            defined($dev->productid) or die "not defined productid\n";
            $dev->productid eq '' or die "not empty productid\n";
        },
        dump    => {},
    },
    "03-productid-getter" => {
        config  => { qw{ productid 0000 } },
        code    => sub {
            my ($dev) = shift;
            $dev->productid eq '0000' or die "missing productid\n";
        },
        dump    => { PRODUCTID => "0000" },
    },
    "04-serial-getter-is-always-defined" => {
        config  => {},
        code    => sub {
            my ($dev) = shift;
            defined($dev->serial) or die "not defined serial\n";
            $dev->serial eq '' or die "not empty serial\n";
        },
        dump    => {},
    },
    "04-serial-getter" => {
        config  => { qw{ serial 0000 } },
        code    => sub {
            my ($dev) = shift;
            $dev->serial eq '0000' or die "missing serial\n";
        },
        dump    => { SERIAL => "0000" },
    },
    "04-serial-setter" => {
        config  => { qw{ serial 0000 } },
        code    => sub {
            my ($dev) = shift;
            $dev->serial('1111');
        },
        dump    => { SERIAL => "1111" },
    },
    "04-serial-unset" => {
        config  => { qw{ serial 0000 } },
        code    => sub {
            my ($dev) = shift;
            length($dev->serial('')) == 0 or die "unset must return empty set string\n";
        },
        dump    => {},
    },
    "04-serial-delete" => {
        config  => { qw{ serial 0000 } },
        code    => sub {
            my ($dev) = shift;
            $dev->delete_serial() eq '0000' or die "delete must return deleted serial\n";
        },
        dump    => {},
    },
    "05-default-enabled" => {
        config  => {},
        code    => sub {
            my ($dev) = shift;
            $dev->enabled() or die "default enabled must be true\n";
        },
        dump    => {},
    },
    "06-default-supported" => {
        config  => {},
        code    => sub {
            my ($dev) = shift;
            $dev->supported() and die "default supported must be false\n";
        },
        dump    => {},
    },
    "07-default-update" => {
        config  => {},
        code    => sub {
            my ($dev) = shift;
            $dev->update() and die "default update does nothing\n";
        },
        dump    => {},
    },
    "08-default-skip" => {
        config  => {},
        code    => sub {
            my ($dev) = shift;
            $dev->skip() or die "default skip must be true\n";
        },
        dump    => {},
    },
    "08-skip-on-invalib-vendorid" => {
        config  => { qw{ vendorid 0000 } },
        code    => sub {
            my ($dev) = shift;
            $dev->skip() or die "skip on invalib vendorid must be true\n";
        },
        dump    => { VENDORID => "0000" },
    },
    "08-skip-on-invalib-vendorid" => {
        config  => { vendorid => "" },
        code    => sub {
            my ($dev) = shift;
            $dev->skip() or die "skip on invalib vendorid must be true\n";
        },
        dump    => {},
    },
    "10-normal-dump" => {
        config  => { qw{ vendorid 045e productid 0009 caption mouse name generic-mouse serial 1234XYZ } },
        dump    => {
            VENDORID    => "045e",
            PRODUCTID   => "0009",
            CAPTION     => "mouse",
            NAME        => "generic-mouse",
            SERIAL      => "1234XYZ"
        },
    },
    "11-dump-after-updated-by-ids" => {
        config  => { qw{ vendorid 045e productid 0009 caption mouse name generic-mouse serial 1234XYZ } },
        code    => sub {
            my ($dev) = shift;
            $dev->update_by_ids();
        },
        dump    => {
            MANUFACTURER    => "Microsoft Corp.",
            VENDORID        => "045e",
            PRODUCTID       => "0009",
            CAPTION         => "IntelliMouse",
            NAME            => "IntelliMouse",
            SERIAL          => "1234XYZ"
        },
    },
    # Test GLPI::Agent::Tools::USB::Gertec module
    # This test can fail on usb.ids update. Update name & caption in expected test dump if they are changed by update_by_ids() method.
    "20-gertec-on-mswin32" => {
        setup   => sub {
            return if $OSNAME eq "MSWin32";
            # Pretend we are in MSWin32 environment
            $OSNAME = "MSWin32";
        },
        config  => {
            vendorid    => '1753',
            productid   => 'C902',
            name        => 'PPC 920-930 Enumerator Device',
            caption     => 'PPC 920-930 Enumerator Device',
        },
        code    => sub {
            my ($dev) = shift;
            ref($dev) eq 'GLPI::Agent::Tools::USB::Gertec'
                or die "Wrong device class\n";
            $dev->update_by_ids();
            $dev->update();
        },
        dump    => {
            MANUFACTURER    => "GERTEC Telecomunicacoes Ltda.",
            VENDORID        => "1753",
            PRODUCTID       => "C902",
            CAPTION         => "PPC 920-930 Enumerator Device",
            NAME            => "PPC 920-930 Enumerator Device",
            #~ SERIAL          => "TODO"
        },
        reset   => sub {
            $OSNAME = $RealOSNAME;
        },
    },
);

plan tests => 3 * (scalar keys %tests) + 1;

foreach my $test (sort keys %tests) {

    my $setup;
    $setup = &{$tests{$test}->{setup}}()
        if $tests{$test}->{setup};

    # Include reload in object parameters while test index >= 20
    my ($testindex) = $test =~ /^(\d+)-/;
    $testindex = int($testindex) >= 20 if $testindex;
    my @opts = $testindex ? (reload => 1) : ();
    push @opts, %{$tests{$test}->{config}} if $tests{$test}->{config};

    # Create object
    my $device;
    lives_ok {
        $device = GLPI::Agent::Tools::USB->new(@opts);
    } "$test: instantiation";

    lives_ok {
        &{$tests{$test}->{code} // sub {}}($device);
    } "$test: test code on device";

    my $dump = $device->dump();
    cmp_deeply(
        $dump,
        $tests{$test}->{dump},
        "$test: device dump check"
    );

    &{$tests{$test}->{reset}}($setup)
        if $setup && $tests{$test}->{reset};
}
