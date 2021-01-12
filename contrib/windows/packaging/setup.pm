package
        setup;

use strict;
use warnings;
use parent qw(Exporter);

use File::Spec;
use Cwd qw(abs_path);

our @EXPORT = ('%setup');

use lib abs_path(File::Spec->rel2abs('../../agent', __FILE__));

my $basefolder = abs_path(File::Spec->rel2abs('../../..', __FILE__));

our %setup = (
    datadir => $basefolder.'/share',
    vardir  => $basefolder.'/var',
    libdir  => $basefolder.'/perl/agent',
);

1;
