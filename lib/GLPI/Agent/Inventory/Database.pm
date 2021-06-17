package GLPI::Agent::Inventory::Database;

sub new {
    my ($class, %params) = @_;

    my $self = {
        _type           => $params{type},
        _name           => $params{name},
        _version        => $params{version},
        _manufacturer   => $params{manufacturer},
        _instances      => [],
        _is_active      => undef,
        _is_onbackup    => undef,
        _creation_date  => undef,
        _update_date    => undef,
    };

    bless $self, $class;

    return $self;
}

sub entry {
    my ($self) = @_;
    return {
        TYPE            => $self->{_type},
        NAME            => $self->{_name},
        VERSION         => $self->{_version},
        MANUFACTURER    => $self->{_manufacturer},
        INSTANCES       => $self->{_instances},
        IS_ACTIVE       => $self->{_is_active},
        IS_ONBACKUP     => $self->{_is_onbackup},
        CREATION_DATE   => $self->{_creation_date},
        UPDATE_DATE     => $self->{_update_date},
    };
}

sub addInstance {
    my ($self, %infos) = @_;

    my %instance = map
        { $_  => $infos{$_} }
        grep { defined($infos{$_}) } qw(
        name
        size
        port
        is_active
        is_onbackup
        last_boot_date
    );

    push @{$self->{_instances}}, \%instance;
}

sub wasCreated {
    my ($self, $created) = @_;

    if ($created =~ /^(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})$/) {
        my $time = int($1.$2.$3.$4.$5.$6);
        if (!$self->{_created} || $self->{_created} > $time) {
            $self->{_created} = $time;
            $self->{_creation_date} = $created;
        }
    }
}

sub wasUpdated {
    my ($self, $updated) = @_;

    if ($updated =~ /^(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})$/) {
        my $time = int($1.$2.$3.$4.$5.$6);
        if (!$self->{_updated} || $self->{_updated} < $time) {
            $self->{_updated} = $time;
            $self->{_update_date} = $updated;
        }
    }
}

1;

__END__

=head1 NAME

GLPI::Agent::Inventory::Database

=head1 DESCRIPTION

This class provides methods to support database inventory

=head1 FUNCTIONS
