#!/usr/bin/perl

use strict;
use warnings;

use UNIVERSAL::require;
use Cpanel::JSON::XS;
use Data::Dumper;

use constant    inventory_schema => qw(
    https://raw.githubusercontent.com/glpi-project/inventory_format/master/inventory.schema.json
);

$Data::Dumper::Pad   = "     ";
$Data::Dumper::Terse = 1;

die "JSON::Validator perl module required\n"
    unless JSON::Validator->require();

my $schema = inventory_schema;
if ($ARGV[0] && $ARGV[0] eq "--schema" ) {
    shift @ARGV;
    $schema = shift @ARGV;
    if (-e $schema) {
        print "Loading schema from $schema file...\n";
        $schema = "file://$schema";
    } else {
        die "Schema file not found: $schema\n";
    }
} elsif ($ARGV[0] && $ARGV[0] eq "--help" ) {
    print "$0 [--schema FILE] JSON FILES
        --schema FILE   use given file as JSON schema\n";
    print "\nValidate given json files against GLPI inventory schema or given schema file\n\n";
    exit(0);
} else {
    print "Loading inventory schema from url...\n";
    print $schema,"\n";
}

my $jv = JSON::Validator->new();
$jv->load_and_validate_schema($schema)
    or die "Failed to validate inventory schema against the OpenAPI specification\n";

print "Inventory schema loaded\n---\n";

my $err = 0;
my $fh;
my $parser = Cpanel::JSON::XS->new;

while (@ARGV) {
    my $file = shift @ARGV;
    next unless $file && -e $file;

    print "Validating $file... ";
    open $fh, "<", $file
        or die "Can't read '$file': $!\n";
    my $json = join("",<$fh>);
    close($fh);

    $json = $parser->decode($json);

    my @errors = $jv->validate($json);
    if (@errors) {
        print "ERROR:\n";
        my $count = 1;
        foreach my $error (@errors) {
            print sprintf("% 3d: %s", $count++, $error->path);
            my $value = $json;
            map {
                if (ref($value) eq 'HASH') {
                    $value = $value->{$_};
                } elsif (ref($value) eq 'ARRAY' && $_ =~ /^\d+$/) {
                    $value = $value->[int($_)];
                } else {
                    undef $value;
                }
            } grep { length } split("/", $error->path);
            if (ref($value)) {
                $value = Dumper($value);
                $value =~ s/^\s+//;
                chomp($value);
            }
            $value = "'$value'" if defined($value) && $error->message =~ /^string/i;
            print " => $value" if defined($value);
            print "\n     ", $error->message, "\n";
        }
        $err = 1;
    } else {
        print "OK\n";
    }
}

exit($err);
