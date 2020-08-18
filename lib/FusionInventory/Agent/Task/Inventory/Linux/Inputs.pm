package FusionInventory::Agent::Task::Inventory::Linux::Inputs;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;

use constant    category    => "input";

sub isEnabled {
    return has_file('/proc/bus/input/devices');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $handle = getFileHandle(
        file => '/proc/bus/input/devices',
        logger => $logger
    );
    return unless $handle;

    my @inputs;
    my $device;
    my $in;

    while (my $line = <$handle>) {
        if ($line =~ /^I: Bus=.*Vendor=(.*) Prod/) {
            $in = 1;
            $device->{vendor}=$1;
        } elsif ($line =~ /^$/) {
            $in = 0;
            if ($device->{phys} && $device->{phys} =~ "input") {
                push @inputs, {
                    DESCRIPTION => $device->{name},
                    CAPTION     => $device->{name},
                    TYPE        => $device->{type},
                };
            }

            $device = {};
        } elsif ($in) {
            if ($line =~ /^P: Phys=.*(button).*/i) {
                $device->{phys}="nodev";
            } elsif ($line =~ /^P: Phys=.*(input).*/i) {
                $device->{phys}="input";
            }
            if ($line =~ /^N: Name=\"(.*)\"/i) {
                $device->{name}=$1;
            }
            if ($line =~ /^H: Handlers=(\w+)/i) {
                if ($1 =~ ".*kbd.*") {
                    $device->{type}="Keyboard";
                } elsif ($1 =~ ".*mouse.*") {
                    $device->{type}="Pointing";
                } else {
                    # Keyboard ou Pointing
                    $device->{type}=$1;
                }
            }
        }
    }
    close $handle;

    foreach my $input (@inputs) {
        $inventory->addEntry(
            section => 'INPUTS',
            entry   => $input
        );
    }
}

1;
