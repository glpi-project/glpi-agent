package GLPI::Agent::Task::Collect::File;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Collect::Common';

use English qw(-no_match_vars);
use Digest::SHA;
use File::Basename;
use File::Find;
use File::stat;

use GLPI::Agent::Tools;

use constant    function        => "findFile";

use constant    OPTIONAL        => 0;
use constant    MANDATORY       => 1;

use constant    json_validation => {
    dir         => MANDATORY,
    limit       => MANDATORY,
    recursive   => MANDATORY,
    timeout     => OPTIONAL,
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

# Recursive function to normalize regex and limit not useful complexity
sub _normalized_regex {
    my ($start, $mid, $end, $debug) = @_;

    $mid //= '';
    $end //= '';

    my $regex = $start.$end;

    push @{$debug}, [ 'in:', $start, $mid, $end ] if ref($debug);

    # Try to match inner regex group if exists
    my ($pre, $grpdef, $grp, $post) = $regex =~ /^
        ( .* )                                          (?#pre)
        (?<!(?<!\\)\\)\(
        ( \?\w*-*\w*: | \?> | \*atomic: )?              (?#grpdef)
        ( (?: [^\(\)] | (?<=(?<!\\)\\)[\(\)] )* )       (?#grp)
        (?<!(?<!\\)\\)\)
        (.*)                                            (?#post)
    $/x;

    push @{$debug}, [ 'match:', $pre, $grpdef, $grp, $post ] if ref($debug);

    return $start.$mid.$end
        if empty($grpdef) && empty($grp) && empty($post);

    # Support other group definition syntax as it would be included in group
    my $atomic = $grp =~ /^[*?]/ ? "" : "?>";

    # Normalize pre part to not miss separated group+subgroup case
    $pre = _normalized_regex($pre, undef, undef, $debug);

    # On match
    if (length($end)) {
        my $startlen = length($start);
        my $prelen = length($pre);
        my $grpdeflen = empty($grpdef) ? 0 : length($grpdef);
        my $endmatch = $prelen + 1 + $grpdeflen + length($grp) + 1;
        push @{$debug}, [ 'end:', $startlen, $prelen, $grpdeflen, $endmatch ] if ref($debug);
        if ($endmatch <= $startlen) {
            # We add grp and right part of start to mid
            return _normalized_regex($pre, "($atomic$grp)".substr($start, $endmatch).$mid, $end, $debug);
        } else {
            my $right = $endmatch - $startlen;
            if ($prelen >= length($start)) {
                # We add left part of end to mid, grp and last end part
                return _normalized_regex($pre, $mid.substr($end, 0, $right)."($atomic$grp)", $post, $debug);
            } else {
                # We add merge sub group from mid
                return _normalized_regex($pre, "($atomic".substr($start, $prelen + 1 + $grpdeflen).$mid.substr($end, 0, $right-1).")", $post, $debug);
            }
        }
    }

    push @{$debug}, [ 'on-pre:', $atomic ] if ref($debug);

    # We prepend normalized regex to mid
    return _normalized_regex($pre//'', "($atomic$grp)", $post//'', $debug).$mid;
}

sub _compiled_regex {
    my ($self, $regex, $debug) = @_;

    return if empty($regex);

    # 1. regex is still limited server-side to 255 chars as stored in a VARCHAR(255) field
    #    Any longer string would anyway never a good test
    if (length($regex) > 255) {
        $self->{logger}->error("Aborting File Collect job with too long regex starting with: ".substr($regex, 0, 10));
        return 1;
    }

    # 2. normalize regex to remove not useful complexity
    my $normalized = _normalized_regex($regex, undef, undef, $debug);
    if ($regex ne $normalized) {
        if (length($regex) < 50) {
            $self->{logger}->debug("Job regex normalized from /$regex/ to /$normalized/")
        } elsif (length($normalized) < 50) {
            $self->{logger}->debug("Job regex normalized to /$normalized/")
        } else {
            $self->{logger}->debug("Job very long regex normalized")
        }
    }

    # 3. compile normalized regex one time
    my $compiled;
    eval {
        $compiled = qr($normalized);
    };

    # 3. Abort job on regex compilation error
    if ($EVAL_ERROR) {
        my ($error) = $EVAL_ERROR =~ /^(.*) at .*/;
        $self->{logger}->error("Aborting File Collect job on regex compilation error".(empty($error)? "" : ": $error"));
        return 1;
    }

    return $compiled;
}

sub results {
    my ($self) = @_;

    my $limit = $self->{limit} || 50;

    my $filter = $self->{filter} // {};

    # Handle case a regex was provided in the job
    my $qrRegex = $self->_compiled_regex($filter->{regex});

    # Abort on regex compilation error
    return if $qrRegex && ref($qrRegex) ne "Regexp";

    return unless !empty($self->{dir}) && -d $self->{dir};

    $self->{logger}->debug("Looking for file under '$self->{dir}' folder");

    my @results;

    File::Find::find(
        {
            wanted => sub {
                if (!$self->{recursive} && $File::Find::name ne $self->{dir}) {
                    $File::Find::prune = 1  # Don't recurse.
                }

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

                return if defined($qrRegex) && $File::Find::name !~ $qrRegex;

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
                goto DONE if @results >= $limit;
            },
            no_chdir => 1

        },
        $self->{dir}
    );
    DONE:

    return \@results;
}

1;
