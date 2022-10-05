
BEGIN {
    # Avoid installation issue introduced by perl 5.24.1 removing '.' path from
    # @INC to avoid possible module injection in normal running perl scripts
    push @INC, '.' if ( $^V && $^V gt 'v5.24' );
}

use inc::Module::Install;
use English qw(-no_match_vars);
use lib::GLPI::Agent::Version;

name 'GLPI-Agent';
include 'Module::AutoInstall';
abstract 'GLPI unified Agent for UNIX, Linux, Windows and MacOSX';
license 'gpl';
repository 'https://github.com/glpi-project/glpi-agent';
version '1.5-dev';
perl_version '5.008';
authors 'Teclib Editions';

provides
    'GLPI::Agent' => {
        file    => 'lib/GLPI/Agent.pm',
        version => $GLPI::Agent::Version::VERSION
    };

# mandatory dependencies
requires 'File::Which'        => '0';
requires 'LWP::UserAgent'     => '5.8';
requires 'Net::IP'            => '0';
requires 'Text::Template'     => '0';
requires 'UNIVERSAL::require' => '0';
requires 'XML::LibXML'        => '0';
requires 'YAML::Tiny'         => '0';
requires 'Memoize'            => '0';
requires 'Time::HiRes'        => '0';
requires 'Digest::SHA'        => '0';
requires 'Cpanel::JSON::XS'   => '0';
requires 'Data::UUID'         => '0';
requires 'DateTime'           => '0';

if ($OSNAME eq 'MSWin32') {
    requires 'Win32::OLE'         => '0';
    requires 'Win32::Job'         => '0';
    requires 'Win32::TieRegistry' => '0';
}

recommends 'Compress::Zlib'       => '0';
recommends 'HTTP::Daemon'         => '0';
recommends 'IO::Socket::SSL'      => '1.14';
recommends 'LWP::Protocol::https' => '0';

if ($OSNAME ne 'MSWin32') {
    recommends 'Proc::Daemon'         => '0';
} else {
    recommends 'Win32::Daemon'        => '0';
    recommends 'Win32::Unicode::File' => '0';
}

# test dependencies
test_requires 'File::Copy::Recursive'        => '0';
test_requires 'HTTP::Proxy'                  => '0';
test_requires 'HTTP::Server::Simple'         => '0';
test_requires 'HTTP::Server::Simple::Authen' => '0';
test_requires 'IO::Socket::SSL'              => '0';
test_requires 'IO::Capture::Stderr'          => '0';
test_requires 'IPC::Run'                     => '0';
test_requires 'JSON::PP'                     => '0';
test_requires 'Net::SNMP'                    => '0';
test_requires 'LWP::Protocol::https'         => '0';
test_requires 'Parallel::ForkManager'        => '0';
test_requires 'Data::UUID'                   => '0';
test_requires 'Test::Compile'                => '0';
test_requires 'Test::Deep'                   => '0';
test_requires 'Test::Exception'              => '0';
test_requires 'Test::MockModule'             => '0';
test_requires 'Test::More'                   => '0.93'; # subtest
test_requires 'Test::NoWarnings'             => '0';
test_requires 'Test::MockObject'             => '0';

# Inventory
recommends 'Net::CUPS'                       => 0.60 if $OSNAME ne 'MSWin32';
recommends 'Parse::EDID'                     => '0';

# Remote Inventory
recommends 'Net::SSH2'                       => '0';

# Deploy
recommends 'Archive::Extract'             => '0';
recommends 'File::Copy::Recursive'        => '0';
recommends 'JSON::PP'                     => '0';
recommends 'Net::Ping'                    => '0';
recommends 'Parallel::ForkManager'        => '0';
recommends 'URI::Escape'                  => '0';

# Network
recommends 'Net::NBName' => '0';
recommends 'Net::SNMP'   => '0';
recommends 'Thread::Queue' => '2.01';

# Wake-On-LAN
recommends 'Net::Write::Layer2' => '0';

install_script 'bin/glpi-agent';
install_script 'bin/glpi-win32-service' if $OSNAME eq 'MSWin32';
install_script 'bin/glpi-injector';
install_script 'bin/glpi-inventory';
install_script 'bin/glpi-wakeonlan';
install_script 'bin/glpi-netdiscovery';
install_script 'bin/glpi-netinventory';
install_script 'bin/glpi-esx';
install_script 'bin/glpi-remote';

resources
    homepage    => "http://glpi-project.org/",
    bugtracker  => "https://github.com/glpi-project/glpi-agent/issues",
    repository  => "https://github.com/glpi-project/glpi-agent/",
    IRC         => "irc://irc.freenode.net/#glpi";

makemaker_args(
    test => {
        TESTS => join ' ', map { glob } qw(
            t/*.t
            t/*/*.t
            t/*/*/*.t
            t/*/*/*/*.t
            t/*/*/*/*/*.t
            t/*/*/*/*/*/*.t
        )
    },
    INSTALLMAN3DIR => 'none'
);

WriteAll;

# substitute prefix everywhere
$MY::variables{SYSCONFDIR} =~ s/\$\(PREFIX\)/$MY::variables{PREFIX}/;
$MY::variables{DATADIR} =~ s/\$\(PREFIX\)/$MY::variables{PREFIX}/;
$MY::variables{LOCALSTATEDIR} =~ s/\$\(PREFIX\)/$MY::variables{PREFIX}/;

# look for already existing configuration file
my $config_file_message = -f "$MY::variables{SYSCONFDIR}/agent.cfg" ?
    "previous configuration file found, new one will be installed as agent.cfg.new" :
    "no previous configuration file found, new one will be installed as agent.cfg";

print <<EOF;

Installation summary
--------------------
version : '$MY::variables{VERSION}'
comments: '$MY::variables{COMMENTS}'
prefix  : '$MY::variables{PREFIX}'
configuration installation directory: '$MY::variables{SYSCONFDIR}'
constant data installation directory: '$MY::variables{DATADIR}'
variable data installation directory: '$MY::variables{LOCALSTATEDIR}'

$config_file_message
EOF

package MY;

use Config;
use English qw(-no_match_vars);

our %variables;

# force a perl-independant prefix for everything
sub constants {
    my $self = shift;

    # for some reason, initialising variables from the global scope doesn't work
    %variables = (
        PREFIX               => '/usr/local',
        VERSION              => '',
        COMMENTS             => "Platform  : $Config{myuname},Build date: ".gmtime()." (GMT)",
        RAWCOMMENTS          => '',
        INSTALLSCRIPT        => '$(PREFIX)/bin',
        INSTALLSITESCRIPT    => '$(PREFIX)/bin',
        INSTALLVENDORSCRIPT  => '$(PREFIX)/bin',
        INSTALLLIB           => '$(DATADIR)/lib',
        INSTALLSITELIB       => '$(DATADIR)/lib',
        INSTALLVENDORLIB     => '$(DATADIR)/lib',
        INSTALLMAN1DIR       => '$(PREFIX)/share/man/man1',
        INSTALLSITEMAN1DIR   => '$(PREFIX)/share/man/man1',
        INSTALLVENDORMAN1DIR => '$(PREFIX)/share/man/man1',
        INSTALLMAN3DIR       => '$(PREFIX)/share/man/man3',
        INSTALLSITEMAN3DIR   => '$(PREFIX)/share/man/man3',
        INSTALLVENDORMAN3DIR => '$(PREFIX)/share/man/man3',
        SYSCONFDIR           => '$(PREFIX)/etc/glpi-agent',
        DATADIR              => '$(PREFIX)/share/glpi-agent',
        LOCALSTATEDIR        => '$(PREFIX)/var/glpi-agent',
        SNAPDIR              => '',
    );

    # allow variables defined on command line to override defaults
    foreach my $name (keys %variables) {
        $variables{$name} = $self->{ARGS}->{$name} if $self->{ARGS}->{$name};
    }

    # get all standard MM variables definitions, and override them if needed
    my @code = split(/\n/, $self->SUPER::constants(@_));
    foreach my $line (@code) {
        # Skip comments
        next if $line =~ /^\s*#/;
        # Skip everything which isn't a var assignment.
        next unless $line =~ /^([A-Z0-9_]+) =/;
        my $name = $1;
        if ($name eq 'VERSION' && ! $variables{VERSION}) {
            ( $variables{VERSION} ) = /=\s*(\S+)\s*$/;
        }
        # skip variables we're not interested
        next unless $variables{$name};

        $line = "$name = $variables{$name}";
    }

    # Fix COMMENTS and prepare it as a list of perl strings
    if ($variables{COMMENTS}) {
        $variables{COMMENTS} =~ s/[^a-zA-Z0-9 ,.:_-]//g;
        $variables{RAWCOMMENTS} = "\\n    "
            . join(",\\n    ",map { "\\\"$_\\\"" } split(/,/,$variables{COMMENTS}))
            . "\\n";
    }

    # add out own variables
    foreach my $name (qw/SYSCONFDIR DATADIR LOCALSTATEDIR COMMENTS RAWCOMMENTS/) {
        push @code, "$name = $variables{$name}";
    }

    return join("\n", @code);
}

sub install {
    my $self = shift;
    my $install = $self->SUPER::install(@_);

    # add dependency on data and configuration installation targets, and remove
    # dependency on perlocal installation target
    # depending on MakeMaker version, the line to match changes
    $install =~ s/install :: pure_install doc_install/install :: pure_install config_install data_install setup_install version_install/;
    $install =~ s/install :: all pure_install doc_install/install :: all pure_install config_install data_install setup_install version_install/;

    # suppress all lines related to packlist file installation
    $install =~ s/.*\.packlist \\\n//g;

    # add data and configuration installation targets
    $install .= <<'EOF';

config_install : pure_install
	$(MKPATH) $(DESTDIR)$(SYSCONFDIR)
	$(NOECHO) $(CHMOD) $(PERM_DIR) $(DESTDIR)$(SYSCONFDIR)
	for config in agent.cfg $(shell cd etc; echo *-plugin.cfg ); \
	do \
	  if $(TEST_F) $(DESTDIR)$(SYSCONFDIR)/$$config; then \
	    $(RM_F) $(DESTDIR)$(SYSCONFDIR)/$$config.new; \
	    $(CP) etc/$$config $(DESTDIR)$(SYSCONFDIR)/$$config.new; \
	    $(CHMOD) $(PERM_RW) $(DESTDIR)$(SYSCONFDIR)/$$config.new; \
	  else \
	    $(CP) etc/$$config $(DESTDIR)$(SYSCONFDIR)/$$config; \
	    $(CHMOD) $(PERM_RW) $(DESTDIR)$(SYSCONFDIR)/$$config; \
	  fi; \
	done
	$(ABSPERLRUN) -pi \
	    -e "s|=> undef, # SYSCONFDIR.*|=> '$(SNAPDIR)$(SYSCONFDIR)',|;" \
	        $(DESTDIR)$(INSTALLSITELIB)/GLPI/Agent/Config.pm

data_install : pure_install
	$(MOD_INSTALL) "share" "$(DESTDIR)$(DATADIR)"

setup_install : pure_install
	# Cleanup setup file to only really needed hash during install
	$(ABSPERLRUN) -pi \
	    -e 'undef $$_ if m/^use (File::Spec|Cwd)/;' \
	    -e 'if (m/# Compute/) { print "1;\n"; last; };' \
	    -e 's|datadir => .*|datadir => "$(SNAPDIR)$(DATADIR)",|;' \
	    -e 's|libdir  => .*|libdir  => "$(SNAPDIR)$(INSTALLSITELIB)",|;' \
	    -e 's|vardir  => .*|vardir  => "$(LOCALSTATEDIR)",|' \
	        $(DESTDIR)$(INSTALLSITELIB)/setup.pm

version_install : pure_install
	# Cleanup and update Version module during install
	$(ABSPERLRUN) -pi \
	    -e 'last if m|^__END__|;' \
	    -e 's|^our \$$VERSION =.*|our \$$VERSION = "$(VERSION)";|;' \
	    -e 's|^our \$$COMMENTS =.*|our \$$COMMENTS = [$(RAWCOMMENTS)];|;' \
	        $(DESTDIR)$(INSTALLSITELIB)/GLPI/Agent/Version.pm
EOF
    return $install;
}

# ensure binaries get modified to use configured directories (on Unix only)
sub installbin {
    my $self = shift;
    my $installbin = $self->SUPER::installbin(@_);

    return $installbin if $OSNAME eq 'MSWin32';

    $installbin =~ s|\t\$\(FIXIN\) (.*)\n|\t\$(FIXIN) $1\n\t\$(FINALIZE) $1\n|g;

    $installbin .= <<'EOF';
FINALIZE = $(ABSPERLRUN) -pi \
    -e 's|use lib .*|use lib "$(INSTALLSITELIB)";|;' \
    --
EOF
    return $installbin;
}
