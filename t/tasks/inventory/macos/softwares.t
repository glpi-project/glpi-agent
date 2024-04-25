#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

# Tests are encoded in utf8 in this file
use utf8;
use Data::Dumper;

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Tools qw(getAllLines);
use GLPI::Agent::Task::Inventory::MacOS::Softwares;

use English;

my %tests = (
    'sample1' => [
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '4.7.3',
            'COMMENTS' => '[Intel]',
            'NAME' => 'BigTop',
            'SYSTEM_CATEGORY' => 'Developer/Applications'
        },
        {
            'VERSION' => '4.2',
            'INSTALLDATE' => '09/04/2011',
            'COMMENTS' => '[Universal]',
            'NAME' => 'OpenGL Profiler',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.1',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Type5Camera',
            'COMMENTS' => '[Universal]'
        },
        {
            'INSTALLDATE' => '12/12/2005',
            'VERSION' => '11.2.0',
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive',
            'COMMENTS' => '[PowerPC]',
            'NAME' => 'Microsoft Office Notifications'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'CCacheServer',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.5.11',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'VERSION' => '0.13.0',
            'INSTALLDATE' => '10/22/2010',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Git Gui',
            'SYSTEM_CATEGORY' => 'usr/local',
            'PUBLISHER' => 'Shawn Pearce'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Image Capture Extension',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.1',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'INSTALLDATE' => '05/19/2009',
            'VERSION' => '2.2',
            'PUBLISHER' => 'Apple',
            'NAME' => "Utilitaire d\x{2019}annuaire",
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Type7Camera'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'UnmountAssistantAgent',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.0',
            'INSTALLDATE' => '07/03/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'NAME' => 'License',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '07/25/2009',
            'VERSION' => 11
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Type6Camera',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.0',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.7.1',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'MallocDebug',
            'COMMENTS' => '[Universal]'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '4.0',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Help Indexer',
            'COMMENTS' => '[Intel]'
        },
        {
            'INSTALLDATE' => '05/19/2009',
            'VERSION' => '1.1.1',
            'PUBLISHER' => 'Apple',
            'NAME' => 'URL Access Scripting',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '3.8.1',
            'INSTALLDATE' => '09/04/2011',
            'NAME' => 'Speech Startup',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '04/05/2007',
            'VERSION' => '2.51',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Big Bang Backgammon',
            'SYSTEM_CATEGORY' => 'Applications/Big Bang Board Games'
        },
        {
            'INSTALLDATE' => '05/19/2009',
            'VERSION' => '10.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'eaptlstrust',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '6.1',
            'INSTALLDATE' => '09/04/2011',
            'NAME' => 'Type8Camera',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/TeX',
            'NAME' => 'TeX Live Utility',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '10/06/2009',
            'VERSION' => '0.65'
        },
        {
            'VERSION' => '2.3.6',
            'INSTALLDATE' => '09/04/2011',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Bluetooth Diagnostics Utility',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'WebKitPluginHost_0',
            'SYSTEM_CATEGORY' => 'Developer/SDKs',
            'PUBLISHER' => 'Apple',
            'VERSION' => undef,
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'VERSION' => '3.5.0',
            'INSTALLDATE' => '09/04/2011',
            'NAME' => 'Utilitaire VoiceOver',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications/Utilities'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '4.1',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Quartz Debug',
            'SYSTEM_CATEGORY' => 'Developer/Applications'
        },
        {
            'VERSION' => '2.3',
            'INSTALLDATE' => '09/04/2011',
            'COMMENTS' => '[Intel]',
            'NAME' => 'quicklookd',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Big Bang Board Games',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Big Bang Checkers',
            'INSTALLDATE' => '04/05/2007',
            'VERSION' => '2.51'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'NAME' => 'Match',
            'COMMENTS' => '[Universal]',
            'VERSION' => undef,
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Front Row',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2.2.1',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'VERSION' => '3.0.3',
            'INSTALLDATE' => '09/04/2011',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Configuration audio et MIDI',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'PUBLISHER' => 'Apple'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Chess',
            'INSTALLDATE' => '05/19/2009',
            'VERSION' => '2.4.2'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.3',
            'NAME' => 'Pixie',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Developer/Applications'
        },
        {
            'VERSION' => '6.6',
            'INSTALLDATE' => '09/04/2011',
            'COMMENTS' => '[Universal]',
            'NAME' => 'PrinterProxy',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive',
            'NAME' => 'Microsoft Cert Manager',
            'COMMENTS' => '[PowerPC]',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '050929',
            'INSTALLDATE' => '12/22/2005'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Mail',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '4.5'
        },
        {
            'VERSION' => '3.0.3',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'ScreenSaverEngine',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.3.6',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Bluetooth Explorer',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Developer/Applications'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'LexmarkCUPSDriver',
            'COMMENTS' => '[Intel]',
            'PUBLISHER' => 'Lexmark International',
            'VERSION' => '1.1.26',
            'INSTALLDATE' => '07/01/2009'
        },
        {
            'VERSION' => '4.0',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Quartz Composer',
            'COMMENTS' => '[Intel]'
        },
        {
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'PubSubAgent',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/17/2012',
            'VERSION' => '1.0.5'
        },
        {
            'VERSION' => '4.0',
            'INSTALLDATE' => '06/27/2009',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => "Programme d\x{2019}installation",
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Java VisualVM',
            'SYSTEM_CATEGORY' => 'usr/share',
            'INSTALLDATE' => '02/17/2012',
            'VERSION' => '13.6.0'
        },
        {
            'PUBLISHER' => 'SEIKO EPSON',
            'COMMENTS' => '[Intel]',
            'NAME' => 'commandtoescp',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '07/09/2009',
            'VERSION' => '8.02'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.3',
            'PUBLISHER' => 'Apple',
            'NAME' => 'TCIM',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'X11',
            'VERSION' => '2.3.6',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'NAME' => 'Officejet',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '06/16/2009',
            'VERSION' => '3.0'
        },
        {
            'INSTALLDATE' => '06/15/2009',
            'VERSION' => '1.7.1',
            'PUBLISHER' => 'CANON INC.',
            'NAME' => 'CIJAutoSetupTool',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Library/Printers'
        },
        {
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'SecurityProxy',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '05/21/2009',
            'VERSION' => '1.0'
        },
        {
            'PUBLISHER' => 'Microsoft',
            'NAME' => 'Microsoft Excel',
            'COMMENTS' => '[PowerPC]',
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive',
            'INSTALLDATE' => '12/12/2005',
            'VERSION' => '11.2.0'
        },
        {
            'VERSION' => '1.7',
            'INSTALLDATE' => '09/04/2011',
            'NAME' => 'Dashboard',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '10.6.0',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Informations Système',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications/Utilities'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'PhotosmartPro',
            'COMMENTS' => '[Intel]',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'VERSION' => '3.0',
            'INSTALLDATE' => '06/16/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'OpenGL Shader Builder',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.1'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Assistant réglages Bluetooth',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2.4.5',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.4.1',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => "Utilitaire d\x{2019}emplacement d\x{2019}extension",
            'COMMENTS' => '[Intel]'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Configuration actions de dossier',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.1.4',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'VERSION' => 20,
            'INSTALLDATE' => '02/17/2012',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Language Chooser',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '1.0.2',
            'INSTALLDATE' => '12/13/2006',
            'COMMENTS' => '[PowerPC]',
            'NAME' => 'Bienvenue sur Tiger',
            'SYSTEM_CATEGORY' => 'Library/Documentation'
        },
        {
            'VERSION' => '5.0.4',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'HelpViewer',
            'COMMENTS' => '[Intel]',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '02/17/2012',
            'VERSION' => 6534,
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'WebKitPluginHost',
            'COMMENTS' => '[Intel]'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'Canon IJScanner1',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'PUBLISHER' => 'CANON INC.',
            'VERSION' => '1.0.0',
            'INSTALLDATE' => '06/15/2009'
        },
        {
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive',
            'NAME' => 'Microsoft Graph',
            'COMMENTS' => '[PowerPC]',
            'INSTALLDATE' => '12/12/2005',
            'VERSION' => '11.2.0'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.1.1',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Installation à distance de Mac OS X',
            'COMMENTS' => '[Intel]'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Apple80211Agent',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.2.2'
        },
        {
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Intel]',
            'NAME' => 'FileSyncAgent',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '5.0.3'
        },
        {
            'INSTALLDATE' => '07/09/2009',
            'VERSION' => '8.02',
            'PUBLISHER' => 'SEIKO EPSON',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'EPIJAutoSetupTool2',
            'COMMENTS' => '[Intel]'
        },
        {
            'INSTALLDATE' => '05/19/2009',
            'VERSION' => '7.0',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Aide-mémoire',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'INSTALLDATE' => '02/17/2009',
            'VERSION' => '1.0.2',
            'COMMENTS' => '[Universal]',
            'NAME' => "Guide de l\x{2019}utilisateur de Keynote",
            'SYSTEM_CATEGORY' => 'Library/Documentation'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.5.4',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Python',
            'COMMENTS' => '[Universal]'
        },
        {
            'NAME' => 'Python Launcher_0',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2.6.1',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '3.8.1',
            'PUBLISHER' => 'Apple',
            'NAME' => 'SpeechFeedbackWindow',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '3.0.4',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'COMMENTS' => '[Intel]',
            'NAME' => 'PackageMaker'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Console',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '10.6.3'
        },
        {
            'INSTALLDATE' => '02/17/2012',
            'VERSION' => '13.6.0',
            'SYSTEM_CATEGORY' => 'usr/share',
            'NAME' => "Lanceur d\x{2019}applets",
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Spin Control',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '0.9'
        },
        {
            'VERSION' => '3.0.2',
            'INSTALLDATE' => '02/17/2009',
            'SYSTEM_CATEGORY' => 'Applications/iWork \'06',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Keynote',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/TeX',
            'NAME' => 'TeXShop',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '10/06/2009',
            'VERSION' => '2.26'
        },
        {
            'VERSION' => '10.6',
            'INSTALLDATE' => '07/31/2009',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Assistant réglages',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'check_afp',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2.1',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'VERSION' => '3.5.0',
            'INSTALLDATE' => '09/04/2011',
            'COMMENTS' => '[Universal]',
            'NAME' => 'VoiceOver',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'iChat',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => '5.0.3',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'OBEXAgent',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.4.5'
        },
        {
            'VERSION' => '3.2.6',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Interface Builder',
            'COMMENTS' => '[Intel]'
        },
        {
            'VERSION' => '2.4.5',
            'INSTALLDATE' => '09/04/2011',
            'COMMENTS' => '[Universal]',
            'NAME' => 'AVRCPAgent',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '2.0',
            'INSTALLDATE' => '06/16/2009',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Inkjet3',
            'PUBLISHER' => 'Hewlett-Packard Development Company'
        },
        {
            'INSTALLDATE' => '06/15/2009',
            'VERSION' => '1.0.0',
            'PUBLISHER' => 'CANON INC.',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'COMMENTS' => '[Intel]',
            'NAME' => 'CIJScannerRegister'
        },
        {
            'VERSION' => '2.7',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'COMMENTS' => '[Intel]',
            'NAME' => 'SleepX'
        },
        {
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Spaces',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.1'
        },
        {
            'INSTALLDATE' => '06/11/2009',
            'VERSION' => '2.0',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'KeyboardViewer',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'BluetoothCamera',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.0.1'
        },
        {
            'PUBLISHER' => 'Samsung Electronics Co.',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Samsung Scanner',
            'INSTALLDATE' => '07/01/2009',
            'VERSION' => '2.00.29'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'PluginProcess',
            'INSTALLDATE' => '02/17/2012',
            'VERSION' => '6534.52'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Premiers contacts avec GarageBand',
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'VERSION' => '1.0.2',
            'INSTALLDATE' => '10/15/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive',
            'COMMENTS' => '[PowerPC]',
            'NAME' => 'Microsoft PowerPoint',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '11.2.0',
            'INSTALLDATE' => '12/12/2005'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.7',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Dock'
        },
        {
            'PUBLISHER' => 'SEIKO EPSON',
            'NAME' => 'pdftopdf2',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '07/09/2009',
            'VERSION' => '8.02'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'PreferenceSyncClient',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '07/02/2009',
            'VERSION' => '2.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ScreenReaderUIServer',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '3.5.0'
        },
        {
            'VERSION' => '8.4.19',
            'INSTALLDATE' => '07/23/2009',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Wish',
            'COMMENTS' => '[Intel]',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'KerberosAgent',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.5.11',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'NAME' => 'Préférences Système',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '7.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => "Utilitaire d\x{2019}emplacement de m\x{e9}moire",
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.4.1',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'VERSION' => '3.0.4',
            'INSTALLDATE' => '09/04/2011',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Assistant migration',
            'SYSTEM_CATEGORY' => 'Applications/Utilities'
        },
        {
            'INSTALLDATE' => '02/17/2012',
            'VERSION' => '5.0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'AppleMobileSync'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Automator Launcher',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.2',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'ARM Help',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.7.3',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'Python_0',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.6'
        },
        {
            'INSTALLDATE' => '05/19/2009',
            'VERSION' => '1.2',
            'NAME' => 'ChineseTextConverterService',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'INSTALLDATE' => '04/05/2007',
            'VERSION' => '2.51',
            'NAME' => 'Big Bang Tic-Tac-Toe',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications/Big Bang Board Games'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Ticket Viewer',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.0',
            'INSTALLDATE' => '05/19/2009'
        },
        {
            'INSTALLDATE' => '07/23/2009',
            'VERSION' => '8.5.7',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Wish_0',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'ImageCaptureService',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.0.1',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'VERSION' => '3.0',
            'INSTALLDATE' => '09/04/2011',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Assistant de certification',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '1.1',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Front Row_0',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'CoreServicesUIAgent',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '41.5',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Éditeur AppleScript',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '04/24/2009',
            'VERSION' => '2.3'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '3.11.1',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Intel]',
            'NAME' => 'SpeechRecognitionServer',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Utilitaire AirPort',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '5.5.3'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'System Events',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.3.4'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'DiskImageMounter',
            'COMMENTS' => '[Intel]',
            'PUBLISHER' => 'Apple',
            'VERSION' => '10.6.8',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'NAME' => 'VoiceOver Quickstart',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '3.5.0',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '10.6.8',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Finder',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '4.7.3',
            'COMMENTS' => '[Intel]',
            'NAME' => 'CPUPalette',
            'SYSTEM_CATEGORY' => 'Library/Application Support'
        },
        {
            'NAME' => 'HP Utility',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'VERSION' => '4.6.1',
            'INSTALLDATE' => '06/23/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'COMMENTS' => '[Intel]',
            'NAME' => 'IA32 Help',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '4.7.3'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Transfert de podcast',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.0.2'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'ServerJoiner',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '10.6.3'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '5.4',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Lecteur DVD',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Java Web Start',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/17/2012',
            'VERSION' => '13.6.0'
        },
        {
            'NAME' => 'Reggie SE',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'VERSION' => '4.7.3',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'TamilIM',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/19/2009',
            'VERSION' => '1.3'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.1',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'PTPCamera'
        },
        {
            'NAME' => "Outil d\x{2019}\x{e9}talonnage du moniteur",
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '4.6',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'NAME' => 'iCal',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => '4.0.4',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'VERSION' => undef,
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'NAME' => 'Embed',
            'COMMENTS' => '[Universal]'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.3',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Repeat After Me',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Developer/Applications'
        },
        {
            'INSTALLDATE' => '05/19/2009',
            'VERSION' => '2.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Service de résumé',
            'COMMENTS' => '[Intel]'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.0.4',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Database Events'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Lexmark Scanner',
            'INSTALLDATE' => '07/01/2009',
            'VERSION' => '3.2.45'
        },
        {
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Inkjet4',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '06/16/2009',
            'VERSION' => '2.2'
        },
        {
            'VERSION' => '10.6',
            'INSTALLDATE' => '05/19/2009',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'SecurityFixer',
            'COMMENTS' => '[Intel]',
            'PUBLISHER' => 'Apple'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'syncuid',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5.2',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'VERSION' => '6.0.4',
            'INSTALLDATE' => '02/17/2009',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'iDVD',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Colorimètre numérique',
            'COMMENTS' => '[Intel]',
            'PUBLISHER' => 'Apple',
            'VERSION' => '3.7.2',
            'INSTALLDATE' => '05/28/2009'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[Intel]',
            'NAME' => "Transfert d\x{2019}images",
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.0.1'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.2.2',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Livre des polices',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'VERSION' => '3.10.35',
            'INSTALLDATE' => '07/12/2009',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'SpeechService'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'KeyboardSetupAssistant',
            'INSTALLDATE' => '05/19/2009',
            'VERSION' => '10.5.0'
        },
        {
            'VERSION' => '1.5',
            'INSTALLDATE' => '09/04/2011',
            'COMMENTS' => '[Intel]',
            'NAME' => 'OpenGL Driver Monitor',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '1.0.2',
            'INSTALLDATE' => '02/17/2009',
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'NAME' => 'Premiers contacts avec iDVD',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '2.5',
            'INSTALLDATE' => '09/04/2011',
            'COMMENTS' => '[Universal]',
            'NAME' => 'ManagedClient',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive',
            'COMMENTS' => '[PowerPC]',
            'NAME' => 'Microsoft Clip Gallery',
            'INSTALLDATE' => '12/12/2005',
            'VERSION' => '11.2.0'
        },
        {
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Printer Setup Utility',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.6'
        },
        {
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Utilitaire de disque',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '11.5.2'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'NAME' => 'Extract',
            'COMMENTS' => '[Universal]',
            'VERSION' => undef,
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => "Agent de la borne d\x{2019}acc\x{e8}s AirPort",
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.5.5',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'ARDAgent',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '3.5.2',
            'INSTALLDATE' => '02/17/2012'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Jar Bundler',
            'SYSTEM_CATEGORY' => 'usr/share',
            'VERSION' => '13.6.0',
            'INSTALLDATE' => '02/17/2012'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Échange de fichiers Bluetooth',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2.4.5',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'INSTALLDATE' => '06/30/2009',
            'VERSION' => '1.0.3',
            'NAME' => '50onPaletteServer',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'INSTALLDATE' => '04/07/2009',
            'VERSION' => '2.1',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Grapher',
            'COMMENTS' => '[Intel]'
        },
        {
            'INSTALLDATE' => '02/17/2009',
            'VERSION' => '1.0.2',
            'NAME' => "Guide de l\x{2019}utilisateur de Pages",
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Library/Documentation'
        },
        {
            'INSTALLDATE' => '05/19/2009',
            'VERSION' => '1.1',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'PluginIM'
        },
        {
            'VERSION' => '3.1.0',
            'INSTALLDATE' => '05/19/2009',
            'COMMENTS' => '[Intel]',
            'NAME' => 'UserNotificationCenter',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '02/17/2012',
            'VERSION' => '13.6.0',
            'NAME' => 'Préférences Java',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications/Utilities'
        },
        {
            'NAME' => 'FileMerge',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'VERSION' => '2.5',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '4.7.3',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'COMMENTS' => '[Intel]',
            'NAME' => 'PowerPC Help'
        },
        {
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'SyncServer',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '5.2'
        },
        {
            'INSTALLDATE' => '06/15/2009',
            'VERSION' => '1.0.0',
            'PUBLISHER' => 'CANON INC.',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Canon IJScanner2'
        },
        {
            'VERSION' => '2.4.5',
            'INSTALLDATE' => '09/04/2011',
            'COMMENTS' => '[Universal]',
            'NAME' => 'BluetoothAudioAgent',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[Universal]',
            'NAME' => 'iTunes',
            'INSTALLDATE' => '02/17/2012',
            'VERSION' => '10.5.3'
        },
        {
            'INSTALLDATE' => '06/16/2009',
            'VERSION' => '2.1',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Inkjet8'
        },
        {
            'INSTALLDATE' => '07/01/2009',
            'VERSION' => '1.2.10',
            'PUBLISHER' => 'Lexmark International',
            'NAME' => 'Utilitaire de l\'imprimante Lexmark',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Library/Printers'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'USB Prober',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'PUBLISHER' => 'Apple',
            'VERSION' => '4.0.0',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'MacVim',
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => '7.3',
            'INSTALLDATE' => '08/15/2010'
        },
        {
            'VERSION' => '1.0.2',
            'INSTALLDATE' => '02/17/2009',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Premiers contacts avec iMovie',
            'SYSTEM_CATEGORY' => 'Library/Documentation'
        },
        {
            'VERSION' => '3.2.6',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Xcode',
            'COMMENTS' => '[Universal]'
        },
        {
            'NAME' => 'Automator Runner',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.1',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '4.3',
            'PUBLISHER' => 'Apple',
            'NAME' => 'SCIM',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'EM64T Help',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '4.7.3'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Build Applet_0',
            'PUBLISHER' => 'Python Software Foundation.',
            'VERSION' => '2.6.0',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'COMMENTS' => '[Intel]',
            'NAME' => 'EPSON Scanner',
            'PUBLISHER' => 'EPSON',
            'VERSION' => '5.0',
            'INSTALLDATE' => '07/09/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'CharacterPalette',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0.4',
            'INSTALLDATE' => '07/02/2009'
        },
        {
            'INSTALLDATE' => '04/05/2007',
            'VERSION' => '2.51',
            'NAME' => 'Big Bang 4-In-A-Row',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications/Big Bang Board Games'
        },
        {
            'COMMENTS' => '[PowerPC]',
            'NAME' => 'Microsoft Entourage',
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '11.2.1',
            'INSTALLDATE' => '12/12/2005'
        },
        {
            'VERSION' => '3.0',
            'INSTALLDATE' => '06/18/2009',
            'NAME' => 'Deskjet',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'Hewlett-Packard Development Company'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive',
            'COMMENTS' => '[PowerPC]',
            'NAME' => 'Microsoft Word',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '11.2.0',
            'INSTALLDATE' => '12/12/2005'
        },
        {
            'INSTALLDATE' => '10/23/2010',
            'VERSION' => 169,
            'COMMENTS' => '[Universal]',
            'NAME' => 'About Xcode',
            'SYSTEM_CATEGORY' => 'Developer'
        },
        {
            'SYSTEM_CATEGORY' => 'usr/libexec',
            'NAME' => 'MiniTerm',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.5'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ODSAgent',
            'COMMENTS' => '[Intel]',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.4.1',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Canon IJ Printer Utility',
            'PUBLISHER' => 'CANON INC.',
            'VERSION' => '7.17.10',
            'INSTALLDATE' => '06/15/2009'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'Icon Composer',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'VERSION' => '2.1.1',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'INSTALLDATE' => '05/19/2009',
            'VERSION' => '1.3',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Yahoo! Sync'
        },
        {
            'VERSION' => '1.1.2',
            'INSTALLDATE' => '02/17/2009',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'iWeb',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '10/06/2009',
            'VERSION' => '4.0.7',
            'NAME' => 'Excalibur',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications/TeX'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'HPFaxBackend',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'VERSION' => '3.1.0',
            'INSTALLDATE' => '07/25/2009'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.1.1',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => "Partage d\x{2019}\x{e9}cran",
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'iSync Plug-in Maker',
            'COMMENTS' => '[Universal]',
            'VERSION' => '3.1',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'rastertoescpII',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'SEIKO EPSON',
            'VERSION' => '8.02',
            'INSTALLDATE' => '07/09/2009'
        },
        {
            'VERSION' => '1.0',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'store_helper'
        },
        {
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Inkjet1',
            'INSTALLDATE' => '06/16/2009',
            'VERSION' => '2.1.2'
        },
        {
            'VERSION' => '1.0',
            'INSTALLDATE' => '05/19/2009',
            'NAME' => 'wxPerl_0',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Kotoeri',
            'COMMENTS' => '[Universal]',
            'VERSION' => '4.2.1',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.2',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Accessibility Verifier',
            'COMMENTS' => '[Intel]'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '3.0.3',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Photo Booth',
            'COMMENTS' => '[Intel]'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Image Capture Web Server',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.0',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'NAME' => 'iChatAgent',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5.0.3',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'NAME' => 'iPhoto',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.0.6',
            'INSTALLDATE' => '02/17/2009'
        },
        {
            'INSTALLDATE' => '12/12/2005',
            'VERSION' => '040322',
            'PUBLISHER' => 'Microsoft',
            'COMMENTS' => '[PowerPC]',
            'NAME' => 'Alerts Daemon',
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'Assistant réglages de réseau',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '05/19/2009',
            'VERSION' => '1.6'
        },
        {
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Assistant Boot Camp',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '3.0.4'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'Type2Camera',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.0'
        },
        {
            'VERSION' => '10.0.0',
            'INSTALLDATE' => '12/12/2005',
            'COMMENTS' => '[PowerPC]',
            'NAME' => 'Microsoft Query',
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive',
            'PUBLISHER' => 'Microsoft'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[Intel]',
            'NAME' => 'iSync',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '3.1.2'
        },
        {
            'NAME' => 'Utilitaire AppleScript',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.1.1',
            'INSTALLDATE' => '05/19/2009'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Premiers contacts avec iPhoto',
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'INSTALLDATE' => '02/17/2009',
            'VERSION' => '1.0.2'
        },
        {
            'INSTALLDATE' => '05/19/2009',
            'VERSION' => '3.7.8',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'SpeakableItems'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'Utilitaire de réseau',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.4.6',
            'INSTALLDATE' => '06/25/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[Universal]',
            'NAME' => 'GarageBand',
            'PUBLISHER' => 'Apple',
            'VERSION' => '3.0.5',
            'INSTALLDATE' => '10/15/2009'
        },
        {
            'VERSION' => '2.5.4',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Python Launcher',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '4.0.4',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'iCal Helper',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.1.3',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Diagnostic réseau',
            'COMMENTS' => '[Universal]'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.0.4',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'AddressBookManager'
        },
        {
            'INSTALLDATE' => '07/31/2009',
            'VERSION' => '10.6',
            'COMMENTS' => '[Intel]',
            'NAME' => "Moniteur d\x{2019}activit\x{e9}",
            'SYSTEM_CATEGORY' => 'Applications/Utilities'
        },
        {
            'VERSION' => '5.0',
            'INSTALLDATE' => '02/17/2012',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'AppleMobileDeviceHelper',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.0.4',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AddressBookSync',
            'COMMENTS' => '[Intel]'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => "Carnet d\x{2019}adresses",
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => '5.0.3',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Dictionnaire',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.1.3'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '4.7.3',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'COMMENTS' => '[Intel]',
            'NAME' => 'CHUD Remover'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Exposé',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.1'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '10.6',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => "Utilitaire d\x{2019}archive"
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'rcd',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.6'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'KoreanIM',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.1',
            'INSTALLDATE' => '05/05/2009'
        },
        {
            'VERSION' => '3.10.35',
            'INSTALLDATE' => '07/12/2009',
            'NAME' => 'SpeechSynthesisServer',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '10.6.3',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'COMMENTS' => '[Universal]',
            'NAME' => 'CrashReporterPrefs'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Safari',
            'COMMENTS' => '[Intel]',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5.1.2',
            'INSTALLDATE' => '02/17/2012'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'InkServer',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.0',
            'INSTALLDATE' => '05/19/2009'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.0.1',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ChineseHandwriting',
            'COMMENTS' => '[Intel]'
        },
        {
            'NAME' => 'Core Image Fun House',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'VERSION' => '2.1.43',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'LaTeXiT',
            'SYSTEM_CATEGORY' => 'Applications/TeX',
            'INSTALLDATE' => '10/06/2009',
            'VERSION' => '1.16.1'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Big Bang Board Games',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Big Bang Chess',
            'INSTALLDATE' => '04/05/2007',
            'VERSION' => '2.51'
        },
        {
            'VERSION' => '4.7.3',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Saturn',
            'COMMENTS' => '[Intel]'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Aquamacs Emacs',
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '09/30/2009',
            'VERSION' => 22
        },
        {
            'INSTALLDATE' => '10/14/2009',
            'VERSION' => '4.9.01.0180',
            'COMMENTS' => '[Universal]',
            'NAME' => 'VPNClient',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Résolution des conflits',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5.2',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Time Machine',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.1'
        },
        {
            'NAME' => 'Éditeur d\'équations',
            'COMMENTS' => '[PowerPC]',
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '11.0.0',
            'INSTALLDATE' => '12/12/2005'
        },
        {
            'INSTALLDATE' => '07/24/2009',
            'VERSION' => '2.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Spotlight'
        },
        {
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'COMMENTS' => '[Intel]',
            'NAME' => 'HP Printer Utility',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '06/23/2009',
            'VERSION' => '8.1.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'IncompatibleAppDisplay',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => 305
        },
        {
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Intel]',
            'NAME' => 'File Sync',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '5.0.3'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'Laserjet',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'VERSION' => '1.0',
            'INSTALLDATE' => '06/22/2009'
        },
        {
            'PUBLISHER' => 'Michael O. McCracken.',
            'SYSTEM_CATEGORY' => 'Applications/TeX',
            'NAME' => 'BibDesk',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '10/06/2009',
            'VERSION' => '1.3.20'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '3.0.2',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Dashcode',
            'SYSTEM_CATEGORY' => 'Developer/Applications'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ParentalControls',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Inkjet',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '06/16/2009',
            'VERSION' => '3.0'
        },
        {
            'INSTALLDATE' => '02/17/2012',
            'VERSION' => '13.6.0',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Jar Launcher',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '4.0',
            'INSTALLDATE' => '06/16/2009',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Photosmart',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'Hewlett-Packard Development Company'
        },
        {
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'COMMENTS' => '[Intel]',
            'NAME' => 'hpdot4d',
            'INSTALLDATE' => '05/02/2010',
            'VERSION' => '3.5.0'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'COMMENTS' => '[Intel]',
            'NAME' => 'SpindownHD',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '4.7.3'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Problem Reporter',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '10.6.7',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.0.1',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'TWAINBridge'
        },
        {
            'NAME' => 'commandtohp',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'VERSION' => '1.9.2',
            'INSTALLDATE' => '06/15/2009'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'kcSync',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '3.0.1'
        },
        {
            'NAME' => 'Set Info',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => undef
        },
        {
            'VERSION' => '1.8.3',
            'INSTALLDATE' => '02/17/2012',
            'NAME' => 'webdav_cert_ui',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Aperçu',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '5.0.3'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Big Bang Board Games',
            'NAME' => 'Big Bang Mancala',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '04/05/2007',
            'VERSION' => '2.51'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'PacketLogger',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2.3.6',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'SRLanguageModeler',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.9',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'VERSION' => '33.12',
            'INSTALLDATE' => '09/04/2011',
            'COMMENTS' => '[Intel]',
            'NAME' => 'FontRegistryUIAgent',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Terminal',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.1.2'
        },
        {
            'NAME' => 'Inkjet6',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'VERSION' => '1.0',
            'INSTALLDATE' => '06/16/2009'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.1.1',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'loginwindow',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'SystemUIServer',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.6'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'Quartz Composer Visualizer',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'VERSION' => '1.2',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'VERSION' => '1.0.2',
            'INSTALLDATE' => '02/17/2009',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'COMMENTS' => '[Universal]',
            'NAME' => "Visite guid\x{e9}e d\x{2019}iWork"
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'WebProcess',
            'INSTALLDATE' => '02/17/2012',
            'VERSION' => '6534.52'
        },
        {
            'NAME' => 'DiskImages UI Agent',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '289.1'
        },
        {
            'VERSION' => undef,
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Proof'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Capture',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/19/2009',
            'VERSION' => '1.5'
        },
        {
            'VERSION' => '3.0',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'dotmacfx',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '6.6',
            'INSTALLDATE' => '09/04/2011',
            'NAME' => 'AddPrinter',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'Premiers contacts avec iWeb',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'VERSION' => '1.0.2',
            'INSTALLDATE' => '02/17/2009'
        },
        {
            'VERSION' => '5.2',
            'INSTALLDATE' => '09/04/2011',
            'NAME' => 'SecurityAgent',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '2.94',
            'INSTALLDATE' => '10/06/2009',
            'NAME' => 'i-Installer',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'PUBLISHER' => 'Gerben Wierda--'
        },
        {
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive',
            'COMMENTS' => '[PowerPC]',
            'NAME' => 'Organization Chart',
            'INSTALLDATE' => '12/12/2005',
            'VERSION' => '11.0.0'
        },
        {
            'VERSION' => undef,
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'NAME' => 'Remove',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Syncrospector',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '5.2'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'NAME' => 'HPScanner',
            'COMMENTS' => '[Intel]',
            'PUBLISHER' => 'Hewlett-Packard Company',
            'VERSION' => '1.1.52',
            'INSTALLDATE' => '07/24/2009'
        },
        {
            'VERSION' => '11.2.0',
            'INSTALLDATE' => '12/12/2005',
            'NAME' => 'Project Gallery Launcher',
            'COMMENTS' => '[PowerPC]',
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive',
            'PUBLISHER' => 'Microsoft'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => undef,
            'COMMENTS' => '[Universal]',
            'NAME' => 'Show Info',
            'SYSTEM_CATEGORY' => 'Library/Scripts'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Folder Actions Dispatcher',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.0.2'
        },
        {
            'VERSION' => '2.5.4',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Build Applet',
            'PUBLISHER' => 'Python Software Foundation.'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.1.1',
            'NAME' => 'VietnameseIM',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Utilitaire ColorSync',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '4.6.2'
        },
        {
            'NAME' => 'AppleFileServer',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => undef,
            'INSTALLDATE' => '02/17/2012'
        },
        {
            'NAME' => 'Brother Contrôleur d\'état',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'Brother Industries',
            'VERSION' => '3.00',
            'INSTALLDATE' => '05/19/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'HALLab',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.6',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'NAME' => 'Rename',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => undef
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Comic Life',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.2.4 (v554)',
            'INSTALLDATE' => '03/15/2006'
        },
        {
            'VERSION' => '7.1',
            'INSTALLDATE' => '09/28/2011',
            'COMMENTS' => '[Universal]',
            'NAME' => 'TrueCrypt',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '12.3',
            'PUBLISHER' => 'Apple',
            'NAME' => 'CoreLocationAgent',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '4.0.2',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Keychain Scripting',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'Type4Camera',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.1'
        },
        {
            'NAME' => 'Inkjet5',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'VERSION' => '2.1',
            'INSTALLDATE' => '06/16/2009'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'QuickTime Player',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Apple',
            'VERSION' => '10.0',
            'INSTALLDATE' => '02/17/2012'
        },
        {
            'NAME' => 'Microsoft Database Daemon',
            'COMMENTS' => '[PowerPC]',
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '11.2.0',
            'INSTALLDATE' => '12/12/2005'
        },
        {
            'NAME' => 'App Store',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => '1.0.2',
            'INSTALLDATE' => '02/17/2012'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'Automator',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2.1.1',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.0',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Type1Camera',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '4.7.3',
            'NAME' => 'Shark',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Developer/Applications'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AppleScript Runner',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '1.0.2'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.4.5',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'BluetoothUIServer'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Mise à jour de logiciels',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'VERSION' => '4.0.6',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'INSTALLDATE' => '12/12/2005',
            'VERSION' => '11.2.0',
            'PUBLISHER' => 'Microsoft',
            'COMMENTS' => '[PowerPC]',
            'NAME' => 'Supprimer Office',
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive'
        },
        {
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Intel]',
            'NAME' => 'AutoImporter',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.0.1'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Instruments',
            'VERSION' => '2.7',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Property List Editor',
            'VERSION' => '5.3',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'PUBLISHER' => 'Brother Industries',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Brother Scanner',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'INSTALLDATE' => '06/29/2009',
            'VERSION' => '2.0.2'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Image Events',
            'COMMENTS' => '[Intel]',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.1.4',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'VERSION' => '2.51',
            'INSTALLDATE' => '04/05/2007',
            'NAME' => 'Big Bang Reversi',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications/Big Bang Board Games'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'TextEdit',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '06/27/2009',
            'VERSION' => '1.6'
        },
        {
            'NAME' => 'hprastertojpeg',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'VERSION' => '1.0.1',
            'INSTALLDATE' => '03/30/2009'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'AU Lab',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.2'
        },
        {
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'NAME' => 'pdftopdf',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '04/16/2009',
            'VERSION' => '1.3'
        },
        {
            'VERSION' => '6.1',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'MassStorageCamera',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'Utilitaire RAID',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.2',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'wxPerl',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0',
            'INSTALLDATE' => '05/19/2009'
        },
        {
            'VERSION' => '2.0.3',
            'INSTALLDATE' => '05/19/2009',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AppleGraphicsWarning',
            'COMMENTS' => '[Intel]',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '02/17/2009',
            'VERSION' => '6.0.3',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[Universal]',
            'NAME' => 'iMovie HD'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Calculette',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '4.5.3'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.1',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'NetAuthAgent'
        },
        {
            'INSTALLDATE' => '02/17/2009',
            'VERSION' => '2.0.2',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Pages',
            'SYSTEM_CATEGORY' => 'Applications/iWork \'06'
        },
        {
            'VERSION' => '4.1.1',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => "Trousseau d\x{2019}acc\x{e8}s",
            'COMMENTS' => '[Intel]'
        },
        {
            'VERSION' => '11.2.0',
            'INSTALLDATE' => '12/12/2005',
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive',
            'COMMENTS' => '[PowerPC]',
            'NAME' => 'Utilitaire de base de données',
            'PUBLISHER' => 'Microsoft'
        },
        {
            'INSTALLDATE' => '03/15/2006',
            'VERSION' => '3.5',
            'PUBLISHER' => 'The Omni Group',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[Universal]',
            'NAME' => 'OmniOutliner'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Création de page Web',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.0',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'VERSION' => '5.2',
            'INSTALLDATE' => '09/04/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'SyncDiagnostics',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Raster2CanonIJ',
            'VERSION' => undef,
            'INSTALLDATE' => '06/15/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Application Loader',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.4.1',
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'IORegistryExplorer',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.1'
        },
        {
            'NAME' => 'Microsoft Error Reporting',
            'COMMENTS' => '[PowerPC]',
            'SYSTEM_CATEGORY' => 'Applications/Office 2004 for Mac Test Drive',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '050811',
            'INSTALLDATE' => '12/12/2005'
        },
        {
            'PUBLISHER' => 'Epson',
            'NAME' => 'Epson Printer Utility Lite',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '07/09/2009',
            'VERSION' => '8.02'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'Accessibility Inspector',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '2.0'
        },
        {
            'VERSION' => '2.3',
            'INSTALLDATE' => '09/04/2011',
            'COMMENTS' => '[Intel]',
            'NAME' => 'quicklookd32',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/SDKs',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Python_1',
            'PUBLISHER' => 'Apple',
            'VERSION' => undef,
            'INSTALLDATE' => '09/04/2011'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'FontSyncScripting',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2.0.6',
            'INSTALLDATE' => '05/19/2009'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Type3Camera',
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.0'
        },
        {
            'INSTALLDATE' => '09/04/2011',
            'VERSION' => '6.0',
            'PUBLISHER' => 'Apple',
            'NAME' => 'MakePDF',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library'
        }
    ],
    'sample2' => [
        {
            'PUBLISHER' => 'Hewlett-Packard Company',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'NAME' => 'HP Scanner 3',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '3.2.9'
        },
        {
            'NAME' => 'DiskImageMounter',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '10.6.5'
        },
        {
            'VERSION' => '4.7.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'BigTop',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'SLLauncher',
            'VERSION' => '1.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '20/01/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Parallels Desktop',
            'PUBLISHER' => 'Parallels Holdings',
            'VERSION' => '6.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '08/03/2011'
        },
        {
            'INSTALLDATE' => '12/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '3.10.35',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'SpeechService'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '22/06/2009',
            'VERSION' => '1.0',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'NAME' => 'Laserjet',
            'SYSTEM_CATEGORY' => 'Library/Printers',
        },
        {
            'VERSION' => '2.0.1',
            'INSTALLDATE' => '21/07/2009',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Transfert de podcast',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '16/06/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.0',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Photosmart'
        },
        {
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Inkjet3',
            'INSTALLDATE' => '16/06/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.0'
        },
        {
            'VERSION' => '2.4.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'NAME' => 'Chess',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Reggie SE',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '4.7.3'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '08/03/2011',
            'VERSION' => '6.0',
            'SYSTEM_CATEGORY' => 'Library/Parallels',
            'NAME' => 'DockPlistEdit'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '3.0.3',
            'NAME' => 'Photo Booth',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/DivX',
            'NAME' => 'DivX Support',
            'COMMENTS' => '[PowerPC]',
            'INSTALLDATE' => '17/11/2009',
            'VERSION' => '1.1.0'
        },
        {
            'INSTALLDATE' => '25/04/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => undef,
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'NAME' => 'Rename'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Assistant Installation de Microsoft Office 2008',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '12.2.8',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '27/12/2010'
        },
        {
            'PUBLISHER' => 'Parallels Holdings',
            'SYSTEM_CATEGORY' => 'Library/Parallels',
            'NAME' => 'Parallels Mounter',
            'INSTALLDATE' => '08/03/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '6.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'NAME' => 'NetAuthAgent',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '07/07/2010',
            'VERSION' => '2.1'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Création de page Web',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0'
        },
        {
            'VERSION' => '1.0.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '15/06/2009',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'NAME' => 'CIJScannerRegister',
            'PUBLISHER' => 'CANON INC.'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'PhotosmartPro',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'VERSION' => '3.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009'
        },
        {
            'VERSION' => '1.2.10',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '01/07/2009',
            'NAME' => 'Utilitaire de l\'imprimante Lexmark',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'Lexmark International'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ChineseTextConverterService',
            'VERSION' => '1.2',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Image Capture Web Server',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.0'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Outil d’étalonnage du moniteur',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.6'
        },
        {
            'NAME' => 'Front Row',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '22/07/2009',
            'VERSION' => '2.2.1'
        },
        {
            'VERSION' => '6.0',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'Type2Camera',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'Keychain Scripting',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '07/07/2010',
            'VERSION' => '4.0.2'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '21/07/2009',
            'VERSION' => '6.2.1',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Apple80211Agent',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'VERSION' => '1.0.0',
            'INSTALLDATE' => '10/06/2010',
            'COMMENTS' => '[Intel]',
            'NAME' => 'hpPreProcessing',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'Hewlett-Packard Development Company'
        },
        {
            'INSTALLDATE' => '25/04/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => undef,
            'NAME' => 'Match',
            'SYSTEM_CATEGORY' => 'Library/Scripts'
        },
        {
            'VERSION' => '1.3',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/07/2009',
            'NAME' => 'Clipboard Viewer',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
        },
        {
            'USERNAME' => 'lubrano',
            'NAME' => 'h-nb1',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.5'
        },
        {
            'NAME' => 'Folder Actions Dispatcher',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0.2',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '2.3.6',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Bluetooth Diagnostics Utility'
        },
        {
            'VERSION' => '300.4',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'IncompatibleAppDisplay',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'INSTALLDATE' => '15/06/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.0.0',
            'PUBLISHER' => 'CANON INC.',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'NAME' => 'Canon IJScanner1',
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Dashboard',
            'INSTALLDATE' => '20/02/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.7'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '5.4',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Lecteur DVD',
            'SYSTEM_CATEGORY' => 'Applications',
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Type1Camera',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Type3Camera',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.0',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'OpenGL Profiler',
            'PUBLISHER' => 'Apple',
            'VERSION' => '4.2',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '13/01/2011',
            'VERSION' => '14.0.2',
            'PUBLISHER' => 'Microsoft',
            'NAME' => 'Utilitaire de base de données Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011'
        },
        {
            'NAME' => 'Problem Reporter',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '20/02/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '10.6.6'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'NAME' => 'License',
            'VERSION' => '11',
            'INSTALLDATE' => '25/07/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '3.1.0',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'NAME' => 'UserNotificationCenter',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'VERSION' => '2.3.8',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'OBEXAgent',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'VoiceOver',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '3.4.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'webdav_cert_ui',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '1.8.1'
        },
        {
            'VERSION' => '4.7.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'IA32 Help',
        },
        {
            'VERSION' => '7.6.6',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/04/2009',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'QuickTime Player 7',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '3.0.4',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'PackageMaker',
        },
        {
            'NAME' => 'SpeechRecognitionServer',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '3.11.1',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '29/05/2009'
        },
        {
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.1.1',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Utilitaire AppleScript',
        },
        {
            'INSTALLDATE' => '24/07/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Spotlight'
        },
        {
            'VERSION' => '12.2.8',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Cert Manager',
            'PUBLISHER' => 'Microsoft'
        },
        {
            'VERSION' => '1.5',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010',
            'NAME' => 'OpenGL Driver Monitor',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'PUBLISHER' => 'Apple'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'Type8Camera',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0.1'
        },
        {
            'INSTALLDATE' => '13/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '14.0.2',
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011',
            'NAME' => 'Microsoft Clip Gallery'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '07/07/2010',
            'VERSION' => '4.5.3',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Calculette'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'Safari',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '18/03/2011',
            'VERSION' => '5.0.4'
        },
        {
            'VERSION' => '5.2',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/07/2009',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'syncuid',
            'PUBLISHER' => 'Apple'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '07/07/2010',
            'VERSION' => '6.5.10',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'NAME' => 'KerberosAgent',
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '2.2',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'AU Lab',
        },
        {
            'VERSION' => '12.2.8',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Alerts Daemon',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'PUBLISHER' => 'Microsoft'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'CharacterPalette',
            'VERSION' => '1.0.4',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/07/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'CoreServicesUIAgent',
            'PUBLISHER' => 'Apple',
            'VERSION' => '41.5',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]'
        },
        {
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Rappels Microsoft Office',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8'
        },
        {
            'USERNAME' => 'lubrano',
            'SYSTEM_CATEGORY' => 'zimbra/zdesktop',
            'NAME' => 'Zimbra Desktop',
            'PUBLISHER' => 'VMware Inc.',
            'VERSION' => '1.0.4',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '07/07/2010'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'SyncDiagnostics',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '18/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '5.2'
        },
        {
            'NAME' => 'Quartz Debug',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.1'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010',
            'VERSION' => '2.7',
            'NAME' => 'SleepX',
            'SYSTEM_CATEGORY' => 'Developer/Applications'
        },
        {
            'NAME' => 'Embed',
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '25/04/2009',
            'VERSION' => undef
        },
        {
            'VERSION' => undef,
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '25/04/2009',
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'NAME' => 'Set Info',
        },
        {
            'NAME' => 'Yap',
            'SYSTEM_CATEGORY' => 'opt/local',
            'INSTALLDATE' => '30/12/2009',
            'VERSION' => undef
        },
        {
            'NAME' => 'DivXUpdater',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'INSTALLDATE' => '17/11/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.1'
        },
        {
            'VERSION' => '13.4.0',
            'INSTALLDATE' => '18/03/2011',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Jar Bundler',
            'SYSTEM_CATEGORY' => 'usr/share',
        },
        {
            'NAME' => 'Spin Control',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'VERSION' => '0.9',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]'
        },
        {
            'VERSION' => '6.0',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'MakePDF',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '3.8.1',
            'INSTALLDATE' => '29/05/2009',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'NAME' => 'SpeechFeedbackWindow',
        },
        {
            'NAME' => 'Session Timer',
            'SYSTEM_CATEGORY' => 'Library/Frameworks',
            'INSTALLDATE' => '09/03/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '17289'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Excel',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '12.2.8',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '0.66',
            'INSTALLDATE' => '20/11/2009',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'CocoaPacketAnalyzer',
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '2.3.8',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Échange de fichiers Bluetooth',
        },
        {
            'INSTALLDATE' => '08/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '2.5.4',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Python Launcher',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'Automator Launcher',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '1.2'
        },
        {
            'NAME' => 'iCal',
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => '4.0.4',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '14.0.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '13/01/2011',
            'NAME' => 'Microsoft Outlook',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011',
            'PUBLISHER' => 'Microsoft'
        },
        {
            'NAME' => 'AddressBookSync',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '2.0.3'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '3.7.8',
            'NAME' => 'SpeakableItems',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'Microsoft Ship Asserts',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '1.1.0',
            'INSTALLDATE' => '13/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Configuration audio et MIDI',
            'PUBLISHER' => 'Apple',
            'VERSION' => '3.0.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'VERSION' => '1.1.1',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '19/05/2009',
            'NAME' => 'URL Access Scripting',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '1.2.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Wireshark',
            'PUBLISHER' => 'Wireshark Development Team'
        },
        {
            'VERSION' => '2.0.6',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '19/05/2009',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'FontSyncScripting',
            'PUBLISHER' => 'Apple'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '22/02/2011',
            'VERSION' => '3.9.14.0',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'Meeting Center',
            'USERNAME' => 'lubrano'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.8.5',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'NAME' => 'HP Utility',
            'SYSTEM_CATEGORY' => 'Library/Printers'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Skype',
            'PUBLISHER' => 'Skype Technologies S.A.',
            'VERSION' => '2.8.0.851',
            'INSTALLDATE' => '08/02/2010',
            'COMMENTS' => '[Universal]'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.0.1',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Type4Camera',
        },
        {
            'VERSION' => '1.1',
            'INSTALLDATE' => '09/07/2008',
            'COMMENTS' => '[Universal]',
            'NAME' => 'À propos d’AHT',
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '1.2',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Utilitaire RAID',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Type5Camera'
        },
        {
            'VERSION' => '3.2.45',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '01/07/2009',
            'NAME' => 'Lexmark Scanner',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
        },
        {
            'VERSION' => '4.3',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '19/05/2009',
            'NAME' => 'SCIM',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '08/07/2009',
            'VERSION' => '2.5.4',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Python',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'VERSION' => '9.4.2',
            'INSTALLDATE' => '23/03/2011',
            'COMMENTS' => '[Universal]',
            'USERNAME' => 'lubrano',
            'NAME' => 'Adobe Reader Updater',
            'SYSTEM_CATEGORY' => 'Library/Caches',
            'PUBLISHER' => 'Adobe Systems Inc.'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => undef,
            'SYSTEM_CATEGORY' => 'Developer/SDKs',
            'PUBLISHER' => 'Apple',
            'NAME' => 'WebKitPluginHost',
        },
        {
            'VERSION' => '17289',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/03/2011',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Network Connect',
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'USB Prober',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '4.0.0'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'Agent de la borne d’accès AirPort',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '1.5.5'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'NAME' => 'Bienvenue sur Leopard',
            'INSTALLDATE' => '23/07/2008',
            'COMMENTS' => '[Universal]',
            'VERSION' => '8.1'
        },
        {
            'PUBLISHER' => 'Macrovision',
            'USERNAME' => 'lubrano',
            'SYSTEM_CATEGORY' => 'Cisco_Network_Assistant',
            'NAME' => 'Cisco Network Assistant',
            'INSTALLDATE' => '13/03/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '8.0'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '21/03/2011',
            'VERSION' => '6.0',
            'PUBLISHER' => 'Parallels Holdings',
            'SYSTEM_CATEGORY' => 'Library/Parallels',
            'NAME' => 'Parallels Service',
        },
        {
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8',
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Entourage'
        },
        {
            'NAME' => 'X11',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'VERSION' => '2.3.6',
            'INSTALLDATE' => '05/01/2011',
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Utilitaire VoiceOver',
            'VERSION' => '3.4.0',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'NAME' => 'Officejet',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'VERSION' => '3.0'
        },
        {
            'VERSION' => '1.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Ticket Viewer',
        },
        {
            'VERSION' => '3.1.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'iSync',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '4.7.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'Saturn',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '11/06/2009',
            'VERSION' => '2.0',
            'PUBLISHER' => 'Apple',
            'NAME' => 'KeyboardViewer',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'VERSION' => '2.3',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'NAME' => 'ManagedClient',
        },
        {
            'VERSION' => '1.5.6',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/07/2006',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Bonjour Browser',
        },
        {
            'NAME' => '50onPaletteServer',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '30/06/2009',
            'VERSION' => '1.0.3'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '1.0.4',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Database Events'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0.4',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'PTPCamera'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AppleFileServer',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => undef
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.5',
            'NAME' => 'h-coul',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'USERNAME' => 'lubrano'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Pixie',
            'VERSION' => '2.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010'
        },
        {
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8',
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Chart Converter',
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'VPNClient',
            'VERSION' => '4.9.01.0180',
            'INSTALLDATE' => '27/12/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'NAME' => 'Show Info',
            'VERSION' => undef,
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '25/04/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'iChatAgent',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5.0.3',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Intel]'
        },
        {
            'NAME' => 'ChineseHandwriting',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0.1',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]'
        },
        {
            'VERSION' => '1.1.1',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '11/11/2010',
            'NAME' => 'Microsoft Help Viewer',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'PUBLISHER' => 'Microsoft'
        },
        {
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'NAME' => 'Inkjet5',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'VERSION' => '2.1'
        },
        {
            'NAME' => 'Assistant migration',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'INSTALLDATE' => '01/07/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '3.0'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'iMovie',
            'PUBLISHER' => 'Apple',
            'VERSION' => '7.1.4',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '01/07/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Raster2CanonIJ',
            'VERSION' => undef,
            'INSTALLDATE' => '15/06/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Xcode',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '3.2.5'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '25/04/2009',
            'VERSION' => undef,
            'NAME' => 'Remove',
            'SYSTEM_CATEGORY' => 'Library/Scripts'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'KeyboardSetupAssistant',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '10.5.0'
        },
        {
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.1.3',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Diagnostic réseau',
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Icon Composer',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010',
            'VERSION' => '2.1'
        },
        {
            'VERSION' => '6.5',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Printer Setup Utility',
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.0',
            'PUBLISHER' => 'Apple',
            'NAME' => 'BluetoothCamera',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'INSTALLDATE' => '01/07/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.00.29',
            'PUBLISHER' => 'Samsung Electronics Co.',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'NAME' => 'Samsung Scanner',
        },
        {
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'NAME' => 'Inkjet4',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'VERSION' => '2.2'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '01/07/2009',
            'VERSION' => '2.0.4',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'iWeb',
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '01/07/2009',
            'VERSION' => '6.2.1',
            'NAME' => 'TrueCrypt',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'VERSION' => '6.5',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'USERNAME' => 'lubrano',
            'NAME' => 'h-nb-toshiba- photocopieur multifonctions noir et blanc',
            'PUBLISHER' => 'Toshiba',
            'SYSTEM_CATEGORY' => 'Library/Printers',
        },
        {
            'NAME' => 'SystemUIServer',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.6',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'VERSION' => '6.5',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'NAME' => 'PrinterProxy',
        },
        {
            'NAME' => 'TCIM',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.3',
            'INSTALLDATE' => '07/07/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '20/10/2009',
            'VERSION' => '1.0',
            'NAME' => 'WiFi Scanner',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'VERSION' => '12.2.8',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '27/12/2010',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Sync Services',
            'PUBLISHER' => 'Microsoft'
        },
        {
            'VERSION' => '2.0',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '20/02/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ParentalControls',
            'PUBLISHER' => 'Apple'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Image Capture Extension',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0.2'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.2.2',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Livre des polices',
            'SYSTEM_CATEGORY' => 'Applications',
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'SpeechSynthesisServer',
            'PUBLISHER' => 'Apple',
            'VERSION' => '3.10.35',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '12/07/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'FontRegistryUIAgent',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.1',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Intel]'
        },
        {
            'VERSION' => '2.3',
            'INSTALLDATE' => '24/04/2009',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Éditeur AppleScript',
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Java Web Start',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/03/2011',
            'VERSION' => '13.4.0'
        },
        {
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Connexion Bureau à Distance',
            'INSTALLDATE' => '13/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.1.0'
        },
        {
            'VERSION' => '3.4.0',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'NAME' => 'ScreenReaderUIServer',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'NAME' => 'Exposé',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.1',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '20/02/2011'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '07/07/2010',
            'VERSION' => '6.5.10',
            'PUBLISHER' => 'Apple',
            'NAME' => 'CCacheServer',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'loginwindow',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.1.1',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'NAME' => 'ScreenSaverEngine',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '3.0.3'
        },
        {
            'NAME' => 'iStumbler',
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => 'Release 98',
            'INSTALLDATE' => '05/02/2007',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'Bluetooth Explorer',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '2.3.6'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'Type6Camera',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.0'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '3.4',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '20/02/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ARDAgent',
        },
        {
            'VERSION' => '12.2.8',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'My Day',
            'PUBLISHER' => 'Microsoft'
        },
        {
            'NAME' => 'HelpViewer',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '5.0.3'
        },
        {
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Supprimer Office',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.1',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'CoreLocationAgent',
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'OpenOffice',
            'VERSION' => '3.2.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '01/02/2010'
        },
        {
            'NAME' => 'Proof',
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'INSTALLDATE' => '25/04/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => undef
        },
        {
            'NAME' => 'AppleScript Runner',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'Partage d’écran',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.1.1'
        },
        {
            'VERSION' => '4.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010',
            'NAME' => 'Help Indexer',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
        },
        {
            'NAME' => 'PSPP',
            'SYSTEM_CATEGORY' => 'opt/local',
            'VERSION' => '@VERSION@',
            'INSTALLDATE' => '30/12/2009'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '4.6.2',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Utilitaire ColorSync',
            'SYSTEM_CATEGORY' => 'Applications/Utilities'
        },
        {
            'VERSION' => '2.1',
            'INSTALLDATE' => '26/08/2010',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'IORegistryExplorer',
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Trousseau d’accès',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '07/07/2010',
            'VERSION' => '4.1'
        },
        {
            'PUBLISHER' => 'Epson',
            'NAME' => 'Epson Printer Utility Lite',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/07/2009',
            'VERSION' => '8.02'
        },
        {
            'PUBLISHER' => 'Brother Industries',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'NAME' => 'Brother Scanner',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '29/06/2009',
            'VERSION' => '2.0.2'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '20/02/2011',
            'VERSION' => '1.7',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Dock'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '2.3.8',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Assistant réglages Bluetooth',
        },
        {
            'VERSION' => '3.2.5',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Interface Builder',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '30/03/2009',
            'VERSION' => '1.0.1',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'hprastertojpeg',
        },
        {
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '10.6',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'NAME' => 'SecurityFixer',
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'quicklookd32',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.3'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Wish',
            'PUBLISHER' => 'Apple',
            'VERSION' => '8.4.19',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '23/07/2009'
        },
        {
            'VERSION' => '3.0',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'NAME' => 'dotmacfx',
        },
        {
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '10.0',
            'NAME' => 'eaptlstrust',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/10/2010',
            'VERSION' => '2.0.0',
            'NAME' => 'VidyoDesktop Uninstaller',
            'SYSTEM_CATEGORY' => 'Applications/Vidyo',
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'SolidWorks eDrawings',
            'VERSION' => '1.0A',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '26/06/2007'
        },
        {
            'VERSION' => '4.4',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'Mail',
            'SYSTEM_CATEGORY' => 'Applications',
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'SyncServer',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '18/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '5.2'
        },
        {
            'INSTALLDATE' => '25/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '3.1.0',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'NAME' => 'HPFaxBackend',
            'SYSTEM_CATEGORY' => 'Library/Printers',
        },
        {
            'VERSION' => '8.02',
            'INSTALLDATE' => '09/07/2009',
            'COMMENTS' => '[Intel]',
            'NAME' => 'rastertoescpII',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'SEIKO EPSON'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '13/01/2011',
            'VERSION' => '2.3.1',
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'Microsoft AutoUpdate',
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '6.0.1',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ImageCaptureService',
        },
        {
            'VERSION' => '8.02',
            'INSTALLDATE' => '09/07/2009',
            'COMMENTS' => '[Intel]',
            'NAME' => 'commandtoescp',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'SEIKO EPSON'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Assistant de certification',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '3.0'
        },
        {
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Inkjet6',
            'INSTALLDATE' => '16/06/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.0'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/03/2011',
            'VERSION' => '3.1',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'NAME' => 'AppleMobileSync',
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'Informations Système',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '10.6.0'
        },
        {
            'VERSION' => '6.1',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/05/2009',
            'NAME' => 'KoreanIM',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '26/01/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '0.9.1',
            'PUBLISHER' => 'Contributors',
            'NAME' => 'Prism',
            'SYSTEM_CATEGORY' => 'zimbra/zdesktop',
            'USERNAME' => 'lubrano'
        },
        {
            'VERSION' => '4.0.6',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '20/02/2011',
            'NAME' => 'Mise à jour de logiciels',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'Instruments',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'VERSION' => '2.7',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'INSTALLDATE' => '30/12/2009',
            'VERSION' => undef,
            'NAME' => 'Free42-Decimal',
            'SYSTEM_CATEGORY' => 'opt/local',
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.7.3',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'ARM Help'
        },
        {
            'VERSION' => '11.5.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Utilitaire de disque',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'pdftopdf2',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'SEIKO EPSON',
            'VERSION' => '8.02',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/07/2009'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/07/2009',
            'VERSION' => '4.5.0',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'PMC Index',
        },
        {
            'SYSTEM_CATEGORY' => 'opt/local',
            'NAME' => 'Free42-Binary',
            'INSTALLDATE' => '30/12/2009',
            'VERSION' => undef
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '13/01/2011',
            'VERSION' => '14.0.0',
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011',
            'NAME' => 'Assistant Installation de Microsoft Office',
        },
        {
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[PowerPC]',
            'VERSION' => '12.2.8',
            'PUBLISHER' => 'Microsoft',
            'NAME' => 'Open XML for Charts',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '27/06/2009',
            'VERSION' => '7.0',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Préférences Système',
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'check_afp',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2.0',
            'INSTALLDATE' => '03/07/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'QuickTime Player',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '10.0'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'NAME' => 'EPSON Scanner',
            'PUBLISHER' => 'EPSON',
            'VERSION' => '5.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/07/2009'
        },
        {
            'VERSION' => '1.1.1',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Installation à distance de Mac OS X',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'MÀJ du programme interne Bluetooth',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '01/08/2009',
            'VERSION' => '2.0.1'
        },
        {
            'VERSION' => '1.3.4',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'NAME' => 'System Events',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'NAME' => 'Repeat After Me',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010'
        },
        {
            'INSTALLDATE' => '13/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '13.0.0',
            'PUBLISHER' => 'Microsoft',
            'NAME' => 'Microsoft Communicator',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AppleGraphicsWarning',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '2.0.3'
        },
        {
            'USERNAME' => 'lubrano',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'Network Recording Player',
            'PUBLISHER' => 'WebEx Communications',
            'VERSION' => '2.2.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '25/02/2010'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Grapher',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '07/04/2009',
            'VERSION' => '2.1'
        },
        {
            'NAME' => 'Lanceur d’applets',
            'SYSTEM_CATEGORY' => 'usr/share',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/03/2011',
            'VERSION' => '13.4.0'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Aperçu',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5.0.3',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]'
        },
        {
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '3.7.2',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'hpdot4d'
        },
        {
            'VERSION' => '3.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'CompactPhotosmart',
            'PUBLISHER' => 'Hewlett-Packard Development Company'
        },
        {
            'VERSION' => '4.0',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Quartz Composer',
        },
        {
            'VERSION' => undef,
            'INSTALLDATE' => '12/11/2009',
            'NAME' => 'Yahoo! Zimbra Desktop',
            'SYSTEM_CATEGORY' => 'zimbra/zdesktop',
            'USERNAME' => 'lubrano',
        },
        {
            'VERSION' => '3.1.9',
            'INSTALLDATE' => '06/03/2011',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Thunderbird',
        },
        {
            'NAME' => 'CPUPalette',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'VERSION' => '4.7.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'VERSION' => '2.1',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'OpenGL Shader Builder',
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '1.6',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Assistant réglages de réseau',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '01/07/2009',
            'VERSION' => '1.0.2',
            'NAME' => 'Premiers contacts avec GarageBand',
            'SYSTEM_CATEGORY' => 'Library/Documentation'
        },
        {
            'VERSION' => '7.19.11.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '22/02/2011',
            'USERNAME' => 'lubrano',
            'NAME' => 'asannotation2',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
        },
        {
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Organigramme hiérarchique',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '27/12/2010',
            'VERSION' => '12.2.8'
        },
        {
            'NAME' => 'Adobe Updater',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'PUBLISHER' => 'Adobe Systems Inc.',
            'VERSION' => 'Adobe Updater 6.2.0.1474',
            'INSTALLDATE' => '02/03/2011',
            'COMMENTS' => '[Intel]'
        },
        {
            'NAME' => 'Accessibility Verifier',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'VERSION' => '1.2',
            'INSTALLDATE' => '26/08/2010',
            'COMMENTS' => '[Intel]'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '07/10/2009',
            'VERSION' => '0.10',
            'NAME' => 'iTerm',
            'SYSTEM_CATEGORY' => 'Applications',
        },
        {
            'NAME' => 'Open XML for Excel',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '12.2.8',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[PowerPC]'
        },
        {
            'PUBLISHER' => 'CANON INC.',
            'NAME' => 'CIJAutoSetupTool',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '15/06/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.7.1'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/DivX',
            'NAME' => 'DivX Products',
            'VERSION' => '1.1.0',
            'INSTALLDATE' => '17/11/2009',
            'COMMENTS' => '[PowerPC]'
        },
        {
            'VERSION' => '3.7.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '28/05/2009',
            'NAME' => 'Colorimètre numérique',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Utilitaire AirPort',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5.5.2',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Flip4Mac',
            'NAME' => 'WMV Player',
            'PUBLISHER' => 'Telestream Inc.',
            'VERSION' => '2.3.1.2',
            'INSTALLDATE' => '04/11/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '1.1',
            'INSTALLDATE' => '13/01/2010',
            'COMMENTS' => '[PowerPC]',
            'NAME' => 'MemoryCard Ejector',
            'SYSTEM_CATEGORY' => 'Applications/Vodafone Mobile Connect',
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'DivX Player',
            'VERSION' => '7.2 (build 10_0_0_183)',
            'INSTALLDATE' => '28/12/2009',
            'COMMENTS' => '[Intel]'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Utilitaire d’emplacement de mémoire',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.4.1',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]'
        },
        {
            'NAME' => 'Application Loader',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'VERSION' => '1.4',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'NAME' => 'Résolution des conflits',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5.2',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/07/2009'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0.1',
            'PUBLISHER' => 'Apple',
            'NAME' => 'AutoImporter',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'NAME' => 'CrashReporterPrefs',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'VERSION' => '10.6.3',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '4.0',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '27/06/2009',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Programme d’installation',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Deskjet',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'VERSION' => '3.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '18/06/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Core Image Fun House',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010',
            'VERSION' => '2.1.43'
        },
        {
            'NAME' => 'AppleMobileDeviceHelper',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/03/2011',
            'VERSION' => '3.1'
        },
        {
            'INSTALLDATE' => '01/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0.2',
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'NAME' => 'Premiers contacts avec iMovie 08',
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'PluginIM',
            'VERSION' => '1.1',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '21/05/2009',
            'VERSION' => '1.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'NAME' => 'SecurityProxy',
        },
        {
            'VERSION' => '10.6.7',
            'INSTALLDATE' => '20/02/2011',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Finder',
            'PUBLISHER' => 'Apple',
        },
        {
            'PUBLISHER' => 'Brother Industries',
            'NAME' => 'Brother Contrôleur d\'état',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '3.00'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'FileSyncAgent',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '5.0.3'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'iTunes',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/03/2011',
            'VERSION' => '10.2.1'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Carnet d’adresses',
            'VERSION' => '5.0.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '20',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Language Chooser',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'NAME' => 'Dictionnaire',
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => '2.1.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'NAME' => 'Vodafone Mobile Connect',
            'SYSTEM_CATEGORY' => 'Applications/Vodafone Mobile Connect',
            'VERSION' => 'Vodafone Mobile Connect 3G 2.11.04',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '13/01/2010'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'iCal Helper',
            'PUBLISHER' => 'Apple',
            'VERSION' => '4.0.4',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'NAME' => 'Utilitaire d’annuaire',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2.2',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]'
        },
        {
            'NAME' => 'g-coul',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'USERNAME' => 'lubrano',
            'VERSION' => '6.5',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/07/2009',
            'VERSION' => '1.0',
            'NAME' => 'ZoneMonitor',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
        },
        {
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.6',
            'PUBLISHER' => 'Apple',
            'NAME' => 'rcd',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'INSTALLDATE' => '12/03/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.0.4',
            'PUBLISHER' => 'Oracle',
            'NAME' => 'VirtualBox',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'FileMerge',
            'VERSION' => '2.5',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]'
        },
        {
            'VERSION' => '2.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'quicklookd',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '24/02/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.9.2.1599',
            'PUBLISHER' => 'Google Inc.',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'GoogleVoiceAndVideoUninstaller'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ODSAgent',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.4.1'
        },
        {
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8',
            'PUBLISHER' => 'Microsoft',
            'NAME' => 'Microsoft Database Daemon',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008'
        },
        {
            'INSTALLDATE' => '17/11/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0',
            'SYSTEM_CATEGORY' => 'Applications/DivX',
            'NAME' => 'Uninstall DivX for Mac'
        },
        {
            'INSTALLDATE' => '18/03/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '13.4.0',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Préférences Java'
        },
        {
            'VERSION' => '1.1',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '20/02/2011',
            'NAME' => 'Time Machine',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'TextEdit',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '27/06/2009',
            'VERSION' => '1.6'
        },
        {
            'VERSION' => '287',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'DiskImages UI Agent',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.1.4',
            'NAME' => 'Image Events',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '6.0.1',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Transfert d’images',
            'PUBLISHER' => 'Apple'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/07/2009',
            'VERSION' => '1.4',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Thread Viewer',
        },
        {
            'VERSION' => '2.1.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Inkjet1',
            'PUBLISHER' => 'Hewlett-Packard Development Company'
        },
        {
            'NAME' => 'AddPrinter',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '6.5',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Assistant Boot Camp',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '3.0.1'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'SRLanguageModeler',
            'VERSION' => '1.9',
            'INSTALLDATE' => '26/08/2010',
            'COMMENTS' => '[Intel]'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/03/2011',
            'VERSION' => '1.0.5',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'PubSubAgent'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'fax',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'VERSION' => '4.1',
            'INSTALLDATE' => '23/04/2010',
            'COMMENTS' => '[Intel]'
        },
        {
            'VERSION' => '10.6',
            'INSTALLDATE' => '31/07/2009',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Assistant réglages',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '2.0',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Service de résumé',
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '8.1.0',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'NAME' => 'HP Printer Utility',
            'SYSTEM_CATEGORY' => 'Library/Printers',
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'UnmountAssistantAgent',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '03/07/2009'
        },
        {
            'VERSION' => '2.1.1',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'Terminal',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'VietnameseIM',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '1.1'
        },
        {
            'NAME' => 'Kotoeri',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '4.2.0',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '11/06/2009'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/03/2011',
            'VERSION' => '17289',
            'SYSTEM_CATEGORY' => 'Library/Frameworks',
            'NAME' => 'Network Diagnostic Utility'
        },
        {
            'VERSION' => '1.1.4',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Configuration actions de dossier',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8',
            'PUBLISHER' => 'Microsoft',
            'NAME' => 'Bibliothèque de projets Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
        },
        {
            'NAME' => 'Microsoft PowerPoint',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '12.2.8',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '27/12/2010'
        },
        {
            'NAME' => 'Premiers contacts avec iWeb',
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'VERSION' => '1.0.2',
            'INSTALLDATE' => '01/07/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'NAME' => 'Dashcode',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '3.0.2'
        },
        {
            'INSTALLDATE' => '15/02/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.0',
            'SYSTEM_CATEGORY' => 'opt/cisco',
            'NAME' => 'vpndownloader'
        },
        {
            'NAME' => 'Utilitaire d’emplacement d’extension',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.4.1',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'GarageBand',
            'INSTALLDATE' => '01/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '4.1.2'
        },
        {
            'VERSION' => '1.1',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Automator Runner',
            'PUBLISHER' => 'Apple'
        },
        {
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'NAME' => 'pdftopdf',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '16/04/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.3'
        },
        {
            'INSTALLDATE' => '01/07/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.1.26',
            'PUBLISHER' => 'Lexmark International',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'LexmarkCUPSDriver',
        },
        {
            'VERSION' => '12.1.0',
            'INSTALLDATE' => '02/07/2009',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Equation Editor',
            'PUBLISHER' => 'Microsoft'
        },
        {
            'VERSION' => '3.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'NAME' => 'Inkjet',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'Hewlett-Packard Development Company'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'MassStorageCamera',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0.3'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'VERSION' => '2.1',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'NAME' => 'Inkjet8',
            'SYSTEM_CATEGORY' => 'Library/Printers'
        },
        {
            'INSTALLDATE' => '20/02/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.0',
            'NAME' => 'App Store',
            'SYSTEM_CATEGORY' => 'Applications',
        },
        {
            'VERSION' => '10.1.102.64',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '11/11/2010',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Adobe Flash Player Install Manager',
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Quartz Composer Visualizer',
            'VERSION' => '1.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'h-color-hp- imprimante couleur',
            'USERNAME' => 'lubrano',
            'VERSION' => '6.5',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'NAME' => 'TamilIM',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '1.3'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Console',
            'INSTALLDATE' => '07/04/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '10.6.3'
        },
        {
            'INSTALLDATE' => '23/09/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '9.4.2',
            'PUBLISHER' => 'Adobe Systems Inc.',
            'NAME' => 'Adobe Reader',
            'SYSTEM_CATEGORY' => 'Applications/Adobe Reader 9'
        },
        {
            'VERSION' => '3.0.1',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'kcSync',
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '5.0.3',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'File Sync',
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '24/02/2011',
            'VERSION' => '1.9.2.1599',
            'PUBLISHER' => 'Google Inc.',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'GoogleTalkPlugin',
        },
        {
            'NAME' => 'MallocDebug',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.7.1'
        },
        {
            'VERSION' => '8.0',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '13/03/2011',
            'USERNAME' => 'lubrano',
            'NAME' => 'Uninstall Cisco Network Assistant',
            'SYSTEM_CATEGORY' => 'Cisco_Network_Assistant/Uninstall_Cisco Network Assistant',
            'PUBLISHER' => 'Macrovision'
        },
        {
            'NAME' => 'Shark',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.7.3'
        },
        {
            'VERSION' => '1.1.0',
            'COMMENTS' => '[PowerPC]',
            'INSTALLDATE' => '17/11/2009',
            'NAME' => 'DivX Community',
            'SYSTEM_CATEGORY' => 'Applications/DivX',
        },
        {
            'NAME' => 'Utilitaire d’archive',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '18/06/2009',
            'VERSION' => '10.6'
        },
        {
            'NAME' => 'Canon IJScanner2',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'PUBLISHER' => 'CANON INC.',
            'VERSION' => '1.0.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '15/06/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Frameworks',
            'NAME' => 'Log Viewer',
            'VERSION' => '17289',
            'INSTALLDATE' => '09/03/2011',
            'COMMENTS' => '[Intel]'
        },
        {
            'COMMENTS' => '[PowerPC]',
            'INSTALLDATE' => '06/12/2007',
            'VERSION' => '10.0.0',
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Query',
        },
        {
            'VERSION' => '2.0.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'AddressBookManager',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'VERSION' => '4.7.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'CHUD Remover',
        },
        {
            'VERSION' => '1.5',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Capture',
        },
        {
            'VERSION' => '6.0.3',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/07/2009',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Messenger',
            'PUBLISHER' => 'Microsoft'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'BluetoothUIServer',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '2.3.8'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '2.3.8',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AVRCPAgent',
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'store_helper',
            'INSTALLDATE' => '20/02/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.0'
        },
        {
            'INSTALLDATE' => '09/07/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '8.02',
            'PUBLISHER' => 'SEIKO EPSON',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'EPIJAutoSetupTool2',
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '1.0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'InkServer'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '5.3',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Property List Editor',
        },
        {
            'NAME' => 'VidyoDesktop',
            'SYSTEM_CATEGORY' => 'Applications/Vidyo',
            'INSTALLDATE' => '19/10/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.0'
        },
        {
            'VERSION' => '5.2',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'SecurityAgent',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'NAME' => 'Build Applet',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'PUBLISHER' => 'Python Software Foundation.',
            'VERSION' => '2.5.4',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Canon IJ Printer Utility',
            'PUBLISHER' => 'CANON INC.',
            'VERSION' => '7.17.10',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '15/06/2009'
        },
        {
            'NAME' => 'Éditeur d\'équations Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '13/01/2011',
            'VERSION' => '14.0.0'
        },
        {
            'USERNAME' => 'lubrano',
            'NAME' => 'Zimbra Desktop désinstallateur',
            'SYSTEM_CATEGORY' => 'zimbra/zdesktop',
            'VERSION' => '1.0.4',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Universal]'
        },
        {
            'NAME' => 'Microsoft Word',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '12.2.8',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]'
        },
        {
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8',
            'PUBLISHER' => 'Microsoft',
            'NAME' => 'Microsoft Graph',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '11/01/2011',
            'VERSION' => '1.4.1',
            'PUBLISHER' => 'The Adium Team',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Adium'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Spaces',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.1',
            'INSTALLDATE' => '20/02/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => 'Apple',
            'NAME' => 'Automator',
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.1.1'
        },
        {
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Document Connection',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8'
        },
        {
            'VERSION' => '2.3.8',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'BluetoothAudioAgent',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Jar Launcher',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/03/2011',
            'VERSION' => '13.4.0'
        },
        {
            'NAME' => 'Cisco AnyConnect VPN Client',
            'SYSTEM_CATEGORY' => 'Applications/Cisco',
            'INSTALLDATE' => '15/02/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.0'
        },
        {
            'NAME' => 'Centre de téléchargement Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '14.0.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '13/01/2011'
        },
        {
            'VERSION' => '2.3.6',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'NAME' => 'PacketLogger',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'Uninstall AnyConnect',
            'SYSTEM_CATEGORY' => 'Applications/Cisco',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '15/02/2010',
            'VERSION' => '1.0'
        },
        {
            'NAME' => 'PreferenceSyncClient',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/07/2009',
            'VERSION' => '2.0'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '1.3',
            'NAME' => 'Yahoo! Sync',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Utilitaire de réseau',
            'INSTALLDATE' => '25/06/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.4.6'
        },
        {
            'VERSION' => '7.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Aide-mémoire',
        },
        {
            'VERSION' => '6.0.11994.637942',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '08/03/2011',
            'NAME' => 'Parallels Transporter',
            'SYSTEM_CATEGORY' => 'Library/Parallels',
            'PUBLISHER' => 'Parallels Holdings'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '4.7.3',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'SpindownHD',
        },
        {
            'VERSION' => '2.00',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '29/06/2009',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'P-touch Status Monitor',
            'PUBLISHER' => 'Brother Industries'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '17/09/2010',
            'VERSION' => '1.2.0',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Nimbuzz'
        },
        {
            'VERSION' => '1.5',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Universal]',
            'NAME' => 'MiniTerm',
            'SYSTEM_CATEGORY' => 'usr/libexec',
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'iChat',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '07/07/2010',
            'VERSION' => '5.0.3'
        },
        {
            'VERSION' => '2.2.5',
            'INSTALLDATE' => '13/01/2011',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'Signalement d\'erreurs Microsoft',
            'PUBLISHER' => 'Microsoft'
        },
        {
            'VERSION' => '14.0.2',
            'INSTALLDATE' => '13/01/2011',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011',
            'NAME' => 'SyncServicesAgent',
            'PUBLISHER' => 'Microsoft'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Install Helper',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/02/2010',
            'VERSION' => '1.0'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'PowerPC Help',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.7.3'
        },
        {
            'NAME' => 'HALLab',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.6'
        },
        {
            'PUBLISHER' => 'Hewlett-Packard Company',
            'NAME' => 'HPScanner',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '24/07/2009',
            'VERSION' => '1.1.52'
        },
        {
            'NAME' => 'commandtohp',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'Hewlett-Packard Development Company',
            'VERSION' => '1.11',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '15/06/2009'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '29/05/2009',
            'VERSION' => '3.8.1',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Speech Startup'
        },
        {
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '19/05/2009',
            'NAME' => 'wxPerl',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'NAME' => 'About Xcode',
            'SYSTEM_CATEGORY' => 'Developer',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '169.2'
        },
        {
            'INSTALLDATE' => '26/08/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.0',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Accessibility Inspector',
            'SYSTEM_CATEGORY' => 'Developer/Applications'
        },
        {
            'NAME' => 'Java VisualVM',
            'SYSTEM_CATEGORY' => 'usr/share',
            'VERSION' => '13.4.0',
            'INSTALLDATE' => '18/03/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Type7Camera',
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'iSync Plug-in Maker',
            'VERSION' => '3.1',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => 'Microsoft',
            'NAME' => 'Microsoft Database Utility',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'TWAINBridge',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.0.1',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'NAME' => 'Extract',
            'VERSION' => undef,
            'INSTALLDATE' => '25/04/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '5.2',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Syncrospector',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'DivX Converter',
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '28/12/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.3'
        },
        {
            'NAME' => 'ServerJoiner',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/07/2009',
            'VERSION' => '10.6.3'
        },
        {
            'NAME' => 'VoiceOver Quickstart',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '3.4.0'
        },
        {
            'VERSION' => '4.7.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'EM64T Help',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
        },
        {
            'NAME' => 'Moniteur d’activité',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'VERSION' => '10.6',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '31/07/2009'
        },
        {
            'VERSION' => '4.1',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '23/04/2010',
            'NAME' => 'rastertofax',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'Hewlett-Packard Development Company'
        }
    ],
    'sample3' => [
        {
            'NAME' => 'Utilitaire de réseau',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.9.2',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '07/24/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '13,0',
            'NAME' => 'Messages'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,1',
            'PUBLISHER' => 'Apple',
            'NAME' => 'TextInputSwitcher'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'NAME' => 'Calibration Assistant'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '07/24/2020',
            'VERSION' => '10.15.8',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Finder'
        },
        {
            'NAME' => 'SSMenuAgent',
            'VERSION' => '3.9.8',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/18/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'NAME' => 'Lecteur DVD',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '6,0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'INSTALLDATE' => '06/15/2020',
            'VERSION' => '10,0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'IMTransferAgent'
        },
        {
            'NAME' => "Moniteur d\x{2019}activit\x{e9}",
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '10,14'
        },
        {
            'NAME' => 'Dock',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,8',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'NAME' => 'Microsoft Outlook',
            'VERSION' => '16.66.1',
            'PUBLISHER' => 'Microsoft',
            'INSTALLDATE' => '07/19/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5,0',
            'NAME' => 'UnmountAssistantAgent'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/06/2020',
            'NAME' => 'Météo'
        },
        {
            'NAME' => 'GlobalProtect',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '07/19/2020',
            'VERSION' => '6.0.5-30',
            'PUBLISHER' => 'Palo Alto Networks'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'KerberosMenuExtra'
        },
        {
            'NAME' => 'Xcode Server Builder',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '12/22/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications/Xcode.app'
        },
        {
            'NAME' => 'Rappels',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '7,0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]'
        },
        {
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'UnRarX',
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => 'UnRarX version 2.2',
            'INSTALLDATE' => '07/07/2020'
        },
        {
            'NAME' => 'Spotlight',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/17/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AppSSOAgent'
        },
        {
            'NAME' => 'AquaAppearanceHelper',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '12/18/2020',
            'PUBLISHER' => 'Zoom Video Communications',
            'VERSION' => '5.16.10 (25689)',
            'NAME' => 'zoom'
        },
        {
            'NAME' => 'Appareils jumelés',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.9.5',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'NAME' => 'FollowUpUI',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'NAME' => 'LocationMenu',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => 15,
            'PUBLISHER' => 'Apple',
            'NAME' => 'AirScanLegacyDiscovery'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Simulateur de widget'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'PUBLISHER' => 'Palo Alto Networks',
            'VERSION' => '7.9.101',
            'INSTALLDATE' => '03/11/2020',
            'NAME' => 'Cortex XDR Agent'
        },
        {
            'NAME' => 'Install in Progress',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '3,0'
        },
        {
            'VERSION' => '1,71',
            'PUBLISHER' => 'EPSON',
            'INSTALLDATE' => '08/19/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'commandFilter'
        },
        {
            'NAME' => 'screencaptureui',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'storeuid'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '2394.0.22',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'CoreLocationAgent'
        },
        {
            'NAME' => 'Photo Library Migration Utility',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2,0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '07/24/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Ordinateur'
        },
        {
            'NAME' => 'Famille',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'VERSION' => '3,5',
            'INSTALLDATE' => '06/06/2020',
            'NAME' => 'Configuration audio et MIDI'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '2,7',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Grapher'
        },
        {
            'NAME' => 'Install Command Line Developer Tools',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => 2373
        },
        {
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ThermalTrap'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Diagnostics sans fil'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/CodonCode Aligner',
            'COMMENTS' => '[32/64-bit]',
            'INSTALLDATE' => '12/19/2020',
            'PUBLISHER' => 'CodonCode',
            'VERSION' => '5.1.4',
            'NAME' => 'CodonCode Aligner'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => 15,
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AirScanScanner'
        },
        {
            'INSTALLDATE' => '10/30/2020',
            'VERSION' => '10,13',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Problem Reporter'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '2,0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => "Utilitaire de logement d\x{2019}extension"
        },
        {
            'NAME' => 'AOSAlertManager',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,07'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => 20,
            'PUBLISHER' => 'Apple',
            'NAME' => 'PluginIM'
        },
        {
            'NAME' => 'AOSHeartbeat',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,07'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6,0',
            'NAME' => 'HelpViewer'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '9.0.15',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'NAME' => 'SpeechRecognitionServer'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '5,0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Captive Network Assistant'
        },
        {
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/10/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'NowPlayingWidgetContainer'
        },
        {
            'NAME' => 'Image Events',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.1.6',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,2',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Configuration des actions de dossier'
        },
        {
            'NAME' => 'Jeux',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'NAME' => 'Photos',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/08/2020',
            'VERSION' => '5,0',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => '11-0247-srvimp.inra',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'VERSION' => 15,
            'USERNAME' => 'fbudar',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'NAME' => 'WiFiAgent',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '13,0',
            'INSTALLDATE' => '08/28/2020'
        },
        {
            'NAME' => 'Mail',
            'PUBLISHER' => 'Apple',
            'VERSION' => '13,4',
            'INSTALLDATE' => '07/24/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'NAME' => 'PIPAgent'
        },
        {
            'INSTALLDATE' => '06/15/2020',
            'VERSION' => '5,0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Assistant de certification'
        },
        {
            'NAME' => 'loginwindow',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/15/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '9,0'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '24.050.0310',
            'INSTALLDATE' => '04/02/2020',
            'NAME' => 'OneDrive'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/06/2020',
            'NAME' => 'EmojiFunctionRowIM'
        },
        {
            'VERSION' => '12,4',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '01/09/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Xcode'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'VERSION' => '4,69',
            'PUBLISHER' => 'Microsoft',
            'INSTALLDATE' => '03/13/2020',
            'NAME' => 'Microsoft AutoUpdate'
        },
        {
            'NAME' => 'Cyberduck',
            'INSTALLDATE' => '05/30/2020',
            'PUBLISHER' => 'David Kocher',
            'VERSION' => '8.6.0',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'Livre des polices',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '10,0',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'AXVisualSupportAgent',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2,5',
            'INSTALLDATE' => '06/25/2020',
            'NAME' => 'Bourse'
        },
        {
            'NAME' => 'UniversalAccessHUD',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'NAME' => 'Microsoft Teams classic',
            'INSTALLDATE' => '10/11/2020',
            'VERSION' => '1.00.627656',
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'Échange de fichiers Bluetooth',
            'INSTALLDATE' => '07/24/2020',
            'VERSION' => '7.0.6',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]'
        },
        {
            'VERSION' => '11,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/22/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AddressBookSourceSync'
        },
        {
            'NAME' => 'ImageCaptureService',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '6,7',
            'PUBLISHER' => 'Apple'
        },
        {
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Fiji',
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => 1,
            'INSTALLDATE' => '03/28/2020'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '5,0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ScreenSaverEngine'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '2,1',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'AppleFileServer'
        },
        {
            'NAME' => 'AccessibilityVisualsAgent',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'NAME' => 'ARDAgent_0',
            'INSTALLDATE' => '06/18/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '3.9.8',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'iCloud Drive_0',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '08/24/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Cocoa-AppleScript Applet',
            'SYSTEM_CATEGORY' => 'Library/Application Support'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '4,1',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Visualiseur de ticket'
        },
        {
            'VERSION' => '7.0.6',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/30/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'BluetoothUIServer'
        },
        {
            'NAME' => 'Match',
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '01/18/2020',
            'VERSION' => undef,
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'Dictionnaire',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2.3.0',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'VERSION' => '10,1',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Création de page web'
        },
        {
            'PUBLISHER' => 'Labtiva Inc',
            'VERSION' => '3.4.25',
            'INSTALLDATE' => '10/13/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Papers 3 (Legacy)'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '4.11.0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Étalonnage de moniteur'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '07/24/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'NAME' => 'iCloud Drive'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'nbagent'
        },
        {
            'NAME' => 'AppleMobileDeviceHelper',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Apple',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5,0',
            'INSTALLDATE' => '08/28/2020'
        },
        {
            'NAME' => 'SpacesTouchBarAgent',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => 20,
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'RegisterPluginIMApp'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '07/24/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'NAME' => 'Localiser'
        },
        {
            'VERSION' => '10,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/15/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'imagent'
        },
        {
            'INSTALLDATE' => '06/22/2020',
            'VERSION' => '11,0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'ABAssistantService'
        },
        {
            'NAME' => 'Automator',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2,10',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'Simulator',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications/Xcode.app',
            'VERSION' => '12,4',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '12/19/2020'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '6,2',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'NetAuthAgent'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '07/24/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'NAME' => 'Gestion du stockage'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'TextInputMenuAgent'
        },
        {
            'INSTALLDATE' => '06/05/2020',
            'VERSION' => '1,62',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Library/Apple',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'MRT'
        },
        {
            'NAME' => 'JapaneseIM',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0'
        },
        {
            'NAME' => 'TextEdit',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,15',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'RapportUIAgent',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1.9.5',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'AddressBookSync',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '11,0',
            'INSTALLDATE' => '06/22/2020'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.1.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => '50onPaletteServer'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2,10',
            'INSTALLDATE' => '06/06/2020',
            'NAME' => "Programme d\x{2019}installation d\x{2019}Automator"
        },
        {
            'INSTALLDATE' => '07/19/2020',
            'VERSION' => 'R 3.6.3 GUI 1.70 El Capitan build',
            'NAME' => 'R',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'PressAndHold',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'NAME' => 'WebKitPluginHost',
            'INSTALLDATE' => '09/01/2020',
            'VERSION' => 609,
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '4,1',
            'INSTALLDATE' => '06/18/2020',
            'NAME' => 'VirtualScanner'
        },
        {
            'NAME' => 'Set Info',
            'INSTALLDATE' => '01/18/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => undef,
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'ScriptMonitor',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.0.1'
        },
        {
            'NAME' => 'FileMerge',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2,11',
            'INSTALLDATE' => '12/19/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications/Xcode.app'
        },
        {
            'NAME' => 'CoreServicesUIAgent',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '340,3',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '6,7',
            'PUBLISHER' => 'Apple',
            'NAME' => 'AutoImporter'
        },
        {
            'NAME' => 'FolderActionsDispatcher',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'AVB Audio Configuration',
            'PUBLISHER' => 'Apple',
            'VERSION' => '850,1',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'NAME' => 'TrackpadIM',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '08/19/2020',
            'PUBLISHER' => 'EPSON',
            'VERSION' => '1,71',
            'NAME' => 'epsonfax'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'NAME' => 'iCloud'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.1.2',
            'INSTALLDATE' => '06/06/2020',
            'NAME' => 'Utilitaire AppleScript'
        },
        {
            'NAME' => 'Éditeur de script',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2,11',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => "Trousseaux d\x{2019}acc\x{e8}s",
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '07/24/2020',
            'VERSION' => '10,5',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'GoogleUpdater',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'COMMENTS' => '[64-bit]',
            'USERNAME' => 'admin',
            'INSTALLDATE' => '03/04/2020',
            'PUBLISHER' => 'Google LLC',
            'VERSION' => '122.0.6234.0'
        },
        {
            'NAME' => 'iCloudUserNotificationsd',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'Kyocera Print Panel',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Kyocera Document Solutions Inc.',
            'VERSION' => '5.4.0516',
            'INSTALLDATE' => '07/19/2020'
        },
        {
            'NAME' => 'Utilitaire de logement de mémoire',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1.5.3',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'IDSRemoteURLConnectionAgent',
            'INSTALLDATE' => '06/18/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '10,0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'GIMP-2',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'GNOME Foundation',
            'VERSION' => '2.10.32',
            'INSTALLDATE' => '06/13/2020'
        },
        {
            'NAME' => 'CMake',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '09/20/2020',
            'VERSION' => '3.27.6',
            'PUBLISHER' => 'Kitware Inc.'
        },
        {
            'NAME' => 'Widget Bourse',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'VERSION' => '10,5',
            'INSTALLDATE' => '07/24/2020',
            'NAME' => 'QuickTime Player'
        },
        {
            'NAME' => 'rastertoepfax',
            'INSTALLDATE' => '08/19/2020',
            'VERSION' => '1,71',
            'PUBLISHER' => 'EPSON',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'Utilitaire VoiceOver',
            'VERSION' => 10,
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '08/07/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'INSTALLDATE' => '07/19/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '3.8.2',
            'SYSTEM_CATEGORY' => 'Library/Developer',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Python'
        },
        {
            'NAME' => 'Aperçu',
            'PUBLISHER' => 'Apple',
            'VERSION' => '11,0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'NAME' => 'Musique',
            'INSTALLDATE' => '06/29/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.0.6',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '8,1',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Résolution des conflits'
        },
        {
            'NAME' => 'AddPrinter',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => 15,
            'PUBLISHER' => 'Apple'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '559.100.2',
            'INSTALLDATE' => '06/06/2020',
            'NAME' => 'DiskImageMounter'
        },
        {
            'NAME' => 'Reset Serial Cloner',
            'INSTALLDATE' => '07/19/2020',
            'PUBLISHER' => 'Franck Perez',
            'VERSION' => undef,
            'SYSTEM_CATEGORY' => 'Applications/SerialCloner2-6',
            'COMMENTS' => '[32-bit (Unsupported)]'
        },
        {
            'INSTALLDATE' => '03/11/2020',
            'VERSION' => '7.9.101',
            'PUBLISHER' => 'Palo Alto Networks',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Cortex XDR Uninstaller'
        },
        {
            'NAME' => 'AddressBookUrlForwarder',
            'VERSION' => '11,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/22/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'NAME' => 'Keychain Circle Notification',
            'INSTALLDATE' => '06/15/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'VERSION' => '124.0.1',
            'PUBLISHER' => 'Mozilla',
            'INSTALLDATE' => '03/25/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Firefox'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'NAME' => 'PowerChime'
        },
        {
            'NAME' => 'Skype Entreprise',
            'VERSION' => '16.30.32',
            'PUBLISHER' => 'Skype Communications S.a.r.l',
            'INSTALLDATE' => '09/23/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '2.0.1',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'NAME' => 'CharacterPalette'
        },
        {
            'VERSION' => '7.9.101',
            'PUBLISHER' => 'Palo Alto Networks',
            'INSTALLDATE' => '03/11/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'Cortex XDR Configuration Wizard'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/11/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ControlStrip'
        },
        {
            'NAME' => 'Réseau',
            'INSTALLDATE' => '07/24/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'System Events',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1.3.6',
            'PUBLISHER' => 'Apple'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'universalAccessAuthWarn'
        },
        {
            'NAME' => 'Utilitaire de disque',
            'PUBLISHER' => 'Apple',
            'VERSION' => '19,0',
            'INSTALLDATE' => '07/24/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'VERSION' => '2,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Assistive Control'
        },
        {
            'NAME' => 'AppleMobileSync',
            'INSTALLDATE' => '08/28/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5,0',
            'SYSTEM_CATEGORY' => 'Library/Apple',
            'COMMENTS' => '[64-bit]'
        },
        {
            'INSTALLDATE' => '07/24/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5,0',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'FaceTime'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '12,3',
            'INSTALLDATE' => '06/08/2020',
            'NAME' => 'ManagedClient'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'KeyboardAccessAgent'
        },
        {
            'NAME' => 'OBEXAgent',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '7.0.6',
            'INSTALLDATE' => '06/30/2020'
        },
        {
            'NAME' => 'Time Machine',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,3'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'ApE',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '03/14/2020',
            'VERSION' => '3.1.4'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'EPSON',
            'VERSION' => '1,73',
            'INSTALLDATE' => '08/19/2020',
            'NAME' => 'FAX Utility'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/18/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '10,1',
            'NAME' => 'PTPCamera'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '01/18/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => undef,
            'NAME' => 'Extract'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/PDF Services',
            'VERSION' => '11.1.2',
            'PUBLISHER' => 'Foxit',
            'USERNAME' => 'admin-pri',
            'INSTALLDATE' => '07/21/2020',
            'NAME' => 'Save as Foxit PDF'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '15.0.1',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'NAME' => 'Java Web Start'
        },
        {
            'NAME' => 'Setup',
            'VERSION' => '1.0.135.0',
            'PUBLISHER' => 'Adobe Systems Inc.',
            'INSTALLDATE' => '04/03/2020',
            'USERNAME' => 'admin-pri',
            'COMMENTS' => '[32-bit (Unsupported)]'
        },
        {
            'NAME' => "Transfert d\x{2019}images",
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '8,0'
        },
        {
            'VERSION' => '13,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'eaptlstrust'
        },
        {
            'INSTALLDATE' => '07/19/2020',
            'VERSION' => '1.0.3629',
            'PUBLISHER' => 'Kyocera Document Solutions Inc.',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'COMMENTS' => '[32/64-bit]',
            'NAME' => 'rastertokpsl'
        },
        {
            'NAME' => 'Aide-mémoire',
            'VERSION' => '10,2',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'NAME' => 'Mission Control',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,2'
        },
        {
            'NAME' => 'Reality Composer',
            'SYSTEM_CATEGORY' => 'Applications/Xcode.app',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '12/22/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,5'
        },
        {
            'NAME' => 'Contacts',
            'VERSION' => '12,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '07/24/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '10,7',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'KeyboardSetupAssistant'
        },
        {
            'NAME' => 'FinchTV',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => '1.3.0',
            'PUBLISHER' => 'Geospiza Inc.',
            'INSTALLDATE' => '04/02/2020'
        },
        {
            'VERSION' => '4.0.0',
            'PUBLISHER' => 'Canon Inc.',
            'INSTALLDATE' => '06/26/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'NAME' => 'Canon IJScanner2'
        },
        {
            'NAME' => 'Type4Camera',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/18/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '10,1'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '07/24/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Récents'
        },
        {
            'NAME' => 'SoftwareUpdateNotificationManager',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '09/03/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'PUBLISHER' => 'Foxit',
            'VERSION' => '11.1.2',
            'USERNAME' => 'fbudar',
            'INSTALLDATE' => '04/02/2020',
            'NAME' => 'FoxitPDFEditorUpdateService'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '07/24/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Récents_0'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '4,6',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => "Assistant d\x{2019}\x{e9}valuation"
        },
        {
            'NAME' => 'rastertopcl_F',
            'PUBLISHER' => 'Kyocera Document Solutions Inc.',
            'VERSION' => '5.4.0401',
            'INSTALLDATE' => '07/19/2020',
            'COMMENTS' => '[32/64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Printers'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '4.14.0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'NAME' => 'Utilitaire ColorSync'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '4,0',
            'INSTALLDATE' => '06/12/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'NAME' => 'Maison'
        },
        {
            'VERSION' => '8.5.9',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Wish'
        },
        {
            'NAME' => 'identityservicesd',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/18/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '10,0'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '10,13',
            'INSTALLDATE' => '10/30/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ReportPanic'
        },
        {
            'NAME' => 'Assistant migration',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '10,15',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'VoiceOver',
            'INSTALLDATE' => '08/07/2020',
            'VERSION' => 10,
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'Dictaphone',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2,1',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]'
        },
        {
            'INSTALLDATE' => '12/22/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5,0',
            'SYSTEM_CATEGORY' => 'Applications/Xcode.app',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Accessibility Inspector'
        },
        {
            'NAME' => 'TYIM',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2,1',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Plans'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.3.9',
            'NAME' => 'Utilitaire AirPort'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '07/24/2020',
            'VERSION' => '10,15',
            'PUBLISHER' => 'Apple',
            'NAME' => "Utilitaire d\x{2019}archive"
        },
        {
            'NAME' => 'Colorimètre numérique',
            'VERSION' => '5,15',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'NAME' => "Utilitaire d\x{2019}annuaire",
            'INSTALLDATE' => '07/24/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6,0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'Foxit PDF Editor',
            'PUBLISHER' => 'Foxit',
            'VERSION' => '11.1.2.0420',
            'INSTALLDATE' => '07/21/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'NAME' => 'Google Chrome',
            'PUBLISHER' => 'Google LLC',
            'VERSION' => '103.0.5060.134',
            'INSTALLDATE' => '07/19/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => 15,
            'INSTALLDATE' => '06/06/2020',
            'NAME' => 'PrinterProxy'
        },
        {
            'NAME' => 'App Store',
            'PUBLISHER' => 'Apple',
            'VERSION' => '3,0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.0.0',
            'NAME' => 'Podcasts'
        },
        {
            'NAME' => 'Menu des scripts',
            'PUBLISHER' => 'Apple',
            'VERSION' => 1,
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '8,0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'CalendarFileHandler'
        },
        {
            'NAME' => 'ODSAgent',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1,8',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => 62,
            'NAME' => 'SocialPushAgent'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1.0.6',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Database Events'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '6.2.0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => "Programme d\x{2019}installation"
        },
        {
            'NAME' => 'Create ML',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications/Xcode.app',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2,0',
            'INSTALLDATE' => '12/22/2020'
        },
        {
            'NAME' => 'SpeechSynthesisServer',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '9.0.24',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'FindMyMacMessenger',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '4,1',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '07/19/2020',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '16.66.1',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Microsoft OneNote'
        },
        {
            'NAME' => 'Moniteur de réception de fax',
            'INSTALLDATE' => '08/19/2020',
            'VERSION' => '1,71',
            'PUBLISHER' => 'EPSON',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'DiskImages UI Agent',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '559.100.2',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'Assistant réglages',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '10,10',
            'INSTALLDATE' => '10/29/2020'
        },
        {
            'INSTALLDATE' => '06/26/2020',
            'VERSION' => '4.0.0',
            'PUBLISHER' => 'Canon Inc.',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Canon IJScanner6'
        },
        {
            'NAME' => 'Dictée vocale',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.0.60.1',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Schrodinger',
            'VERSION' => '2.5.5',
            'INSTALLDATE' => '04/11/2020',
            'NAME' => 'PyMOL'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '01/18/2020',
            'VERSION' => undef,
            'PUBLISHER' => 'Apple',
            'NAME' => 'Embed'
        },
        {
            'NAME' => 'Remove',
            'INSTALLDATE' => '01/18/2020',
            'VERSION' => undef,
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'COMMENTS' => '[64-bit]'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AskPermissionUI'
        },
        {
            'NAME' => 'FontRegistryUIAgent',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '81,0',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'Siri',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/11/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '200.6.1'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => 104,
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'CIMFindInputCodeTool'
        },
        {
            'NAME' => 'VietnameseIM',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'Assistant réglages Bluetooth',
            'INSTALLDATE' => '06/30/2020',
            'VERSION' => '7.0.6',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/18/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Quick Look Simulator'
        },
        {
            'NAME' => "Capture d\x{2019}\x{e9}cran",
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0'
        },
        {
            'PUBLISHER' => 'GSL Biotech LLC',
            'VERSION' => '7.0.1',
            'INSTALLDATE' => '06/20/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'SnapGene Viewer'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'TCIM'
        },
        {
            'NAME' => 'EscrowSecurityAlert',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/18/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'NAME' => 'OSDUIHelper'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => undef,
            'INSTALLDATE' => '01/18/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'NAME' => 'Proof'
        },
        {
            'NAME' => 'AirDrop',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '07/24/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Installer Progress'
        },
        {
            'NAME' => 'SerialCloner 2-6-1',
            'INSTALLDATE' => '07/19/2020',
            'VERSION' => '2.6.1',
            'PUBLISHER' => 'Franck Perez',
            'SYSTEM_CATEGORY' => 'Applications/SerialCloner2-6',
            'COMMENTS' => '[32-bit (Unsupported)]'
        },
        {
            'NAME' => 'UIKitSystem',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '3,17',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Échecs'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'SCIM'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '03/11/2020',
            'VERSION' => '7.9.101',
            'PUBLISHER' => 'Palo Alto Networks',
            'NAME' => 'Cortex XDR'
        },
        {
            'NAME' => 'Mise à jour de logiciels',
            'PUBLISHER' => 'Apple',
            'VERSION' => 6,
            'INSTALLDATE' => '09/03/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'NAME' => 'AddressBookManager',
            'PUBLISHER' => 'Apple',
            'VERSION' => '11,0',
            'INSTALLDATE' => '06/22/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'NAME' => 'TV',
            'INSTALLDATE' => '06/19/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.0.6',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'PUBLISHER' => 'Canon Inc.',
            'VERSION' => '4.0.0',
            'INSTALLDATE' => '06/26/2020',
            'NAME' => 'Canon IJScanner4'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/18/2020',
            'VERSION' => '5,0',
            'PUBLISHER' => 'Apple',
            'NAME' => 'quicklookd'
        },
        {
            'NAME' => 'AinuIM',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '07/24/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '14,0',
            'NAME' => 'Préférences Système'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '10.15.4',
            'NAME' => 'Calculette'
        },
        {
            'NAME' => 'SystemUIServer',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,7',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'VERSION' => '10,1',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'MakePDF'
        },
        {
            'NAME' => 'Microsoft Excel',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '16.66.1',
            'INSTALLDATE' => '07/19/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '3.3.0',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'UserNotificationCenter'
        },
        {
            'NAME' => 'IMAutomaticHistoryDeletionAgent',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '10,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/15/2020'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '08/28/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Apple',
            'NAME' => 'MobileDeviceUpdater'
        },
        {
            'NAME' => 'Launchpad',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/15/2020',
            'NAME' => 'Jumelage de la SmartCard'
        },
        {
            'NAME' => 'Photo Booth',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '11,0',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => 'Rename',
            'VERSION' => undef,
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '01/18/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Scripts'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '07/24/2020',
            'VERSION' => '10,14',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Informations système'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2,0',
            'INSTALLDATE' => '08/28/2020',
            'NAME' => 'AirPlayUIAgent'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'NAME' => 'Dwell Control'
        },
        {
            'NAME' => 'Livres',
            'INSTALLDATE' => '08/07/2020',
            'VERSION' => '2,4',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'NAME' => 'STMUIHelper'
        },
        {
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '10/29/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Language Chooser'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,07',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'AOSPushRelay'
        },
        {
            'NAME' => 'qlmanage',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/18/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'NAME' => 'KoreanIM'
        },
        {
            'NAME' => 'Calendrier',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'VERSION' => '11,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'INSTALLDATE' => '08/19/2020',
            'PUBLISHER' => 'EPSON',
            'VERSION' => '1,71',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'EPFaxAutoSetupTool'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Siri_0'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '4,7',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Notes'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/18/2020',
            'VERSION' => '10,1',
            'PUBLISHER' => 'Apple',
            'NAME' => 'MassStorageCamera'
        },
        {
            'NAME' => 'À propos de ce Mac',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '07/24/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '2.7.16',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Python_0'
        },
        {
            'NAME' => 'Terminal',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'VERSION' => '2,10',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'NAME' => 'Jar Launcher',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '15.0.1'
        },
        {
            'NAME' => 'Assistant Boot Camp',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.1.0',
            'INSTALLDATE' => '06/08/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '07/07/2020',
            'PUBLISHER' => 'RStudio Inc.',
            'VERSION' => '2023.06.1+524',
            'NAME' => 'RStudio'
        },
        {
            'NAME' => 'ParentalControls',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '4,1',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'UniversalAccessControl',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '7,0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '16.66.1',
            'INSTALLDATE' => '07/19/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Microsoft PowerPoint'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '2.2.1',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'NAME' => "Agent de la borne d\x{2019}acc\x{e8}s AirPort"
        },
        {
            'NAME' => 'ScreenReaderUIServer',
            'VERSION' => 10,
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '08/07/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'NAME' => 'SyncServer',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '8,1',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'NAME' => 'QuickLookUIHelper',
            'INSTALLDATE' => '06/18/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5,0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => 360,
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'rcd'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '9.0.15',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Programme de téléchargement de parole'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Centre de notifications'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'DFRHUD'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2,0',
            'NAME' => 'Service de résumé'
        },
        {
            'NAME' => 'Safari',
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '07/24/2020',
            'VERSION' => '15.6.1',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '07/14/2020',
            'PUBLISHER' => 'THE BROAD INSTITUTE INC',
            'VERSION' => '2.16.2',
            'NAME' => 'IGV_2.16'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,1',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Console'
        },
        {
            'NAME' => 'Microsoft Word',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '16.66.1',
            'INSTALLDATE' => '07/19/2020'
        },
        {
            'NAME' => 'UASharedPasteboardProgressUI',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/19/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '54,1'
        },
        {
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'PodcastsAuthAgent'
        },
        {
            'INSTALLDATE' => '04/02/2020',
            'VERSION' => '12,4',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications/Xcode.app',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Instruments'
        },
        {
            'VERSION' => '3.9.8',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '07/24/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ARDAgent'
        },
        {
            'VERSION' => undef,
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '01/18/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'NAME' => 'Show Info'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/06/2020',
            'NAME' => 'DiscHelper'
        },
        {
            'NAME' => 'ChineseTextConverterService',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2,1',
            'INSTALLDATE' => '06/06/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'NAME' => 'Pass Viewer'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '08/07/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'SpeechSynthesizerAuditor'
        },
        {
            'INSTALLDATE' => '06/06/2020',
            'VERSION' => '1,0',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'HindiIM'
        },
        {
            'INSTALLDATE' => '08/07/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => 10,
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'Présentation de VoiceOver'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,0',
            'INSTALLDATE' => '06/10/2020',
            'NAME' => 'NowPlayingTouchUI'
        },
        {
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.7.2',
            'INSTALLDATE' => '06/18/2020',
            'NAME' => "Partage d\x{2019}\x{e9}cran"
        },
        {
            'NAME' => 'syncuid',
            'INSTALLDATE' => '06/06/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '8,1',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[64-bit]'
        },
        {
            'NAME' => '11-0247-srvimp.inra_0',
            'VERSION' => 15,
            'INSTALLDATE' => '06/06/2020',
            'USERNAME' => 'admin',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'Library/Printers'
        },
        {
            'INSTALLDATE' => '10/06/2020',
            'PUBLISHER' => 'EPSON',
            'VERSION' => '5.7.24',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'COMMENTS' => '[64-bit]',
            'NAME' => 'EPSON Scanner'
        },
        {
            'PUBLISHER' => 'Apple',
            'VERSION' => '1,6',
            'INSTALLDATE' => '06/06/2020',
            'COMMENTS' => '[64-bit]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'TamilIM'
        }
    ],
    'sample4' => [
        {
            'VERSION' => '1.5.3',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'Adobe AIR Updater',
            'SYSTEM_CATEGORY' => 'Library/Frameworks',
            'INSTALLDATE' => '09/08/2020'
        },
        {
            'NAME' => 'TrackpadIM',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Dock',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.8'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'XCPreviewAgent_0',
            'VERSION' => '13.3',
            'SYSTEM_CATEGORY' => 'System/iOSSupport',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => 25,
            'COMMENTS' => '[Universal]',
            'NAME' => 'RegisterPluginIMApp'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ManagedClient',
            'COMMENTS' => '[Universal]',
            'VERSION' => '14.2'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => 'FolderActionsDispatcher',
            'VERSION' => '1.0'
        },
        {
            'INSTALLDATE' => '04/17/2020',
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'VERSION' => '4.70',
            'NAME' => 'Microsoft AutoUpdate',
            'COMMENTS' => '[Universal]'
        },
        {
            'NAME' => 'AXVisualSupportAgent',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => 16,
            'NAME' => 'AirScanScanner',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'universalAccessAuthWarn',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Wish',
            'VERSION' => '8.5.9'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'ABAssistantService',
            'VERSION' => '11.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => "E\x{301}diteur de script",
            'VERSION' => '2.11',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Microsoft',
            'INSTALLDATE' => '06/14/2020',
            'VERSION' => '8.0.1',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'Messenger'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => "A\x{300} propos de ce Mac"
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '06/15/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Pages',
            'VERSION' => '6.2'
        },
        {
            'PUBLISHER' => 'Mozilla',
            'INSTALLDATE' => '04/10/2020',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Firefox',
            'COMMENTS' => '[Universal]',
            'VERSION' => '124.0.2'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '03/29/2020',
            'PUBLISHER' => 'Kyocera Document Solutions Inc.',
            'VERSION' => '5.4.0401',
            'COMMENTS' => '[Intel]',
            'NAME' => 'rastertopcl_F'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'AppleSpell',
            'VERSION' => '2.4',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'VERSION' => '1.0',
            'NAME' => 'Aide Cadran',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Lecteur DVD'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => "Appareils jumele\x{301}s",
            'COMMENTS' => '[Universal]',
            'VERSION' => '3.6.0'
        },
        {
            'NAME' => 'Quick Look Simulator',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => "Utilitaire de re\x{301}seau",
            'VERSION' => '1.9.2'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'HP Inc.',
            'INSTALLDATE' => '05/25/2020',
            'COMMENTS' => '[Intel]',
            'NAME' => 'fax',
            'VERSION' => '5.17.3'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Localiser',
            'VERSION' => '3.0',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => "Colorime\x{300}tre nume\x{301}rique",
            'COMMENTS' => '[Universal]',
            'VERSION' => '5.22',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => 'SoftwareUpdateNotificationManager',
            'VERSION' => '1.0'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'EPSON',
            'INSTALLDATE' => '08/19/2020',
            'COMMENTS' => '[Intel]',
            'NAME' => 'rastertoepfax',
            'VERSION' => '1.71'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'FontRegistryUIAgent',
            'COMMENTS' => '[Universal]',
            'VERSION' => '81.0'
        },
        {
            'VERSION' => '1.1.2',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Utilitaire AppleScript',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '2.0',
            'NAME' => "Service de re\x{301}sume\x{301}",
            'COMMENTS' => '[Universal]'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'AOSAlertManager',
            'VERSION' => '1.07',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '10.5',
            'COMMENTS' => '[Universal]',
            'NAME' => 'QuickTime Player',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'PUBLISHER' => 'Simone Lehmann',
            'INSTALLDATE' => '08/08/2020',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'GIMP',
            'COMMENTS' => '[Other]',
            'VERSION' => '2.8.14p2'
        },
        {
            'VERSION' => '1.5a8',
            'NAME' => 'DNA Strider',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'INSTALLDATE' => '06/04/2020',
            'SYSTEM_CATEGORY' => 'Applications/DNA Strider 1.5a9 Folder'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '06/15/2020',
            'VERSION' => '10.2.0',
            'COMMENTS' => '[Intel]',
            'NAME' => 'GarageBand_0'
        },
        {
            'VERSION' => '11.0',
            'NAME' => "Trousseaux d\x{2019}acce\x{300}s",
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'PUBLISHER' => 'EPSON',
            'INSTALLDATE' => '08/19/2020',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'VERSION' => '1.71',
            'NAME' => "Moniteur de re\x{301}ception de fax",
            'COMMENTS' => '[Intel]'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0',
            'NAME' => 'STMUIHelper',
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'INSTALLDATE' => '06/14/2020',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'Adobe AIR Uninstaller',
            'VERSION' => '1.5.3'
        },
        {
            'VERSION' => '1.71',
            'COMMENTS' => '[Intel]',
            'NAME' => 'epsonfax',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'EPSON',
            'INSTALLDATE' => '08/19/2020'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'KeyboardAccessAgent',
            'COMMENTS' => '[Universal]',
            'VERSION' => 10
        },
        {
            'NAME' => 'Template',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'VERSION' => '1.5.3',
            'INSTALLDATE' => '09/08/2020',
            'SYSTEM_CATEGORY' => 'Library/Frameworks'
        },
        {
            'NAME' => 'EPSON Scanner',
            'COMMENTS' => '[Intel]',
            'VERSION' => '5.7.24',
            'INSTALLDATE' => '10/06/2020',
            'PUBLISHER' => 'EPSON',
            'SYSTEM_CATEGORY' => 'Library/Image Capture'
        },
        {
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'SpacesTouchBarAgent',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Users/admin',
            'INSTALLDATE' => '04/05/2020',
            'VERSION' => '3_5',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Untitled'
        },
        {
            'VERSION' => '1.2.2',
            'COMMENTS' => '[Other]',
            'NAME' => 'Adobe Acrobat Updater',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Adobe Systems Inc.'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Pass Viewer'
        },
        {
            'INSTALLDATE' => '09/14/2020',
            'PUBLISHER' => 'Adobe Systems Inc.',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'Uninstall Product',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'VERSION' => '3.5.15.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'AirPort Base Station Agent',
            'VERSION' => '2.2.1'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'NAME' => 'Utilitaire de disque',
            'COMMENTS' => '[Universal]',
            'VERSION' => '21.5'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0',
            'NAME' => 'WidgetKit Simulator',
            'COMMENTS' => '[Universal]'
        },
        {
            'NAME' => 'Spotlight_0',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'EmojiFunctionRowIM',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'iCloud Drive',
            'VERSION' => '1.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'NAME' => 'UniversalAccessControl',
            'COMMENTS' => '[Universal]',
            'VERSION' => '7.0',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '72.100',
            'NAME' => 'UserNotificationCenter',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '6.3',
            'COMMENTS' => '[Universal]',
            'NAME' => 'JapaneseIM-KanaTyping',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1742.6.1',
            'COMMENTS' => '[Universal]',
            'NAME' => 'PTPCamera'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '06/14/2020',
            'PUBLISHER' => 'Bio-Rad Labs. Inc.',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'Image Lab',
            'VERSION' => '5.2'
        },
        {
            'VERSION' => '16.79.2',
            'NAME' => 'Microsoft PowerPoint',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Microsoft',
            'INSTALLDATE' => '02/21/2020',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'PUBLISHER' => 'XMind Ltd.',
            'INSTALLDATE' => '06/14/2020',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'XMind',
            'COMMENTS' => '[Intel]',
            'VERSION' => '8_Update_1'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'NAME' => "Pre\x{301}fe\x{301}rences Syste\x{300}me",
            'COMMENTS' => '[Universal]',
            'VERSION' => '15.0'
        },
        {
            'VERSION' => '8.1',
            'COMMENTS' => '[Universal]',
            'NAME' => 'syncuid',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'DiscHelper',
            'VERSION' => '1.0'
        },
        {
            'NAME' => 'SnapNDrag',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'VERSION' => '2.6.5',
            'INSTALLDATE' => '12/08/2020',
            'PUBLISHER' => 'Yellow Mug Software',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0',
            'NAME' => 'Ordinateur',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'HindiIM',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '10.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'identityservicesd'
        },
        {
            'NAME' => 'storeuid',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '3.3.1',
            'NAME' => 'OnyX',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '10/21/2020',
            'PUBLISHER' => 'Joel BARRIERE',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '8.1',
            'NAME' => "Re\x{301}solution des conflits",
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '2.80.1',
            'NAME' => 'Mendeley Reference Manager',
            'COMMENTS' => '[Intel]',
            'PUBLISHER' => 'Elsevier Inc.',
            'INSTALLDATE' => '10/27/2020',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'VERSION' => '9.0',
            'NAME' => 'loginwindow',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0',
            'NAME' => 'SCIM',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '2.12.7',
            'NAME' => 'Terminal',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'NAME' => 'Assistant migration',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.7'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'NAME' => 'Contacts',
            'COMMENTS' => '[Universal]',
            'VERSION' => '2498.5.1'
        },
        {
            'NAME' => 'Dictionnaire',
            'COMMENTS' => '[Universal]',
            'VERSION' => '2.3.0',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '6.1.27',
            'COMMENTS' => '[Universal]',
            'NAME' => "Dicte\x{301}e vocale"
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'VERSION' => 2395,
            'COMMENTS' => '[Universal]',
            'NAME' => 'Install Command Line Developer Tools'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'NAME' => 'Calculette',
            'COMMENTS' => '[Universal]',
            'VERSION' => '10.16'
        },
        {
            'VERSION' => 25,
            'NAME' => 'PluginIM',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'PUBLISHER' => 'David Kocher',
            'INSTALLDATE' => '11/04/2020',
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => '8.7.1',
            'NAME' => 'Cyberduck',
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'qlmanage',
            'VERSION' => '1.0'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'JavaLauncher',
            'COMMENTS' => '[Universal]',
            'VERSION' => 319
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/F-Secure',
            'INSTALLDATE' => '01/03/2020',
            'PUBLISHER' => 'F-Secure',
            'VERSION' => '3.0.51507',
            'COMMENTS' => '[Universal]',
            'NAME' => "WithSecure\x{2122} XFENCE"
        },
        {
            'VERSION' => '2.8',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Grapher',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Mek&Tosj.',
            'INSTALLDATE' => '06/14/2020',
            'VERSION' => 'EnzymeX 3.1',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'EnzymeX'
        },
        {
            'VERSION' => '2667.4.3.1',
            'NAME' => 'CoreLocationAgent',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => 131,
            'COMMENTS' => '[Universal]',
            'NAME' => 'XProtect',
            'SYSTEM_CATEGORY' => 'Library/Apple',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '04/24/2020'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'NAME' => 'Console',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.1'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Dwell Control',
            'VERSION' => '1.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Jumelage de la SmartCard',
            'VERSION' => '1.0'
        },
        {
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'Inkscape',
            'VERSION' => '0.91',
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '06/14/2020',
            'PUBLISHER' => 'Inkscape Developers'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'quicklookd',
            'COMMENTS' => '[Universal]',
            'VERSION' => '5.0'
        },
        {
            'VERSION' => '9.0.88.6',
            'NAME' => 'SpeechService',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.1.6',
            'NAME' => 'Image Events',
            'COMMENTS' => '[Universal]'
        },
        {
            'NAME' => "Connexion Bureau a\x{300} Distance",
            'COMMENTS' => '[32-bit (Unsupported)]',
            'VERSION' => '2.1.1',
            'INSTALLDATE' => '06/14/2020',
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'INSTALLDATE' => '08/19/2020',
            'PUBLISHER' => 'EPSON',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'VERSION' => '1.71',
            'NAME' => 'commandFilter',
            'COMMENTS' => '[Intel]'
        },
        {
            'PUBLISHER' => 'Microsoft',
            'INSTALLDATE' => '02/21/2020',
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => '16.79.2',
            'NAME' => 'Microsoft Word',
            'COMMENTS' => '[Universal]'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'AddressBookSourceSync',
            'VERSION' => '11.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Notes',
            'VERSION' => '4.9'
        },
        {
            'NAME' => 'TYIM',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Livres',
            'VERSION' => '4.4'
        },
        {
            'NAME' => 'HP Fax Archive',
            'COMMENTS' => '[Intel]',
            'VERSION' => '5.37.1',
            'INSTALLDATE' => '10/25/2020',
            'PUBLISHER' => 'HP Inc.',
            'SYSTEM_CATEGORY' => 'Library/Printers'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0',
            'NAME' => 'nbagent',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '13.3',
            'NAME' => 'XCPreviewAgent',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'PUBLISHER' => 'Microsoft',
            'INSTALLDATE' => '04/17/2020',
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => '16.84',
            'NAME' => 'Microsoft OneNote',
            'COMMENTS' => '[Universal]'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Family (OSX)',
            'VERSION' => '1.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0',
            'NAME' => 'DiskImageMounter',
            'COMMENTS' => '[Universal]'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'VERSION' => '4.3.2',
            'NAME' => 'Bourse',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Diagnostics Reporter',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => 'VoiceOver',
            'VERSION' => 10
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'PodcastsAuthAgent'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '03/12/2020',
            'SYSTEM_CATEGORY' => 'Applications/GarageBand.localized',
            'NAME' => 'GarageBand',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'VERSION' => '6.0.5'
        },
        {
            'NAME' => "Programme d\x{2019}installation d\x{2019}apps iOS",
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '6.3.9',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Utilitaire AirPort',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'Podcasts',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.1.0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2.1',
            'COMMENTS' => '[Universal]',
            'NAME' => 'ChineseTextConverterService'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'Kyocera Print Panel',
            'VERSION' => '5.4.0516',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Kyocera Document Solutions Inc.',
            'INSTALLDATE' => '03/29/2020'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'pdftopdf',
            'VERSION' => '2.7.1',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'HP Inc.',
            'INSTALLDATE' => '05/25/2020'
        },
        {
            'VERSION' => '1.0',
            'NAME' => 'LinkedNotesUIService',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/F-Secure',
            'INSTALLDATE' => '01/03/2020',
            'PUBLISHER' => 'F-Secure',
            'VERSION' => '3.0.51507',
            'COMMENTS' => '[Universal]',
            'NAME' => "Uninstall WithSecure\x{2122} Elements Agent"
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'PressAndHold',
            'VERSION' => '1.0'
        },
        {
            'VERSION' => '3.0.51507',
            'NAME' => 'fschotfix',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'F-Secure',
            'INSTALLDATE' => '04/17/2020',
            'SYSTEM_CATEGORY' => 'Library/F-Secure'
        },
        {
            'VERSION' => '2.0.51',
            'COMMENTS' => '[Intel]',
            'NAME' => 'ApE',
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '06/14/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => "Cre\x{301}ation de page web",
            'VERSION' => '10.1'
        },
        {
            'VERSION' => '3.6.0',
            'NAME' => 'RapportUIAgent',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'NAME' => 'Photo Library Migration Utility',
            'COMMENTS' => '[Universal]',
            'VERSION' => '2.0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'NAME' => 'Installation en cours',
            'COMMENTS' => '[Universal]',
            'VERSION' => '3.0',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '1.0',
            'NAME' => 'Keychain Circle Notification',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Messages',
            'VERSION' => '14.0',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'FaceTime'
        },
        {
            'VERSION' => '2.0.1',
            'COMMENTS' => '[Universal]',
            'NAME' => 'CharacterPalette',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'KoreanIM',
            'VERSION' => '1.0'
        },
        {
            'NAME' => 'Canon IJScanner6',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.0.0',
            'INSTALLDATE' => '06/26/2020',
            'PUBLISHER' => 'Canon Inc.',
            'SYSTEM_CATEGORY' => 'Library/Image Capture'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'OSDUIHelper',
            'VERSION' => '1.1',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'FAX Utility',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.73',
            'PUBLISHER' => 'EPSON',
            'INSTALLDATE' => '08/19/2020',
            'SYSTEM_CATEGORY' => 'Library/Printers'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Apple Silicon]',
            'NAME' => "Programme de mise a\x{300} jour Rosetta 2",
            'VERSION' => '1.0'
        },
        {
            'INSTALLDATE' => '06/14/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'XQuartz',
            'COMMENTS' => '[Other]',
            'VERSION' => '2.7.7'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'INSTALLDATE' => '10/25/2020',
            'PUBLISHER' => 'HP Inc.',
            'VERSION' => '4.9.4',
            'COMMENTS' => '[Intel]',
            'NAME' => 'HP Scanner 3'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'INSTALLDATE' => '06/26/2020',
            'PUBLISHER' => 'Canon Inc.',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Canon IJScanner2',
            'VERSION' => '4.0.0'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '10.0',
            'NAME' => 'imagent',
            'COMMENTS' => '[Universal]'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'AirDrop',
            'VERSION' => '1.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'VERSION' => '2.3',
            'NAME' => 'Dictaphone',
            'COMMENTS' => '[Universal]'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'VERSION' => '2.10',
            'NAME' => 'Automator',
            'COMMENTS' => '[Universal]'
        },
        {
            'NAME' => "Me\x{301}te\x{301}o",
            'COMMENTS' => '[Universal]',
            'VERSION' => '2.1',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Assistant de certification',
            'VERSION' => '5.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => 361,
            'NAME' => 'rcd',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '3105.3.1',
            'NAME' => 'Siri_0',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Adobe Photoshop Elements 9',
            'INSTALLDATE' => '07/09/2020',
            'PUBLISHER' => 'Adobe Systems Inc.',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'Adobe Photoshop Elements',
            'VERSION' => '9.0 (20100905.m.9093)'
        },
        {
            'VERSION' => 1,
            'NAME' => 'Menu des scripts',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'NAME' => 'SSMenuAgent',
            'COMMENTS' => '[Universal]',
            'VERSION' => '3.9.8',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'iCloud Drive'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '6.3',
            'NAME' => 'JapaneseIM-RomajiTyping',
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => 'AOSUIPrefPaneLauncher',
            'VERSION' => '1.0'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'IDSRemoteURLConnectionAgent',
            'VERSION' => '10.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.2',
            'NAME' => 'Configuration des actions de dossier',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => "Programme d\x{2019}installation d\x{2019}Automator",
            'COMMENTS' => '[Universal]',
            'VERSION' => '2.10'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => "Utilitaire d\x{2019}annuaire",
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.2'
        },
        {
            'NAME' => 'ControlStrip',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '1.17',
            'COMMENTS' => '[Universal]',
            'NAME' => 'TextEdit',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'iCloud',
            'VERSION' => '1.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '06/14/2020',
            'PUBLISHER' => 'RStudio Inc.',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'RStudio',
            'COMMENTS' => '[Intel]',
            'VERSION' => '0.98.1103'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => 6,
            'COMMENTS' => '[Universal]',
            'NAME' => "Mise a\x{300} jour de logiciels"
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0',
            'NAME' => 'AskPermissionUI',
            'COMMENTS' => '[Universal]'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Support Tool',
            'VERSION' => '3.0.51507',
            'SYSTEM_CATEGORY' => 'Applications/F-Secure',
            'PUBLISHER' => 'F-Secure',
            'INSTALLDATE' => '01/03/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => "Re\x{301}cents"
        },
        {
            'VERSION' => '5.17.3',
            'NAME' => 'rastertofax',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/25/2020',
            'PUBLISHER' => 'HP Inc.',
            'SYSTEM_CATEGORY' => 'Library/Printers'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'FindMyMacMessenger',
            'VERSION' => '4.1'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '11.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'AddressBookManager'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Language Chooser',
            'VERSION' => '1.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'VERSION' => '1.0.1',
            'COMMENTS' => '[Universal]',
            'NAME' => 'ScriptMonitor',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'VERSION' => '1.6',
            'NAME' => 'TamilIM',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '5.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'UnmountAssistantAgent',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'VERSION' => '1.0',
            'NAME' => "Assistant d\x{2019}effacement",
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'INSTALLDATE' => '09/14/2020',
            'PUBLISHER' => 'Adobe Systems Inc.',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'adobe_licutil',
            'VERSION' => 'Adobe License Utility 1.0.0.15 (BuildVersion: 1.0; BuildDate: Mon Aug 23 2010 21:49:00)'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'PIPAgent'
        },
        {
            'VERSION' => '4.2',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Numbers',
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '06/15/2020'
        },
        {
            'VERSION' => '8.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'CalendarFileHandler',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'FollowUpUI',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => "Informations syste\x{300}me",
            'VERSION' => '11.0'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'INSTALLDATE' => '06/14/2020',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'Adobe AIR Application Installer',
            'VERSION' => '1.5.3'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'eaptlstrust',
            'VERSION' => '13.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => 'R 3.1.3 GUI 1.65 Mavericks build',
            'COMMENTS' => '[Intel]',
            'NAME' => 'R',
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '06/14/2020'
        },
        {
            'INSTALLDATE' => '05/24/2020',
            'USERNAME' => 'admin',
            'VERSION' => undef,
            'NAME' => 'com.apple.ctcategories',
            'COMMENTS' => '[Other]',
            'SYSTEM_CATEGORY' => 'Library/HTTPStorages'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'VideoLAN',
            'INSTALLDATE' => '06/14/2020',
            'COMMENTS' => '[Intel]',
            'NAME' => 'VLC',
            'VERSION' => '2.2.1'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'CoreServicesUIAgent',
            'COMMENTS' => '[Universal]',
            'VERSION' => 369
        },
        {
            'INSTALLDATE' => '08/19/2020',
            'PUBLISHER' => 'EPSON',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'VERSION' => '1.71',
            'NAME' => 'EPFaxAutoSetupTool',
            'COMMENTS' => '[Intel]'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'LogTransport2',
            'VERSION' => '2.0.1.011',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'PUBLISHER' => 'Adobe Systems Inc.',
            'INSTALLDATE' => '09/14/2020'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'IMTransferAgent',
            'COMMENTS' => '[Universal]',
            'VERSION' => '10.0'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => "Transfert d\x{2019}images",
            'VERSION' => '8.0',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'NAME' => 'NativeMessagingHost_0',
            'COMMENTS' => '[Universal]',
            'VERSION' => '5.0',
            'PUBLISHER' => 'Adobe Inc.',
            'INSTALLDATE' => '02/01/2020',
            'SYSTEM_CATEGORY' => 'Library/Application Support'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'NAME' => 'Utilitaire VoiceOver',
            'COMMENTS' => '[Universal]',
            'VERSION' => 10
        },
        {
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'Adobe Application Manager',
            'VERSION' => '1.5.113.0',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'PUBLISHER' => 'Adobe Systems Inc.',
            'INSTALLDATE' => '09/14/2020'
        },
        {
            'VERSION' => '2.2.9',
            'NAME' => 'Microsoft Error Reporting',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'PUBLISHER' => 'Microsoft',
            'INSTALLDATE' => '02/29/2020',
            'SYSTEM_CATEGORY' => 'Library/Application Support'
        },
        {
            'VERSION' => '1.07',
            'COMMENTS' => '[Universal]',
            'NAME' => 'AOSPushRelay',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => 'IMAutomaticHistoryDeletionAgent',
            'VERSION' => '10.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'TCIM'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '11.0',
            'COMMENTS' => '[Universal]',
            'NAME' => "Aperc\x{327}u"
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => 'SpeechRecognitionServer',
            'VERSION' => '9.0.59.2'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Rappels',
            'VERSION' => '7.0',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'VietnameseIM',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0',
            'NAME' => 'iCloudUserNotificationsd',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => '-Adobe Systems Inc.',
            'INSTALLDATE' => '07/09/2020',
            'SYSTEM_CATEGORY' => 'Applications/Adobe',
            'VERSION' => '3.07',
            'NAME' => 'PhotoshopdotcomInspirationBrowser',
            'COMMENTS' => '[32-bit (Unsupported)]'
        },
        {
            'NAME' => 'ScreenSaverEngine',
            'COMMENTS' => '[Universal]',
            'VERSION' => '5.0',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'LocationMenu',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'screencaptureui'
        },
        {
            'NAME' => 'DFRHUD',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Visualiseur de ticket',
            'VERSION' => '4.1'
        },
        {
            'VERSION' => '3.9.8',
            'COMMENTS' => '[Universal]',
            'NAME' => 'ARDAgent',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Ajouter une imprimante',
            'VERSION' => 17
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => "Temps d\x{2019}e\x{301}cran",
            'VERSION' => '3.0'
        },
        {
            'NAME' => 'Finder',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.5',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '3.5',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Configuration audio et MIDI',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'MakePDF',
            'VERSION' => '10.1'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.1.0',
            'NAME' => '50onPaletteServer',
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '02/21/2020',
            'PUBLISHER' => 'Microsoft',
            'VERSION' => '16.79.3',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Microsoft Outlook'
        },
        {
            'VERSION' => '1.1.4',
            'NAME' => 'Microsoft Ship Asserts',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'INSTALLDATE' => '02/29/2020',
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Library/Application Support'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => 613,
            'COMMENTS' => '[Universal]',
            'NAME' => 'WebKitPluginHost'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Installer Progress'
        },
        {
            'VERSION' => '16.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Mail',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'VERSION' => '17.0',
            'NAME' => 'WiFiAgent',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'VirtualScanner',
            'VERSION' => '1742.6.1',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'PUBLISHER' => 'Adobe Systems Inc.',
            'INSTALLDATE' => '07/09/2020',
            'VERSION' => '3.5.15.0',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => '{F0915E53-C75D-4FF2-ADCB-4D4DB79927F6}'
        },
        {
            'VERSION' => '10.13',
            'NAME' => 'Problem Reporter',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'NAME' => 'hpdot4d_0',
            'COMMENTS' => '[Intel]',
            'VERSION' => '5.3.1',
            'INSTALLDATE' => '10/25/2020',
            'PUBLISHER' => 'HP Inc.',
            'SYSTEM_CATEGORY' => 'Library/Printers'
        },
        {
            'PUBLISHER' => 'Google LLC',
            'INSTALLDATE' => '12/07/2020',
            'VERSION' => '121.0.6167.0',
            'USERNAME' => 'agoulut',
            'NAME' => 'GoogleUpdater',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Library/Application Support'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Utilitaire ColorSync',
            'VERSION' => '12.0.0',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'NAME' => 'Mission Control',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.2'
        },
        {
            'INSTALLDATE' => '06/14/2020',
            'PUBLISHER' => 'Adobe Systems Inc.',
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => '9.0.2.(20101217.p.9699)',
            'NAME' => 'Adobe Elements 9 Organizer',
            'COMMENTS' => '[32-bit (Unsupported)]'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'System Events',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.3.6'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'Canon IJScanner4',
            'VERSION' => '4.0.0',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'INSTALLDATE' => '06/26/2020',
            'PUBLISHER' => 'Canon Inc.'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '05/25/2020',
            'PUBLISHER' => 'HP Inc.',
            'COMMENTS' => '[Intel]',
            'NAME' => 'hpPreProcessing',
            'VERSION' => '1.7.2'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Calibration Assistant',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0'
        },
        {
            'NAME' => 'Raccourcis',
            'COMMENTS' => '[Universal]',
            'VERSION' => '5.0',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0',
            'NAME' => 'AMSEngagementViewService',
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => 'TextInputMenuAgent',
            'VERSION' => '1.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'VERSION' => '1742.6.1',
            'COMMENTS' => '[Universal]',
            'NAME' => 'MassStorageCamera'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AddressBookSync',
            'COMMENTS' => '[Universal]',
            'VERSION' => '11.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'SpeechSynthesizerAuditor',
            'VERSION' => '1.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.9',
            'COMMENTS' => '[Universal]',
            'NAME' => 'ODSAgent'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Application Scripts',
            'VERSION' => undef,
            'USERNAME' => 'agoulut',
            'NAME' => 'group.is.workflow',
            'COMMENTS' => '[Other]',
            'INSTALLDATE' => '05/30/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'VERSION' => '7.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'HelpViewer'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => "Re\x{301}seau",
            'VERSION' => '1.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '5.0',
            'NAME' => 'Captive Network Assistant',
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => "Utilitaire de logement de me\x{301}moire",
            'VERSION' => '1.5.3'
        },
        {
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'AquaAppearanceHelper',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Xcode Previews',
            'COMMENTS' => '[Universal]',
            'VERSION' => '13.3'
        },
        {
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'ShortcutDroplet',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'PUBLISHER' => 'Adobe Systems Inc.',
            'INSTALLDATE' => '09/14/2020',
            'VERSION' => '1.5.113.0',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'AAM Registration Notifier'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Photo Booth',
            'VERSION' => '12.2'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Database Events',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0.6'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'PUBLISHER' => 'Adobe Inc.',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Acrobat Update Helper',
            'VERSION' => '1.2.2'
        },
        {
            'NAME' => 'Launchpad',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '11.0',
            'NAME' => 'Diagnostics sans fil',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '3.0.51507',
            'COMMENTS' => '[Universal]',
            'NAME' => 'fsavd',
            'SYSTEM_CATEGORY' => 'Library/F-Secure',
            'PUBLISHER' => 'F-Secure',
            'INSTALLDATE' => '01/03/2020'
        },
        {
            'VERSION' => '6.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Maison',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'VERSION' => '7.0',
            'NAME' => 'Photos',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Applications'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'ImageJ64',
            'VERSION' => '10.2',
            'SYSTEM_CATEGORY' => 'Applications/ImageJ',
            'INSTALLDATE' => '07/23/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '3.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'App Store',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'Adobe Help',
            'VERSION' => '3.2.1.650',
            'SYSTEM_CATEGORY' => 'Applications/Adobe',
            'INSTALLDATE' => '07/09/2020'
        },
        {
            'NAME' => 'Commande universelle',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => 'CIMFindInputCodeTool',
            'VERSION' => 104
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'ClassroomStudentMenuExtra',
            'VERSION' => '1.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'CinematicFramingOnboardingUI'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '2.0',
            'NAME' => "Utilitaire de logement d\x{2019}extension",
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.07',
            'COMMENTS' => '[Universal]',
            'NAME' => 'AOSHeartbeat'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'HP Inc.',
            'INSTALLDATE' => '10/25/2020',
            'COMMENTS' => '[Intel]',
            'NAME' => 'ScanEventHandler',
            'VERSION' => '1.4.0'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Calendrier',
            'VERSION' => '11.0',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '8.1',
            'NAME' => 'SyncServer',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '6.2',
            'NAME' => 'NetAuthAgent',
            'COMMENTS' => '[Universal]'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Musique',
            'VERSION' => '1.2.5',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Application Scripts',
            'INSTALLDATE' => '08/08/2020',
            'USERNAME' => 'agoulut',
            'VERSION' => undef,
            'COMMENTS' => '[Other]',
            'NAME' => 'com.microsoft.openxml'
        },
        {
            'NAME' => 'TextInputSwitcher',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.1',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'VERSION' => '6.2.0',
            'COMMENTS' => '[Universal]',
            'NAME' => "Programme d\x{2019}installation"
        },
        {
            'VERSION' => '11.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'AddressBookUrlForwarder',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '1.0',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'Fiji',
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '06/14/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => "E\x{301}checs",
            'VERSION' => '3.18'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0',
            'NAME' => 'KerberosMenuExtra',
            'COMMENTS' => '[Universal]'
        },
        {
            'NAME' => 'HP Utility',
            'COMMENTS' => '[Intel]',
            'VERSION' => '5.37.1',
            'PUBLISHER' => 'HP Inc.',
            'INSTALLDATE' => '10/25/2020',
            'SYSTEM_CATEGORY' => 'Library/Printers'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'SpeechSynthesisServer',
            'COMMENTS' => '[Universal]',
            'VERSION' => '9.0.88.6'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'Plans',
            'VERSION' => '3.0',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'VERSION' => '1.0',
            'NAME' => "Centre de contro\x{302}le",
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => 'sociallayerd',
            'VERSION' => '1.0'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/ImageJ',
            'INSTALLDATE' => '07/23/2020',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'ImageJ',
            'VERSION' => '10.2'
        },
        {
            'VERSION' => '1.0',
            'NAME' => 'AutomationModeUI',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'VERSION' => '9.0',
            'COMMENTS' => '[Universal]',
            'NAME' => "E\x{301}change de fichiers Bluetooth"
        },
        {
            'PUBLISHER' => 'HP Inc.',
            'INSTALLDATE' => '10/25/2020',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'VERSION' => '4.17.1',
            'NAME' => 'hpdot4d',
            'COMMENTS' => '[Intel]'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ThermalTrap',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'MTLReplayer',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AppSSOAgent',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0'
        },
        {
            'VERSION' => '1040.6',
            'COMMENTS' => '[Universal]',
            'NAME' => 'AVB Audio Configuration',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'HP Inc.',
            'INSTALLDATE' => '10/25/2020',
            'COMMENTS' => '[Intel]',
            'NAME' => 'HP Device Monitor Manager',
            'VERSION' => '5.37.1'
        },
        {
            'VERSION' => '623.100.1',
            'COMMENTS' => '[Universal]',
            'NAME' => 'DiskImages UI Agent',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'VERSION' => '1.0',
            'NAME' => 'AinuIM',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Microsoft',
            'INSTALLDATE' => '06/14/2020',
            'VERSION' => '14.0.2',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'NAME' => 'Lync'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '04/10/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '17.4.1',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Safari'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'PrinterProxy',
            'VERSION' => 20
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'HP Inc.',
            'INSTALLDATE' => '09/26/2020',
            'COMMENTS' => '[Intel]',
            'NAME' => 'commandtohp',
            'VERSION' => '2.4.1'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '5.1',
            'COMMENTS' => '[Universal]',
            'NAME' => "Assistant d\x{2019}e\x{301}valuation"
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Application Scripts',
            'INSTALLDATE' => '05/20/2020',
            'NAME' => 'com.microsoft.openxml_1',
            'COMMENTS' => '[Other]',
            'VERSION' => undef,
            'USERNAME' => 'admin'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Famille'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => 'KeyboardSetupAssistant',
            'VERSION' => '1.0'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => "Capture d\x{2019}e\x{301}cran",
            'VERSION' => '1.0',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Game Center',
            'VERSION' => '1.0'
        },
        {
            'NAME' => 'Assistive Control',
            'COMMENTS' => '[Universal]',
            'VERSION' => '2.0',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Application Scripts',
            'INSTALLDATE' => '05/24/2020',
            'USERNAME' => 'admin',
            'VERSION' => undef,
            'COMMENTS' => '[Other]',
            'NAME' => 'group.is.workflow_0'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'OpenSpell',
            'VERSION' => '1.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'VERSION' => '10.0',
            'NAME' => 'Livre des polices',
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'Kyocera Document Solutions Inc.',
            'INSTALLDATE' => '03/29/2020',
            'COMMENTS' => '[Intel]',
            'NAME' => 'rastertokpsl',
            'VERSION' => '1.0.3629'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'PUBLISHER' => 'HP Inc.',
            'INSTALLDATE' => '08/14/2020',
            'COMMENTS' => '[Intel]',
            'NAME' => 'HPScanner',
            'VERSION' => '1.10.3'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'UIKitSystem'
        },
        {
            'NAME' => 'Keynote',
            'COMMENTS' => '[Intel]',
            'VERSION' => '7.2',
            'INSTALLDATE' => '06/15/2020',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'VERSION' => '10.14',
            'COMMENTS' => '[Universal]',
            'NAME' => "Moniteur d\x{2019}activite\x{301}",
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'NAME' => 'Microsoft Excel',
            'COMMENTS' => '[Universal]',
            'VERSION' => '16.79.2',
            'INSTALLDATE' => '02/21/2020',
            'PUBLISHER' => 'Microsoft',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Shortcuts Events',
            'VERSION' => '1.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'NowPlayingTouchUI',
            'VERSION' => '1.0'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Automator Application Stub',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.3'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Centre de notifications',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0'
        },
        {
            'INSTALLDATE' => '09/08/2020',
            'SYSTEM_CATEGORY' => 'Library/Frameworks',
            'NAME' => 'Adobe AIR Application Installer_0',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'VERSION' => '1.5.3'
        },
        {
            'VERSION' => '4.1',
            'NAME' => 'ParentalControls',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => 10,
            'COMMENTS' => '[Universal]',
            'NAME' => 'ScreenReaderUIServer'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'VERSION' => '10.15',
            'COMMENTS' => '[Universal]',
            'NAME' => "Utilitaire d\x{2019}archive"
        },
        {
            'INSTALLDATE' => '07/09/2020',
            'PUBLISHER' => 'Adobe Systems Inc.',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'ExtendScript Toolkit',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'VERSION' => 'ESTK CS5 3.5.0.52'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '2.0',
            'COMMENTS' => '[Universal]',
            'NAME' => "Partage d\x{2019}e\x{301}cran"
        },
        {
            'VERSION' => '1.7',
            'COMMENTS' => '[Universal]',
            'NAME' => 'SystemUIServer',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'AccessibilityVisualsAgent',
            'VERSION' => '1.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => "Assistant re\x{301}glages",
            'VERSION' => '10.10'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => "E\x{301}talonnage de moniteur",
            'VERSION' => '4.14',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'VERSION' => '3.0.51507',
            'COMMENTS' => '[Universal]',
            'NAME' => "WithSecure\x{2122} Elements Agent",
            'SYSTEM_CATEGORY' => 'Applications/F-Secure',
            'INSTALLDATE' => '01/03/2020',
            'PUBLISHER' => 'F-Secure'
        },
        {
            'VERSION' => '10.2',
            'COMMENTS' => '[Universal]',
            'NAME' => "Aide-me\x{301}moire",
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '04/17/2020',
            'PUBLISHER' => 'Adobe Inc.',
            'VERSION' => '24.002.20687',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Adobe Acrobat Reader'
        },
        {
            'COMMENTS' => '[Intel]',
            'NAME' => 'HP Product Research Manager',
            'VERSION' => '10.37.1',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '10/25/2020',
            'PUBLISHER' => 'HP Inc.'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'VERSION' => 10,
            'COMMENTS' => '[Universal]',
            'NAME' => "Pre\x{301}sentation de VoiceOver"
        },
        {
            'VERSION' => '1.0',
            'NAME' => 'PowerChime',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Assistant Boot Camp',
            'VERSION' => '6.1.0'
        },
        {
            'VERSION' => '3.5.15.0',
            'NAME' => 'Setup',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'INSTALLDATE' => '09/14/2020',
            'PUBLISHER' => 'Adobe Systems Inc.',
            'SYSTEM_CATEGORY' => 'Library/Application Support'
        },
        {
            'VERSION' => '2.0',
            'NAME' => 'AirPlayUIAgent',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '111.0.5563.110',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Google Chrome',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'Google LLC',
            'INSTALLDATE' => '03/21/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => "Assistant re\x{301}glages Bluetooth",
            'VERSION' => '9.0'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'QuickLookUIHelper',
            'COMMENTS' => '[Universal]',
            'VERSION' => '5.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Time Machine',
            'VERSION' => '1.3'
        },
        {
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '05/30/2020',
            'SYSTEM_CATEGORY' => 'Library/Apple',
            'VERSION' => '1.93',
            'NAME' => 'MRT',
            'COMMENTS' => '[Universal]'
        },
        {
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Spotlight',
            'COMMENTS' => '[Universal]',
            'VERSION' => '3.0'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => "Programme d\x{2019}installation de profil",
            'VERSION' => '1.0',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'COMMENTS' => '[Universal]',
            'NAME' => 'EscrowSecurityAlert',
            'VERSION' => '1.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'UASharedPasteboardProgressUI',
            'VERSION' => '54.1'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'VERSION' => '9.0.59.2',
            'COMMENTS' => '[Universal]',
            'NAME' => "Programme de te\x{301}le\x{301}chargement de parole"
        },
        {
            'NAME' => 'AAM Updates Notifier',
            'COMMENTS' => '[32-bit (Unsupported)]',
            'VERSION' => '1.5.113.0',
            'INSTALLDATE' => '09/14/2020',
            'PUBLISHER' => 'Adobe Systems Inc.',
            'SYSTEM_CATEGORY' => 'Library/Application Support'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'VERSION' => '9.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'BluetoothUIServer'
        },
        {
            'NAME' => 'Microsoft Teams classic',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.00.627656',
            'PUBLISHER' => 'Microsoft',
            'INSTALLDATE' => '11/08/2020',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'NativeMessagingHost',
            'VERSION' => '5.0',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'PUBLISHER' => 'Adobe Inc.',
            'INSTALLDATE' => '02/01/2020'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Siri',
            'VERSION' => '1.0'
        },
        {
            'PUBLISHER' => 'Skype Communications S.a.r.l',
            'INSTALLDATE' => '11/08/2020',
            'SYSTEM_CATEGORY' => 'Applications',
            'VERSION' => '16.30.32',
            'NAME' => 'Skype Entreprise',
            'COMMENTS' => '[Intel]'
        },
        {
            'VERSION' => '9.0',
            'NAME' => 'OBEXAgent',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'COMMENTS' => '[Other]',
            'NAME' => 'com.microsoft.openxml_0',
            'VERSION' => undef,
            'USERNAME' => 'admin',
            'INSTALLDATE' => '05/20/2020',
            'SYSTEM_CATEGORY' => 'Library/Containers'
        },
        {
            'VERSION' => '24.055.0317',
            'NAME' => 'OneDrive',
            'COMMENTS' => '[Universal]',
            'PUBLISHER' => 'Microsoft',
            'INSTALLDATE' => '04/10/2020',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'NAME' => 'FileZilla',
            'COMMENTS' => '[Intel]',
            'VERSION' => '3.64.0',
            'PUBLISHER' => 'Tim Kosse',
            'INSTALLDATE' => '04/26/2020',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Horloge',
            'VERSION' => '1.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Apple',
            'INSTALLDATE' => '02/26/2020',
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Gestion du stockage'
        },
        {
            'COMMENTS' => '[Universal]',
            'NAME' => 'TV',
            'VERSION' => '1.2.5',
            'SYSTEM_CATEGORY' => 'System/Applications',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '06/15/2020',
            'COMMENTS' => '[Intel]',
            'NAME' => 'iMovie',
            'VERSION' => '10.1.6'
        },
        {
            'VERSION' => '1.0',
            'NAME' => 'BluetoothUIService',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/26/2020',
            'PUBLISHER' => 'Apple',
            'SYSTEM_CATEGORY' => 'System/Library'
        }
    ],
);


plan tests => 2 * scalar (keys %tests)
    + 7;

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/macos/system_profiler/$test.SPApplicationsDataType";
    my $softwares = GLPI::Agent::Task::Inventory::MacOS::Softwares::_getSoftwaresList(file => $file, format => 'text');
    # Dump found result when still not integrated in test file
    unless (@{$tests{$test}}) {
        my $dumper = Data::Dumper->new([$softwares])->Useperl(1)->Indent(1)->Pad("    ");
        $dumper->{xpad} = "    ";
        print STDERR "$test current result: ", $dumper->Dump();
    }
    cmp_deeply(
        [ sort { compare() } @{$softwares} ],
        [ sort { compare() } @{$tests{$test}} ],
        "$test: parsing"
    );
    lives_ok {
        $inventory->addEntry(section => 'SOFTWARES', entry => $_)
            foreach @$softwares;
    } "$test: registering";
}

sub compare {
    return
        $a->{NAME}  cmp $b->{NAME};
}

SKIP: {
    skip "Only if OS is darwin (Mac OS X) and command 'system_profiler' is available", 6
        unless $OSNAME eq 'darwin' && GLPI::Agent::Task::Inventory::MacOS::Softwares::isEnabled();

    my @hasSoftwareOutput = getAllLines(
        command => "/usr/sbin/system_profiler SPApplicationsDataType"
    );
    # On MacOSX, skip test as system_profiler may return no software in container, CircleCI case
    skip "No installed software seen on this system", 6
        if @hasSoftwareOutput == 0;

    my $softs = GLPI::Agent::Tools::MacOS::_getSystemProfilerInfosXML(
        type            => 'SPApplicationsDataType',
        localTimeOffset => GLPI::Agent::Tools::MacOS::detectLocalTimeOffset(),
        format => 'xml'
    );
    ok ($softs);
    ok (scalar(keys %$softs) > 0);

    my $infos = GLPI::Agent::Tools::MacOS::getSystemProfilerInfos(
        type            => 'SPApplicationsDataType',
        localTimeOffset => GLPI::Agent::Tools::MacOS::detectLocalTimeOffset(),
        format => 'xml'
    );
    ok ($infos);
    ok (scalar(keys %$infos) > 0);

    my $softwareHash = GLPI::Agent::Task::Inventory::MacOS::Softwares::_getSoftwaresList(
        format => 'xml',
    );
    ok (defined $softwareHash);
    ok (scalar(@{$softwareHash}) > 1);
}
