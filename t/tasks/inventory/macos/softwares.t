#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

# Tests are encoded in utf8 in this file
use utf8;

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use GLPI::Test::Inventory;
use GLPI::Agent::Tools qw(getAllLines);
use GLPI::Agent::Task::Inventory::MacOS::Softwares;

use English;

my %tests = (
    'sample2' => [
        {
            'PUBLISHER' => 'Copyright 2010 Hewlett-Packard Company',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'NAME' => 'HP Scanner 3',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '3.2.9'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'DiskImageMounter',
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
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'SLLauncher',
            'PUBLISHER' => undef,
            'VERSION' => '1.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '20/01/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Parallels Desktop',
            'USERNAME' => '',
            'PUBLISHER' => '6.0.11994.637942, Copyright 2005-2011 Parallels Holdings, Ltd. and its affiliates',
            'VERSION' => '6.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '08/03/2011'
        },
        {
            'INSTALLDATE' => '12/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '3.10.35',
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'SpeechService'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '22/06/2009',
            'VERSION' => '1.0',
            'PUBLISHER' => 'HP Laserjet Driver 1.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
            'NAME' => 'Laserjet',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'USERNAME' => ''
        },
        {
            'VERSION' => '2.0.1',
            'INSTALLDATE' => '21/07/2009',
            'COMMENTS' => '[Intel]',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Transfert de podcast',
            'PUBLISHER' => '2.0.1, Copyright © 2007-2009 Apple Inc.'
        },
        {
            'INSTALLDATE' => '16/06/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.0',
            'PUBLISHER' => 'HP Photosmart Driver 4.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Photosmart'
        },
        {
            'PUBLISHER' => 'HP Inkjet 3 Driver 2.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Inkjet3',
            'USERNAME' => '',
            'INSTALLDATE' => '16/06/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.0'
        },
        {
            'VERSION' => '2.4.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'USERNAME' => '',
            'NAME' => 'Chess',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => '2.4.2, Copyright 2003-2009 Apple Inc.'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
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
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Parallels',
            'NAME' => 'DockPlistEdit'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '3.0.3',
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'Photo Booth',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'Applications/DivX',
            'NAME' => 'DivX Support',
            'USERNAME' => '',
            'COMMENTS' => '[PowerPC]',
            'INSTALLDATE' => '17/11/2009',
            'VERSION' => '1.1.0'
        },
        {
            'INSTALLDATE' => '25/04/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => undef,
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'NAME' => 'Rename'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Assistant Installation de Microsoft Office 2008',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'VERSION' => '12.2.8',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '27/12/2010'
        },
        {
            'PUBLISHER' => '6.0.11994.637942, Copyright 2005-2011 Parallels Holdings, Ltd. and its affiliates',
            'SYSTEM_CATEGORY' => 'Library/Parallels',
            'NAME' => 'Parallels Mounter',
            'USERNAME' => '',
            'INSTALLDATE' => '08/03/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '6.0'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'NetAuthAgent',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '07/07/2010',
            'VERSION' => '2.1'
        },
        {
            'PUBLISHER' => '6.0, © Copyright 2003-2009 Apple  Inc., all rights reserved.',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Création de page Web',
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
            'USERNAME' => '',
            'PUBLISHER' => 'CIJScannerRegister version 1.0.0, Copyright CANON INC. 2009 All Rights Reserved.'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'PhotosmartPro',
            'PUBLISHER' => 'HP Photosmart Pro Driver 3.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
            'VERSION' => '3.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009'
        },
        {
            'VERSION' => '1.2.10',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '01/07/2009',
            'USERNAME' => '',
            'NAME' => 'Utilitaire de l\'imprimante Lexmark',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => '1.0, Copyright 2008 Lexmark International, Inc. All rights reserved.'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ChineseTextConverterService',
            'USERNAME' => '',
            'PUBLISHER' => 'Chinese Text Converter 1.1',
            'VERSION' => '1.2',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]'
        },
        {
            'PUBLISHER' => '6.0, © Copyright 2003-2009 Apple Inc., all rights reserved.',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Image Capture Web Server',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.0'
        },
        {
            'PUBLISHER' => '4.6, Copyright 2008 Apple Computer, Inc.',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Outil d’étalonnage du moniteur',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.6'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'Front Row',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '22/07/2009',
            'VERSION' => '2.2.1'
        },
        {
            'VERSION' => '6.0',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'USERNAME' => '',
            'NAME' => 'Type2Camera',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => '6.0, © Copyright 2000-2009 Apple Inc., all rights reserved.'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
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
            'PUBLISHER' => '6.2.1, Copyright © 2000–2009 Apple Inc. All rights reserved.',
            'NAME' => 'Apple80211Agent',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => ''
        },
        {
            'VERSION' => '1.0.0',
            'INSTALLDATE' => '10/06/2010',
            'COMMENTS' => '[Intel]',
            'USERNAME' => '',
            'NAME' => 'hpPreProcessing',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => '1.0.0, (c) Copyright 2001-2010 Hewlett-Packard Development Company, L.P.'
        },
        {
            'INSTALLDATE' => '25/04/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => undef,
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'Match',
            'SYSTEM_CATEGORY' => 'Library/Scripts'
        },
        {
            'VERSION' => '1.3',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/07/2009',
            'USERNAME' => '',
            'NAME' => 'Clipboard Viewer',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'PUBLISHER' => undef
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => 'lubrano',
            'NAME' => 'h-nb1',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.5'
        },
        {
            'NAME' => 'Folder Actions Dispatcher',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => '1.0.2',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '2.3.6',
            'PUBLISHER' => '2.3.6, Copyright (c) 2010 Apple Inc. All rights reserved.',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Bluetooth Diagnostics Utility'
        },
        {
            'VERSION' => '300.4',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'IncompatibleAppDisplay',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'INSTALLDATE' => '15/06/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.0.0',
            'PUBLISHER' => '1.0.0, Copyright CANON INC. 2009 All Rights Reserved',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'NAME' => 'Canon IJScanner1',
            'USERNAME' => ''
        },
        {
            'PUBLISHER' => '1.7, Copyright 2006-2008 Apple Inc.',
            'USERNAME' => '',
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
            'PUBLISHER' => '5.4, Copyright © 2001-2010 by Apple Inc.  All Rights Reserved.',
            'NAME' => 'Lecteur DVD',
            'SYSTEM_CATEGORY' => 'Applications',
            'USERNAME' => ''
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0',
            'PUBLISHER' => '6.0, © Copyright 2000-2009 Apple Inc., all rights reserved.',
            'USERNAME' => '',
            'NAME' => 'Type1Camera',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Type3Camera',
            'USERNAME' => '',
            'PUBLISHER' => '6.0, © Copyright 2001-2009 Apple Inc., all rights reserved.',
            'VERSION' => '6.0',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'OpenGL Profiler',
            'USERNAME' => '',
            'PUBLISHER' => '4.2, Copyright 2003-2009 Apple, Inc.',
            'VERSION' => '4.2',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '13/01/2011',
            'VERSION' => '14.0.2',
            'PUBLISHER' => '14.0.2 (101115), © 2010 Microsoft Corporation. All rights reserved.',
            'USERNAME' => '',
            'NAME' => 'Utilitaire de base de données Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'Problem Reporter',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '20/02/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '10.6.6'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'NAME' => 'License',
            'USERNAME' => '',
            'PUBLISHER' => 'License',
            'VERSION' => '11',
            'INSTALLDATE' => '25/07/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '3.1.0',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'NAME' => 'UserNotificationCenter',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'VERSION' => '2.3.8',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'OBEXAgent',
            'PUBLISHER' => '2.3.8, Copyright (c) 2010 Apple Inc. All rights reserved.'
        },
        {
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'VoiceOver',
            'USERNAME' => '',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '3.4.0'
        },
        {
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'webdav_cert_ui',
            'USERNAME' => '',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '1.8.1'
        },
        {
            'VERSION' => '4.7.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'IA32 Help',
            'PUBLISHER' => undef
        },
        {
            'VERSION' => '7.6.6',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/04/2009',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'QuickTime Player 7',
            'USERNAME' => '',
            'PUBLISHER' => '7.6.6, Copyright © 1989-2009 Apple Inc. All Rights Reserved'
        },
        {
            'VERSION' => '3.0.4',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'PackageMaker',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'NAME' => 'SpeechRecognitionServer',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => '3.11.1',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '29/05/2009'
        },
        {
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.1.1',
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Utilitaire AppleScript',
            'USERNAME' => ''
        },
        {
            'INSTALLDATE' => '24/07/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.0',
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Spotlight'
        },
        {
            'VERSION' => '12.2.8',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Cert Manager',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.'
        },
        {
            'VERSION' => '1.5',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010',
            'NAME' => 'OpenGL Driver Monitor',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'USERNAME' => '',
            'PUBLISHER' => '1.5, Copyright © 2009 Apple Inc.'
        },
        {
            'PUBLISHER' => '6.0.1, © Copyright 2002-2009 Apple Inc., all rights reserved.',
            'NAME' => 'Type8Camera',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0.1'
        },
        {
            'INSTALLDATE' => '13/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '14.0.2',
            'PUBLISHER' => '14.0.2 (101115), © 2010 Microsoft Corporation. All rights reserved.',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011',
            'NAME' => 'Microsoft Clip Gallery'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '07/07/2010',
            'VERSION' => '4.5.3',
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Calculette'
        },
        {
            'PUBLISHER' => '5.0.4, Copyright © 2003-2011 Apple Inc.',
            'USERNAME' => '',
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
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'syncuid',
            'PUBLISHER' => '4.0, Copyright Apple Computer Inc. 2004'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '07/07/2010',
            'VERSION' => '6.5.10',
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'KerberosAgent',
            'USERNAME' => ''
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '2.2',
            'PUBLISHER' => '2.2 ©2010, Apple, Inc',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'AU Lab',
            'USERNAME' => ''
        },
        {
            'VERSION' => '12.2.8',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'USERNAME' => '',
            'NAME' => 'Alerts Daemon',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'CharacterPalette',
            'PUBLISHER' => undef,
            'VERSION' => '1.0.4',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/07/2009'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'CoreServicesUIAgent',
            'PUBLISHER' => 'Copyright © 2009 Apple Inc.',
            'VERSION' => '41.5',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]'
        },
        {
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'USERNAME' => '',
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
            'PUBLISHER' => 'Zimbra Desktop 1.0.4, (C) 2010 VMware Inc.',
            'VERSION' => '1.0.4',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '07/07/2010'
        },
        {
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'SyncDiagnostics',
            'USERNAME' => '',
            'INSTALLDATE' => '18/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '5.2'
        },
        {
            'PUBLISHER' => 'Quartz Debug 4.1',
            'USERNAME' => '',
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
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'SleepX',
            'SYSTEM_CATEGORY' => 'Developer/Applications'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
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
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'NAME' => 'Set Info',
            'PUBLISHER' => undef
        },
        {
            'PUBLISHER' => undef,
            'NAME' => 'Yap',
            'SYSTEM_CATEGORY' => 'opt/local',
            'USERNAME' => '',
            'COMMENTS' => undef,
            'INSTALLDATE' => '30/12/2009',
            'VERSION' => undef
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
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
            'USERNAME' => '',
            'NAME' => 'Jar Bundler',
            'SYSTEM_CATEGORY' => 'usr/share',
            'PUBLISHER' => undef
        },
        {
            'USERNAME' => '',
            'NAME' => 'Spin Control',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'PUBLISHER' => 'Spin Control',
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
            'USERNAME' => '',
            'PUBLISHER' => '6.0, © Copyright 2003-2009 Apple Inc., all rights reserved.'
        },
        {
            'VERSION' => '3.8.1',
            'INSTALLDATE' => '29/05/2009',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'SpeechFeedbackWindow',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'Session Timer',
            'SYSTEM_CATEGORY' => 'Library/Frameworks',
            'INSTALLDATE' => '09/03/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '17289'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Excel',
            'USERNAME' => '',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
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
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '2.3.8',
            'PUBLISHER' => '2.3.8, Copyright (c) 2010 Apple Inc. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Échange de fichiers Bluetooth',
            'USERNAME' => ''
        },
        {
            'INSTALLDATE' => '08/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '2.5.4',
            'PUBLISHER' => '2.5.4, © 001-2006 Python Software Foundation',
            'USERNAME' => '',
            'NAME' => 'Python Launcher',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'PUBLISHER' => '1.2, Copyright © 2004-2009 Apple Inc. All rights reserved.',
            'USERNAME' => '',
            'NAME' => 'Automator Launcher',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '1.2'
        },
        {
            'NAME' => 'iCal',
            'SYSTEM_CATEGORY' => 'Applications',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => '4.0.4',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '14.0.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '13/01/2011',
            'USERNAME' => '',
            'NAME' => 'Microsoft Outlook',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011',
            'PUBLISHER' => '14.0.2 (101115), © 2010 Microsoft Corporation. All rights reserved.'
        },
        {
            'PUBLISHER' => undef,
            'NAME' => 'AddressBookSync',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '2.0.3'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '3.7.8',
            'PUBLISHER' => undef,
            'NAME' => 'SpeakableItems',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => ''
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'Microsoft Ship Asserts',
            'USERNAME' => '',
            'PUBLISHER' => '1.1.0 (101115), © 2010 Microsoft Corporation. All rights reserved.',
            'VERSION' => '1.1.0',
            'INSTALLDATE' => '13/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Configuration audio et MIDI',
            'PUBLISHER' => '3.0.3, Copyright 2002-2010 Apple, Inc.',
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
            'USERNAME' => '',
            'PUBLISHER' => 'URL Access Scripting 1.1, Copyright © 2002-2004 Apple Computer, Inc.'
        },
        {
            'VERSION' => '1.2.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Wireshark',
            'PUBLISHER' => '1.2.0, Copyright 1998-2009 Wireshark Development Team'
        },
        {
            'VERSION' => '2.0.6',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '19/05/2009',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'FontSyncScripting',
            'USERNAME' => '',
            'PUBLISHER' => 'FontSync Scripting 2.0. Copyright © 2000-2008 Apple Inc.'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '22/02/2011',
            'VERSION' => '3.9.14.0',
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'Meeting Center',
            'USERNAME' => 'lubrano'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.8.5',
            'PUBLISHER' => 'HP Utility version 4.8.5, Copyright (c) 2005-2010 Hewlett-Packard Development Company, L.P.',
            'USERNAME' => '',
            'NAME' => 'HP Utility',
            'SYSTEM_CATEGORY' => 'Library/Printers'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Skype',
            'PUBLISHER' => 'Skype version 2.8.0.851 (16248), Copyright © 2004-2010 Skype Technologies S.A.',
            'VERSION' => '2.8.0.851',
            'INSTALLDATE' => '08/02/2010',
            'COMMENTS' => '[Universal]'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.0.1',
            'PUBLISHER' => '6.0.1, © Copyright 2001-2010 Apple Inc. All rights reserved.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Type4Camera',
            'USERNAME' => ''
        },
        {
            'VERSION' => '1.1',
            'INSTALLDATE' => '09/07/2008',
            'COMMENTS' => '[Universal]',
            'NAME' => 'À propos d’AHT',
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'USERNAME' => '',
            'PUBLISHER' => 'Apple Hardware Test Read Me'
        },
        {
            'VERSION' => '1.2',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Utilitaire RAID',
            'PUBLISHER' => 'RAID Utility 1.0 (121), Copyright © 2007-2009 Apple Inc.'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.0',
            'PUBLISHER' => '6.0, © Copyright 2001-2009 Apple Inc., all rights reserved.',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Type5Camera'
        },
        {
            'VERSION' => '3.2.45',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '01/07/2009',
            'NAME' => 'Lexmark Scanner',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'VERSION' => '4.3',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '19/05/2009',
            'NAME' => 'SCIM',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'PUBLISHER' => '4.0, Copyright © 1997-2009 Apple Inc., All Rights Reserved'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '08/07/2009',
            'VERSION' => '2.5.4',
            'PUBLISHER' => '2.5.4a0, (c) 2004 Python Software Foundation.',
            'NAME' => 'Python',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => ''
        },
        {
            'VERSION' => '9.4.2',
            'INSTALLDATE' => '23/03/2011',
            'COMMENTS' => '[Universal]',
            'USERNAME' => 'lubrano',
            'NAME' => 'Adobe Reader Updater',
            'SYSTEM_CATEGORY' => 'Library/Caches',
            'PUBLISHER' => '9.4.2, ©2009-2010 Adobe Systems Incorporated. All rights reserved.'
        },
        {
            'COMMENTS' => undef,
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => undef,
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'Developer/SDKs',
            'NAME' => 'WebKitPluginHost',
            'USERNAME' => ''
        },
        {
            'VERSION' => '17289',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/03/2011',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Network Connect',
            'PUBLISHER' => undef
        },
        {
            'PUBLISHER' => '4.0.0, Copyright © 2002-2010 Apple Inc. All Rights Reserved.',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'USB Prober',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '4.0.0'
        },
        {
            'PUBLISHER' => '1.5.5 (155.2), Copyright © 2006-2009 Apple Inc. All Rights Reserved.',
            'NAME' => 'Agent de la borne d’accès AirPort',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '1.5.5'
        },
        {
            'PUBLISHER' => 'Welcome to Leopard',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'NAME' => 'Bienvenue sur Leopard',
            'INSTALLDATE' => '23/07/2008',
            'COMMENTS' => '[Universal]',
            'VERSION' => '8.1'
        },
        {
            'PUBLISHER' => 'InstallAnywhere 8.0, Copyright © 2006 Macrovision Corporation.',
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
            'PUBLISHER' => '6.0.11994.637942, Copyright 2005-2011 Parallels Holdings, Ltd. and its affiliates',
            'SYSTEM_CATEGORY' => 'Library/Parallels',
            'NAME' => 'Parallels Service',
            'USERNAME' => ''
        },
        {
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Entourage'
        },
        {
            'NAME' => 'X11',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'USERNAME' => '',
            'PUBLISHER' => 'org.x.X11',
            'VERSION' => '2.3.6',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => undef
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Utilitaire VoiceOver',
            'PUBLISHER' => undef,
            'VERSION' => '3.4.0',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => 'HP Officejet Driver 3.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
            'NAME' => 'Officejet',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'USERNAME' => '',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'VERSION' => '3.0'
        },
        {
            'VERSION' => '1.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Ticket Viewer',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'VERSION' => '3.1.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'iSync',
            'SYSTEM_CATEGORY' => 'Applications',
            'USERNAME' => '',
            'PUBLISHER' => '3.1.2, Copyright © 2003-2010 Apple Inc.'
        },
        {
            'VERSION' => '4.7.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'USERNAME' => '',
            'NAME' => 'Saturn',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'PUBLISHER' => undef
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '11/06/2009',
            'VERSION' => '2.0',
            'PUBLISHER' => '2.0, Copyright © 2004-2009 Apple Inc., All Rights Reserved',
            'NAME' => 'KeyboardViewer',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => ''
        },
        {
            'VERSION' => '2.3',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ManagedClient',
            'PUBLISHER' => undef
        },
        {
            'VERSION' => '1.5.6',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/07/2006',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Bonjour Browser',
            'PUBLISHER' => undef
        },
        {
            'PUBLISHER' => undef,
            'NAME' => '50onPaletteServer',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '30/06/2009',
            'VERSION' => '1.0.3'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '1.0.4',
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Database Events'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0.4',
            'PUBLISHER' => '6.0.4, © Copyright 2004-2010 Apple Inc. All rights reserved.',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'PTPCamera'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AppleFileServer',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => undef
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.5',
            'PUBLISHER' => undef,
            'NAME' => 'h-coul',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'USERNAME' => 'lubrano'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Pixie',
            'PUBLISHER' => undef,
            'VERSION' => '2.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010'
        },
        {
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Chart Converter',
            'USERNAME' => ''
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'VPNClient',
            'PUBLISHER' => undef,
            'VERSION' => '4.9.01.0180',
            'INSTALLDATE' => '27/12/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'NAME' => 'Show Info',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => undef,
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '25/04/2009'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'iChatAgent',
            'PUBLISHER' => undef,
            'VERSION' => '5.0.3',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Intel]'
        },
        {
            'USERNAME' => '',
            'NAME' => 'ChineseHandwriting',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => undef,
            'VERSION' => '1.0.1',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]'
        },
        {
            'VERSION' => '1.1.1',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '11/11/2010',
            'USERNAME' => '',
            'NAME' => 'Microsoft Help Viewer',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'PUBLISHER' => '1.1.1 (100910), © 2007 Microsoft Corporation. All rights reserved.'
        },
        {
            'PUBLISHER' => 'HP Inkjet 5 Driver 2.1, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
            'NAME' => 'Inkjet5',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'USERNAME' => '',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'VERSION' => '2.1'
        },
        {
            'PUBLISHER' => undef,
            'NAME' => 'Assistant migration',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'USERNAME' => '',
            'INSTALLDATE' => '01/07/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '3.0'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'iMovie',
            'PUBLISHER' => '7.1.4, Copyright © 2007-2008 Apple Inc. All Rights Reserved.',
            'VERSION' => '7.1.4',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '01/07/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Raster2CanonIJ',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => undef,
            'COMMENTS' => undef,
            'INSTALLDATE' => '15/06/2009'
        },
        {
            'PUBLISHER' => 'Xcode version 3.2.5',
            'USERNAME' => '',
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
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'Remove',
            'SYSTEM_CATEGORY' => 'Library/Scripts'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'KeyboardSetupAssistant',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '10.5.0'
        },
        {
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.1.3',
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Diagnostic réseau',
            'USERNAME' => ''
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
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
            'NAME' => 'Printer Setup Utility',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.0',
            'PUBLISHER' => '6.0, © Copyright 2004-2009 Apple Inc., all rights reserved.',
            'NAME' => 'BluetoothCamera',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => ''
        },
        {
            'INSTALLDATE' => '01/07/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.00.29',
            'PUBLISHER' => 'Copyright (C) 2004-2009 Samsung Electronics Co., Ltd.',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'NAME' => 'Samsung Scanner',
            'USERNAME' => ''
        },
        {
            'PUBLISHER' => 'HP Inkjet 4 Driver 2.2, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
            'NAME' => 'Inkjet4',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'USERNAME' => '',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'VERSION' => '2.2'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '01/07/2009',
            'VERSION' => '2.0.4',
            'PUBLISHER' => '2.0.4, Copyright 2008 Apple Inc.',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'iWeb',
            'USERNAME' => ''
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '01/07/2009',
            'VERSION' => '6.2.1',
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'TrueCrypt',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'VERSION' => '6.5',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'USERNAME' => 'lubrano',
            'NAME' => 'h-nb-toshiba- photocopieur multifonctions noir et blanc',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => undef
        },
        {
            'NAME' => 'SystemUIServer',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'PUBLISHER' => 'SystemUIServer version 1.6, Copyright 2000-2009 Apple Computer, Inc.',
            'VERSION' => '1.6',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'VERSION' => '6.5',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'PrinterProxy',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'NAME' => 'TCIM',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'PUBLISHER' => '6.2, Copyright © 1997-2006 Apple Computer Inc., All Rights Reserved',
            'VERSION' => '6.3',
            'INSTALLDATE' => '07/07/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '20/10/2009',
            'VERSION' => '1.0',
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'WiFi Scanner',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'VERSION' => '12.2.8',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '27/12/2010',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Sync Services',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.'
        },
        {
            'VERSION' => '2.0',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '20/02/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ParentalControls',
            'USERNAME' => '',
            'PUBLISHER' => '2.0, Copyright Apple Inc. 2007-2009'
        },
        {
            'PUBLISHER' => '6.0.2, © Copyright 2000-2010 Apple Inc. All rights reserved.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Image Capture Extension',
            'USERNAME' => '',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0.2'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.2.2',
            'PUBLISHER' => '2.2.2, Copyright © 2003-2010 Apple Inc.',
            'NAME' => 'Livre des polices',
            'SYSTEM_CATEGORY' => 'Applications',
            'USERNAME' => ''
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'SpeechSynthesisServer',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => '3.10.35',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '12/07/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'FontRegistryUIAgent',
            'USERNAME' => '',
            'PUBLISHER' => 'Copyright © 2008 Apple Inc.',
            'VERSION' => '1.1',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Intel]'
        },
        {
            'VERSION' => '2.3',
            'INSTALLDATE' => '24/04/2009',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Éditeur AppleScript',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Java Web Start',
            'USERNAME' => '',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/03/2011',
            'VERSION' => '13.4.0'
        },
        {
            'PUBLISHER' => '2.1.0 (100825), © 2010 Microsoft Corporation. All rights reserved.',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Connexion Bureau à Distance',
            'INSTALLDATE' => '13/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.1.0'
        },
        {
            'VERSION' => '3.4.0',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'USERNAME' => '',
            'NAME' => 'ScreenReaderUIServer',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => undef
        },
        {
            'NAME' => 'Exposé',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'USERNAME' => '',
            'PUBLISHER' => '1.1, Copyright 2007-2008 Apple Inc.',
            'VERSION' => '1.1',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '20/02/2011'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '07/07/2010',
            'VERSION' => '6.5.10',
            'PUBLISHER' => '6.5 Copyright © 2008 Massachusetts Institute of Technology',
            'USERNAME' => '',
            'NAME' => 'CCacheServer',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'loginwindow',
            'PUBLISHER' => undef,
            'VERSION' => '6.1.1',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'PUBLISHER' => undef,
            'NAME' => 'ScreenSaverEngine',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '3.0.3'
        },
        {
            'USERNAME' => '',
            'NAME' => 'iStumbler',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'iStumbler Release 98',
            'VERSION' => 'Release 98',
            'INSTALLDATE' => '05/02/2007',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => '2.3.6, Copyright (c) 2010 Apple Inc. All rights reserved.',
            'USERNAME' => '',
            'NAME' => 'Bluetooth Explorer',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '2.3.6'
        },
        {
            'PUBLISHER' => '6.0, © Copyright 2002-2009 Apple Inc., all rights reserved.',
            'NAME' => 'Type6Camera',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.0'
        },
        {
            'VERSION' => '3.4',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '20/02/2011',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ARDAgent',
            'PUBLISHER' => undef
        },
        {
            'VERSION' => '12.2.8',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'My Day',
            'USERNAME' => '',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'HelpViewer',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '5.0.3'
        },
        {
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Supprimer Office',
            'USERNAME' => '',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.1',
            'PUBLISHER' => 'Copyright © 2009 Apple Inc.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'CoreLocationAgent',
            'USERNAME' => ''
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'OpenOffice',
            'PUBLISHER' => 'OpenOffice.org 3.2.0 [320m8(Build:9472)]',
            'VERSION' => '3.2.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '01/02/2010'
        },
        {
            'PUBLISHER' => undef,
            'NAME' => 'Proof',
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'USERNAME' => '',
            'INSTALLDATE' => '25/04/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => undef
        },
        {
            'NAME' => 'AppleScript Runner',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => '1.0.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009'
        },
        {
            'PUBLISHER' => '1.1.1, Copyright © 2007-2009 Apple Inc., All Rights Reserved.',
            'USERNAME' => '',
            'NAME' => 'Partage d’écran',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '02/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.1.1'
        },
        {
            'VERSION' => '4.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010',
            'USERNAME' => '',
            'NAME' => 'Help Indexer',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'PUBLISHER' => undef
        },
        {
            'USERNAME' => '',
            'NAME' => 'PSPP',
            'SYSTEM_CATEGORY' => 'opt/local',
            'PUBLISHER' => undef,
            'VERSION' => '@VERSION@',
            'COMMENTS' => undef,
            'INSTALLDATE' => '30/12/2009'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '4.6.2',
            'PUBLISHER' => '4.6.2, © Copyright 2009 Apple Inc.',
            'USERNAME' => '',
            'NAME' => 'Utilitaire ColorSync',
            'SYSTEM_CATEGORY' => 'Applications/Utilities'
        },
        {
            'VERSION' => '2.1',
            'INSTALLDATE' => '26/08/2010',
            'COMMENTS' => '[Intel]',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'IORegistryExplorer',
            'PUBLISHER' => undef
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Trousseau d’accès',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '07/07/2010',
            'VERSION' => '4.1'
        },
        {
            'PUBLISHER' => 'Epson Printer Utility Lite version 8.02',
            'NAME' => 'Epson Printer Utility Lite',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'USERNAME' => '',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/07/2009',
            'VERSION' => '8.02'
        },
        {
            'PUBLISHER' => '2.0.2, Copyright 2009 Brother Industries, LTD.',
            'USERNAME' => '',
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
            'PUBLISHER' => 'Dock 1.7',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Dock'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '2.3.8',
            'PUBLISHER' => '2.3.8, Copyright (c) 2010 Apple Inc. All rights reserved.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Assistant réglages Bluetooth',
            'USERNAME' => ''
        },
        {
            'VERSION' => '3.2.5',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Interface Builder',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '30/03/2009',
            'VERSION' => '1.0.1',
            'PUBLISHER' => 'HP Photosmart Compact Photo Printer driver 1.0.1, Copyright (c) 2007-2009 Hewlett-Packard Development Company, L.P.',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'hprastertojpeg',
            'USERNAME' => ''
        },
        {
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '10.6',
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'SecurityFixer',
            'USERNAME' => ''
        },
        {
            'PUBLISHER' => '1.0, Copyright Apple Inc. 2007',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'quicklookd32',
            'USERNAME' => '',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.3'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Wish',
            'PUBLISHER' => 'Wish Shell 8.4.19,',
            'VERSION' => '8.4.19',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '23/07/2009'
        },
        {
            'VERSION' => '3.0',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Universal]',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'dotmacfx',
            'PUBLISHER' => undef
        },
        {
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '10.0',
            'PUBLISHER' => undef,
            'NAME' => 'eaptlstrust',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => ''
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/10/2010',
            'VERSION' => '2.0.0',
            'PUBLISHER' => undef,
            'NAME' => 'VidyoDesktop Uninstaller',
            'SYSTEM_CATEGORY' => 'Applications/Vidyo',
            'USERNAME' => ''
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'SolidWorks eDrawings',
            'PUBLISHER' => undef,
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
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'PUBLISHER' => '© 2002-2003 Apple',
            'NAME' => 'SyncServer',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'INSTALLDATE' => '18/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '5.2'
        },
        {
            'INSTALLDATE' => '25/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '3.1.0',
            'PUBLISHER' => '1.0, Copyright © 2009 Hewlett-Packard Development Company, L.P.',
            'NAME' => 'HPFaxBackend',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'USERNAME' => ''
        },
        {
            'VERSION' => '8.02',
            'INSTALLDATE' => '09/07/2009',
            'COMMENTS' => '[Intel]',
            'USERNAME' => '',
            'NAME' => 'rastertoescpII',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'rastertoescpII Copyright (C) SEIKO EPSON CORPORATION 2001-2009. All rights reserved.'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '13/01/2011',
            'VERSION' => '2.3.1',
            'PUBLISHER' => '2.3.1 (101115), © 2010 Microsoft Corporation. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'Microsoft AutoUpdate',
            'USERNAME' => ''
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '6.0.1',
            'PUBLISHER' => '6.0, © Copyright 2003-2009 Apple Inc., all rights reserved.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ImageCaptureService',
            'USERNAME' => ''
        },
        {
            'VERSION' => '8.02',
            'INSTALLDATE' => '09/07/2009',
            'COMMENTS' => '[Intel]',
            'NAME' => 'commandtoescp',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'USERNAME' => '',
            'PUBLISHER' => 'commandtoescp Copyright (C) SEIKO EPSON CORPORATION 2001-2009. All rights reserved.'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Assistant de certification',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '3.0'
        },
        {
            'PUBLISHER' => 'HP Inkjet 6 Driver 1.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
            'USERNAME' => '',
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
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AppleMobileSync',
            'USERNAME' => ''
        },
        {
            'PUBLISHER' => '10.6.0, Copyright 1997-2009 Apple, Inc.',
            'USERNAME' => '',
            'NAME' => 'Informations Système',
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
            'USERNAME' => '',
            'PUBLISHER' => '6.0, Copyright © 1997-2006 Apple Computer Inc., All Rights Reserved'
        },
        {
            'INSTALLDATE' => '26/01/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '0.9.1',
            'PUBLISHER' => 'Prism 0.9.1, © 2007 Contributors',
            'NAME' => 'Prism',
            'SYSTEM_CATEGORY' => 'zimbra/zdesktop',
            'USERNAME' => 'lubrano'
        },
        {
            'VERSION' => '4.0.6',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '20/02/2011',
            'USERNAME' => '',
            'NAME' => 'Mise à jour de logiciels',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Software Update version 4.0, Copyright © 2000-2009, Apple Inc. All rights reserved.'
        },
        {
            'USERNAME' => '',
            'NAME' => 'Instruments',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'PUBLISHER' => undef,
            'VERSION' => '2.7',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'COMMENTS' => undef,
            'INSTALLDATE' => '30/12/2009',
            'VERSION' => undef,
            'PUBLISHER' => undef,
            'NAME' => 'Free42-Decimal',
            'SYSTEM_CATEGORY' => 'opt/local',
            'USERNAME' => ''
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.7.3',
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'ARM Help'
        },
        {
            'VERSION' => '11.5.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Utilitaire de disque',
            'USERNAME' => '',
            'PUBLISHER' => 'Version 11.5.2, Copyright © 1999-2010 Apple Inc. All rights reserved.'
        },
        {
            'NAME' => 'pdftopdf2',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'USERNAME' => '',
            'PUBLISHER' => 'pdftopdf2 version 8.02, Copyright (C) SEIKO EPSON CORPORATION 2001-2009. All rights reserved.',
            'VERSION' => '8.02',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/07/2009'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/07/2009',
            'VERSION' => '4.5.0',
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'PMC Index',
            'USERNAME' => ''
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'opt/local',
            'NAME' => 'Free42-Binary',
            'COMMENTS' => undef,
            'INSTALLDATE' => '30/12/2009',
            'VERSION' => undef
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '13/01/2011',
            'VERSION' => '14.0.0',
            'PUBLISHER' => '14.0.0 (100825), © 2010 Microsoft Corporation. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011',
            'NAME' => 'Assistant Installation de Microsoft Office',
            'USERNAME' => ''
        },
        {
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[PowerPC]',
            'VERSION' => '12.2.8',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'NAME' => 'Open XML for Charts',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'USERNAME' => ''
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '27/06/2009',
            'VERSION' => '7.0',
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Préférences Système',
            'USERNAME' => ''
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'check_afp',
            'PUBLISHER' => 'AFP Client Session Monitor, Copyright © 2000 - 2007, Apple Inc.',
            'VERSION' => '2.0',
            'INSTALLDATE' => '03/07/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => '10.0, Copyright © 2009-2010 Apple Inc. All Rights Reserved.',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'QuickTime Player',
            'USERNAME' => '',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '10.0'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'NAME' => 'EPSON Scanner',
            'PUBLISHER' => '5.0, Copyright 2003 EPSON',
            'VERSION' => '5.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/07/2009'
        },
        {
            'VERSION' => '1.1.1',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Installation à distance de Mac OS X',
            'USERNAME' => '',
            'PUBLISHER' => 'Remote Install Mac OS X 1.1.1, Copyright © 2007-2009 Apple Inc. All rights reserved'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'MÀJ du programme interne Bluetooth',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '01/08/2009',
            'VERSION' => '2.0.1'
        },
        {
            'VERSION' => '1.3.4',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'USERNAME' => '',
            'NAME' => 'System Events',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => undef
        },
        {
            'NAME' => 'Repeat After Me',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'USERNAME' => '',
            'PUBLISHER' => '1.3, Copyright © 2002-2005 Apple Computer, Inc.',
            'VERSION' => '1.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010'
        },
        {
            'INSTALLDATE' => '13/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '13.0.0',
            'PUBLISHER' => '13.0.0 (100825), © 2010 Microsoft Corporation. All rights reserved.',
            'USERNAME' => '',
            'NAME' => 'Microsoft Communicator',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'PUBLISHER' => 'Version 2.0.3, Copyright Apple Inc., 2008',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AppleGraphicsWarning',
            'USERNAME' => '',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '2.0.3'
        },
        {
            'USERNAME' => 'lubrano',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'Network Recording Player',
            'PUBLISHER' => 'Network Recording Player version 2.2, Copyright WebEx Communications, Inc. 2006',
            'VERSION' => '2.2.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '25/02/2010'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Grapher',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '07/04/2009',
            'VERSION' => '2.1'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'Lanceur d’applets',
            'SYSTEM_CATEGORY' => 'usr/share',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/03/2011',
            'VERSION' => '13.4.0'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Aperçu',
            'PUBLISHER' => '5.0.1, Copyright 2002-2009 Apple Inc.',
            'VERSION' => '5.0.3',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]'
        },
        {
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '3.7.2',
            'PUBLISHER' => 'hpdot4d 3.7.2, (c) Copyright 2005-2010 Hewlett-Packard Development Company, L.P.',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'hpdot4d'
        },
        {
            'VERSION' => '3.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'CompactPhotosmart',
            'USERNAME' => '',
            'PUBLISHER' => 'HP Compact Photosmart Driver 3.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.'
        },
        {
            'VERSION' => '4.0',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Quartz Composer',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'VERSION' => undef,
            'INSTALLDATE' => '12/11/2009',
            'COMMENTS' => undef,
            'NAME' => 'Yahoo! Zimbra Desktop',
            'SYSTEM_CATEGORY' => 'zimbra/zdesktop',
            'USERNAME' => 'lubrano',
            'PUBLISHER' => undef
        },
        {
            'VERSION' => '3.1.9',
            'INSTALLDATE' => '06/03/2011',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Thunderbird',
            'USERNAME' => '',
            'PUBLISHER' => 'Thunderbird 3.1.9'
        },
        {
            'USERNAME' => '',
            'NAME' => 'CPUPalette',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'PUBLISHER' => undef,
            'VERSION' => '4.7.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'VERSION' => '2.1',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'OpenGL Shader Builder',
            'PUBLISHER' => undef
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '1.6',
            'PUBLISHER' => '1.6',
            'NAME' => 'Assistant réglages de réseau',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => ''
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '01/07/2009',
            'VERSION' => '1.0.2',
            'PUBLISHER' => 'GarageBand Getting Started',
            'USERNAME' => '',
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
            'PUBLISHER' => undef
        },
        {
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Organigramme hiérarchique',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '27/12/2010',
            'VERSION' => '12.2.8'
        },
        {
            'NAME' => 'Adobe Updater',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'USERNAME' => '',
            'PUBLISHER' => 'Adobe Updater 6.2.0.1474, Copyright � 2002-2008 by Adobe Systems Incorporated. All rights reserved.',
            'VERSION' => 'Adobe Updater 6.2.0.1474',
            'INSTALLDATE' => '02/03/2011',
            'COMMENTS' => '[Intel]'
        },
        {
            'NAME' => 'Accessibility Verifier',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => '1.2',
            'INSTALLDATE' => '26/08/2010',
            'COMMENTS' => '[Intel]'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '07/10/2009',
            'VERSION' => '0.10',
            'PUBLISHER' => '0.10',
            'NAME' => 'iTerm',
            'SYSTEM_CATEGORY' => 'Applications',
            'USERNAME' => ''
        },
        {
            'NAME' => 'Open XML for Excel',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'USERNAME' => '',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'VERSION' => '12.2.8',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[PowerPC]'
        },
        {
            'PUBLISHER' => 'CIJAutoSetupTool.app version 1.7.0, Copyright CANON INC. 2007-2008 All Rights Reserved.',
            'NAME' => 'CIJAutoSetupTool',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'USERNAME' => '',
            'INSTALLDATE' => '15/06/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.7.1'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/DivX',
            'NAME' => 'DivX Products',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => '1.1.0',
            'INSTALLDATE' => '17/11/2009',
            'COMMENTS' => '[PowerPC]'
        },
        {
            'VERSION' => '3.7.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '28/05/2009',
            'NAME' => 'Colorimètre numérique',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'USERNAME' => '',
            'PUBLISHER' => '3.7.2, Copyright 2001-2008 Apple Inc. All Rights Reserved.'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Utilitaire AirPort',
            'PUBLISHER' => '5.5.2, Copyright 2001-2010 Apple Inc.',
            'VERSION' => '5.5.2',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Flip4Mac',
            'NAME' => 'WMV Player',
            'USERNAME' => '',
            'PUBLISHER' => '2.3.1.2 © 2005-2009 Telestream Inc. All Rights Reserved.',
            'VERSION' => '2.3.1.2',
            'INSTALLDATE' => '04/11/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '1.1',
            'INSTALLDATE' => '13/01/2010',
            'COMMENTS' => '[PowerPC]',
            'USERNAME' => '',
            'NAME' => 'MemoryCard Ejector',
            'SYSTEM_CATEGORY' => 'Applications/Vodafone Mobile Connect',
            'PUBLISHER' => undef
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'DivX Player',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => '7.2 (build 10_0_0_183)',
            'INSTALLDATE' => '28/12/2009',
            'COMMENTS' => '[Intel]'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Utilitaire d’emplacement de mémoire',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => '1.4.1',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]'
        },
        {
            'NAME' => 'Application Loader',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => '1.4',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'NAME' => 'Résolution des conflits',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'PUBLISHER' => '1.0, Copyright Apple Computer Inc. 2004',
            'VERSION' => '5.2',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/07/2009'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0.1',
            'PUBLISHER' => '6.0, © Copyright 2000-2009 Apple Inc., all rights reserved.',
            'NAME' => 'AutoImporter',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => ''
        },
        {
            'NAME' => 'CrashReporterPrefs',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'USERNAME' => '',
            'PUBLISHER' => undef,
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
            'USERNAME' => '',
            'PUBLISHER' => '3.0, Copyright © 2000-2006 Apple Computer Inc., All Rights Reserved'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Deskjet',
            'USERNAME' => '',
            'PUBLISHER' => 'HP Deskjet Driver 3.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
            'VERSION' => '3.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '18/06/2009'
        },
        {
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Core Image Fun House',
            'USERNAME' => '',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010',
            'VERSION' => '2.1.43'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'AppleMobileDeviceHelper',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/03/2011',
            'VERSION' => '3.1'
        },
        {
            'INSTALLDATE' => '01/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0.2',
            'PUBLISHER' => 'iMovie 08 Getting Started',
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'NAME' => 'Premiers contacts avec iMovie 08',
            'USERNAME' => ''
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'PluginIM',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => '1.1',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '21/05/2009',
            'VERSION' => '1.0',
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'SecurityProxy',
            'USERNAME' => ''
        },
        {
            'VERSION' => '10.6.7',
            'INSTALLDATE' => '20/02/2011',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Finder',
            'USERNAME' => '',
            'PUBLISHER' => 'Mac OS X Finder 10.6.7'
        },
        {
            'PUBLISHER' => 'ver3.00, ©2005-2009 Brother Industries, Ltd. All Rights Reserved.',
            'USERNAME' => '',
            'NAME' => 'Brother Contrôleur d\'état',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '3.00'
        },
        {
            'PUBLISHER' => '© Copyright 2009 Apple Inc., all rights reserved.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'FileSyncAgent',
            'USERNAME' => '',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '5.0.3'
        },
        {
            'PUBLISHER' => 'iTunes 10.2.1, © 2000-2011 Apple Inc. All rights reserved.',
            'NAME' => 'iTunes',
            'SYSTEM_CATEGORY' => 'Applications',
            'USERNAME' => '',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/03/2011',
            'VERSION' => '10.2.1'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Carnet d’adresses',
            'PUBLISHER' => undef,
            'VERSION' => '5.0.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '20',
            'PUBLISHER' => 'System Language Initializer',
            'USERNAME' => '',
            'NAME' => 'Language Chooser',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'USERNAME' => '',
            'NAME' => 'Dictionnaire',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => undef,
            'VERSION' => '2.1.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'NAME' => 'Vodafone Mobile Connect',
            'SYSTEM_CATEGORY' => 'Applications/Vodafone Mobile Connect',
            'USERNAME' => '',
            'PUBLISHER' => 'Vodafone Mobile Connect 3G 2.11.04.00',
            'VERSION' => 'Vodafone Mobile Connect 3G 2.11.04',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '13/01/2010'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'iCal Helper',
            'PUBLISHER' => undef,
            'VERSION' => '4.0.4',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'NAME' => 'Utilitaire d’annuaire',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'PUBLISHER' => '2.2, Copyright © 2001–2008 Apple Inc.',
            'VERSION' => '2.2',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]'
        },
        {
            'NAME' => 'g-coul',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'USERNAME' => 'lubrano',
            'PUBLISHER' => undef,
            'VERSION' => '6.5',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/07/2009',
            'VERSION' => '1.0',
            'PUBLISHER' => undef,
            'NAME' => 'ZoneMonitor',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'USERNAME' => ''
        },
        {
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.6',
            'PUBLISHER' => '2.6',
            'USERNAME' => '',
            'NAME' => 'rcd',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'INSTALLDATE' => '12/03/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.0.4',
            'PUBLISHER' => 'Oracle VM VirtualBox Manager 4.0.4, © 2007-2011 Oracle Corporation',
            'USERNAME' => '',
            'NAME' => 'VirtualBox',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'FileMerge',
            'PUBLISHER' => undef,
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
            'USERNAME' => '',
            'PUBLISHER' => '1.0, Copyright Apple Inc. 2007'
        },
        {
            'INSTALLDATE' => '24/02/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.9.2.1599',
            'PUBLISHER' => 'v1.9.2.1599. Copyright 2007-2009 Google Inc. All rights reserved.',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'GoogleVoiceAndVideoUninstaller'
        },
        {
            'PUBLISHER' => '1.4.1 (141.6), Copyright © 2007-2009 Apple Inc. All Rights Reserved.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ODSAgent',
            'USERNAME' => '',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.4.1'
        },
        {
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'USERNAME' => '',
            'NAME' => 'Microsoft Database Daemon',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008'
        },
        {
            'INSTALLDATE' => '17/11/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.0',
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/DivX',
            'NAME' => 'Uninstall DivX for Mac'
        },
        {
            'INSTALLDATE' => '18/03/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '13.4.0',
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Préférences Java'
        },
        {
            'VERSION' => '1.1',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '20/02/2011',
            'USERNAME' => '',
            'NAME' => 'Time Machine',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => '1.1, Copyright 2007-2008 Apple Inc.'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
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
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.1.4',
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'Image Events',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '6.0.1',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Transfert d’images',
            'PUBLISHER' => '6.0, © Copyright 2000-2009 Apple Inc., all rights reserved.'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/07/2009',
            'VERSION' => '1.4',
            'PUBLISHER' => 'Thread Viewer',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Thread Viewer',
            'USERNAME' => ''
        },
        {
            'VERSION' => '2.1.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Inkjet1',
            'USERNAME' => '',
            'PUBLISHER' => 'HP Inkjet 1 Driver 2.1.2, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.'
        },
        {
            'NAME' => 'AddPrinter',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => '6.5',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'PUBLISHER' => 'Boot Camp Assistant 3.0.1, Copyright © 2009 Apple Inc. All rights reserved',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Assistant Boot Camp',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '3.0.1'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'SRLanguageModeler',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => '1.9',
            'INSTALLDATE' => '26/08/2010',
            'COMMENTS' => '[Intel]'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/03/2011',
            'VERSION' => '1.0.5',
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'PubSubAgent'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'fax',
            'USERNAME' => '',
            'PUBLISHER' => 'HP Fax 4.1, Copyright (c) 2009-2010 Hewlett-Packard Development Company, L.P.',
            'VERSION' => '4.1',
            'INSTALLDATE' => '23/04/2010',
            'COMMENTS' => '[Intel]'
        },
        {
            'VERSION' => '10.6',
            'INSTALLDATE' => '31/07/2009',
            'COMMENTS' => '[Universal]',
            'USERNAME' => '',
            'NAME' => 'Assistant réglages',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => '10.6'
        },
        {
            'VERSION' => '2.0',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Service de résumé',
            'USERNAME' => '',
            'PUBLISHER' => 'Summary Service Version  2'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '8.1.0',
            'PUBLISHER' => 'HP Printer Utility version 8.1.0, Copyright (c) 2005-2010 Hewlett-Packard Development Company, L.P.',
            'NAME' => 'HP Printer Utility',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'USERNAME' => ''
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'UnmountAssistantAgent',
            'USERNAME' => '',
            'PUBLISHER' => undef,
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
            'USERNAME' => '',
            'PUBLISHER' => '2.1.1, © 1995-2009 Apple Inc. All Rights Reserved.'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'VietnameseIM',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '1.1'
        },
        {
            'USERNAME' => '',
            'NAME' => 'Kotoeri',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => undef,
            'VERSION' => '4.2.0',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '11/06/2009'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/03/2011',
            'VERSION' => '17289',
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Frameworks',
            'NAME' => 'Network Diagnostic Utility'
        },
        {
            'VERSION' => '1.1.4',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'NAME' => 'Configuration actions de dossier',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'NAME' => 'Bibliothèque de projets Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'USERNAME' => ''
        },
        {
            'USERNAME' => '',
            'NAME' => 'Microsoft PowerPoint',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'VERSION' => '12.2.8',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '27/12/2010'
        },
        {
            'NAME' => 'Premiers contacts avec iWeb',
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'USERNAME' => '',
            'PUBLISHER' => 'iWeb Getting Started',
            'VERSION' => '1.0.2',
            'INSTALLDATE' => '01/07/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
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
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'opt/cisco',
            'NAME' => 'vpndownloader'
        },
        {
            'USERNAME' => '',
            'NAME' => 'Utilitaire d’emplacement d’extension',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => undef,
            'VERSION' => '1.4.1',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'PUBLISHER' => 'GarageBand 4.1.2 (248.7), Copyright © 2007 by Apple Inc.',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'GarageBand',
            'USERNAME' => '',
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
            'USERNAME' => '',
            'PUBLISHER' => '1.1, Copyright © 2006-2009 Apple Inc. All rights reserved.'
        },
        {
            'PUBLISHER' => 'HP PDF Filter 1.3, Copyright (c) 2001-2009 Hewlett-Packard Development Company, L.P.',
            'NAME' => 'pdftopdf',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'USERNAME' => '',
            'INSTALLDATE' => '16/04/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.3'
        },
        {
            'INSTALLDATE' => '01/07/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.1.26',
            'PUBLISHER' => '0.0.0 (v27), Copyright 2008 Lexmark International, Inc. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'LexmarkCUPSDriver',
            'USERNAME' => ''
        },
        {
            'VERSION' => '12.1.0',
            'INSTALLDATE' => '02/07/2009',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Equation Editor',
            'USERNAME' => '',
            'PUBLISHER' => '12.1.0 (080205), © 2007 Microsoft Corporation.  All rights reserved.'
        },
        {
            'VERSION' => '3.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'USERNAME' => '',
            'NAME' => 'Inkjet',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'HP Inkjet Driver 3.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.'
        },
        {
            'PUBLISHER' => '6.0.3, © Copyright 2000-2010 Apple Inc. All rights reserved.',
            'USERNAME' => '',
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
            'PUBLISHER' => 'HP Inkjet 8 Driver 2.1, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
            'USERNAME' => '',
            'NAME' => 'Inkjet8',
            'SYSTEM_CATEGORY' => 'Library/Printers'
        },
        {
            'INSTALLDATE' => '20/02/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.0',
            'PUBLISHER' => undef,
            'NAME' => 'App Store',
            'SYSTEM_CATEGORY' => 'Applications',
            'USERNAME' => ''
        },
        {
            'VERSION' => '10.1.102.64',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '11/11/2010',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Adobe Flash Player Install Manager',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Quartz Composer Visualizer',
            'PUBLISHER' => undef,
            'VERSION' => '1.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'h-color-hp- imprimante couleur',
            'USERNAME' => 'lubrano',
            'PUBLISHER' => undef,
            'VERSION' => '6.5',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'PUBLISHER' => 'Tamil Input Method 1.2',
            'NAME' => 'TamilIM',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '1.3'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
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
            'PUBLISHER' => 'Adobe® Acrobat® 9.4.2, ©1984-2010 Adobe Systems Incorporated. All rights reserved.',
            'USERNAME' => '',
            'NAME' => 'Adobe Reader',
            'SYSTEM_CATEGORY' => 'Applications/Adobe Reader 9'
        },
        {
            'VERSION' => '3.0.1',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'kcSync',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '5.0.3',
            'PUBLISHER' => '© Copyright 2009 Apple Inc., all rights reserved.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'File Sync',
            'USERNAME' => ''
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '24/02/2011',
            'VERSION' => '1.9.2.1599',
            'PUBLISHER' => 'v1.9.2.1599. Copyright 2007-2009 Google Inc. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'GoogleTalkPlugin',
            'USERNAME' => ''
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
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
            'PUBLISHER' => 'InstallAnywhere 8.0, Copyright © 2006 Macrovision Corporation.'
        },
        {
            'PUBLISHER' => undef,
            'NAME' => 'Shark',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'USERNAME' => '',
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
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'PUBLISHER' => undef,
            'NAME' => 'Utilitaire d’archive',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '18/06/2009',
            'VERSION' => '10.6'
        },
        {
            'NAME' => 'Canon IJScanner2',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'USERNAME' => '',
            'PUBLISHER' => '1.0.0, Copyright CANON INC. 2009 All Rights Reserved',
            'VERSION' => '1.0.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '15/06/2009'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Frameworks',
            'NAME' => 'Log Viewer',
            'PUBLISHER' => undef,
            'VERSION' => '17289',
            'INSTALLDATE' => '09/03/2011',
            'COMMENTS' => '[Intel]'
        },
        {
            'COMMENTS' => '[PowerPC]',
            'INSTALLDATE' => '06/12/2007',
            'VERSION' => '10.0.0',
            'PUBLISHER' => '10.0.0 (1204)  Copyright 1995-2002 Microsoft Corporation.  All rights reserved.',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Query',
            'USERNAME' => ''
        },
        {
            'VERSION' => '2.0.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'AddressBookManager',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'VERSION' => '4.7.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'CHUD Remover',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'VERSION' => '1.5',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Capture',
            'PUBLISHER' => undef
        },
        {
            'VERSION' => '6.0.3',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/07/2009',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Messenger',
            'PUBLISHER' => '6.0.3 (070803), © 2006 Microsoft Corporation. All rights reserved.'
        },
        {
            'PUBLISHER' => '2.3.8, Copyright (c) 2010 Apple Inc. All rights reserved.',
            'NAME' => 'BluetoothUIServer',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '2.3.8'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '2.3.8',
            'PUBLISHER' => '2.3.8, Copyright (c) 2010 Apple Inc. All rights reserved.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'AVRCPAgent',
            'USERNAME' => ''
        },
        {
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'store_helper',
            'USERNAME' => '',
            'INSTALLDATE' => '20/02/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.0'
        },
        {
            'INSTALLDATE' => '09/07/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '8.02',
            'PUBLISHER' => 'EPIJAutoSetupTool2 Copyright (C) SEIKO EPSON CORPORATION 2001-2009. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'EPIJAutoSetupTool2',
            'USERNAME' => ''
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '1.0',
            'PUBLISHER' => '1.0, Copyright 2008 Apple Inc.',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'InkServer'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '5.3',
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Property List Editor',
            'USERNAME' => ''
        },
        {
            'PUBLISHER' => undef,
            'NAME' => 'VidyoDesktop',
            'SYSTEM_CATEGORY' => 'Applications/Vidyo',
            'USERNAME' => '',
            'INSTALLDATE' => '19/10/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.0'
        },
        {
            'VERSION' => '5.2',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'SecurityAgent',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'NAME' => 'Build Applet',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'USERNAME' => '',
            'PUBLISHER' => '2.5.4a0, (c) 2004 Python Software Foundation.',
            'VERSION' => '2.5.4',
            'COMMENTS' => undef,
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Canon IJ Printer Utility',
            'PUBLISHER' => 'Canon IJ Printer Utility version 7.17.10, Copyright CANON INC. 2001-2009 All Rights Reserved.',
            'VERSION' => '7.17.10',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '15/06/2009'
        },
        {
            'PUBLISHER' => undef,
            'NAME' => 'Éditeur d\'équations Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011',
            'USERNAME' => '',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '13/01/2011',
            'VERSION' => '14.0.0'
        },
        {
            'USERNAME' => 'lubrano',
            'NAME' => 'Zimbra Desktop désinstallateur',
            'SYSTEM_CATEGORY' => 'zimbra/zdesktop',
            'PUBLISHER' => '1.0.4',
            'VERSION' => '1.0.4',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Universal]'
        },
        {
            'NAME' => 'Microsoft Word',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'USERNAME' => '',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'VERSION' => '12.2.8',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]'
        },
        {
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'USERNAME' => '',
            'NAME' => 'Microsoft Graph',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '11/01/2011',
            'VERSION' => '1.4.1',
            'PUBLISHER' => '1.4.1, Copyright 2001-2010 The Adium Team',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Adium'
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Spaces',
            'PUBLISHER' => '1.1, Copyright 2007-2008 Apple Inc.',
            'VERSION' => '1.1',
            'INSTALLDATE' => '20/02/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => '2.1.1, Copyright © 2004-2009 Apple Inc. All rights reserved.',
            'USERNAME' => '',
            'NAME' => 'Automator',
            'SYSTEM_CATEGORY' => 'Applications',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.1.1'
        },
        {
            'PUBLISHER' => '12.2.8 (101117), © 2009 Microsoft Corporation. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Document Connection',
            'USERNAME' => '',
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
            'USERNAME' => '',
            'PUBLISHER' => '2.3.8, Copyright (c) 2010 Apple Inc. All rights reserved.'
        },
        {
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Jar Launcher',
            'USERNAME' => '',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/03/2011',
            'VERSION' => '13.4.0'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'Cisco AnyConnect VPN Client',
            'SYSTEM_CATEGORY' => 'Applications/Cisco',
            'INSTALLDATE' => '15/02/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.0'
        },
        {
            'USERNAME' => '',
            'NAME' => 'Centre de téléchargement Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011',
            'PUBLISHER' => '14.0.2 (101115), © 2010 Microsoft Corporation. All rights reserved.',
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
            'USERNAME' => '',
            'PUBLISHER' => '2.3.6, Copyright (c) 2010 Apple Inc. All rights reserved.'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'Uninstall AnyConnect',
            'SYSTEM_CATEGORY' => 'Applications/Cisco',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '15/02/2010',
            'VERSION' => '1.0'
        },
        {
            'PUBLISHER' => undef,
            'NAME' => 'PreferenceSyncClient',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '02/07/2009',
            'VERSION' => '2.0'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '1.3',
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'NAME' => 'Yahoo! Sync',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'PUBLISHER' => 'Version 1.4.6, Copyright © 2000-2009 Apple Inc. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Utilitaire de réseau',
            'USERNAME' => '',
            'INSTALLDATE' => '25/06/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.4.6'
        },
        {
            'VERSION' => '7.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Aide-mémoire',
            'PUBLISHER' => undef
        },
        {
            'VERSION' => '6.0.11994.637942',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '08/03/2011',
            'USERNAME' => '',
            'NAME' => 'Parallels Transporter',
            'SYSTEM_CATEGORY' => 'Library/Parallels',
            'PUBLISHER' => '6.0.11994.637942, Copyright 2005-2011 Parallels Holdings, Ltd. and its affiliates'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '4.7.3',
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'SpindownHD',
            'USERNAME' => ''
        },
        {
            'VERSION' => '2.00',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '29/06/2009',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'P-touch Status Monitor',
            'PUBLISHER' => 'ver2.00, © 2005-2008 Brother Industries, Ltd.'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '17/09/2010',
            'VERSION' => '1.2.0',
            'PUBLISHER' => 'Nimbuzz for Mac OS X, version 1.2.0',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Nimbuzz'
        },
        {
            'VERSION' => '1.5',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Universal]',
            'NAME' => 'MiniTerm',
            'SYSTEM_CATEGORY' => 'usr/libexec',
            'USERNAME' => '',
            'PUBLISHER' => 'Terminal window application for PPP'
        },
        {
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'iChat',
            'USERNAME' => '',
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
            'USERNAME' => '',
            'PUBLISHER' => '2.2.5 (101115), © 2010 Microsoft Corporation. All rights reserved.'
        },
        {
            'VERSION' => '14.0.2',
            'INSTALLDATE' => '13/01/2011',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011',
            'NAME' => 'SyncServicesAgent',
            'USERNAME' => '',
            'PUBLISHER' => '14.0.2 (101115), © 2010 Microsoft Corporation. All rights reserved.'
        },
        {
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Install Helper',
            'USERNAME' => '',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/02/2010',
            'VERSION' => '1.0'
        },
        {
            'PUBLISHER' => undef,
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'PowerPC Help',
            'USERNAME' => '',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.7.3'
        },
        {
            'PUBLISHER' => undef,
            'NAME' => 'HALLab',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'USERNAME' => '',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '1.6'
        },
        {
            'PUBLISHER' => '1.1.52, Copyright 2009 Hewlett-Packard Company',
            'NAME' => 'HPScanner',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'USERNAME' => '',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '24/07/2009',
            'VERSION' => '1.1.52'
        },
        {
            'USERNAME' => '',
            'NAME' => 'commandtohp',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'HP Command File Filter 1.11, Copyright (c) 2006-2010 Hewlett-Packard Development Company, L.P.',
            'VERSION' => '1.11',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '15/06/2009'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '29/05/2009',
            'VERSION' => '3.8.1',
            'PUBLISHER' => undef,
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Speech Startup'
        },
        {
            'VERSION' => '1.0',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '19/05/2009',
            'NAME' => 'wxPerl',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'PUBLISHER' => 'About Xcode',
            'USERNAME' => '',
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
            'PUBLISHER' => 'Accessibility Inspector 2.0, Copyright 2002-2009 Apple Inc.',
            'USERNAME' => '',
            'NAME' => 'Accessibility Inspector',
            'SYSTEM_CATEGORY' => 'Developer/Applications'
        },
        {
            'NAME' => 'Java VisualVM',
            'SYSTEM_CATEGORY' => 'usr/share',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => '13.4.0',
            'INSTALLDATE' => '18/03/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0',
            'PUBLISHER' => '6.0, © Copyright 2002-2009 Apple Inc., all rights reserved.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Type7Camera',
            'USERNAME' => ''
        },
        {
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'iSync Plug-in Maker',
            'PUBLISHER' => undef,
            'VERSION' => '3.1',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'USERNAME' => '',
            'NAME' => 'Microsoft Database Utility',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'TWAINBridge',
            'USERNAME' => '',
            'PUBLISHER' => '6.0.1, © Copyright 2000-2010 Apple Inc., all rights reserved.',
            'VERSION' => '6.0.1',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Scripts',
            'NAME' => 'Extract',
            'USERNAME' => '',
            'PUBLISHER' => undef,
            'VERSION' => undef,
            'INSTALLDATE' => '25/04/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'VERSION' => '5.2',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'USERNAME' => '',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'Syncrospector',
            'PUBLISHER' => 'Syncrospector 3.0, © 2004 Apple Computer, Inc., All rights reserved.'
        },
        {
            'PUBLISHER' => undef,
            'NAME' => 'DivX Converter',
            'SYSTEM_CATEGORY' => 'Applications',
            'USERNAME' => '',
            'INSTALLDATE' => '28/12/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.3'
        },
        {
            'PUBLISHER' => undef,
            'NAME' => 'ServerJoiner',
            'SYSTEM_CATEGORY' => 'System/Library',
            'USERNAME' => '',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/07/2009',
            'VERSION' => '10.6.3'
        },
        {
            'PUBLISHER' => undef,
            'USERNAME' => '',
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
            'USERNAME' => '',
            'PUBLISHER' => undef
        },
        {
            'USERNAME' => '',
            'NAME' => 'Moniteur d’activité',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'PUBLISHER' => undef,
            'VERSION' => '10.6',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '31/07/2009'
        },
        {
            'VERSION' => '4.1',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '23/04/2010',
            'USERNAME' => '',
            'NAME' => 'rastertofax',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'HP Fax 4.1, Copyright (c) 2009-2010 Hewlett-Packard Development Company, L.P.'
        }
    ]
);

my $datesStr = {
    "7/8/15 11:11 PM" => '08/07/2015',
    "7/31/09 9:18 AM" => '31/07/2009',
    "1/13/10 6:16 PM" => '13/01/2010',
    "04/09/11 22:42" => '09/04/2011'
};

plan tests => 2 * scalar (keys %tests)
    + 1
    + scalar (keys %$datesStr)
    + 7;

for my $dateStr (keys %$datesStr) {
    my $formatted = GLPI::Agent::Task::Inventory::MacOS::Softwares::_formatDate($dateStr);
    ok ($formatted eq $datesStr->{$dateStr}, "'" . $datesStr->{$dateStr} ."' expected but got '" . $formatted . "'");
}

my $NotADate = "this string should be a date...";
my $nothingdone = GLPI::Agent::Task::Inventory::MacOS::Softwares::_formatDate($NotADate);
ok ($nothingdone eq $NotADate);

my $inventory = GLPI::Test::Inventory->new();

foreach my $test (keys %tests) {
    my $file = "resources/macos/system_profiler/$test.SPApplicationsDataType";
    my $softwares = GLPI::Agent::Task::Inventory::MacOS::Softwares::_getSoftwaresList(file => $file, format => 'text');
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
