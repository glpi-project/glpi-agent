package FusionInventory::Agent::Task::Inventory::Virtualization::Parallels;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Virtualization;

sub isEnabled {
    return canRun('prlctl');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    if (!$params{scan_homedirs}) {
        $logger->warning(
            "'scan-homedirs' configuration parameter disabled, " .
            "ignoring parallels virtual machines in user directories"
        );
        return;
    }

    foreach my $user ( glob("/Users/*") ) {
        $user =~ s/.*\///; # Just keep the login
        next if $user =~ /Shared/i;
        next if $user =~ /^\./i; # skip hidden directory
        next if $user =~ /\ /;   # skip directory containing space
        next if $user =~ /'/;    # skip directory containing quote

        foreach my $machine (_parsePrlctlA(
                logger  => $logger,
                command => "su '$user' -c 'prlctl list -a'"
        )) {

            my $uuid = $machine->{UUID};
            # Avoid security risk. Should never appends
            $uuid =~ s/[^A-Za-z0-9\.\s_-]//g;


            ($machine->{MEMORY}, $machine->{VCPU}) =
                _parsePrlctlI(
                    logger  => $logger,
                    command => "su '$user' -c 'prlctl list -i $uuid'"
                );

            $inventory->addEntry(
                section => 'VIRTUALMACHINES', entry => $machine
            );
        }
    }
}

sub _parsePrlctlA {
    my $handle = getFileHandle(@_);

    return unless $handle;

    my %status_list = (
        'running'   => STATUS_RUNNING,
        'blocked'   => STATUS_BLOCKED,
        'paused'    => STATUS_PAUSED,
        'suspended' => STATUS_PAUSED,
        'crashed'   => STATUS_CRASHED,
        'dying'     => STATUS_DYING,
        'stopped'   => STATUS_OFF
    );


    # get headers line first
    my $line = <$handle>;

    my @machines;
    while (my $line = <$handle>) {
        chomp $line;
        my @info = split(/\s+/, $line, 4);
        my $uuid   = $info[0];
        my $status = $status_list{$info[1]};
        my $name   = $info[3];


        $uuid =~s/{(.*)}/$1/;

        # Avoid security risk. Should never appends
        next if $uuid =~ /(;\||&)/;

        push @machines, {
            NAME      => $name,
            UUID      => $uuid,
            STATUS    => $status,
            SUBSYSTEM => "Parallels",
            VMTYPE    => "Parallels",
        };
    }

    close $handle;

    return @machines;
}

sub _parsePrlctlI {
    my $handle = getFileHandle(@_);

    my ($mem, $cpus);
    while (my $line = <$handle>) {
        if ($line =~ m/^\s\smemory\s(.*)Mb/) {
            $mem = $1;
        }
        if ($line =~ m/^\s\scpu\s(\d{1,2})/) {
            $cpus = $1;
        }
    }

    close $handle;

    return ($mem, $cpus);
}

1;
