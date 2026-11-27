package GLPI::Agent::Task::Deploy::Signature;

use strict;
use warnings;
use Cpanel::JSON::XS;
use Digest::SHA qw(sha512_hex);
use File::Spec;
use Scalar::Util qw(reftype);

sub new {
    my ($class, %params) = @_;
    return bless { logger => $params{logger} }, $class;
}

sub _fail {
    my ($self, $message) = @_;
    if ($self->{logger}) {
        $self->{logger}->error("Security check error: $message");
        return;
    }
    die "$message\n";
}

sub _digest {
    my ($self, $data) = @_;
    my $json = eval { Cpanel::JSON::XS->new->utf8->canonical->encode($data) };
    return $self->_fail('Cannot encode signed deployment data') if $@ || !defined($json);
    return sha512_hex($json);
}

sub _validAction {
    my ($self, $name, $params) = @_;
    return defined($name) && $name =~ /\A(?:cmd|copy|move|delete|mkdir)\z/ && ref($params) eq 'HASH';
}

sub actionDigest {
    my ($self, $name, $params) = @_;
    return $self->_fail('Unsupported signed action') unless $self->_validAction($name, $params);
    return $self->_digest({ $name => $params });
}

sub jobDigest {
    my ($self, $job) = @_;
    return $self->_fail('Missing signed job actions')
        unless (reftype($job) // '') eq 'HASH' && ref($job->{actions}) eq 'ARRAY';
    foreach my $action (@{$job->{actions}}) {
        return $self->_fail('Invalid signed action') unless ref($action) eq 'HASH' && keys(%$action) == 1;
        my ($name) = keys %$action;
        return $self->_fail('Unsupported signed action') unless $self->_validAction($name, $action->{$name});
    }
    my $description = {
        actions          => $job->{actions},
        checks           => $job->{checks} // [],
        requires         => $job->{requires} // {},
        userinteractions => $job->{userinteractions} // $job->{userchecks} // [],
    };
    return $self->_fail('Invalid signed job checks') unless ref($description->{checks}) eq 'ARRAY';
    return $self->_fail('Invalid signed job requirements') unless ref($description->{requires}) eq 'HASH';
    return $self->_fail('Invalid signed job interactions') unless ref($description->{userinteractions}) eq 'ARRAY';
    return $self->_digest($description);
}

sub validFilename {
    my ($self, $name) = @_;
    # Use one portable filename policy on all platforms, including Windows ADS
    # and device names, rather than relying on the build host's File::Spec.
    return defined($name) && !ref($name) && length($name) &&
        $name !~ m{[\\/:<>"|?*\x00-\x1f\x7f]} && $name !~ /[. ]\z/ &&
        $name !~ /\A(?:CON|PRN|AUX|NUL|CONIN\$|CONOUT\$|COM[0-9\x{b9}\x{b2}\x{b3}]|LPT[0-9\x{b9}\x{b2}\x{b3}])(?:\.|\z)/i;
}

sub payloadFiles {
    my ($self, $directory) = @_;
    opendir my $handle, $directory or return $self->_fail('Cannot inspect signed payload');
    my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir $handle;
    closedir $handle;
    my %seen;
    foreach my $name (@names) {
        return $self->_fail('Unsafe signed payload filename') unless $self->validFilename($name);
        return $self->_fail('Ambiguous signed payload filename') if $seen{lc($name)}++;
        my $path = File::Spec->catfile($directory, $name);
        my @stat = lstat($path);
        return $self->_fail('Signed payload must contain only regular, unlinked files')
            unless @stat && !-l _ && -f _ && $stat[3] == 1;
    }
    return \@names;
}

1;
