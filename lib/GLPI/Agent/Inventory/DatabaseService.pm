package GLPI::Agent::Inventory::DatabaseService;

use strict;
use warnings;

sub new {
    my ($class, %params) = @_;

    my $self = {
        _type               => $params{type},
        _name               => $params{name},
        _version            => $params{version},
        _manufacturer       => $params{manufacturer},
        _port               => $params{port},
        _path               => undef,
        _size               => undef,
        _is_active          => $params{is_active},
        _is_onbackup        => undef,
        _last_boot_date     => undef,
        _last_backup_date   => undef,
        _databases          => [],
    };

    map {
        my $lkey = "_".$_;
        $self->{$lkey} = $params{$_}
            if defined($params{$_}) && $params{$_} =~ /^(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})$/
    } qw(
        last_boot_date
        last_backup_date
    );

    bless $self, $class;

    return $self;
}

sub entry {
    my ($self) = @_;

    my $entry = {
        TYPE            => $self->{_type},
        NAME            => $self->{_name},
        VERSION         => $self->{_version},
        MANUFACTURER    => $self->{_manufacturer},
    };

    # Update entry
    map {
        my $lkey = "_".lc($_);
        $entry->{$_} = $self->{$lkey}
            if defined($self->{$lkey});
    } qw(PORT PATH SIZE IS_ACTIVE IS_ONBACKUP LAST_BOOT_DATE LAST_BACKUP_DATE);

    # Add found databases
    $entry->{DATABASES} = $self->{_databases}
        if @{$self->{_databases}};

    return $entry;
}

sub addDatabase {
    my ($self, %infos) = @_;

    my $database = {};
    map {
        $database->{uc($_)} = $infos{$_}
            if defined($infos{$_})
    } qw(
        name
        size
        is_active
        is_onbackup
    );

    map {
        $database->{uc($_)} = $infos{$_}
            if defined($infos{$_}) && $infos{$_} =~ /^(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})$/
    } qw(
        creation_date
        update_date
        last_backup_date
    );

    push @{$self->{_databases}}, $database;
}

sub size {
    my ($self, $size) = @_;

    $self->{_size} = $size if defined($size);

    return $self->{_size};
}

1;

__END__

=head1 NAME

GLPI::Agent::Inventory::DatabaseService

=head1 DESCRIPTION

This class provides methods to support database service inventory

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<type>

the database service type

=item I<name>

the database service name

=item I<version>

the database service version

=item I<manufacturer>

the database service manufacturer

=back

=head2 entry()

Return the suitable entry to be inserted in GLPI::Agent::Inventory
object.

=head2 addDatabase(%infos)

Add a database defined by %infos hash to the database service.

=head2 size($size)

Set the database service storage if $size is defined, otherwise return the set
storage size.
