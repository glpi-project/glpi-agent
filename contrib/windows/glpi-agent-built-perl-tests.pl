#!perl

use strict;
use warnings;

use File::Spec;
use Cwd qw(abs_path);
use File::Spec::Functions qw(catfile);

use lib abs_path(File::Spec->rel2abs('../packaging', __FILE__));
use PerlBuildJob;

use lib 'lib';
use GLPI::Agent::Version;

# HACK: make "use Perl::Dist::GLPI::Agent::Step::XXX" works as included plugin
map { $INC{"Perl/Dist/GLPI/Agent/Step/$_.pm"} = __FILE__ } qw(Test);

my $provider = $GLPI::Agent::Version::PROVIDER;

sub build_app {
    my ($arch) = @_;

    my $app = Perl::Dist::GLPI::Agent->new(
        arch            => $arch,
        _restore_step   => PERL_BUILD_STEPS,
    );

    $app->parse_options(
        -job            => "glpi-agent built perl test",
        -image_dir      => "C:\\Strawberry-perl-for-$provider-Agent",
        -working_dir    => "C:\\Strawberry-perl-for-$provider-Agent_build",
        -nointeractive,
        -restorepoints,
    );

    return $app;
}

my %do = ();
while ( @ARGV ) {
    my $arg = shift @ARGV;
    if ($arg eq "--arch") {
        my $arch = shift @ARGV;
        next unless $arch =~ /^x(86|64)$/;
        $do{$arch} = 1;
    } elsif ($arg eq "--all") {
        %do = (
            #~ x86 => 32,
            x64 => 64
        );
    }
}

foreach my $arch (keys(%do) || ("x64")) {
    print "Running $arch built perl tests...\n";
    my $app = build_app($arch);
    $app->do_job();
    # global_dump_FINAL.txt must exist in debug_dir if all steps have been passed
    exit(1) unless -e catfile($app->global->{debug_dir}, 'global_dump_FINAL.txt');
}

print "Tests processing passed\n";

exit(0);

package
    Perl::Dist::GLPI::Agent::Step::Test;

use parent 'Perl::Dist::Strawberry::Step';

use File::Spec::Functions qw(catfile catdir);
use File::Glob qw(:glob);

sub run {
    my $self = shift;

    # Update PATH to include perl/bin for DLLs loading
    my $binpath = catfile($self->global->{image_dir}, 'perl/bin');
    $ENV{PATH} .= ":$binpath";

    # Without defined modules, run the tests
    my $perlbin = catfile($binpath, 'perl.exe');

    # Run few checks
    my @checks = (
        "OpenSSL version"   => [ "-MNet::SSLeay", "-e", 'print Net::SSLeay::SSLeay_version(0)," (", sprintf("0x%x",Net::SSLeay::SSLeay()),") installed with perl $^V\n"' ],
        "libxml2 version"   => [ "-MXML::LibXML", "-e", 'print STDERR "Using libxml2 v".XML::LibXML::LIBXML_DOTTED_VERSION()."\n"' ],
    );
    while (@checks) {
        my $check   = shift @checks;
        my $options = shift @checks;
        $self->boss->message(2, "Check: $check");
        unshift @{$options}, $perlbin;
        $self->execute_standard($options);
    }

    my $makefile_pl_cmd = [ $perlbin, "Makefile.PL"];
    $self->boss->message(2, "Test: gonna run perl Makefile.PL");
    my $rv = $self->execute_standard($makefile_pl_cmd);
    die "ERROR: TEST, perl Makefile.PL\n" unless (defined $rv && $rv == 0);
}

sub test {
    my $self = shift;

    # Update PATH to include perl/bin for DLLs loading
    my $binpath = catfile($self->global->{image_dir}, 'perl/bin');
    $ENV{PATH} .= ":$binpath";

    # Without defined modules, run the tests
    my $makebin = catfile($binpath, 'gmake.exe');

    my @test_files = ();
    @test_files = map { bsd_glob($_) } @{$self->{config}->{test_files}}
        if ref($self->{config}->{test_files}) && @{$self->{config}->{test_files}};
    if (@test_files && ref($self->{config}->{skip_tests}) && @{$self->{config}->{skip_tests}}) {
        my %skip_tests = map { $_ => 1 } @{$self->{config}->{skip_tests}};
        @test_files = grep { not $skip_tests{$_} } @test_files;
    }

    # Only test files compilation
    my $make_test_cmd = [ $makebin, "test" ];
    push @{$make_test_cmd}, "TEST_FILES=@test_files" if @test_files;
    $self->boss->message(2, "Test: gonna run gmake test");
    my $rv = $self->execute_standard($make_test_cmd);
    die "ERROR: TEST, make test\n" unless (defined $rv && $rv == 0);
}

package
    Perl::Dist::GLPI::Agent;

use parent qw(Perl::Dist::Strawberry);

use File::Path qw(remove_tree);
use File::Spec::Functions qw(canonpath);
use File::Glob qw(:glob);
use Time::HiRes qw(usleep);
use PerlBuildJob;

sub message {
    my ($self, $level, @msg) = @_;
    # Filter out wrong message
    return if $level == 0 && $msg[0] =~ /restorepoint saved$/;
    $self->SUPER::message($level, @msg);
}

sub make_restorepoint {
    my ($self, $text) = @_;

    my $step = $self->global->{_restore_step};

    return $self->message(3, "skipping restorepoint '$text'\n");
}

sub create_dirs {
    my $self = shift;

    # Make a first pass on removing expected dirs as this may fail for unknown reason
    foreach my $global (qw(image_dir build_dir debug_dir env_dir)) {
        my $dir = $self->global->{$global}
            or next;
        remove_tree($dir) if -d $dir;

        # We may have some issue with fs synchro, be ready to wait a little
        my $timeout = time + 10;
        while (-d $dir && time < $timeout) {
            usleep(100000);
        }
    }

    $self->SUPER::create_dirs();
}

sub ask_about_restorepoint {
    my ($self, $image_dir, $bits) = @_;
    my @points;
    for my $pp (sort(bsd_glob($self->global->{restore_dir}."/*.pp"))) {
        my $d = eval { do($pp) };
        warn "SKIPPING/1 $pp\n" and next unless defined $d && ref($d) eq 'HASH';
        warn "SKIPPING/2 $pp\n" and next unless defined $d->{build_job_steps};
        warn "SKIPPING/3 $pp\n" and next unless defined $d->{restorepoint_info};
        warn "SKIPPING/4 $pp\n" and next unless $d->{restorepoint_zip_image_dir} && -f $d->{restorepoint_zip_image_dir};
        warn "SKIPPING/5 $pp\n" and next unless $d->{restorepoint_zip_debug_dir} && -f $d->{restorepoint_zip_debug_dir};
        warn "SKIPPING/6 $pp\n" and next unless canonpath($d->{image_dir}) eq canonpath($image_dir);
        warn "SKIPPING/7 $pp\n" and next unless $d->{bits} == $bits;
        push @points, $d;
    }

    # Select the restore point at expected step
    my $step = $self->global->{_restore_step};
    my ($restorepoint) = grep { $_->{build_job_steps}->[$step]->{done} && ! $_->{build_job_steps}->[$step+1]->{done} } @points;
    die "ERROR: restorepoint from built perl is required\n" unless $restorepoint;

    return $restorepoint;
}

sub create_buildmachine {
    my ($self, $job, $restorepoint) = @_;
    my $h;
    my $counter = 0;

    $h = delete $job->{build_job_steps};
    for my $s (@$h) {
        my $p = delete $s->{plugin};
        my $n = eval "use $p; $p->new()";
        die "ERROR: invalid plugin '$p'\n$@" unless $n;
        $n->{boss} = $self;
        $n->{config} = $s;
        $n->{data} = { done=>0, plugin=>$p, output=>undef };
        push @{$self->{build_job_steps}}, $n;
    }
    $counter += scalar(@$h);

    # store remaining job data into global-hash
    while (my ($k, $v) = each %$job) {
        if (my $vv = $self->global->{$k}) {
            $self->message(2, "parameter '$k=$vv' overridden from commandline");
            $job->{$k} = $vv;
        } else {
            $self->global->{$k} = $v;
        }
    }

    if ($restorepoint) {
        my $i;
        my $start_time = time;
        $self->message(0, "loading RESTOREPOINT=$restorepoint->{restorepoint_info}\n");

        $self->unzip_dir($restorepoint->{restorepoint_zip_debug_dir}, $self->global->{debug_dir});
        $self->unzip_dir($restorepoint->{restorepoint_zip_image_dir}, $self->global->{image_dir});

        $self->message(0, sprintf("RESTOREPOINT loaded in %.2f minutes\n", (time-$start_time)/60));
    } else {
        $self->message(0, "new build machine created, total steps=$counter");
    }
}

sub load_jobfile {
    my ($self, $arch) = @_;

    return {
        bits            => $self->global->{arch} eq 'x64' ? 64 : 32,
        build_job_steps => [
            ### STEP 0 Run GLPI Agent test suite ##############################
            {
                plugin      => 'Perl::Dist::GLPI::Agent::Step::Test',
                # By default all possible test will be run
                test_files  => [
                    #~ qw(t/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t t/*/*/*/*/*.t t/*/*/*/*/*/*.t)
                    qw(t/*.t)
                ],
                skip_tests  => [
                    # Fails if not run as administrator
                    #~ qw(t/agent/config.t)
                ],
            },
        ],
    };
}
