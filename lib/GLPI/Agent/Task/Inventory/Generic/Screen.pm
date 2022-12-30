package GLPI::Agent::Task::Inventory::Generic::Screen;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);
use MIME::Base64;
use UNIVERSAL::require;

use File::Find;
use File::Basename;
use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Screen;

use constant    category    => "monitor";

sub isEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my %options = (
        logger  => $params{logger},
        datadir => $params{datadir},
        format  => $inventory->getFormat() // 'json',
        remote  => $inventory->getRemote()
    );

    foreach my $screen (_getScreens(%options)) {
        $inventory->addEntry(
            section => 'MONITORS',
            entry   => $screen
        );
    }
}

sub _getEdidInfo {
    my (%params) = @_;

    Parse::EDID->require();
    if ($EVAL_ERROR) {
        $params{logger}->debug(
            "Parse::EDID Perl module not available, unable to parse EDID data"
        ) if $params{logger};
        return;
    }

    my $edid = Parse::EDID::parse_edid($params{edid});
    if (my $error = Parse::EDID::check_parsed_edid($edid)) {
        $params{logger}->debug("bad edid: $error") if $params{logger};
        # Don't return if edid is finally partially parsed
        return unless ($edid->{monitor_name} && $edid->{week} &&
            $edid->{year} && $edid->{serial_number});
    }

    my $screen = GLPI::Agent::Tools::Screen->new( %params, edid => $edid );

    my $info = {
        CAPTION      => $screen->caption || undef,
        DESCRIPTION  => $screen->week_year_manufacture,
        MANUFACTURER => $screen->manufacturer,
        SERIAL       => $screen->serial
    };

    # Add ALTSERIAL if defined by Screen object
    $info->{ALTSERIAL} = $screen->altserial if $screen->altserial;

    return $info;
}

sub _getScreensFromWindows {
    my (%params) = @_;

    GLPI::Agent::Tools::Win32->use();

    my @screens;

    # VideoOutputTechnology table, see ref:
    # - https://msdn.microsoft.com/en-us/library/bb980612(v=vs.85).aspx
    # - https://msdn.microsoft.com/en-us/library/ff546605.aspx
    my %ports = qw(
        -1      Other
         0      VGA
         1      S-Video
         2      Composite
         3      YUV
         4      DVI
         5      HDMI
         6      LVDS
         8      D-Jpn
         9      SDI
        10      DisplayPort
        11      eDisplayPort
        12      UDI
        13      eUDI
        14      SDTV
        15      Miracast
    );

    # Vista and upper, able to get the second screen
    foreach my $object (getWMIObjects(
        moniker    => 'winmgmts:{impersonationLevel=impersonate,authenticationLevel=Pkt}!//./root/wmi',
        class      => 'WMIMonitorConnectionParams',
        properties => [ qw/Active InstanceName VideoOutputTechnology/ ]
    )) {
        next unless $object->{InstanceName};
        next unless $object->{Active};

        $object->{InstanceName} =~ s/_\d+//;
        my $screen = {
            id => $object->{InstanceName}
        };

        # Skip setting monitor port as it is not used on server-side and this
        # does not respect json format
        if ($params{format} ne 'json' && exists($object->{VideoOutputTechnology})) {
            my $port = $object->{VideoOutputTechnology};
            $screen->{PORT} = $ports{$port}
                if (exists($ports{$port}));
        }

        push @screens, $screen;
    }

    # The generic Win32_DesktopMonitor class, the second screen will be missing
    foreach my $object (getWMIObjects(
        class => 'Win32_DesktopMonitor',
        properties => [ qw/
            Caption MonitorManufacturer MonitorType PNPDeviceID Availability
        / ]
    )) {
        next unless $object->{Availability};
        next unless $object->{PNPDeviceID};
        next unless $object->{Availability} == 3;

        push @screens, {
            id           => $object->{PNPDeviceID},
            NAME         => $object->{Caption},
            TYPE         => $object->{MonitorType},
            MANUFACTURER => $object->{MonitorManufacturer},
            CAPTION      => $object->{Caption}
        };
    }

    foreach my $screen (@screens) {
        next unless $screen->{id};
        # Support overrided EDID block, see https://docs.microsoft.com/en-us/windows-hardware/drivers/display/overriding-monitor-edids
        $screen->{edid} = getRegistryValue(
            path => "HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Enum/$screen->{id}/Device Parameters/EDID_OVERRIDE",
            logger => $params{logger}
        ) // getRegistryValue(
            path => "HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Enum/$screen->{id}/Device Parameters/EDID",
            method => "GetBinaryValue", # method for winrm remote inventory
            logger => $params{logger}
        );
        $screen->{edid} =~ s/^\s+$// if $screen->{edid};
        delete $screen->{id};
        $screen->{edid} or delete $screen->{edid};
    }

    return @screens;
}

sub _getScreensFromUnix {
    my (%params) = @_;

    my $logger = $params{logger};
    $logger->debug("retrieving EDID data:");

    if (has_folder('/sys/devices')) {
        my @screens;

        if ($params{remote}) {
            my @cards = Glob("/sys/devices/*/*/drm/* /sys/devices/*/*/*/drm/*");
            # But we need to filter out links
            my @ctrls = Glob("/sys/devices/*/*/drm/* /sys/devices/*/*/*/drm/*", "-h");
            @cards = grep { my $card = $_; ! grep { $card eq $_ } @ctrls } @cards
                if @cards && @ctrls;

            foreach my $card (@cards) {
                my @edid = Glob("$card/*/edid")
                    or next;
                foreach my $sysfile (@edid) {
                    my $edid = getAllLines(file => $sysfile);
                    push @screens, { edid => $edid } if $edid;
                }
            }
        } else {
            no warnings 'File::Find';
            File::Find::find(
                {
                    no_chdir => 1,
                    wanted   => sub {
                        return unless basename($_) eq 'edid';
                        return unless canRead($_);
                        my $edid = getAllLines(file => $_);
                        push @screens, { edid => $edid } if $edid;
                    },
                },
                '/sys/devices'
            );
        }

        $logger->debug_result(
            action => 'reading /sys/devices content',
            data   => scalar @screens
        );

        return @screens if @screens;
    } else {
        $logger->debug_result(
            action => 'reading /sys/devices content',
            status => 'directory not available'
        );
    }

    if (canRun('monitor-get-edid-using-vbe')) {
        my $edid = getAllLines(command => 'monitor-get-edid-using-vbe');
        $logger->debug_result(
            action => 'running monitor-get-edid-using-vbe command',
            data   => $edid
        );
        return { edid => $edid } if $edid;
    } else {
        $logger->debug_result(
            action => 'running monitor-get-edid-using-vbe command',
            status => 'command not available'
        );
    }

    if (canRun('monitor-get-edid')) {
        my $edid = getAllLines(command => 'monitor-get-edid');
        $logger->debug_result(
            action => 'running monitor-get-edid command',
            data   => $edid
        );
        return { edid => $edid } if $edid;
    } else {
        $logger->debug_result(
            action => 'running monitor-get-edid command',
            status => 'command not available'
        );
    }

    if (canRun('get-edid')) {
        my $edid;
        foreach (1..5) { # Sometime get-edid return an empty string...
            $edid = getAllLines(command => 'get-edid');
            last if $edid;
        }
        $logger->debug_result(
            action => 'running get-edid command',
            data   => $edid
        );
        return { edid => $edid } if $edid;
    } else {
        $logger->debug_result(
            action => 'running get-edid command',
            status => 'command not available'
        );
    }

    return;
}

sub _getScreensFromMacOS {
    my (%params) = @_;

    my $logger = $params{logger};

    $logger->debug("retrieving AppleBacklightDisplay and AppleDisplay datas:")
        if $logger;

    GLPI::Agent::Tools::MacOS->require();

    my @screens;
    my @displays = GLPI::Agent::Tools::MacOS::getIODevices(
        class   => 'AppleBacklightDisplay',
        options => '-r -lw0 -d 1',
        logger  => $logger,
    );

    push @displays, GLPI::Agent::Tools::MacOS::getIODevices(
        class   => 'AppleDisplay',
        options => '-r -lw0 -d 1',
        logger  => $logger,
    );

    foreach my $display (@displays) {
        my $screen = {};
        if ($display->{IODisplayCapabilityString} && $display->{IODisplayCapabilityString} =~ /model\((.*)\)/) {
            $screen->{CAPTION} = $1;
        }
        if ($display->{IODisplayEDID} && $display->{IODisplayEDID} =~ /^[0-9a-f]+$/i
          && (length($display->{IODisplayEDID}) == 256 || length($display->{IODisplayEDID}) == 512)) {
            $screen->{edid} = pack("H*", $display->{IODisplayEDID})
        }
        push @screens, $screen;
    }

    return @screens if @screens;

    # Try unix commands if no screen is detected
    return _getScreensFromUnix(%params);
}

sub _getScreens {
    my (%params) = @_;

    my %screens = ();

    my @screens =
        OSNAME eq 'MSWin32' ?  _getScreensFromWindows(%params) :
        OSNAME eq 'darwin' ?   _getScreensFromMacOS(%params) :
                                _getScreensFromUnix(%params);

    foreach my $screen (@screens) {
        next unless $screen->{edid};

        my $info = _getEdidInfo(
            edid    => $screen->{edid},
            logger  => $params{logger},
            datadir => $params{datadir},
        );
        if ($info) {
            $screen->{CAPTION}      = $info->{CAPTION};
            $screen->{DESCRIPTION}  = $info->{DESCRIPTION};
            $screen->{MANUFACTURER} = $info->{MANUFACTURER};
            $screen->{SERIAL}       = $info->{SERIAL};
            $screen->{ALTSERIAL}    = $info->{ALTSERIAL} if $info->{ALTSERIAL};
        }

        $screen->{BASE64} = encode_base64($screen->{edid});

        delete $screen->{edid};

        # Add or merge found values
        my $serial = $info->{SERIAL} || $screen->{BASE64};
        if (!exists($screens{$serial})) {
            $screens{$serial} = $screen ;
        } else {
            foreach my $key (keys(%$screen)) {
                if (exists($screens{$serial}->{$key})) {
                    if ($screens{$serial}->{$key} ne $screen->{$key} && $params{logger}) {
                        $params{logger}->warning(
                            "Not merging not coherent $key value for screen associated to $serial serial number"
                        );
                    }
                    next;
                }
                $screens{$serial}->{$key} = $screen->{$key};
            }
        }
    }

    return values(%screens);
}

1;
