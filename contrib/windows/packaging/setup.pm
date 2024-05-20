package
        setup;

use strict;
use warnings;
use parent qw(Exporter);

use File::Spec;
use Cwd qw(abs_path);
use Win32::API;

our @EXPORT = ('%setup');

use lib abs_path(File::Spec->rel2abs('../../agent', __FILE__));

my $basefolder = abs_path(File::Spec->rel2abs('../../..', __FILE__));

our %setup = (
    datadir => $basefolder.'/share',
    vardir  => $basefolder.'/var',
    libdir  => $basefolder.'/perl/agent',
);

my $apiSetDllDirectory = Win32::API->new(
    'kernel32',
    'BOOL SetDllDirectoryA(LPCSTR lpPathName)'
);
$apiSetDllDirectory->Call(File::Spec->catdir($basefolder, 'perl', 'bin'));

1;
