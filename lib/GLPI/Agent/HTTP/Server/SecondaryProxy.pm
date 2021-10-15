package GLPI::Agent::HTTP::Server::SecondaryProxy;

use strict;
use warnings;

use English qw(-no_match_vars);

use base "GLPI::Agent::HTTP::Server::Proxy";

use GLPI::Agent::Tools;
use GLPI::Agent::HTTP::Client::OCS;

our $VERSION = "1.1";

sub log_prefix {
    return "[proxy2 server plugin] ";
}

sub config_file {
    return "proxy2-server-plugin.cfg";
}

1;
__END__

=head1 NAME

GLPI::Agent::HTTP::Server::SecondaryProxy - An embedded HTTP server
plugin providing a secondary proxy for agents not able to contact the server.

Useful if you need to open a proxy on 2 different ports and even one with SSL
support.

=head1 DESCRIPTION

This is a server plugin to pass inventory toward a server.

It listens on port 62354 by default.

The following default requests are accepted:

=over

=item /proxy/glpi

=item /proxy/apiversion

=back

=head1 CONFIGURATION

=over

=item disabled         C<yes> by default

=item url_path         C</proxy> by default

=item port             C<0> by default to use default one

=item prolog_freq      C<24> by default, this is the delay agents will finally
                       recontact the proxy

=item local_store      empty by default,this is the folder where to store inventories

=item only_local_store C<no> by default, set it to C<yes> to not submit inventories
                       to server.

=item maxrate          C<30> by default

=item maxrate_period   C<3600> (in seconds) by default.

=back

Defaults can be overrided in C<proxy2-server-plugin.cfg> file or better in the
C<proxy2-server-plugin.local> if included from C<proxy2-server-plugin.cfg>.
