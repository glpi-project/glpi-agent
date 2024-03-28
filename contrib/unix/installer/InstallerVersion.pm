package
    InstallerVersion;

# Support glpi-agent-linux-installer.pl run from sources for testing
use lib qw(./lib ../../lib);

use GLPI::Agent::Version;
use constant DISTRO  => "linux";

sub VERSION {
    return $GLPI::Agent::Version::VERSION;
}

1;
