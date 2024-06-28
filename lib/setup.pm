package
        setup;

use strict;
use warnings;
use parent qw(Exporter);

use English qw(-no_match_vars);
use UNIVERSAL::require;
use File::Spec;
use File::Basename qw(dirname);

our @EXPORT = ('%setup');

our %setup = (
    datadir => './share',
    libdir  => './lib',
    vardir  => './var',
);

# Compute directly libdir from this setup file as it should be installed in expected directory
eval {
    $setup{libdir} = File::Spec->rel2abs(dirname(__FILE__))
        unless $setup{libdir} && File::Spec->file_name_is_absolute($setup{libdir});

    # If run from sources, we can try to rebase setup keys to absolute folders related to libdir
    if (File::Spec->file_name_is_absolute($setup{libdir})) {
        foreach my $key (qw(datadir vardir)) {
            # Anyway don't update if target still absolute
            next if $setup{$key} && File::Spec->file_name_is_absolute($setup{$key});

            my $folder = File::Spec->rel2abs($setup{$key}, dirname($setup{libdir}));
            $setup{$key} = $folder if $folder && -d $folder;
        }
    }
};

# Set DLL directory from perl exe path on MSWin32
if ($OSNAME eq 'MSWin32') {
    Win32::API->require();
    my $apiSetDllDirectory = Win32::API->new(
        'kernel32',
        'BOOL SetDllDirectoryA(LPCSTR lpPathName)'
    );
    $apiSetDllDirectory->Call(dirname($^X));
}

1;
