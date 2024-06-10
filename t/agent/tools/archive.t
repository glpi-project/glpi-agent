#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';

use English qw(-no_match_vars);
use File::Temp qw(tempdir);
use Digest::SHA;
use File::Spec;

use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Agent::Config;
use GLPI::Agent::Logger;
use GLPI::Agent::Tools::Archive;

if ($OSNAME eq 'MSWin32') {
    plan skip_all => 'not working on Windows, but tested module not used on Windows';
}

my %archives = (
    'tar' => {
        file    => "config.tar",
        check   => "resources/config/sample1",
        sha256  => "2bc961e85ba3c36a7467b81bfd0b2c11991c25fb6bfc6864cb9801269dc5d78e"
    },
    'tgz' => {
        file    => "config.tar.gz",
        check   => "resources/config/sample1",
        sha256  => "2bc961e85ba3c36a7467b81bfd0b2c11991c25fb6bfc6864cb9801269dc5d78e"
    },
    'gz' => {
        file    => "config.tar.gz",
        check   => "config.tar",
        type    => "gz",
        sha256  => "1c1531ed8353b93e605e87057519b034144b12976590fbda4b8117c5f5007162"
    },
    'tar.bz2' => {
        file    => "config.tar.bz2",
        check   => "resources/config/sample1",
        sha256  => "2bc961e85ba3c36a7467b81bfd0b2c11991c25fb6bfc6864cb9801269dc5d78e"
    },
    'bz2' => {
        file    => "config.tar.bz2",
        check   => "config.tar",
        type    => "bz2",
        sha256  => "1c1531ed8353b93e605e87057519b034144b12976590fbda4b8117c5f5007162"
    },
    'tar.xz' => {
        file    => "config.tar.xz",
        check   => "resources/config/sample1",
        sha256  => "2bc961e85ba3c36a7467b81bfd0b2c11991c25fb6bfc6864cb9801269dc5d78e"
    },
    'xz' => {
        file    => "config.tar.xz",
        check   => "config.tar",
        type    => "xz",
        sha256  => "1c1531ed8353b93e605e87057519b034144b12976590fbda4b8117c5f5007162"
    },
    'zip' => {
        file    => "config.zip",
        check   => "resources/config/sample1",
        sha256  => "2bc961e85ba3c36a7467b81bfd0b2c11991c25fb6bfc6864cb9801269dc5d78e"
    },
);

plan tests => 4 * (scalar keys %archives) + 1;

my $logger = GLPI::Agent::Logger->new(
    config => GLPI::Agent::Config->new(
        options => {
            config => 'none',
            logger => 'Test'
        }
    )
);

foreach my $test (keys %archives) {
    my $folder = tempdir(CLEANUP => 1);
    my $file = "resources/archive/". $archives{$test}->{file};
    ;

    my $archive;
    lives_ok {
        $archive = GLPI::Agent::Tools::Archive->new(
            archive => $file,
            type    => $archives{$test}->{type} // "",
            logger  => $logger,
        );
    } "$test: archive object";

    lives_ok {
        $archive->extract(to => $folder);
    } "$test: archive extract";

    $file = File::Spec->catfile($folder, $archives{$test}->{check});
    ok(-e $file, "$test: extracted file");

    if (-e $file) {
        my $sha = Digest::SHA->new(256)->addfile($file);
        is($sha->hexdigest, $archives{$test}->{sha256}, "$test: sha256 checked file");
    } else {
        fail "$test: sha256 checked file with missing file";
    }
}
