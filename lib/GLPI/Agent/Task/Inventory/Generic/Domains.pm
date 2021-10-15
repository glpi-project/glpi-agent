package GLPI::Agent::Task::Inventory::Generic::Domains;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use Sys::Hostname;

use GLPI::Agent::Tools;

use constant    category    => "hardware";

sub isEnabled {
    return has_file("/etc/resolv.conf");
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # first, parse /etc/resolv.conf for the DNS servers,
    # and the domain search list
    my %dns_list;
    my %search_list;
    my $handle = getFileHandle(
        file => '/etc/resolv.conf',
        logger => $logger
    );
    if ($handle) {
        while (my $line = <$handle>) {
            if (my ($dns) = $line =~ /^nameserver\s+(\S+)/) {
                $dns =~ s/\.+$//;
                $dns_list{$dns} = 1;
            } elsif (my ($domain) = $line =~ /^(?:domain|search)\s+(\S+)/) {
                $domain =~ s/\.$//;
                $search_list{$domain} = 1;
            }
        }
        close $handle;
    }

    my $dns = join('/', sort keys %dns_list);

    # attempt to deduce the actual domain from the host name
    # and fallback on the domain search list
    my $domain;
    my $hostname = hostname();
    my $pos = index $hostname, '.';

    if ($pos >= 0) {
        $domain = substr($hostname, $pos + 1);
        $domain =~ s/\.+$//;
    } else {
        $domain = join('/', sort keys %search_list);
    }

    $inventory->setHardware({
        WORKGROUP => $domain,
        DNS       => $dns
    });

}

1;
