package GLPI::Agent::Task::Inventory::Generic::SSH;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;

use constant    category    => "os";

sub isEnabled {
    return canRun('ssh-keyscan');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $port;
    my $command = "ssh-keyscan";
    if (canRead('/etc/ssh/sshd_config')) {
        foreach my $line (getAllLines( file => '/etc/ssh/sshd_config' )) {
            next unless $line =~ /^Port\s+(\d+)/;
            $port = $1;
        }
    }
    $command .= " -p $port" if $port;

    # Use a 1 second timeout instead of default 5 seconds as this is still
    # large enough for loopback ssh pubkey scan.
    $command .= ' -T 1 127.0.0.1';
    my @ssh_keys = sort map { /^\S+\s(ssh.*)/ && $1 } grep { /^[^#]\S+\sssh/ } getAllLines(
        command => $command,
        @_,
    );

    $inventory->setOperatingSystem({
        SSH_KEY => $ssh_keys[0]
    }) if @ssh_keys;
}

1;
