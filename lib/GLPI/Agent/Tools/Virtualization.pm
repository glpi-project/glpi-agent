package GLPI::Agent::Tools::Virtualization;

use strict;
use warnings;
use parent 'Exporter';

use UNIVERSAL::require;

use constant STATUS_RUNNING => 'running';
use constant STATUS_BLOCKED => 'blocked';
use constant STATUS_IDLE => 'idle';
use constant STATUS_PAUSED => 'paused';
use constant STATUS_SHUTDOWN => 'shutdown';
use constant STATUS_CRASHED => 'crashed';
use constant STATUS_DYING => 'dying';
use constant STATUS_OFF => 'off';

our @EXPORT = qw(
    STATUS_RUNNING  STATUS_BLOCKED STATUS_IDLE  STATUS_PAUSED
    STATUS_SHUTDOWN STATUS_CRASHED STATUS_DYING STATUS_OFF
    getVirtualUUID
);

sub getVirtualUUID {
    my $machineid = shift
        or return '';

    my $name = shift
        or return '';

    return '' unless Digest::SHA->use('sha1_hex');

    return sha1_hex($machineid . $name);
}

1;
