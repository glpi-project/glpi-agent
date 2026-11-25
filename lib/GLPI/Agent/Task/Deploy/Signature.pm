package GLPI::Agent::Task::Deploy::Signature;

use strict;
use warnings;
use parent 'Exporter';

use Cpanel::JSON::XS;
use Digest::SHA qw(sha512_hex);
use File::Spec;

our @EXPORT_OK = qw(jobDigest actionDigest payloadFiles validFilename);

sub _encode {
    return Cpanel::JSON::XS->new->utf8->canonical->encode($_[0]);
}

sub actionDigest {
    my ($name, $params) = @_;
    die "Unsupported signed action\n"
        unless defined($name) && $name =~ /\A(?:cmd|copy|move|delete|mkdir)\z/ && ref($params) eq 'HASH';
    return sha512_hex(_encode({ $name => $params }));
}

sub jobDigest {
    my ($job) = @_;
    die "Missing signed job actions\n" unless ref($job->{actions}) eq 'ARRAY';
    foreach my $action (@{$job->{actions}}) {
        die "Invalid signed action\n" unless ref($action) eq 'HASH' && keys(%$action) == 1;
        my ($name) = keys %$action;
        actionDigest($name, $action->{$name});
    }
    my $description = {
        actions          => $job->{actions},
        checks           => $job->{checks} // [],
        requires         => $job->{requires} // {},
        userinteractions => $job->{userinteractions} // $job->{userchecks} // [],
    };
    die "Invalid signed job checks\n" unless ref($description->{checks}) eq 'ARRAY';
    die "Invalid signed job requirements\n" unless ref($description->{requires}) eq 'HASH';
    die "Invalid signed job interactions\n" unless ref($description->{userinteractions}) eq 'ARRAY';
    return sha512_hex(_encode($description));
}

sub validFilename {
    my ($name) = @_;
    # Use one portable filename policy on all platforms, including Windows ADS
    # and device names, rather than relying on the build host's File::Spec.
    return defined($name) && !ref($name) && length($name) &&
        $name !~ m{[\\/:<>"|?*\x00-\x1f\x7f]} && $name !~ /[. ]\z/ &&
        $name !~ /\A(?:CON|PRN|AUX|NUL|CONIN\$|CONOUT\$|COM[0-9\x{b9}\x{b2}\x{b3}]|LPT[0-9\x{b9}\x{b2}\x{b3}])(?:\.|\z)/i;
}

sub payloadFiles {
    my ($directory) = @_;
    opendir my $handle, $directory or die "Cannot inspect signed payload\n";
    my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir $handle;
    closedir $handle;
    my %seen;
    foreach my $name (@names) {
        die "Unsafe signed payload filename\n" unless validFilename($name);
        die "Ambiguous signed payload filename\n" if $seen{lc($name)}++;
        my $path = File::Spec->catfile($directory, $name);
        my @stat = lstat($path);
        die "Signed payload must contain only regular, unlinked files\n"
            unless @stat && !-l _ && -f _ && $stat[3] == 1;
    }
    return @names;
}

1;
