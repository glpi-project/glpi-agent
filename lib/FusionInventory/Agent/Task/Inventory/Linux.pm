package FusionInventory::Agent::Task::Inventory::Linux;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use XML::TreePP;


use FusionInventory::Agent::Tools;

our $runAfter = ["FusionInventory::Agent::Task::Inventory::Generic"];

sub isEnabled {
    return $OSNAME eq 'linux';
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $kernelVersion = getFirstLine(command => 'uname -v');
    my $kernelRelease = getFirstLine(command => 'uname -r');

    my $systemId  = _getRHNSystemId('/etc/sysconfig/rhn/systemid');
    my $hostid = getFirstLine(command => 'hostid');

    my $boottime =
        time - getFirstMatch(file => '/proc/uptime', pattern => qr/^(\S+)/);

    $inventory->setHardware({
        OSVERSION  => $kernelRelease,
        OSCOMMENTS => $kernelVersion,
        WINPRODID  => $systemId,
    });

    $inventory->setOperatingSystem({
        HOSTID         => $hostid,
        KERNEL_VERSION => $kernelRelease,
        BOOT_TIME      => getFormatedLocalTime($boottime)
    });

}

# Get RedHat Network SystemId
sub _getRHNSystemId {
    my ($file) = @_;

    return unless -f $file;
    my $tpp = XML::TreePP->new();
    my $h = $tpp->parsefile($file);
    eval {
        foreach (@{$h->{params}{param}{value}{struct}{member}}) {
            next unless $_->{name} eq 'system_id';
            return $_->{value}{string};
        }
    }
}

1;
