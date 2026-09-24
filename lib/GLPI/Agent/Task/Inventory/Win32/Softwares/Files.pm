package GLPI::Agent::Task::Inventory::Win32::Softwares::Files;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use GLPI::Agent::Tools::Win32;

use constant    category    => "software";

# PE header machine type => GLPI ARCH value (architecture of the file itself,
# so a 32bit exe reports i586 even on a 64bit host)
my %ARCH = (
    0x014c => 'i586',
    0x8664 => 'x86_64',
    0xaa64 => 'arm64',
    0x01c0 => 'arm',
    0x01c4 => 'arm',
    0x0200 => 'ia64',
);

sub isEnabled {
    my (%params) = @_;

    my $files = $params{inventory_files};
    return ref($files) eq 'ARRAY' && @{$files} ? 1 : 0;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};
    my $files     = $params{inventory_files};

    return unless ref($files) eq 'ARRAY';

    foreach my $file (@{$files}) {
        next if empty($file);

        unless (has_file($file)) {
            $logger->debug("inventory-files: file not found, skipping: $file")
                if $logger;
            next;
        }

        my $software = _getSoftwareFromFile(file => $file, logger => $logger)
            or next;

        $inventory->addEntry(section => 'SOFTWARES', entry => $software);
    }
}

sub _getSoftwareFromFile {
    my (%params) = @_;

    my $file = $params{file};
    my $info = _getFileInfo(%params);

    # Fallback name is the file base name, so we always report something usable
    my ($basename) = $file =~ m{[\\/]?([^\\/]+)$};

    my $software = {
        NAME            => $info->{ProductName} || $info->{FileDescription} || $basename,
        VERSION         => $info->{FileVersion} || $info->{ProductVersion},
        # Publisher from the version resource, else from the digital signature
        PUBLISHER       => $info->{CompanyName} || _signerOrg($info->{Signer}),
        COMMENTS        => $file,
        FROM            => "inventory-files",
    };

    # Some resources store the version comma-separated (e.g. "8, 2, 95, 150")
    $software->{VERSION} =~ s/\s*,\s*/./g if defined $software->{VERSION};

    # major/minor from the first two version numbers, whatever the separator
    if (defined($software->{VERSION}) && $software->{VERSION} =~ /(\d+)\D+(\d+)/) {
        $software->{VERSION_MAJOR} = $1;
        $software->{VERSION_MINOR} = $2;
    }

    $software->{ARCH} = $ARCH{$info->{Machine}}
        if defined($info->{Machine}) && $ARCH{$info->{Machine}};

    # File creation date as install date
    $software->{INSTALLDATE} = _formatDate($info->{CreationDate})
        if $info->{CreationDate};

    my $stat = FileStat($file);
    $software->{FILESIZE} = $stat->size if $stat;

    delete $software->{$_} foreach grep { empty($software->{$_}) } keys %{$software};

    return $software;
}

sub _signerOrg {
    my ($subject) = @_;

    return unless defined($subject);

    # Authenticode subject e.g.: CN="Foo, Inc.", O=Foo Inc, C=DE
    return $1 if $subject =~ /CN="([^"]+)"/;
    return trimWhitespace($1) if $subject =~ /CN=([^,]+)/;

    return;
}

sub _formatDate {
    my ($date) = @_;

    # PowerShell gives yyyy-MM-dd, GLPI expects DD/MM/YYYY
    my ($y, $m, $d) = $date =~ /^(\d{4})-(\d{2})-(\d{2})$/
        or return;

    return "$d/$m/$y";
}

sub _getFileInfo {
    my (%params) = @_;

    my $file = $params{file};

    # Escape single quotes for the PowerShell single-quoted literal
    (my $path = $file) =~ s/'/''/g;

    # UTF-8 output (no BOM) so special chars survive and key=value parsing stays robust
    my $script = <<"SCRIPT";
\$OutputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding \$false
\$ErrorActionPreference = 'Stop'
try {
    \$item = Get-Item -LiteralPath '$path'
    \$vi = \$item.VersionInfo
    Write-Output ("ProductName="     + \$vi.ProductName)
    Write-Output ("ProductVersion="  + \$vi.ProductVersion)
    Write-Output ("FileVersion="     + \$vi.FileVersion)
    Write-Output ("FileDescription=" + \$vi.FileDescription)
    Write-Output ("CompanyName="     + \$vi.CompanyName)
    Write-Output ("CreationDate="    + \$item.CreationTime.ToString('yyyy-MM-dd'))
    # Authenticode signer only when there is no CompanyName (it can be slow)
    if ([string]::IsNullOrEmpty(\$vi.CompanyName)) {
        try {
            \$sig = Get-AuthenticodeSignature -LiteralPath \$item.FullName
            if (\$sig -and \$sig.SignerCertificate) {
                Write-Output ("Signer=" + \$sig.SignerCertificate.Subject)
            }
        } catch {
        }
    }
    try {
        \$fs = [System.IO.File]::Open(\$item.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        \$br = New-Object System.IO.BinaryReader(\$fs)
        \$fs.Position = 0x3C
        \$fs.Position = \$br.ReadInt32() + 4
        Write-Output ("Machine=" + \$br.ReadUInt16())
        \$br.Close(); \$fs.Close()
    } catch {
    }
} catch {
}
SCRIPT

    my %info;
    foreach my $line (runPowerShell(script => $script, logger => $params{logger})) {
        $line =~ s/^\x{FEFF}//;
        my ($key, $value) = $line =~ /^(\w+)=(.*)$/
            or next;
        $value = trimWhitespace($value);
        $info{$key} = $value unless empty($value);
    }

    return \%info;
}

1;
