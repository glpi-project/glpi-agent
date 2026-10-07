package GLPI::Agent::Task::Inventory::Generic::SSH;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools;

use constant    category    => "os";

sub isEnabled {
    return canRun('ssh-keyscan');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $port;
    my $command = [ "ssh-keyscan" ];
    my $sshd_config = OSNAME eq 'MSWin32' ? "$ENV{ProgramData}\\ssh\\sshd_config" : "/etc/ssh/sshd_config";
    $sshd_config =~ s{\\}{/}g if OSNAME eq 'MSWin32';
    if (canRead($sshd_config)) {
        foreach my $line (getAllLines( file => $sshd_config )) {
            next unless $line =~ /^Port\s+(\d+)/;
            $port = $1;
        }
    }
    push @{$command}, "-p", $port if $port;

    my @ssh_keys;

    # Get signing algorithm supported list
    my @sig_algo = getAllLines(
        command => [ qw(ssh -Q sig) ],
        @_
    );

    # Get first found ssh pub key with supported signing algorithms
    foreach my $algo (@sig_algo) {
        my @lines = grep { /\S+/ } getAllLines(
            command => [ @{$command}, "-t", $algo, "-T", 1, "127.0.0.1" ],
            @_,
        );
        # No output means no sshd server responded as not installed or active
        return unless @lines;
        @ssh_keys = sort map { /^\S+\s(ssh.*)/ && $1 } grep { /^[^#]\S+\sssh/ } @lines
            and last;
    }

    # Fallback on old algorithm in the case new one doesn't find a key
    unless (@ssh_keys) {
        # Use a 1 second timeout instead of default 5 seconds as this is still
        # large enough for loopback ssh pubkey scan.
        push @{$command}, "-T", 1, "127.0.0.1";
        @ssh_keys = sort map { /^\S+\s(ssh.*)/ && $1 } grep { /^[^#]\S+\sssh/ } getAllLines(
            command => $command,
            @_,
        );
    }

    $inventory->setOperatingSystem({
        SSH_KEY => $ssh_keys[0]
    }) if @ssh_keys;
}

1;
