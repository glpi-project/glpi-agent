#!/usr/bin/perl

use strict;
use warnings;

use Archive::Zip          qw(:ERROR_CODES);
use File::Copy::Recursive qw(fmove);
use File::Spec::Functions qw(catdir catfile);
use LWP::UserAgent;

my @CodeSignTool = qw(CodeSignTool-v1.2.0-windows https://www.ssl.com/download/29773/);

my ($folder, $msifile) = @ARGV;

die "No base folder given\n" unless $folder;
die "No MSI filename given\n" unless $msifile;

die "No such '$folder' base folder\n" unless -d $folder;

my $output_file = catfile($folder, 'output', $msifile);
die "No such '$output_file' msi file\n" unless -e $output_file;

if ($ENV{CST_CREDENTIALID} && $ENV{CST_USERNAME} && $ENV{CST_PASSWORD} && $ENV{CST_SECRET}) {
    my $signed_folder = catdir($folder, 'download');
    my $signed_file = catfile($signed_folder, $msifile);
    chdir $folder;
    mkdir 'download' unless -d 'download';
    mkdir 'tools' unless -d 'tools';
    unless (-d 'tools/CodeSignTool') {
        my $zipfile = "download/".$CodeSignTool[0].".zip";
        _mirror($zipfile, $CodeSignTool[1]) unless -e $zipfile;
        print "Extracting $zipfile archive...\n";
        my $zip = Archive::Zip->new($zipfile);
        die "Could not open archive $zipfile for extraction\n" unless defined $zip;
        die "Failed to extract $zipfile\n"
            unless $zip->extractTree( $CodeSignTool[0], 'tools/CodeSignTool' ) == AZ_OK;
        die "Nothing extracted from $zipfile\n"
            unless -d 'tools/CodeSignTool';
    }
    chdir 'tools/CodeSignTool'
        or die "Can't cd to CodeSignTool: $!\n";
    print "Running CodeSignTool.bat sign ...\n";
    my $codesigntool_cmd = 'CodeSignTool.bat sign ' .
        '-username="'.$ENV{CST_USERNAME}.'" -password="'.$ENV{CST_PASSWORD}.'" ' .
        '-credential_id="'.$ENV{CST_CREDENTIALID}.'" -totp_secret="'.$ENV{CST_SECRET}.'" ' .
        '-input_file_path="'.$output_file.'" -output_dir_path="'.$signed_folder.'"';
    system($codesigntool_cmd) == 0
        or die "\nCodeSignTool failure: $!\n";
    die "\nCodeSignTool failed to sign\n" unless -e $signed_file;
    print "Updating $msifile with signed version\n";
    fmove($signed_file, $output_file)
        or die "Failed to move '$signed_file' to '$output_file': $!\n";
} else {
    print "No authority setup to sign '$output_file', skipping\n";
}

exit(0);

sub _mirror {
    my ($file, $url) = @_;

    print "Downloading file '$url'...\n";
    my $ua = LWP::UserAgent->new(env_proxy=>1);
    my $r = $ua->mirror( $url, $file );
    die "Error getting $url:\n" . $r->as_string . "\n" if $r->is_error;
    print "Already up to date\n" if $r->code == HTTP::Status::RC_NOT_MODIFIED;
}
