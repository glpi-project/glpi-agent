package GLPI::Agent::Task::Collect::File;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Collect::Common';

use Digest::SHA;
use File::Basename;
use File::Find;
use File::stat;

use constant    function        => "findFile";

use constant    OPTIONAL        => 0;
use constant    MANDATORY       => 1;

use constant    json_validation => {
    dir         => MANDATORY,
    limit       => MANDATORY,
    recursive   => MANDATORY,
    filter      => {
        regex           => OPTIONAL,
        sizeEquals      => OPTIONAL,
        sizeGreater     => OPTIONAL,
        sizeLower       => OPTIONAL,
        checkSumSHA512  => OPTIONAL,
        checkSumSHA2    => OPTIONAL,
        name            => OPTIONAL,
        iname           => OPTIONAL,
        is_file         => MANDATORY,
        is_dir          => MANDATORY
    }
};

sub results {
    my ($self) = @_;

    my %params = (
        dir     => '/',
        limit   => 50,
        @_
    );

    return unless -d $self->{dir};

    $self->{logger}->debug("Looking for file under '$self->{dir}' folder");

    my @results;

    File::Find::find(
        {
            wanted => sub {
                if (!$self->{recursive} && $File::Find::name ne $self->{dir}) {
                    $File::Find::prune = 1  # Don't recurse.
                }

                my $filter = $self->{filter} // {};
                if (   $filter->{is_dir}
                    && !$filter->{checkSumSHA512}
                    && !$filter->{checkSumSHA2}
                ) {
                    return unless -d $File::Find::name;
                }

                if ( $filter->{is_file} ) {
                    return unless -f $File::Find::name;
                }

                my $filename = basename($File::Find::name);

                if ( $filter->{name} ) {
                    return if $filename ne $filter->{name};
                }

                if ( $filter->{iname} ) {
                    return if lc($filename) ne lc( $filter->{iname} );
                }

                if ( $filter->{regex} ) {
                    my $re = qr($filter->{regex});
                    return unless $File::Find::name =~ $re;
                }

                my $st   = stat($File::Find::name);
                my $size = $st->size;
                if ( $filter->{sizeEquals} ) {
                    return unless $size == $filter->{sizeEquals};
                }

                if ( $filter->{sizeGreater} ) {
                    return if $size < $filter->{sizeGreater};
                }

                if ( $filter->{sizeLower} ) {
                    return if $size > $filter->{sizeLower};
                }

                if ( $filter->{checkSumSHA512} ) {
                    my $sha = Digest::SHA->new('512');
                    $sha->addfile( $File::Find::name, 'b' );
                    return
                        if $sha->hexdigest ne lc($filter->{checkSumSHA512});
                }

                # checkSumSHA2 is an historic feature and was indeed sha256 at the time of this code original writing
                my $expectedSha256 = $filter->{checkSumSHA256} || $filter->{checkSumSHA2};
                if (!empty($expectedSha256)) {
                    my $sha = Digest::SHA->new('256');
                    $sha->addfile( $File::Find::name, 'b' );
                    return
                        if $sha->hexdigest ne lc($expectedSha256);
                }

                $self->{logger}->debug2("Found file: ".$File::Find::name);

                push @results, {
                    size => $size,
                    path => $File::Find::name
                };
                goto DONE if @results >= $self->{limit};
            },
            no_chdir => 1

        },
        $self->{dir}
    );
    DONE:

    return @results;
}

1;
