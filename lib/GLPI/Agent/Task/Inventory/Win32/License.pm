package GLPI::Agent::Task::Inventory::Win32::License;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use GLPI::Agent::Tools::License;
use GLPI::Agent::Tools::Win32;
use GLPI::Agent::Tools;

use constant    category    => "licenseinfo";

my $seenProducts;

sub isEnabled {
    return 1;
}

sub _resetSeenProducts {
    $seenProducts = {};
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my @licenses;

    # Important for remote inventory optimization
    my $required_for_office = [ qw/
        DigitalProductID ProductCode ProductName ProductNameBrand ProductID
        SPLevel OEM ConvertToEdition ProductNameNonQualified ProductNameVersion
        TrialType
        /
    ];

    my $officeKey = getRegistryKey(
        path        => "HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Office",
        # Important for remote inventory optimization
        required    => $required_for_office,
    );
    _scanOfficeLicences($officeKey) if $officeKey;

    my $fileAdobe = 'C:\Program Files\Common Files\Adobe\Adobe PCD\cache\cache.db';
    if (is64bit()) {
        $fileAdobe = 'C:\Program Files (x86)\Common Files\Adobe\Adobe PCD\cache\cache.db';
        my $officeKey32 = getRegistryKey(
            path        => "HKEY_LOCAL_MACHINE/SOFTWARE/Wow6432Node/Microsoft/Office",
            # Important for remote inventory optimization
            required    => $required_for_office,
        );
        _scanOfficeLicences($officeKey32) if $officeKey32;
    }

    push @licenses, getAdobeLicensesWithoutSqlite($fileAdobe) if has_file($fileAdobe);

    _scanWmiSoftwareLicensingProducts();

    push @licenses, _getSeenProducts();

    foreach my $license (@licenses) {
        $inventory->addEntry(
            section => 'LICENSEINFOS',
            entry   => $license
        );
    }

    _resetSeenProducts();
}

sub _getSeenProducts {
    return unless $seenProducts;
    return grep { defined $_->{KEY} } values(%{$seenProducts});
}

sub _scanWmiSoftwareLicensingProducts {
    foreach my $object (getWMIObjects(
        moniker    => 'winmgmts:\\\\.\\root\\CIMV2',
        class      => 'SoftwareLicensingProduct',
        properties => [ qw/
            Name Description LicenseStatus PartialProductKey ID
            ProductKeyChannel ProductKeyID ProductKeyID2 ApplicationID
        / ]
    )) {
        next unless $object->{'PartialProductKey'} && $object->{'LicenseStatus'};

        # Skip operating system license as still set from OS module
        next if ($object->{'Description'} && $object->{'Description'} =~ /Operating System/i);

        if ($object->{'ID'}) {
            my $wmiLicence = _getWmiLicense($object);
            my $uiidLC = lc($object->{'ID'});
            if (!defined $seenProducts->{$uiidLC}) {
                $seenProducts->{$uiidLC} = $wmiLicence;
            } else {
                $wmiLicence->{'FULLNAME'} = $seenProducts->{$uiidLC}->{'FULLNAME'}
                    if $seenProducts->{$uiidLC}->{'FULLNAME'};
                $wmiLicence->{'TRIAL'}    = $seenProducts->{$uiidLC}->{'TRIAL'}
                    if $seenProducts->{$uiidLC}->{'TRIAL'};

                my $uiidToDelete = $uiidLC;
                if ($seenProducts->{$uiidLC}->{PRODUCTCODE}) {
                    # Change key Target
                    $uiidLC = $seenProducts->{$uiidLC}->{PRODUCTCODE};
                    if ($seenProducts->{$uiidLC} && $seenProducts->{$uiidLC}->{KEY}) {
                        my $wmiKey = substr $wmiLicence->{KEY}, -5;
                        if ($seenProducts->{$uiidLC}->{'KEY'} =~ m/$wmiKey$/) {
                            # Skip this licence - Registry give more information
                            next;
                        }
                    }
                }
                delete $seenProducts->{$uiidToDelete};
                $seenProducts->{$uiidLC} = $wmiLicence;
            }
        }
    }
}

sub _scanOfficeLicences {
    my ($key) = @_;

    # registry data structure:
    # SOFTWARE/Microsoft/Office
    # └── x.y
    #     └── Registration
    #         └── UUID
    #             └── DigitalProductID:value
    #             └── ProductID:value
    #             └── ...

    foreach my $versionKey (keys %{$key}) {
        # Skip value keys
        next if $versionKey =~ m{^/};
        my $registrationKey = $key->{$versionKey}->{'Registration/'}
            or next;

        foreach my $uuidKey (keys %{$registrationKey}) {
            # Skip value keys
            next if $uuidKey =~ m{^/};
            my ($cleanUuidKey) = $uuidKey =~ /([-\w]+)/
                or next;
            $cleanUuidKey = lc($cleanUuidKey);
            # Keep in memory seen product with ProductCode value or DigitalProductID
            $seenProducts->{$cleanUuidKey} = _getOfficeLicense($registrationKey->{$uuidKey})
                if $registrationKey->{$uuidKey}->{'/DigitalProductID'};
            my $productName = getRegistryKeyValue($registrationKey->{$uuidKey}, 'ProductName');
            if ($registrationKey->{$uuidKey}->{'/ProductCode'} && $productName) {
                my ($productcode) = $registrationKey->{$uuidKey}->{'/ProductCode'} =~ /([-\w]+)/;
                $seenProducts->{$cleanUuidKey} = {
                    PRODUCTCODE => lc($productcode // ""),
                    FULLNAME    => $productName,
                };
                $seenProducts->{$cleanUuidKey}->{'TRIAL'} = 1
                    if $registrationKey->{$uuidKey}->{'/ProductNameBrand'} && $registrationKey->{$uuidKey}->{'/ProductNameBrand'} =~ /trial/i;
            }
        }
    }
}

sub _getWmiLicense {
    my ($wmi) = @_;

    my $key = $wmi->{'PartialProductKey'};
    if ($key && length($key) == 5) {
        $key = sprintf("XXXXX-XXXXX-XXXXX-XXXXX-%s", $key);
    }
    my $channel = $wmi->{'ProductKeyChannel'} || '';
    my $license = {
        KEY       => $key,
        PRODUCTID => $wmi->{'ProductKeyID2'} || $wmi->{'ApplicationID'} || $wmi->{'ProductKeyID'},
        OEM       => $channel =~ /OEM/i ? 1 : 0,
        FULLNAME  => $wmi->{'Description'},
        NAME      => $wmi->{'Name'}
    };

    return $license;
}

sub _getOfficeLicense {
    my ($key) = @_;

    my $license = {
        KEY       => decodeMicrosoftKey($key->{'/DigitalProductID'}),
        PRODUCTID => $key->{'/ProductID'},
        UPDATE    => $key->{'/SPLevel'},
        OEM       => $key->{'/OEM'},
        FULLNAME  => getRegistryKeyValue($key, 'ProductName') ||
                     getRegistryKeyValue($key, 'ConvertToEdition'),
        NAME      => getRegistryKeyValue($key, 'ProductNameNonQualified') ||
                     getRegistryKeyValue($key, 'ProductNameVersion')
    };

    if ($key->{'/TrialType'} && $key->{'/TrialType'} =~ /(\d+)$/) {
        $license->{TRIAL} = int($1);
    }

    my @products;
    foreach my $variable (keys %$key) {
        next unless $variable =~ m/\/(\w+)NameVersion$/;
        push @products, $1;
    }
    if (@products) {
        $license->{COMPONENTS} = join('/', sort @products);
    }

    return $license;
}

1;
