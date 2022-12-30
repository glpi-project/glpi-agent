package GLPI::Agent::Task::Inventory::Generic::Domains;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Hostname;

use constant    category    => "hardware";

sub isEnabled {
    return canRead("/etc/resolv.conf");
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $infos;

    # first, parse /etc/resolv.conf for the DNS servers,
    # and the domain search list
    my %search_list;
    my @lines = getAllLines(
        file => '/etc/resolv.conf',
        logger => $logger
    );
    if (@lines) {
        my %dns_list;
        foreach my $line (@lines) {
            if (my ($dns) = $line =~ /^nameserver\s+(\S+)/) {
                $dns =~ s/\.+$//;
                $dns_list{$dns} = 1;
            } elsif (my ($domain) = $line =~ /^(?:domain|search)\s+(\S+)/) {
                $domain =~ s/\.$//;
                $search_list{$domain} = 1;
            }
        }
        $infos->{DNS} = join('/', sort keys %dns_list)
            if keys(%dns_list);
    }

    # attempt to deduce the actual domain from the host name
    # and fallback on the domain search list
    my $hostname = getHostname();
    my $pos = index $hostname, '.';

    if ($pos > 0) {
        $hostname =~ s/\.+$//;
        $infos->{WORKGROUP} = substr($hostname, $pos + 1) if $pos < length($hostname);
    }

    $infos->{WORKGROUP} = join('/', sort keys %search_list)
        if !$infos->{WORKGROUP} && keys(%search_list);

    $inventory->setHardware($infos) if $infos;
}

1;
