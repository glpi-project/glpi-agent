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
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'NAME' => 'HP Scanner 3',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '3.2.9'
        },
        {
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
            'PUBLISHER' => '6.0.11994.637942, Copyright 2005-2011 Parallels Holdings, Ltd. and its affiliates',
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
            'PUBLISHER' => 'HP Laserjet Driver 1.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
            'NAME' => 'Laserjet',
            'SYSTEM_CATEGORY' => 'Library/Printers',
        },
        {
            'VERSION' => '2.0.1',
            'INSTALLDATE' => '21/07/2009',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Transfert de podcast',
            'PUBLISHER' => '2.0.1, Copyright © 2007-2009 Apple Inc.'
        },
        {
            'INSTALLDATE' => '16/06/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.0',
            'PUBLISHER' => 'HP Photosmart Driver 4.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Photosmart'
        },
        {
            'PUBLISHER' => 'HP Inkjet 3 Driver 2.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
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
            'PUBLISHER' => '2.4.2, Copyright 2003-2009 Apple Inc.'
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
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'VERSION' => '12.2.8',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '27/12/2010'
        },
        {
            'PUBLISHER' => '6.0.11994.637942, Copyright 2005-2011 Parallels Holdings, Ltd. and its affiliates',
            'SYSTEM_CATEGORY' => 'Library/Parallels',
            'NAME' => 'Parallels Mounter',
            'INSTALLDATE' => '08/03/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '6.0'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'NetAuthAgent',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '07/07/2010',
            'VERSION' => '2.1'
        },
        {
            'PUBLISHER' => '6.0, © Copyright 2003-2009 Apple  Inc., all rights reserved.',
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
            'PUBLISHER' => 'CIJScannerRegister version 1.0.0, Copyright CANON INC. 2009 All Rights Reserved.'
        },
        {
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
            'NAME' => 'Utilitaire de l\'imprimante Lexmark',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => '1.0, Copyright 2008 Lexmark International, Inc. All rights reserved.'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ChineseTextConverterService',
            'PUBLISHER' => 'Chinese Text Converter 1.1',
            'VERSION' => '1.2',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]'
        },
        {
            'PUBLISHER' => '6.0, © Copyright 2003-2009 Apple Inc., all rights reserved.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Image Capture Web Server',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.0'
        },
        {
            'PUBLISHER' => '4.6, Copyright 2008 Apple Computer, Inc.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Outil d’étalonnage du moniteur',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.6'
        },
        {
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
            'NAME' => 'Type2Camera',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => '6.0, © Copyright 2000-2009 Apple Inc., all rights reserved.'
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
            'PUBLISHER' => '6.2.1, Copyright © 2000–2009 Apple Inc. All rights reserved.',
            'NAME' => 'Apple80211Agent',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'VERSION' => '1.0.0',
            'INSTALLDATE' => '10/06/2010',
            'COMMENTS' => '[Intel]',
            'NAME' => 'hpPreProcessing',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => '1.0.0, (c) Copyright 2001-2010 Hewlett-Packard Development Company, L.P.'
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
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0.2',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '2.3.6',
            'PUBLISHER' => '2.3.6, Copyright (c) 2010 Apple Inc. All rights reserved.',
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
            'PUBLISHER' => '1.0.0, Copyright CANON INC. 2009 All Rights Reserved',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'NAME' => 'Canon IJScanner1',
        },
        {
            'PUBLISHER' => '1.7, Copyright 2006-2008 Apple Inc.',
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
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0',
            'PUBLISHER' => '6.0, © Copyright 2000-2009 Apple Inc., all rights reserved.',
            'NAME' => 'Type1Camera',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Type3Camera',
            'PUBLISHER' => '6.0, © Copyright 2001-2009 Apple Inc., all rights reserved.',
            'VERSION' => '6.0',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'OpenGL Profiler',
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
            'NAME' => 'Utilitaire de base de données Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011'
        },
        {
            'NAME' => 'Problem Reporter',
            'SYSTEM_CATEGORY' => 'System/Library',
            'INSTALLDATE' => '20/02/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '10.6.6'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'NAME' => 'License',
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
        },
        {
            'VERSION' => '2.3.8',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'OBEXAgent',
            'PUBLISHER' => '2.3.8, Copyright (c) 2010 Apple Inc. All rights reserved.'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'VoiceOver',
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
            'PUBLISHER' => '7.6.6, Copyright © 1989-2009 Apple Inc. All Rights Reserved'
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
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.'
        },
        {
            'VERSION' => '1.5',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '26/08/2010',
            'NAME' => 'OpenGL Driver Monitor',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'PUBLISHER' => '1.5, Copyright © 2009 Apple Inc.'
        },
        {
            'PUBLISHER' => '6.0.1, © Copyright 2002-2009 Apple Inc., all rights reserved.',
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
            'PUBLISHER' => '14.0.2 (101115), © 2010 Microsoft Corporation. All rights reserved.',
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
            'PUBLISHER' => '5.0.4, Copyright © 2003-2011 Apple Inc.',
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
            'PUBLISHER' => '4.0, Copyright Apple Computer Inc. 2004'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '07/07/2010',
            'VERSION' => '6.5.10',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'KerberosAgent',
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '2.2',
            'PUBLISHER' => '2.2 ©2010, Apple, Inc',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'AU Lab',
        },
        {
            'VERSION' => '12.2.8',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'NAME' => 'Alerts Daemon',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.'
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
            'PUBLISHER' => 'Copyright © 2009 Apple Inc.',
            'VERSION' => '41.5',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]'
        },
        {
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
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
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'SyncDiagnostics',
            'INSTALLDATE' => '18/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '5.2'
        },
        {
            'PUBLISHER' => 'Quartz Debug 4.1',
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
            'PUBLISHER' => '6.0, © Copyright 2003-2009 Apple Inc., all rights reserved.'
        },
        {
            'VERSION' => '3.8.1',
            'INSTALLDATE' => '29/05/2009',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
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
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '2.3.8',
            'PUBLISHER' => '2.3.8, Copyright (c) 2010 Apple Inc. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Échange de fichiers Bluetooth',
        },
        {
            'INSTALLDATE' => '08/07/2009',
            'COMMENTS' => '[Universal]',
            'VERSION' => '2.5.4',
            'PUBLISHER' => '2.5.4, © 001-2006 Python Software Foundation',
            'NAME' => 'Python Launcher',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'PUBLISHER' => '1.2, Copyright © 2004-2009 Apple Inc. All rights reserved.',
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
            'PUBLISHER' => '14.0.2 (101115), © 2010 Microsoft Corporation. All rights reserved.'
        },
        {
            'NAME' => 'AddressBookSync',
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
            'PUBLISHER' => '1.1.0 (101115), © 2010 Microsoft Corporation. All rights reserved.',
            'VERSION' => '1.1.0',
            'INSTALLDATE' => '13/01/2011',
            'COMMENTS' => '[Universal]'
        },
        {
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
            'PUBLISHER' => 'URL Access Scripting 1.1, Copyright © 2002-2004 Apple Computer, Inc.'
        },
        {
            'VERSION' => '1.2.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
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
            'PUBLISHER' => 'FontSync Scripting 2.0. Copyright © 2000-2008 Apple Inc.'
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
            'PUBLISHER' => 'HP Utility version 4.8.5, Copyright (c) 2005-2010 Hewlett-Packard Development Company, L.P.',
            'NAME' => 'HP Utility',
            'SYSTEM_CATEGORY' => 'Library/Printers'
        },
        {
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
        },
        {
            'VERSION' => '1.1',
            'INSTALLDATE' => '09/07/2008',
            'COMMENTS' => '[Universal]',
            'NAME' => 'À propos d’AHT',
            'SYSTEM_CATEGORY' => 'Library/Documentation',
            'PUBLISHER' => 'Apple Hardware Test Read Me'
        },
        {
            'VERSION' => '1.2',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Utilitaire RAID',
            'PUBLISHER' => 'RAID Utility 1.0 (121), Copyright © 2007-2009 Apple Inc.'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.0',
            'PUBLISHER' => '6.0, © Copyright 2001-2009 Apple Inc., all rights reserved.',
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
            'PUBLISHER' => '4.0, Copyright © 1997-2009 Apple Inc., All Rights Reserved'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '08/07/2009',
            'VERSION' => '2.5.4',
            'PUBLISHER' => '2.5.4a0, (c) 2004 Python Software Foundation.',
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
            'PUBLISHER' => '9.4.2, ©2009-2010 Adobe Systems Incorporated. All rights reserved.'
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => undef,
            'SYSTEM_CATEGORY' => 'Developer/SDKs',
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
            'PUBLISHER' => '4.0.0, Copyright © 2002-2010 Apple Inc. All Rights Reserved.',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'NAME' => 'USB Prober',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '4.0.0'
        },
        {
            'PUBLISHER' => '1.5.5 (155.2), Copyright © 2006-2009 Apple Inc. All Rights Reserved.',
            'NAME' => 'Agent de la borne d’accès AirPort',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '1.5.5'
        },
        {
            'PUBLISHER' => 'Welcome to Leopard',
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
        },
        {
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Entourage'
        },
        {
            'NAME' => 'X11',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'PUBLISHER' => 'org.x.X11',
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
            'PUBLISHER' => 'HP Officejet Driver 3.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
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
            'NAME' => 'Ticket Viewer',
        },
        {
            'VERSION' => '3.1.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'iSync',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => '3.1.2, Copyright © 2003-2010 Apple Inc.'
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
            'PUBLISHER' => '2.0, Copyright © 2004-2009 Apple Inc., All Rights Reserved',
            'NAME' => 'KeyboardViewer',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'VERSION' => '2.3',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
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
            'NAME' => 'Database Events'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '6.0.4',
            'PUBLISHER' => '6.0.4, © Copyright 2004-2010 Apple Inc. All rights reserved.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'PTPCamera'
        },
        {
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
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
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
            'PUBLISHER' => '1.1.1 (100910), © 2007 Microsoft Corporation. All rights reserved.'
        },
        {
            'PUBLISHER' => 'HP Inkjet 5 Driver 2.1, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
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
            'PUBLISHER' => '7.1.4, Copyright © 2007-2008 Apple Inc. All Rights Reserved.',
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
            'PUBLISHER' => 'Xcode version 3.2.5',
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
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '10.5.0'
        },
        {
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.1.3',
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
            'NAME' => 'Printer Setup Utility',
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.0',
            'PUBLISHER' => '6.0, © Copyright 2004-2009 Apple Inc., all rights reserved.',
            'NAME' => 'BluetoothCamera',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'INSTALLDATE' => '01/07/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.00.29',
            'PUBLISHER' => 'Copyright (C) 2004-2009 Samsung Electronics Co., Ltd.',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'NAME' => 'Samsung Scanner',
        },
        {
            'PUBLISHER' => 'HP Inkjet 4 Driver 2.2, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
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
            'PUBLISHER' => '2.0.4, Copyright 2008 Apple Inc.',
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
            'SYSTEM_CATEGORY' => 'Library/Printers',
        },
        {
            'NAME' => 'SystemUIServer',
            'SYSTEM_CATEGORY' => 'System/Library',
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
        },
        {
            'NAME' => 'TCIM',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => '6.2, Copyright © 1997-2006 Apple Computer Inc., All Rights Reserved',
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
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.'
        },
        {
            'VERSION' => '2.0',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '20/02/2011',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ParentalControls',
            'PUBLISHER' => '2.0, Copyright Apple Inc. 2007-2009'
        },
        {
            'PUBLISHER' => '6.0.2, © Copyright 2000-2010 Apple Inc. All rights reserved.',
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
            'PUBLISHER' => '2.2.2, Copyright © 2003-2010 Apple Inc.',
            'NAME' => 'Livre des polices',
            'SYSTEM_CATEGORY' => 'Applications',
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'SpeechSynthesisServer',
            'VERSION' => '3.10.35',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '12/07/2009'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'FontRegistryUIAgent',
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
            'NAME' => 'Éditeur AppleScript',
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Java Web Start',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '18/03/2011',
            'VERSION' => '13.4.0'
        },
        {
            'PUBLISHER' => '2.1.0 (100825), © 2010 Microsoft Corporation. All rights reserved.',
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
            'NAME' => 'CCacheServer',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'loginwindow',
            'VERSION' => '6.1.1',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'NAME' => 'ScreenSaverEngine',
            'SYSTEM_CATEGORY' => 'System/Library',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '3.0.3'
        },
        {
            'NAME' => 'iStumbler',
            'SYSTEM_CATEGORY' => 'Applications',
            'PUBLISHER' => 'iStumbler Release 98',
            'VERSION' => 'Release 98',
            'INSTALLDATE' => '05/02/2007',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => '2.3.6, Copyright (c) 2010 Apple Inc. All rights reserved.',
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
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '6.0'
        },
        {
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
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.'
        },
        {
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
        },
        {
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'OpenOffice',
            'PUBLISHER' => 'OpenOffice.org 3.2.0 [320m8(Build:9472)]',
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
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.0.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009'
        },
        {
            'PUBLISHER' => '1.1.1, Copyright © 2007-2009 Apple Inc., All Rights Reserved.',
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
            'PUBLISHER' => '4.6.2, © Copyright 2009 Apple Inc.',
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
            'PUBLISHER' => 'Epson Printer Utility Lite version 8.02',
            'NAME' => 'Epson Printer Utility Lite',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '09/07/2009',
            'VERSION' => '8.02'
        },
        {
            'PUBLISHER' => '2.0.2, Copyright 2009 Brother Industries, LTD.',
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
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Dock'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '2.3.8',
            'PUBLISHER' => '2.3.8, Copyright (c) 2010 Apple Inc. All rights reserved.',
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
            'PUBLISHER' => 'HP Photosmart Compact Photo Printer driver 1.0.1, Copyright (c) 2007-2009 Hewlett-Packard Development Company, L.P.',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'hprastertojpeg',
        },
        {
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '10.6',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'SecurityFixer',
        },
        {
            'PUBLISHER' => '1.0, Copyright Apple Inc. 2007',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'quicklookd32',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '2.3'
        },
        {
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
            'SYSTEM_CATEGORY' => 'System/Library',
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
            'PUBLISHER' => '© 2002-2003 Apple',
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
            'PUBLISHER' => '1.0, Copyright © 2009 Hewlett-Packard Development Company, L.P.',
            'NAME' => 'HPFaxBackend',
            'SYSTEM_CATEGORY' => 'Library/Printers',
        },
        {
            'VERSION' => '8.02',
            'INSTALLDATE' => '09/07/2009',
            'COMMENTS' => '[Intel]',
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
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '6.0.1',
            'PUBLISHER' => '6.0, © Copyright 2003-2009 Apple Inc., all rights reserved.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'ImageCaptureService',
        },
        {
            'VERSION' => '8.02',
            'INSTALLDATE' => '09/07/2009',
            'COMMENTS' => '[Intel]',
            'NAME' => 'commandtoescp',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'commandtoescp Copyright (C) SEIKO EPSON CORPORATION 2001-2009. All rights reserved.'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Assistant de certification',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Intel]',
            'VERSION' => '3.0'
        },
        {
            'PUBLISHER' => 'HP Inkjet 6 Driver 1.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
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
            'NAME' => 'AppleMobileSync',
        },
        {
            'PUBLISHER' => '10.6.0, Copyright 1997-2009 Apple, Inc.',
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
            'NAME' => 'Mise à jour de logiciels',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => 'Software Update version 4.0, Copyright © 2000-2009, Apple Inc. All rights reserved.'
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
            'PUBLISHER' => 'Version 11.5.2, Copyright © 1999-2010 Apple Inc. All rights reserved.'
        },
        {
            'NAME' => 'pdftopdf2',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'pdftopdf2 version 8.02, Copyright (C) SEIKO EPSON CORPORATION 2001-2009. All rights reserved.',
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
            'PUBLISHER' => '14.0.0 (100825), © 2010 Microsoft Corporation. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011',
            'NAME' => 'Assistant Installation de Microsoft Office',
        },
        {
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[PowerPC]',
            'VERSION' => '12.2.8',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
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
            'PUBLISHER' => 'AFP Client Session Monitor, Copyright © 2000 - 2007, Apple Inc.',
            'VERSION' => '2.0',
            'INSTALLDATE' => '03/07/2009',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => '10.0, Copyright © 2009-2010 Apple Inc. All Rights Reserved.',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'QuickTime Player',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '10.0'
        },
        {
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
            'NAME' => 'Installation à distance de Mac OS X',
            'PUBLISHER' => 'Remote Install Mac OS X 1.1.1, Copyright © 2007-2009 Apple Inc. All rights reserved'
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
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'NAME' => 'Repeat After Me',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
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
            'NAME' => 'Microsoft Communicator',
            'SYSTEM_CATEGORY' => 'Applications'
        },
        {
            'PUBLISHER' => 'Version 2.0.3, Copyright Apple Inc., 2008',
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
            'PUBLISHER' => 'Network Recording Player version 2.2, Copyright WebEx Communications, Inc. 2006',
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
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'hpdot4d'
        },
        {
            'VERSION' => '3.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'CompactPhotosmart',
            'PUBLISHER' => 'HP Compact Photosmart Driver 3.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.'
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
            'PUBLISHER' => 'Thunderbird 3.1.9'
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
            'PUBLISHER' => '1.6',
            'NAME' => 'Assistant réglages de réseau',
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '01/07/2009',
            'VERSION' => '1.0.2',
            'PUBLISHER' => 'GarageBand Getting Started',
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
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Organigramme hiérarchique',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '27/12/2010',
            'VERSION' => '12.2.8'
        },
        {
            'NAME' => 'Adobe Updater',
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'PUBLISHER' => 'Adobe Updater 6.2.0.1474, Copyright � 2002-2008 by Adobe Systems Incorporated. All rights reserved.',
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
            'PUBLISHER' => '0.10',
            'NAME' => 'iTerm',
            'SYSTEM_CATEGORY' => 'Applications',
        },
        {
            'NAME' => 'Open XML for Excel',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'VERSION' => '12.2.8',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[PowerPC]'
        },
        {
            'PUBLISHER' => 'CIJAutoSetupTool.app version 1.7.0, Copyright CANON INC. 2007-2008 All Rights Reserved.',
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
            'PUBLISHER' => '3.7.2, Copyright 2001-2008 Apple Inc. All Rights Reserved.'
        },
        {
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
            'PUBLISHER' => '2.3.1.2 © 2005-2009 Telestream Inc. All Rights Reserved.',
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
            'PUBLISHER' => '3.0, Copyright © 2000-2006 Apple Computer Inc., All Rights Reserved'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Deskjet',
            'PUBLISHER' => 'HP Deskjet Driver 3.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.',
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
            'NAME' => 'SecurityProxy',
        },
        {
            'VERSION' => '10.6.7',
            'INSTALLDATE' => '20/02/2011',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Finder',
            'PUBLISHER' => 'Mac OS X Finder 10.6.7'
        },
        {
            'PUBLISHER' => 'ver3.00, ©2005-2009 Brother Industries, Ltd. All Rights Reserved.',
            'NAME' => 'Brother Contrôleur d\'état',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'VERSION' => '3.00'
        },
        {
            'PUBLISHER' => '© Copyright 2009 Apple Inc., all rights reserved.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'FileSyncAgent',
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '5.0.3'
        },
        {
            'PUBLISHER' => 'iTunes 10.2.1, © 2000-2011 Apple Inc. All rights reserved.',
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
            'PUBLISHER' => 'System Language Initializer',
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
            'PUBLISHER' => 'Vodafone Mobile Connect 3G 2.11.04.00',
            'VERSION' => 'Vodafone Mobile Connect 3G 2.11.04',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '13/01/2010'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'iCal Helper',
            'VERSION' => '4.0.4',
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'NAME' => 'Utilitaire d’annuaire',
            'SYSTEM_CATEGORY' => 'System/Library',
            'PUBLISHER' => '2.2, Copyright © 2001–2008 Apple Inc.',
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
            'PUBLISHER' => '2.6',
            'NAME' => 'rcd',
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'INSTALLDATE' => '12/03/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '4.0.4',
            'PUBLISHER' => 'Oracle VM VirtualBox Manager 4.0.4, © 2007-2011 Oracle Corporation',
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
            'PUBLISHER' => '1.0, Copyright Apple Inc. 2007'
        },
        {
            'INSTALLDATE' => '24/02/2011',
            'COMMENTS' => '[Universal]',
            'VERSION' => '1.9.2.1599',
            'PUBLISHER' => 'v1.9.2.1599. Copyright 2007-2009 Google Inc. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Library/Application Support',
            'NAME' => 'GoogleVoiceAndVideoUninstaller'
        },
        {
            'PUBLISHER' => '1.4.1 (141.6), Copyright © 2007-2009 Apple Inc. All Rights Reserved.',
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
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
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
            'PUBLISHER' => '1.1, Copyright 2007-2008 Apple Inc.'
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
            'SYSTEM_CATEGORY' => 'System/Library'
        },
        {
            'VERSION' => '6.0.1',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
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
        },
        {
            'VERSION' => '2.1.2',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Inkjet1',
            'PUBLISHER' => 'HP Inkjet 1 Driver 2.1.2, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.'
        },
        {
            'NAME' => 'AddPrinter',
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '6.5',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'PUBLISHER' => 'Boot Camp Assistant 3.0.1, Copyright © 2009 Apple Inc. All rights reserved',
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
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'PubSubAgent'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'fax',
            'PUBLISHER' => 'HP Fax 4.1, Copyright (c) 2009-2010 Hewlett-Packard Development Company, L.P.',
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
            'PUBLISHER' => '10.6'
        },
        {
            'VERSION' => '2.0',
            'INSTALLDATE' => '19/05/2009',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Service de résumé',
            'PUBLISHER' => 'Summary Service Version  2'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'VERSION' => '8.1.0',
            'PUBLISHER' => 'HP Printer Utility version 8.1.0, Copyright (c) 2005-2010 Hewlett-Packard Development Company, L.P.',
            'NAME' => 'HP Printer Utility',
            'SYSTEM_CATEGORY' => 'Library/Printers',
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'UnmountAssistantAgent',
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
            'PUBLISHER' => '2.1.1, © 1995-2009 Apple Inc. All Rights Reserved.'
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
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8',
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'NAME' => 'Bibliothèque de projets Microsoft',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
        },
        {
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
            'PUBLISHER' => 'iWeb Getting Started',
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
            'SYSTEM_CATEGORY' => 'System/Library',
            'VERSION' => '1.4.1',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'PUBLISHER' => 'GarageBand 4.1.2 (248.7), Copyright © 2007 by Apple Inc.',
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
            'PUBLISHER' => '1.1, Copyright © 2006-2009 Apple Inc. All rights reserved.'
        },
        {
            'PUBLISHER' => 'HP PDF Filter 1.3, Copyright (c) 2001-2009 Hewlett-Packard Development Company, L.P.',
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
            'PUBLISHER' => '0.0.0 (v27), Copyright 2008 Lexmark International, Inc. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'LexmarkCUPSDriver',
        },
        {
            'VERSION' => '12.1.0',
            'INSTALLDATE' => '02/07/2009',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Equation Editor',
            'PUBLISHER' => '12.1.0 (080205), © 2007 Microsoft Corporation.  All rights reserved.'
        },
        {
            'VERSION' => '3.0',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '16/06/2009',
            'NAME' => 'Inkjet',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'PUBLISHER' => 'HP Inkjet Driver 3.0, Copyright (c) 1994-2009 Hewlett-Packard Development Company, L.P.'
        },
        {
            'PUBLISHER' => '6.0.3, © Copyright 2000-2010 Apple Inc. All rights reserved.',
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
            'PUBLISHER' => 'Tamil Input Method 1.2',
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
            'PUBLISHER' => 'Adobe® Acrobat® 9.4.2, ©1984-2010 Adobe Systems Incorporated. All rights reserved.',
            'NAME' => 'Adobe Reader',
            'SYSTEM_CATEGORY' => 'Applications/Adobe Reader 9'
        },
        {
            'VERSION' => '3.0.1',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Universal]',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'kcSync',
        },
        {
            'INSTALLDATE' => '05/01/2011',
            'COMMENTS' => '[Intel]',
            'VERSION' => '5.0.3',
            'PUBLISHER' => '© Copyright 2009 Apple Inc., all rights reserved.',
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'File Sync',
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '24/02/2011',
            'VERSION' => '1.9.2.1599',
            'PUBLISHER' => 'v1.9.2.1599. Copyright 2007-2009 Google Inc. All rights reserved.',
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
            'PUBLISHER' => 'InstallAnywhere 8.0, Copyright © 2006 Macrovision Corporation.'
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
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '18/06/2009',
            'VERSION' => '10.6'
        },
        {
            'NAME' => 'Canon IJScanner2',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'PUBLISHER' => '1.0.0, Copyright CANON INC. 2009 All Rights Reserved',
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
            'PUBLISHER' => '10.0.0 (1204)  Copyright 1995-2002 Microsoft Corporation.  All rights reserved.',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'NAME' => 'Microsoft Query',
        },
        {
            'VERSION' => '2.0.3',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '05/01/2011',
            'NAME' => 'AddressBookManager',
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
            'PUBLISHER' => '6.0.3 (070803), © 2006 Microsoft Corporation. All rights reserved.'
        },
        {
            'PUBLISHER' => '2.3.8, Copyright (c) 2010 Apple Inc. All rights reserved.',
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
            'PUBLISHER' => '2.3.8, Copyright (c) 2010 Apple Inc. All rights reserved.',
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
            'PUBLISHER' => 'EPIJAutoSetupTool2 Copyright (C) SEIKO EPSON CORPORATION 2001-2009. All rights reserved.',
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'EPIJAutoSetupTool2',
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '19/05/2009',
            'VERSION' => '1.0',
            'PUBLISHER' => '1.0, Copyright 2008 Apple Inc.',
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
            'SYSTEM_CATEGORY' => 'System/Library',
        },
        {
            'NAME' => 'Build Applet',
            'SYSTEM_CATEGORY' => 'Developer/Applications',
            'PUBLISHER' => '2.5.4a0, (c) 2004 Python Software Foundation.',
            'VERSION' => '2.5.4',
            'INSTALLDATE' => '05/01/2011'
        },
        {
            'SYSTEM_CATEGORY' => 'Library/Printers',
            'NAME' => 'Canon IJ Printer Utility',
            'PUBLISHER' => 'Canon IJ Printer Utility version 7.17.10, Copyright CANON INC. 2001-2009 All Rights Reserved.',
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
            'PUBLISHER' => '1.0.4',
            'VERSION' => '1.0.4',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Universal]'
        },
        {
            'NAME' => 'Microsoft Word',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
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
            'NAME' => 'Microsoft Graph',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008'
        },
        {
            'COMMENTS' => '[Universal]',
            'INSTALLDATE' => '11/01/2011',
            'VERSION' => '1.4.1',
            'PUBLISHER' => '1.4.1, Copyright 2001-2010 The Adium Team',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Adium'
        },
        {
            'SYSTEM_CATEGORY' => 'Applications/Utilities',
            'NAME' => 'Spaces',
            'PUBLISHER' => '1.1, Copyright 2007-2008 Apple Inc.',
            'VERSION' => '1.1',
            'INSTALLDATE' => '20/02/2011',
            'COMMENTS' => '[Universal]'
        },
        {
            'PUBLISHER' => '2.1.1, Copyright © 2004-2009 Apple Inc. All rights reserved.',
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
            'PUBLISHER' => '2.3.8, Copyright (c) 2010 Apple Inc. All rights reserved.'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Jar Launcher',
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
            'PUBLISHER' => '2.3.6, Copyright (c) 2010 Apple Inc. All rights reserved.'
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
            'PUBLISHER' => 'Version 1.4.6, Copyright © 2000-2009 Apple Inc. All rights reserved.',
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
            'PUBLISHER' => '6.0.11994.637942, Copyright 2005-2011 Parallels Holdings, Ltd. and its affiliates'
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
            'PUBLISHER' => 'ver2.00, © 2005-2008 Brother Industries, Ltd.'
        },
        {
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '17/09/2010',
            'VERSION' => '1.2.0',
            'PUBLISHER' => 'Nimbuzz for Mac OS X, version 1.2.0',
            'SYSTEM_CATEGORY' => 'Applications',
            'NAME' => 'Nimbuzz'
        },
        {
            'VERSION' => '1.5',
            'INSTALLDATE' => '07/07/2010',
            'COMMENTS' => '[Universal]',
            'NAME' => 'MiniTerm',
            'SYSTEM_CATEGORY' => 'usr/libexec',
            'PUBLISHER' => 'Terminal window application for PPP'
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
            'PUBLISHER' => '2.2.5 (101115), © 2010 Microsoft Corporation. All rights reserved.'
        },
        {
            'VERSION' => '14.0.2',
            'INSTALLDATE' => '13/01/2011',
            'COMMENTS' => '[Intel]',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2011',
            'NAME' => 'SyncServicesAgent',
            'PUBLISHER' => '14.0.2 (101115), © 2010 Microsoft Corporation. All rights reserved.'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'Install Helper',
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
            'PUBLISHER' => '1.1.52, Copyright 2009 Hewlett-Packard Company',
            'NAME' => 'HPScanner',
            'SYSTEM_CATEGORY' => 'Library/Image Capture',
            'COMMENTS' => '[Intel]',
            'INSTALLDATE' => '24/07/2009',
            'VERSION' => '1.1.52'
        },
        {
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
            'SYSTEM_CATEGORY' => 'System/Library',
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
            'PUBLISHER' => 'About Xcode',
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
            'PUBLISHER' => '6.0, © Copyright 2002-2009 Apple Inc., all rights reserved.',
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
            'PUBLISHER' => '12.2.8 (101117), © 2007 Microsoft Corporation. All rights reserved.',
            'NAME' => 'Microsoft Database Utility',
            'SYSTEM_CATEGORY' => 'Applications/Microsoft Office 2008',
            'INSTALLDATE' => '27/12/2010',
            'COMMENTS' => '[Universal]',
            'VERSION' => '12.2.8'
        },
        {
            'SYSTEM_CATEGORY' => 'System/Library',
            'NAME' => 'TWAINBridge',
            'PUBLISHER' => '6.0.1, © Copyright 2000-2010 Apple Inc., all rights reserved.',
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
            'PUBLISHER' => 'Syncrospector 3.0, © 2004 Apple Computer, Inc., All rights reserved.'
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
            'PUBLISHER' => 'HP Fax 4.1, Copyright (c) 2009-2010 Hewlett-Packard Development Company, L.P.'
        }
    ]
);


plan tests => 2 * scalar (keys %tests)
    + 7;

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
