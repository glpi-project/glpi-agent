#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use File::Temp;

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Task::Inventory::Linux::AntiVirus::ClamAV;

my %sample = (
    clamscan_version    => "ClamAV 1.4.3/28046/Mon Jun 29 03:27:20 2026",
    clamscan_is_active  => "active",
    freshclam_is_active => "inactive",
    freshclam_status    => "● clamav-freshclam.service - ClamAV virus database updater
     Loaded: loaded (/usr/lib/systemd/system/clamav-freshclam.service; disabled; preset: enabled)
     Active: active (running) since Fri 2026-07-03 17:20:08 -03; 40s ago
 Invocation: f7cc51ecd9c44f3d9804f390de00eebe
       Docs: man:freshclam(1)
             man:freshclam.conf(5)
             https://docs.clamav.net/
   Main PID: 639242 (freshclam)
      Tasks: 1 (limit: 18677)
     Memory: 3M (peak: 3.5M)
        CPU: 16ms
     CGroup: /system.slice/clamav-freshclam.service
             └─639242 /usr/bin/freshclam -d --foreground=true

jul 03 17:20:08 INFRA02 systemd[1]: Started clamav-freshclam.service - ClamAV virus database updater.
jul 03 17:20:08 INFRA02 freshclam[639242]: Fri Jul  3 17:20:08 2026 -> ClamAV update process started at Fri Jul  3 17:20:08 2026
jul 03 17:20:08 INFRA02 freshclam[639242]: Fri Jul  3 17:20:08 2026 -> daily.cld database is up-to-date (version: 28049, sigs: 355485, f-level: 9>
jul 03 17:20:08 INFRA02 freshclam[639242]: Fri Jul  3 17:20:08 2026 -> main.cld database is up-to-date (version: 63, sigs: 3287027, f-level: 90, >
jul 03 17:20:08 INFRA02 freshclam[639242]: Fri Jul  3 17:20:08 2026 -> bytecode.cld database is up-to-date (version: 339, sigs: 80, f-level: 90, >
");

my %av_outputs = (
    'clamav-1.4.3-28046-active' => {
        %sample,
        freshclam_is_active => "active",
    },
    'clamav-1.4.3-28046-expired' => {
        %sample,
        dbfile_time => 5 * 86400,
    },
    'clamav-1.4.4-28066-up-to-date' => {
        %sample,
        clamscan_version    => "ClamAV 1.4.4/28066/Mon Jul 20 08:24:24 2026",
        clamscan_is_active  => "",
        freshclam_status    => "○ clamav-freshclam.service - ClamAV virus database updater
     Loaded: loaded (/usr/lib/systemd/system/clamav-freshclam.service; disabled; preset: disabled)
    Drop-In: /usr/lib/systemd/system/service.d
             └─10-timeout-abort.conf
     Active: inactive (dead)
       Docs: man:freshclam(1)
             man:freshclam.conf(5)
             https://docs.clamav.net/
",
        dbfile_time => 86400,
    },
);

my %av_tests = (
    'clamav-1.4.3-28046-active' => {
        COMPANY         => "Cisco Systems / Open Source",
        NAME            => "ClamAV",
        ENABLED         => 1,
        UPTODATE        => 1,
        VERSION         => "1.4.3",
        BASE_VERSION    => "28046",
    },
    'clamav-1.4.3-28046-expired' => {
        COMPANY         => "Cisco Systems / Open Source",
        NAME            => "ClamAV",
        ENABLED         => 1,
        UPTODATE        => 0,
        VERSION         => "1.4.3",
        BASE_VERSION    => "28046",
    },
    'clamav-1.4.4-28066-up-to-date' => {
        COMPANY         => "Cisco Systems / Open Source",
        NAME            => "ClamAV",
        ENABLED         => 0,
        UPTODATE        => 1,
        VERSION         => "1.4.4",
        BASE_VERSION    => "28066",
    },
);

plan tests =>
    (2 * scalar keys %av_tests) +
    1;

foreach my $test (keys %av_tests) {
    my $inventory = GLPI::Test::Inventory->new();
    my $fh = File::Temp->new(
        "daily-XXXXXXXX",
        SUFFIX  => ".cvd",
        TMPDIR  => 1
    );
    my $db_testfile = $fh->filename;
    print $fh "TOUCH";
    close($fh);

    my $touch = time - ($av_outputs{$test}->{dbfile_time} // 0);
    utime $touch, $touch, $db_testfile;

    my $antivirus = GLPI::Agent::Task::Inventory::Linux::AntiVirus::ClamAV::_getClamAVInfo(
        %{$av_outputs{$test}},
        db_file => $db_testfile,
    );

    cmp_deeply($antivirus, $av_tests{$test}, "$test: parsing");

    lives_ok {
        $inventory->addEntry(section => 'ANTIVIRUS', entry => $antivirus);
    } "$test: registering";
}
