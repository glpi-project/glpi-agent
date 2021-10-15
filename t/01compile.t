#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::More;
use UNIVERSAL::require;
use Config;

plan(skip_all => 'Test::Compile required')
    unless Test::Compile->require();
Test::Compile->import();

# use mock modules for non-available ones
if ($OSNAME eq 'MSWin32') {
    push @INC, 't/lib/fake/unix';
} else {
    push @INC, 't/lib/fake/windows';
}

# exclude linked modules
my @files = grep { filter($_) } Test::Compile::all_pm_files('lib');

Test::Compile::all_pm_files_ok(@files);

# filename-based filter
sub filter {

    if (!$Config{usethreads} || $Config{usethreads} ne 'define') {
        return 0 if $_ =~ m{Agent/Task/NetInventory.pm};
        return 0 if $_ =~ m{Agent/Task/NetDiscovery.pm};
        return 0 if $_ =~ m{Agent/Tools/Win32.pm};
        return 0 if $_ =~ m{Agent/Daemon/Win32.pm};
        return 0 if $_ =~ m{Agent/Task/Inventory/Win32};
        return 0 if $_ =~ m{Agent/Tools/Win32/WTS.pm};
        return 0 if $_ =~ m{Agent/Tools/Win32/Users.pm};
        return 0 if $_ =~ m{Agent/Task/Deploy/UserCheck/WTS.pm};
    }

    return 0 if ($_ =~ m{Agent/Daemon/Win32.pm} &&
        !(Win32::Daemon->require()));

    return 0 if ($_ =~ m{Agent/Task/Deploy.pm} &&
        !(File::Copy::Recursive->require()));

    return 0 if ($_ =~ m{Agent/Task/Deploy/P2P.pm} &&
        !(Net::Ping->require() && Parallel::ForkManager->require()));

    return 0 if ($_ =~ m{Agent/Task/Deploy/ActionProcessor.pm} &&
        !(File::Copy::Recursive->require()));

    return 0 if ($_ =~ m{Agent/Task/Deploy/ActionProcessor/Action/Move.pm} &&
        !(File::Copy::Recursive->require()));

    return 0 if ($_ =~ m{Agent/Task/Deploy/ActionProcessor/Action/Copy.pm} &&
        !(File::Copy::Recursive->require()));

    return 1;
}
