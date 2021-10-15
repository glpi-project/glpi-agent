#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);
use Data::Dumper;
use File::Temp qw(tempdir);
use UNIVERSAL::require;

use Test::Deep;
use Test::Exception;
use Test::More;

use GLPI::Agent::Logger;
use GLPI::Agent::Config;
use GLPI::Agent::Inventory;
use GLPI::Agent::Task::Inventory::Linux::Storages;

# Tests need symlink function
plan(skip_all => 'symlink function not implemented on win32')
     if ($OSNAME eq 'MSWin32');

Test::NoWarnings->use();

# This test file can also be used to dump a resource file for inclusion
my $dump = shift @ARGV;
if ($dump && $dump eq "--dump") {
    my $resource_name = shift @ARGV;
    die "No resource filename provided\n" unless $resource_name;
    die "Run me from project sources\n" unless -d "resources";
    my $dump_file = "resources/linux/storages/$resource_name.dump";
    if (-f $dump_file) {
        print STDERR "Dump file still exists, overwriting it: $dump_file\n";
    }

    my $logger = GLPI::Agent::Logger->new(
        config => GLPI::Agent::Config->new(
            options => {
                config => 'none',
                debug  => 2,
                logger => 'Stderr'
            }
        )
    );

    my $inventory = GLPI::Agent::Inventory->new(
        logger  => $logger
    );
    my $system_datas = {};
    GLPI::Agent::Task::Inventory::Linux::Storages::doInventory(
        inventory   => $inventory,
        logger      => $logger,
        dump        => $system_datas
    );

    $Data::Dumper::Sortkeys = 1;
    $Data::Dumper::Indent   = 1;
    my $sorted = [ sort { $a->{NAME} cmp $b->{NAME} } @{$inventory->{content}->{STORAGES}} ];
    my $dumper = Data::Dumper->new(
        [$system_datas, $sorted],
        [qw(SYSTEM STORAGE)]
    );
    open DUMP, ">", $dump_file
        or die "Can't write to $dump_file: $!";
    print DUMP $dumper->Dump();
    my $user = $ENV{USERNAME} || $ENV{USER} || qx/whoami/;
    print DUMP "\n# Dump date: ".localtime(),"\n# Dump system: ",qx/uname -a/,
        "# Dumped by: $user\n";
    close(DUMP);
}

my $inventory = GLPI::Agent::Inventory->new();
my $logger = GLPI::Agent::Logger->new(
    config => GLPI::Agent::Config->new(
        options => {
            config => 'none',
            logger => 'Test'
        }
    )
);

my @dump_filenames = glob "resources/linux/storages/*.dump";

plan tests => scalar(@dump_filenames) + 1;

my ($SYSTEM, $STORAGE);

foreach my $dump_file (@dump_filenames) {
    open DUMP, "<", $dump_file
        or die "Can't read from $dump_file: $!\n";
    my $dump = join('',<DUMP>);
    close(DUMP);
    eval $dump;
    my $root = tempdir(CLEANUP => 1);
    _build_root($root, $SYSTEM);

    # Be sure to keep a clean inventory
    delete $inventory->{content};

    GLPI::Agent::Task::Inventory::Linux::Storages::doInventory(
        inventory   => $inventory,
        logger      => $logger,
        test_path   => $root
    );
    my $sorted = [ sort { $a->{NAME} cmp $b->{NAME} } @{$inventory->{content}->{STORAGES}} ];
    cmp_deeply(
        $sorted,
        $STORAGE,
        "storage: $dump_file"
    );
}

sub _build_root {
    my ($root, $fs) = @_;

    foreach my $key (keys(%{$fs})) {
        my $type = ref($fs->{$key});
        if ($type eq 'HASH') {
            mkdir $root."/".$key;
            _build_root( $root."/".$key, $fs->{$key} );
        } elsif ($type eq 'ARRAY') {
            if ($fs->{$key}->[0] eq 'link') {
                my $link = $fs->{$key}->[1];
                symlink $link, $root."/".$key;
            }
        } else {
            open FILE, ">", $root."/".$key
                or die "Can't write to $root/$key: $!\n";
            print FILE $fs->{$key} if defined($fs->{$key});
            close(FILE);
        }
    }
}
