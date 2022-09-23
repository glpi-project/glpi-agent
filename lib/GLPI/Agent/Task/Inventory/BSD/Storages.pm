package GLPI::Agent::Task::Inventory::BSD::Storages;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::XML;

use constant    category    => "storage";

sub isEnabled {
    return canRun('sysctl');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $storage (_getStorages(logger => $logger)) {
        $inventory->addEntry(
            section => 'STORAGES',
            entry   => $storage
        );
    }
}

sub _getStorages {
    my (%params) = @_;

    my $command = 'sysctl kern.geom.confxml';
    my $lines = getAllLines(
        command => $command,
        %params
    );
    $lines =~ s/^kern.geom.confxml://;
    my $tree = GLPI::Agent::XML->new(string => $lines)->dump_as_hash();

    my @storages = ();
    for my $class (@{$tree->{mesh}->{class}}) {
        my $name = $class->{name} || $class->{'#name'} || '';
        next unless ($name && $name eq 'DISK');
        for my $geom (@{$class->{geom}}) {
            my $device = {};
            $device->{NAME} = $geom->{name} if $geom->{name};
            $device->{DESCRIPTION} = $geom->{provider}->{config}->{descr}
                if ($geom->{provider}
                    && $geom->{provider}->{config}
                    && $geom->{provider}->{config}->{descr});
            $device->{DISKSIZE} = $geom->{provider}->{mediasize}
                if ($geom->{provider}
                    && defined $geom->{provider}->{mediasize});
            $device->{TYPE} = _retrieveDeviceTypeFromName($device->{NAME});
            push @storages, $device;
        }
    }

    # Unittest support
    $params{file} = $params{dmesgFile} if ($params{dmesgFile});

    _extractDataFromDmesg(
        storages => \@storages,
        %params
    );

    return @storages;
}

sub _retrieveDeviceTypeFromName {
    my $name = shift;
    my $type = not (defined $name) ? 'unknown' :
            $name =~ /^da/ ? 'disk' :
            $name =~ /^ada/ ? 'disk' :
            $name =~ /^cd/ ? 'cdrom' :
                'unknown';
    return $type;
}

sub _extractDataFromDmesg {
    my (%params) = @_;

    my $storages = $params{storages};

    my $dmesgLines = getAllLines(
        command => 'dmesg',
        %params
    );
    for my $storage (@$storages) {
        next unless $storage->{NAME};
        $storage->{MODEL} = getFirstMatch(
            string => $dmesgLines,
            pattern => qr/^\Q$storage->{NAME}\E.*<(.*)>/
        ) || '';
        my $desc = getFirstMatch(
            string => $dmesgLines,
            pattern => qr/^\Q$storage->{NAME}\E: (.*<.*>.*)$/
        );
        $storage->{DESCRIPTION} = $desc if $desc;
        $storage->{SERIALNUMBER} = getFirstMatch(
            string => $dmesgLines,
            pattern => qr/^\Q$storage->{NAME}\E: Serial Number (.*)$/
        ) || '';

        if ($storage->{MODEL}) {
            if ($storage->{MODEL} =~ s/^(SGI|SONY|WDC|ASUS|LG|TEAC|SAMSUNG|PHILIPS|PIONEER|MAXTOR|PLEXTOR|SEAGATE|IBM|SUN|SGI|DEC|FUJITSU|TOSHIBA|YAMAHA|HITACHI|VERITAS)\s*//i) {
                $storage->{MANUFACTURER} = $1;
            }

            # clean up the model
            $storage->{MODEL} =~ s/^(\s|,)*//;
            $storage->{MODEL} =~ s/(\s|,)*$//;
        }
    }
}

1;
