#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;

use GLPI::Agent::Tools::AIX;

my %lsvpd_tests = (
    'aix-5.3a' => [
        {
            SE => '65DEDAB',
            FG => 'XXSV',
            DS => 'System VPD',
            RT => 'VSYS',
            TM => '9111-520',
            BR => 'O0',
            VK => 'ipzSeries',
            YL => 'U9111.520.65DEDAB',
            SU => '0004AC0BA763'
        },
        {
            SE => 'DPM2CW2',
            RK => '0000000000000000',
            FC => '787A-001',
            FG => 'XXEV',
            DS => 'CEC',
            RT => 'VCEN',
            TM => '787A-001',
            BR => 'O0',
            VK => 'ipzSeries',
            YL => 'U787A.001.DPM2CW2',
            CI => '9111-520 65DEDAB'
        },
        {
            CC => '522A',
            HE => '0001',
            PN => '80P6949',
            FG => 'XXBP',
            DS => 'SYSTEM BACKPLANE',
            HW => '0001',
            FN => '80P6949',
            SN => 'YL142533608A',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40130002',
            YL => 'U787A.001.DPM2CW2-P1',
            PR => '2300000000000000'
        },
        {
            CC => '28D7',
            HE => '0001',
            PN => '80P5315',
            FG => 'XXSP',
            DS => 'FSP',
            HW => '0001',
            FN => '80P5315',
            SN => 'YL11253320B4',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40B30001',
            YL => 'U787A.001.DPM2CW2-P1-C7'
        },
        {
            CC => '30D2',
            PN => '00P5767',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            SZ => '512',
            FN => '00P5767',
            SN => 'YH10MS5CH923',
            RT => 'VINI',
            YL => 'U787A.001.DPM2CW2-P1-C9',
            VK => 'RS6K'
        },
        {
            CC => '30D2',
            PN => '00P5767',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            SZ => '512',
            FN => '00P5767',
            SN => 'YH10MS5CH8ED',
            RT => 'VINI',
            YL => 'U787A.001.DPM2CW2-P1-C11',
            VK => 'RS6K'
        },
        {
            CC => '30D2',
            PN => '00P5767',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            SZ => '512',
            FN => '00P5767',
            SN => 'YH10MS5CH8F0',
            RT => 'VINI',
            YL => 'U787A.001.DPM2CW2-P1-C14',
            VK => 'RS6K'
        },
        {
            CC => '30D2',
            PN => '00P5767',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            SZ => '512',
            FN => '00P5767',
            SN => 'YH10MS5CH92C',
            RT => 'VINI',
            YL => 'U787A.001.DPM2CW2-P1-C16',
            VK => 'RS6K'
        },
        {
            CC => '528F',
            HE => '0010',
            PN => '80P3249',
            FG => 'XXAV',
            DS => 'ANCHOR',
            HW => '0001',
            FN => '80P3249',
            SN => 'YL1154018250',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40B40000',
            YL => 'U787A.001.DPM2CW2-P1-C20',
            PR => '8100180000000000'
        },
        {
            CC => '28E5',
            HE => '0001',
            PN => '97P4935',
            FG => 'XXOP',
            DS => 'CEC OP PANEL',
            HW => '0001',
            FN => '97P4935',
            SN => 'YL13253220E5',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40B50000',
            YL => 'U787A.001.DPM2CW2-D1',
            PR => 'E000000000000000'
        },
        {
            CC => '51B6',
            PN => '97P2330',
            FG => 'XXPS',
            DS => 'A IBM AC PS',
            FN => '97P2330',
            SN => 'YL1325AX0041',
            RT => 'VINI',
            YL => 'U787A.001.DPM2CW2-E1',
            VK => 'RS6K'
        },
        {
            CC => '51B6',
            PN => '97P2330',
            FG => 'XXPS',
            DS => 'A IBM AC PS',
            FN => '97P2330',
            SN => 'YL13258Z0274',
            RT => 'VINI',
            YL => 'U787A.001.DPM2CW2-E2',
            VK => 'RS6K'
        },
        {
            CC => '6B18',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U787A.001.DPM2CW2-A1',
            FG => 'XXAM',
            DS => 'IBM Air Mover',
            FN => '97P3153'
        },
        {
            CC => '6B18',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U787A.001.DPM2CW2-A2',
            FG => 'XXAM',
            DS => 'IBM Air Mover',
            FN => '97P3153'
        },
        {
            CC => '6B18',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U787A.001.DPM2CW2-A3',
            FG => 'XXAM',
            DS => 'IBM Air Mover',
            FN => '97P3153'
        },
        {
            CC => '6B12',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U787A.001.DPM2CW2-P1-C19',
            FG => 'XXRG',
            DS => 'Voltage Reg',
            FN => '97P2642'
        },
        {
            CC => '6B10',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U787A.001.DPM2CW2-P1-C17',
            FG => 'XXRG',
            DS => 'Voltage Reg',
            FN => '44P3193'
        },
        {
            CC => '6B11',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U787A.001.DPM2CW2-P1-C18',
            FG => 'XXRG',
            DS => 'Voltage Reg',
            FN => '24P6892'
        },
        {
            CC => '28D2',
            FS => '787A-001 DPM2CW2',
            PN => '03N5997',
            EC => 'H13944',
            FG => 'XXDB',
            DS => 'VSBPD4E1  U4SCSI',
            FN => '03N6000',
            SN => 'YL10253423B6',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U787A.001.DPM2CW2-P3'
        },
        {
            CC => '28D1',
            PN => '03N5897',
            EC => 'H13928',
            FG => 'XXMB',
            DS => 'MEDIA BACKPLANE',
            FN => '03N6005',
            SN => 'YL1025352166',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U787A.001.DPM2CW2-P4'
        },
        {
            YL => 'U9111.520.65DEDAB-Y1',
            MI => 'SF240_202 SF240_202 SF240_202',
            DS => 'System Firmware',
            CL => 'SPCN2 084720040818A0E00D20'
        },
        {
            CD => '33880021',
            AX => 'pci6',
            YL => 'U787A.001.DPM2CW2-P1-C2',
            DS => 'PCI Bus',
            PL => '05-08'
        },
        {
            CD => '10140233',
            PN => '80P4527',
            YL => 'U787A.001.DPM2CW2-P1-C2-T1',
            EC => 'H13284',
            DS => 'GXT135P Graphics Adapter',
            MN => 'MATROX',
            FN => '00P5758'
        },
        {
            TM => 'DROM0020541',
            AX => 'cd0',
            YL => 'U787A.001.DPM2CW2-P4-D2',
            RL => 'P633',
            DS => 'IDE DVD-ROM Drive',
            MF => 'IBM',
            PL => '08-08-00'
        },
        {
            PN => '26K5533',
            EC => 'H13979',
            DS => '16 Bit LVD SCSI Disk Drive',
            MF => 'IBM',
            FN => '03N6325',
            PL => '09-08-00-3,0',
            SN => '00060321',
            AX => 'hdisk0',
            TM => 'ST373207LC',
            YL => 'U787A.001.DPM2CW2-P1-T10-L3-L0',
            RL => '43373043'
        },
        {
            PN => '18P8777',
            EC => 'H80564',
            DS => 'LVD SCSI 4mm Tape Drive',
            MF => 'IBM',
            FN => '18P8779',
            LI => 'A170029F',
            PL => '09-08-00-6,0',
            SN => '205CW158',
            AX => 'rmt0',
            TM => 'DDS Gen5',
            YL => 'U787A.001.DPM2CW2-P1-T10-L6-L0'
        },
        {
            FS => '787A-001 DPM2CW2',
            DS => 'SCSI Enclosure Services Device',
            MF => 'IBM',
            FN => '03N6000',
            PL => '09-08-00-15,0',
            SN => '253423B6',
            AX => 'ses0',
            TM => 'VSBPD4E1  U4SCSI',
            FL => 'P3',
            YL => 'U787A.001.DPM2CW2-P1-T10-L15-L0',
            RL => '6000'
        },
        {
            PN => '26K5533',
            EC => 'H13979',
            DS => '16 Bit LVD SCSI Disk Drive',
            MF => 'IBM',
            FN => '03N6325',
            PL => '09-08-00-4,0',
            SN => '0005F82E',
            AX => 'hdisk1',
            TM => 'ST373207LC',
            YL => 'U787A.001.DPM2CW2-P1-T10-L4-L0',
            RL => '43373043'
        },
        {
            PN => '093H6540',
            EC => '0E76812',
            DS => 'IBM 8-Port EIA-232/RS-422A (PCI) Adapter',
            MF => 'AUS1391615',
            FN => '093H6541',
            PL => '0A-08',
            AX => 'sa1',
            CD => '114f0011',
            YL => 'U787A.001.DPM2CW2-P1-C3-T1'
        },
        {
            AX => 'kbd0',
            YL => 'U787A.001.DPM2CW2-P1-T8-L1-L1',
            DS => 'USB keyboard',
            PL => '1.1.1'
        },
        {
            AX => 'mouse0',
            YL => 'U787A.001.DPM2CW2-P1-T8-L1-L3',
            DS => 'USB mouse',
            PL => '1.1.3'
        },
        {
            AX => 'tty0',
            YL => 'U787A.001.DPM2CW2-P1-C3-T1-L0',
            DS => 'Asynchronous Terminal',
            PL => '0A-08-01-00'
        },
        {
            AX => 'tty1',
            YL => 'U787A.001.DPM2CW2-P1-C3-T1-L1',
            DS => 'Asynchronous Terminal',
            PL => '0A-08-01-01'
        },
        {
            AX => 'tty2',
            YL => 'U787A.001.DPM2CW2-P1-C3-T1-L5',
            DS => 'Asynchronous Terminal',
            PL => '0A-08-01-05'
        },
        {
            AX => 'tty3',
            YL => 'U787A.001.DPM2CW2-P1-C3-T1-L6',
            DS => 'Asynchronous Terminal',
            PL => '0A-08-01-06'
        },
        {
            AX => 'tty4',
            YL => 'U787A.001.DPM2CW2-P1-C3-T1-L2',
            DS => 'Asynchronous Terminal',
            PL => '0A-08-01-02'
        },
        {
            AX => 'tty5',
            YL => 'U787A.001.DPM2CW2-P1-C3-T1-L4',
            DS => 'Asynchronous Terminal',
            PL => '0A-08-01-04'
        }
    ],
    'aix-5.3b' => [
        {
            ET => '11',
            SE => '99DXY4Y',
            FG => 'XXSV',
            DS => 'System VPD',
            MN => 'IBM',
            MU => 'B6D63EA81E0011B2921300145E9C9300',
            RT => 'VSYS',
            TM => '8844-31X',
            VK => 'RS6K',
            YL => 'U8844.31X.99DXY4Y'
        },
        {
            ET => '11',
            SE => '99DXY4Y',
            FC => '788D-001',
            FG => 'XXEV',
            DS => 'CEC',
            MN => 'IBM',
            MU => 'B6D63EA81E0011B2921300145E9C9300',
            RT => 'VCEN',
            TM => '788D-001',
            VK => 'RS6K',
            YL => 'U788D.001.99DXY4Y',
            CI => '8844-31X 99DXY4Y'
        },
        {
            PN => '43X1788',
            FG => 'XXBP',
            DS => 'GPUL Blade Planar',
            FN => '43X1814',
            SN => 'YK1030749135',
            RT => 'VINI',
            YL => 'U788D.001.99DXY4Y-P1',
            VK => 'RS6K'
        },
        {
            FG => 'XXMS',
            DS => 'Memory DIMM',
            SZ => '1024',
            FN => 'HYMP512R72BP4-E3',
            SN => '00005055',
            RT => 'VINI',
            YL => 'U788D.001.99DXY4Y-P1-C1',
            VK => 'RS6K'
        },
        {
            FG => 'XXMS',
            DS => 'Memory DIMM',
            SZ => '1024',
            FN => 'HYMP512R72BP4-E3',
            SN => '04008030',
            RT => 'VINI',
            YL => 'U788D.001.99DXY4Y-P1-C2',
            VK => 'RS6K'
        },
        {
            FG => 'XXMS',
            DS => 'Memory DIMM',
            SZ => '1024',
            FN => 'HYMP512R72BP4-E3',
            SN => '00007033',
            RT => 'VINI',
            YL => 'U788D.001.99DXY4Y-P1-C3',
            VK => 'RS6K'
        },
        {
            FG => 'XXMS',
            DS => 'Memory DIMM',
            SZ => '1024',
            FN => 'HYMP512R72BP4-E3',
            SN => '00005031',
            RT => 'VINI',
            YL => 'U788D.001.99DXY4Y-P1-C4',
            VK => 'RS6K'
        },
        {
            YL => 'U8844.31X.99DXY4Y-Y1',
            MI => 'MB245_300_008 MB245_300_008 MB245_300_008',
            DS => 'System Firmware',
            CL => 'PFW 19482006101681CF0681'
        },
        {
            PN => '26K5267',
            EC => 'H17923E',
            DS => 'SCSI Disk Drive',
            MF => 'IBM-ESXS',
            FN => '26K5779',
            PL => '01-08-00-1,0',
            SN => '3LB1FV46',
            AX => 'hdisk0',
            TM => 'ST973401SS',
            BR => 'XS',
            YL => 'U788D.001.99DXY4Y-P1-T10-L1-L0',
            RL => '42353144'
        },
        {
            PN => '26K5267',
            EC => 'H17923E',
            DS => 'SCSI Disk Drive',
            MF => 'IBM-ESXS',
            FN => '26K5779',
            PL => '01-08-01-1,0',
            SN => '3LB1FWWE',
            AX => 'hdisk1',
            TM => 'ST973401SS',
            BR => 'XS',
            YL => 'U788D.001.99DXY4Y-P1-T11-L1-L0',
            RL => '42353144'
        }
    ],
    'aix-5.3c' => [
        {
            ID => 'FF',
            SE => '106BDCA',
            TN => 'FFFFFFFF',
            FG => 'XXSV',
            DS => 'System VPD',
            WN => 'C0507601DBFE',
            MN => 'FFFFFFF',
            SG => 'FFFFFFF',
            RT => 'VSYS',
            TM => '7778-23X',
            BR => 'B0',
            VK => 'ipzSeries',
            YL => 'U7778.23X.106BDCA',
            SU => '0004AC1380A1',
            NN => 'FFFFFFFFFFFFFFFF'
        },
        {
            SE => 'WIH5D66',
            RK => '0000000000000000',
            FC => '78A5-001',
            FG => 'XXEV',
            DS => 'CEC',
            RT => 'VCEN',
            TM => '78A5-001',
            BR => 'B0',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66',
            CI => '7778-23X 106BDCA'
        },
        {
            VZ => '01',
            CC => '53AE',
            HE => '0001',
            PN => '46K7951',
            FG => 'XXBP',
            DS => 'SYS BP & 4W PROC',
            CE => '1',
            HW => '0001',
            FN => '10N9856',
            SN => 'YL13W9249053',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40F30018',
            YL => 'U78A5.001.WIH5D66-P1',
            PR => '3300200100020001'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD001110C29',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P1-C1',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD005346272',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P1-C2',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD000110C0C',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P1-C3',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD004930776',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P1-C4',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD00793074C',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P1-C5',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD003810961',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P1-C6',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD006346270',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P1-C7',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD00281096F',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P1-C8',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '52C1',
            HE => '0010',
            PN => '07P6898',
            FG => 'XXAV',
            DS => 'ANCHOR / RISER',
            CE => '1',
            HW => '0001',
            FN => '07P6897',
            SN => 'YL100899N014',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40B40001',
            YL => 'U78A5.001.WIH5D66-P1-C9',
            PR => '8100008000000000'
        },
        {
            PN => '41Y8581',
            FG => 'XXHD',
            DS => 'Fibre Channel / Ethernet Combo Expansion Card',
            HW => '03',
            FN => '39Y9304',
            SN => 'YK10NY98M6WD',
            RT => 'VINI',
            YL => 'U78A5.001.WIH5D66-P1-C11',
            VK => 'xSeries'
        },
        {
            PN => '46C5192',
            FG => 'XXDT',
            DS => 'SAS Expansion Card',
            HW => '04',
            FN => '46C4069',
            SN => 'YK119093J07F',
            RT => 'VINI',
            YL => 'U78A5.001.WIH5D66-P1-C12',
            VK => 'xSeries'
        },
        {
            VZ => '01',
            CC => '53AF',
            HE => '0001',
            PN => '46K7945',
            FG => 'XXBP',
            DS => 'SYS BP & 4W PROC',
            CE => '1',
            HW => '0001',
            FN => '07P6804',
            SN => 'YL11W923202B',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40F30018',
            YL => 'U78A5.001.WIH5D66-P2',
            PR => '3300200100020001'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD009710956',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P2-C1',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD00D346271',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P2-C2',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD00851096F',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P2-C3',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD00C930661',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P2-C4',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD00F930748',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P2-C5',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD00B410C26',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P2-C6',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD00E34627B',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P2-C7',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '31C3',
            PN => '43X5036',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '4096',
            FN => '43X5036',
            SN => 'YLD00A610973',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH5D66-P2-C8',
            PR => '4400000000000000'
        },
        {
            YL => 'U7778.23X.106BDCA-Y1',
            MI => 'EA350_074 EA350_053 EA350_074',
            DS => 'System Firmware',
            CL => 'FipS_BU 08252010070681E00200'
        },
        {
            AX => 'lhea0',
            YL => 'U78A5.001.WIH5D66-P2',
            DS => 'Logical Host Ethernet Adapter (l-hea)'
        }
    ],
    'aix-6.1a' => [
        {
            SE => '10086CP',
            FG => 'XXSV',
            DS => 'System VPD',
            WN => 'C05076027866',
            RT => 'VSYS',
            TM => '8233-E8B',
            BR => 'S0',
            VK => 'ipzSeries',
            YL => 'U8233.E8B.10086CP',
            SU => '0004AC143433'
        },
        {
            SE => 'DNWHPLG',
            RK => '0000000000000000',
            FC => '78A0-001',
            FG => 'XXEV',
            DS => 'CEC',
            RT => 'VCEN',
            TM => '78A0-001',
            BR => 'S0',
            VK => 'ipzSeries',
            YL => 'U78A0.001.DNWHPLG',
            CI => '8233-E8B 10086CP'
        },
        {
            VZ => '01',
            CC => '2A5C',
            HE => '0001',
            PN => '74Y1827',
            FG => 'XXBP',
            DS => 'SYSTEM BACKPLANE',
            CE => '1',
            HW => '0002',
            FN => '74Y1825',
            SN => 'YL10HA02307L',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40F30024',
            YL => 'U78A0.001.DNWHPLG-P1',
            PR => '2A00000000000000'
        },
        {
            VZ => '04',
            CC => '1819',
            HE => '0001',
            PN => '46K7972',
            FG => 'XXET',
            DS => 'QUAD ETHERNET',
            CE => '1',
            HW => '0001',
            FN => '46K7971',
            SN => 'YL10W0005085',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40910006',
            YL => 'U78A0.001.DNWHPLG-P1-C6'
        },
        {
            VZ => '01',
            CC => '1817',
            HE => '0001',
            PN => '46K7922',
            FG => 'XXBE',
            DS => 'INFINIBAND 12X',
            CE => '1',
            HW => '0001',
            FN => '46K6564',
            SN => 'YL10W935004R',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40333012',
            YL => 'U78A0.001.DNWHPLG-P1-C8',
            PR => '6500020000000000'
        },
        {
            VZ => '01',
            CC => '52B6',
            HE => '0010',
            PN => '46K6943',
            FG => 'XXAV',
            DS => 'ANCHOR',
            CE => '1',
            HW => '0001',
            FN => '46K6943',
            SN => 'YL100803B00C',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40B40000',
            YL => 'U78A0.001.DNWHPLG-P1-C9',
            PR => '8100300000000000'
        },
        {
            VZ => '01',
            CC => '2A0F',
            HE => '0001',
            PN => '74Y1754',
            FG => 'XXTP',
            DS => 'THERMAL PWR MGMT',
            CE => '1',
            HW => '0001',
            FN => '46Y3513',
            SN => 'YL10W00190B5',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40B60003',
            YL => 'U78A0.001.DNWHPLG-P1-C12'
        },
        {
            VZ => '01',
            CC => '530E',
            HE => '0001',
            PN => '74Y2132',
            FG => 'XXPF',
            DS => '6 WAY PROC CUOD',
            CE => '1',
            HW => '0001',
            FN => '74Y1845',
            SN => 'YL1110035009',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40120006',
            YL => 'U78A0.001.DNWHPLG-P1-C13',
            PR => '3400600111018000'
        },
        {
            VZ => '03',
            CC => '31C5',
            HE => '0001',
            HW => '0001',
            SZ => '4096',
            CT => '10210004',
            PR => '4800000000010000',
            PN => '77P8784',
            DS => 'Memory DIMM',
            FG => 'XXMS',
            CE => '1',
            FN => '77P8784',
            SN => 'YLD00030486D',
            RT => 'VINI',
            YL => 'U78A0.001.DNWHPLG-P1-C13-C2',
            VK => 'ipzSeries'
        },
        {
            VZ => '03',
            CC => '31C5',
            HE => '0001',
            HW => '0001',
            SZ => '4096',
            CT => '10210004',
            PR => '4800000000010000',
            PN => '77P8784',
            DS => 'Memory DIMM',
            FG => 'XXMS',
            CE => '1',
            FN => '77P8784',
            SN => 'YLD003304853',
            RT => 'VINI',
            YL => 'U78A0.001.DNWHPLG-P1-C13-C3',
            VK => 'ipzSeries'
        },
        {
            VZ => '03',
            CC => '31C5',
            HE => '0001',
            HW => '0001',
            SZ => '4096',
            CT => '10210004',
            PR => '4800000000010000',
            PN => '77P8784',
            DS => 'Memory DIMM',
            FG => 'XXMS',
            CE => '1',
            FN => '77P8784',
            SN => 'YLD0013047DE',
            RT => 'VINI',
            YL => 'U78A0.001.DNWHPLG-P1-C13-C4',
            VK => 'ipzSeries'
        },
        {
            VZ => '03',
            CC => '31C5',
            HE => '0001',
            HW => '0001',
            SZ => '4096',
            CT => '10210004',
            PR => '4800000000010000',
            PN => '77P8784',
            DS => 'Memory DIMM',
            FG => 'XXMS',
            CE => '1',
            FN => '77P8784',
            SN => 'YLD002304855',
            RT => 'VINI',
            YL => 'U78A0.001.DNWHPLG-P1-C13-C5',
            VK => 'ipzSeries'
        },
        {
            VZ => '03',
            CC => '31C5',
            HE => '0001',
            HW => '0001',
            SZ => '4096',
            CT => '10210004',
            PR => '4800000000010000',
            PN => '77P8784',
            DS => 'Memory DIMM',
            FG => 'XXMS',
            CE => '1',
            FN => '77P8784',
            SN => 'YLD006304856',
            RT => 'VINI',
            YL => 'U78A0.001.DNWHPLG-P1-C13-C6',
            VK => 'ipzSeries'
        },
        {
            VZ => '03',
            CC => '31C5',
            HE => '0001',
            HW => '0001',
            SZ => '4096',
            CT => '10210004',
            PR => '4800000000010000',
            PN => '77P8784',
            DS => 'Memory DIMM',
            FG => 'XXMS',
            CE => '1',
            FN => '77P8784',
            SN => 'YLD00530483B',
            RT => 'VINI',
            YL => 'U78A0.001.DNWHPLG-P1-C13-C7',
            VK => 'ipzSeries'
        },
        {
            VZ => '03',
            CC => '31C5',
            HE => '0001',
            HW => '0001',
            SZ => '4096',
            CT => '10210004',
            PR => '4800000000010000',
            PN => '77P8784',
            DS => 'Memory DIMM',
            FG => 'XXMS',
            CE => '1',
            FN => '77P8784',
            SN => 'YLD007304859',
            RT => 'VINI',
            YL => 'U78A0.001.DNWHPLG-P1-C13-C8',
            VK => 'ipzSeries'
        },
        {
            VZ => '03',
            CC => '31C5',
            HE => '0001',
            HW => '0001',
            SZ => '4096',
            CT => '10210004',
            PR => '4800000000010000',
            PN => '77P8784',
            DS => 'Memory DIMM',
            FG => 'XXMS',
            CE => '1',
            FN => '77P8784',
            SN => 'YLD00430481E',
            RT => 'VINI',
            YL => 'U78A0.001.DNWHPLG-P1-C13-C9',
            VK => 'ipzSeries'
        },
        {
            VZ => '01',
            CC => '2BCD',
            HE => '0001',
            PN => '74Y5487',
            FG => 'XXOP',
            DS => 'CEC OP PANEL',
            CE => '1',
            HW => '0002',
            FN => '74Y5481',
            SN => 'YL10W00610E4',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40B50000',
            YL => 'U78A0.001.DNWHPLG-D1'
        },
        {
            CC => '51CA',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U78A0.001.DNWHPLG-P1-C13-C1',
            FG => 'XXRG',
            DS => 'Voltage Reg',
            FN => '46K6300'
        },
        {
            CC => '51C9',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U78A0.001.DNWHPLG-P1-C13-C10',
            FG => 'XXRG',
            DS => 'Voltage Reg',
            FN => '46K6302'
        },
        {
            CC => '51C8',
            PN => '46K5673',
            FG => 'XXPS',
            DS => 'A IBM AC PS',
            FN => '46K5673',
            SN => 'YL10HA01N01A',
            RT => 'VINI',
            YL => 'U78A0.001.DNWHPLG-E1',
            VK => 'RS6K'
        },
        {
            CC => '51C8',
            PN => '46K5673',
            FG => 'XXPS',
            DS => 'A IBM AC PS',
            FN => '46K5673',
            SN => 'YL10HA01N00M',
            RT => 'VINI',
            YL => 'U78A0.001.DNWHPLG-E2',
            VK => 'RS6K'
        },
        {
            CC => '6B1B',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U78A0.001.DNWHPLG-A1',
            FG => 'XXAM',
            DS => 'IBM Air Mover',
            FN => '44V3454'
        },
        {
            CC => '6B1B',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U78A0.001.DNWHPLG-A2',
            FG => 'XXAM',
            DS => 'IBM Air Mover',
            FN => '44V3454'
        },
        {
            CC => '6B1B',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U78A0.001.DNWHPLG-A3',
            FG => 'XXAM',
            DS => 'IBM Air Mover',
            FN => '44V3454'
        },
        {
            CC => '6B1B',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U78A0.001.DNWHPLG-A4',
            FG => 'XXAM',
            DS => 'IBM Air Mover',
            FN => '44V3454'
        },
        {
            VZ => '01',
            CC => '2A16',
            PN => '46K7882',
            FG => 'XXDB',
            DS => 'PSBPD8E4  3GSAS',
            CE => '1',
            FN => '46K7881',
            SN => 'YL10W002805W',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U78A0.001.DNWHPLG-P2'
        },
        {
            SE => '00H0441',
            FG => 'XXEV',
            DS => 'Tres-19',
            RT => 'VCEN',
            TM => '5877-001',
            BR => 'S0',
            VK => 'RS6K',
            YL => 'U5877.001.00H0441',
            CI => '8233-E8B 10086CP'
        },
        {
            CC => '2C43',
            HE => '0032',
            PN => '44V8544',
            FG => 'XXPS',
            DS => 'DCA-T19',
            HW => '0001',
            FN => '44V8544',
            SN => 'YH1019M17506',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '10E4000A',
            YL => 'U5877.001.00H0441-E1'
        },
        {
            CC => '2C43',
            HE => '0032',
            PN => '44V8544',
            FG => 'XXPS',
            DS => 'DCA-T19',
            HW => '0001',
            FN => '44V8544',
            SN => 'YH1019M18061',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '10E4000A',
            YL => 'U5877.001.00H0441-E2'
        },
        {
            CC => '6B0A',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U5877.001.00H0441-E1-A1',
            FG => 'XXAM',
            DS => 'IBM Air Mover',
            FN => '42R8429'
        },
        {
            CC => '6B0A',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U5877.001.00H0441-E1-A2',
            FG => 'XXAM',
            DS => 'IBM Air Mover',
            FN => '42R8429'
        },
        {
            CC => '6B0A',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U5877.001.00H0441-E2-A1',
            FG => 'XXAM',
            DS => 'IBM Air Mover',
            FN => '42R8429'
        },
        {
            CC => '6B0A',
            RT => 'VINI',
            VK => 'RS6K',
            YL => 'U5877.001.00H0441-E2-A2',
            FG => 'XXAM',
            DS => 'IBM Air Mover',
            FN => '42R8429'
        },
        {
            VZ => '02',
            CC => '50A6',
            HE => '0001',
            PN => '45D5367',
            FG => 'XXPO',
            DS => 'SPCN',
            CE => '1',
            HW => '0001',
            FN => '45D5368',
            SN => 'YH10UD01811S',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '10B30004',
            YL => 'U5877.001.00H0441-P2'
        },
        {
            VZ => '04',
            CC => '50AA',
            HE => '0001',
            PN => '45D5430',
            FG => 'XXIB',
            DS => 'MIDPLANE',
            CE => '1',
            HW => '0001',
            FN => '45D5431',
            SN => 'YH10UD01712D',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '10F30005',
            YL => 'U5877.001.00H0441-P5'
        },
        {
            VZ => '03',
            CC => '50A2',
            HE => '0001',
            HW => '0001',
            FL => 'P1',
            CT => '10F30008',
            PR => '2300000000000000',
            PN => '45D5320',
            DS => 'I/O BACKPLANE',
            FG => 'XXIB',
            CE => '1',
            FN => '45D5321',
            SN => 'YH10UD01712F',
            RT => 'VINI',
            YL => 'U5877.001.00H0441-P1',
            VK => 'ipzSeries',
            RV => '01'
        },
        {
            YL => 'U8233.E8B.10086CP-Y1',
            MI => 'AL710_099 AL710_065 AL710_099',
            DS => 'System Firmware',
            CL => 'SPCN2 183420070213A0E00D20'
        },
        {
            AX => 'lhea0',
            YL => 'U78A0.001.DNWHPLG-P1',
            DS => 'Logical Host Ethernet Adapter (l-hea)'
        },
        {
            CC => '5774',
            PN => '10N7255',
            EC => 'D76626',
            DS => '4Gb FC PCI Express Adapter (df1000fe)',
            MF => '001C',
            ZC => '00000000',
            FN => '10N7255',
            PL => '01-00',
            SN => '1C95208B5B',
            ZM => '3',
            AX => 'fcs0',
            CD => '10dffe01',
            YL => 'U5877.001.00H0441-P1-C5-T1',
            RL => '02E8277F'
        },
        {
            CC => '5774',
            PN => '10N7255',
            EC => 'D76626',
            DS => '4Gb FC PCI Express Adapter (df1000fe)',
            MF => '001C',
            ZC => '00000000',
            FN => '10N7255',
            PL => '01-01',
            SN => '1C95208B5B',
            ZM => '3',
            AX => 'fcs1',
            CD => '10dffe01',
            YL => 'U5877.001.00H0441-P1-C5-T2',
            RL => '02E8277F'
        },
        {
            CC => '5774',
            PN => '10N7255',
            EC => 'D76626',
            DS => '4Gb FC PCI Express Adapter (df1000fe)',
            MF => '001C',
            ZC => '00000000',
            FN => '10N7255',
            PL => '02-00',
            SN => '1C95208D7A',
            ZM => '3',
            AX => 'fcs2',
            CD => '10dffe01',
            YL => 'U5877.001.00H0441-P1-C6-T1',
            RL => '02E8277F'
        },
        {
            CC => '5774',
            PN => '10N7255',
            EC => 'D76626',
            DS => '4Gb FC PCI Express Adapter (df1000fe)',
            MF => '001C',
            ZC => '00000000',
            FN => '10N7255',
            PL => '02-01',
            SN => '1C95208D7A',
            ZM => '3',
            AX => 'fcs3',
            CD => '10dffe01',
            YL => 'U5877.001.00H0441-P1-C6-T2',
            RL => '02E8277F'
        },
        {
            CD => '10dffe01',
            AX => 'fscsi0',
            YL => 'U5877.001.00H0441-P1-C5-T1',
            DS => 'FC SCSI I/O Controller Protocol Device',
            PL => '01-00-01'
        },
        {
            CD => '10dffe01',
            AX => 'fscsi1',
            YL => 'U5877.001.00H0441-P1-C5-T2',
            DS => 'FC SCSI I/O Controller Protocol Device',
            PL => '01-01-01'
        },
        {
            CD => '10dffe01',
            AX => 'fscsi2',
            YL => 'U5877.001.00H0441-P1-C6-T1',
            DS => 'FC SCSI I/O Controller Protocol Device',
            PL => '02-00-01'
        },
        {
            CD => '10dffe01',
            AX => 'fscsi3',
            YL => 'U5877.001.00H0441-P1-C6-T2',
            DS => 'FC SCSI I/O Controller Protocol Device',
            PL => '02-01-01'
        },
        {
            SN => '83040523',
            TM => 'DF600F',
            AX => 'hdisk3',
            YL => 'U5877.001.00H0441-P1-C6-T2-W50060E80104AA033-L2000000000000',
            RL => '30303030',
            DS => 'Other FC SCSI Disk Drive',
            MF => 'HITACHI',
            PL => '02-01-01'
        },
        {
            SN => '83040523',
            TM => 'DF600F',
            AX => 'hdisk4',
            YL => 'U5877.001.00H0441-P1-C6-T2-W50060E80104AA033-L3000000000000',
            RL => '30303030',
            DS => 'Other FC SCSI Disk Drive',
            MF => 'HITACHI',
            PL => '02-01-01'
        },
        {
            SN => '83040523',
            TM => 'DF600F',
            AX => 'hdisk5',
            YL => 'U5877.001.00H0441-P1-C6-T2-W50060E80104AA033-L4000000000000',
            RL => '30303030',
            DS => 'Other FC SCSI Disk Drive',
            MF => 'HITACHI',
            PL => '02-01-01'
        },
        {
            SN => '83040523',
            TM => 'DF600F',
            AX => 'hdisk6',
            YL => 'U5877.001.00H0441-P1-C6-T2-W50060E80104AA033-L5000000000000',
            RL => '30303030',
            DS => 'Other FC SCSI Disk Drive',
            MF => 'HITACHI',
            PL => '02-01-01'
        },
        {
            SN => '83040523',
            TM => 'DF600F',
            AX => 'hdisk7',
            YL => 'U5877.001.00H0441-P1-C6-T2-W50060E80104AA033-L6000000000000',
            RL => '30303030',
            DS => 'Other FC SCSI Disk Drive',
            MF => 'HITACHI',
            PL => '02-01-01'
        },
        {
            SN => '83040523',
            TM => 'DF600F',
            AX => 'hdisk8',
            YL => 'U5877.001.00H0441-P1-C6-T2-W50060E80104AA033-L7000000000000',
            RL => '30303030',
            DS => 'Other FC SCSI Disk Drive',
            MF => 'HITACHI',
            PL => '02-01-01'
        },
        {
            SN => '83040523',
            TM => 'DF600F',
            AX => 'hdisk9',
            YL => 'U5877.001.00H0441-P1-C6-T2-W50060E80104AA033-L8000000000000',
            RL => '30303030',
            DS => 'Other FC SCSI Disk Drive',
            MF => 'HITACHI',
            PL => '02-01-01'
        },
        {
            SN => '83040523',
            TM => 'DF600F',
            AX => 'hdisk10',
            YL => 'U5877.001.00H0441-P1-C6-T2-W50060E80104AA033-L9000000000000',
            RL => '30303030',
            DS => 'Other FC SCSI Disk Drive',
            MF => 'HITACHI',
            PL => '02-01-01'
        },
        {
            SN => '83040523',
            TM => 'DF600F',
            AX => 'hdisk11',
            YL => 'U5877.001.00H0441-P1-C6-T2-W50060E80104AA033-LA000000000000',
            RL => '30303030',
            DS => 'Other FC SCSI Disk Drive',
            MF => 'HITACHI',
            PL => '02-01-01'
        },
        {
            SN => '83040523',
            TM => 'DF600F',
            AX => 'hdisk12',
            YL => 'U5877.001.00H0441-P1-C6-T2-W50060E80104AA033-LB000000000000',
            RL => '30303030',
            DS => 'Other FC SCSI Disk Drive',
            MF => 'HITACHI',
            PL => '02-01-01'
        },
        {
            SN => '83040523',
            TM => 'DF600F',
            AX => 'hdisk13',
            YL => 'U5877.001.00H0441-P1-C6-T2-W50060E80104AA033-LC000000000000',
            RL => '30303030',
            DS => 'Other FC SCSI Disk Drive',
            MF => 'HITACHI',
            PL => '02-01-01'
        },
        {
            SN => '83040523',
            TM => 'DF600F',
            AX => 'hdisk14',
            YL => 'U5877.001.00H0441-P1-C6-T2-W50060E80104AA033-LD000000000000',
            RL => '30303030',
            DS => 'Other FC SCSI Disk Drive',
            MF => 'HITACHI',
            PL => '02-01-01'
        },
        {
            SN => '83040523',
            TM => 'DF600F',
            AX => 'hdisk15',
            YL => 'U5877.001.00H0441-P1-C6-T2-W50060E80104AA033-LE000000000000',
            RL => '30303030',
            DS => 'Other FC SCSI Disk Drive',
            MF => 'HITACHI',
            PL => '02-01-01'
        },
        {
            SN => '83040523',
            TM => 'DF600F',
            AX => 'hdisk16',
            YL => 'U5877.001.00H0441-P1-C6-T2-W50060E80104AA033-LF000000000000',
            RL => '30303030',
            DS => 'Other FC SCSI Disk Drive',
            MF => 'HITACHI',
            PL => '02-01-01'
        },
        {
            SN => '83040523',
            TM => 'DF600F',
            AX => 'hdisk17',
            YL => 'U5877.001.00H0441-P1-C6-T2-W50060E80104AA033-L10000000000000',
            RL => '30303030',
            DS => 'Other FC SCSI Disk Drive',
            MF => 'HITACHI',
            PL => '02-01-01'
        },
        {
            AX => 'fc1',
            DS => 'Fibre Channel Network Interface',
            PL => '01-01-02'
        },
        {
            SN => '1310211169',
            TM => 'ULT3580-TD4',
            AX => 'rmt0',
            YL => 'U5877.001.00H0441-P1-C5-T1-W2002000E1113516B-L0',
            FW => 'A239',
            DS => 'IBM 3580 Ultrium Tape Drive (FCP)',
            MF => 'IBM',
            PL => '01-00-01'
        },
        {
            SN => '1310207123',
            TM => 'ULT3580-TD4',
            AX => 'rmt1',
            YL => 'U5877.001.00H0441-P1-C6-T1-W2008000E1113516B-L0',
            FW => 'A239',
            DS => 'IBM 3580 Ultrium Tape Drive (FCP)',
            MF => 'IBM',
            PL => '02-00-01'
        },
        {
            SN => '00L4U78M1656_LL0',
            TM => '3573-TL',
            AX => 'smc0',
            YL => 'U5877.001.00H0441-P1-C5-T1-W2002000E1113516B-L1000000000000',
            FW => '9.20',
            DS => 'IBM 3573 Tape Medium Changer (FCP)',
            MF => 'IBM',
            PL => '01-00-01'
        },
        {
            SN => '00L4U78M1656_LL0',
            TM => '3573-TL',
            AX => 'smc1',
            YL => 'U5877.001.00H0441-P1-C6-T1-W2008000E1113516B-L1000000000000',
            FW => '9.20',
            DS => 'IBM 3573 Tape Medium Changer (FCP)',
            MF => 'IBM',
            PL => '02-00-01'
        }
    ],
    'aix-6.1b' => [
        {
            SE => '066B96A',
            FG => 'XXSV',
            DS => 'System VPD',
            WN => 'C0507601DBAD',
            RT => 'VSYS',
            TM => '7998-60X',
            BR => 'B0',
            VK => 'ipzSeries',
            YL => 'U7998.60X.066B96A',
            SU => '0004AC13804B'
        },
        {
            SE => 'WIH55B2',
            RK => '0000000000000000',
            FC => '78A5-001',
            FG => 'XXEV',
            DS => 'CEC',
            RT => 'VCEN',
            TM => '78A5-001',
            BR => 'B0',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH55B2',
            CI => '7998-60X 066B96A'
        },
        {
            VZ => '01',
            CC => '53AD',
            HE => '0001',
            PN => '46K7686',
            FG => 'XXBP',
            DS => 'SYS BP & 2W PROC',
            CE => '1',
            HW => '0001',
            FN => '10N9674',
            SN => 'YL10W921605K',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40F30015',
            YL => 'U78A5.001.WIH55B2-P1',
            PR => '3300200100020000'
        },
        {
            VZ => '01',
            CC => '31C2',
            PN => '43X5035',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '2048',
            FN => '43X5035',
            SN => 'YLD0014403BC',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH55B2-P1-C1',
            PR => '4400000000000000'
        },
        {
            VZ => '01',
            CC => '31C2',
            PN => '43X5035',
            FG => 'XXMS',
            DS => 'Memory DIMM',
            CE => '1',
            SZ => '2048',
            FN => '43X5035',
            SN => 'YLD0004403BB',
            RT => 'VINI',
            VK => 'ipzSeries',
            YL => 'U78A5.001.WIH55B2-P1-C3',
            PR => '4400000000000000'
        },
        {
            VZ => '03',
            CC => '52BF',
            HE => '0010',
            PN => '10N9483',
            FG => 'XXAV',
            DS => 'ANCHOR / RISER',
            CE => '1',
            HW => '0001',
            FN => '10N9483',
            SN => 'YL107899G01W',
            RT => 'VINI',
            VK => 'ipzSeries',
            CT => '40B40001',
            YL => 'U78A5.001.WIH55B2-P1-C9',
            PR => '8100008000000000'
        },
        {
            PN => '39Y9187',
            FG => 'XXDT',
            DS => 'SAS Expansion Card',
            HW => '03',
            FN => '39Y9188',
            SN => 'YK105499D091',
            RT => 'VINI',
            YL => 'U78A5.001.WIH55B2-P1-C10',
            VK => 'xSeries'
        },
        {
            PN => '41Y8581',
            FG => 'XXHD',
            DS => 'Fibre Channel / Ethernet Combo Expansion Card',
            HW => '03',
            FN => '39Y9304',
            SN => 'YK10NY97PHHA',
            RT => 'VINI',
            YL => 'U78A5.001.WIH55B2-P1-C11',
            VK => 'xSeries'
        },
        {
            YL => 'U7998.60X.066B96A-Y1',
            MI => 'EA350_038 EA340_039 EA350_038',
            DS => 'System Firmware',
            CL => 'FipS_BU 02202009102881E00200'
        },
        {
            AX => 'lhea0',
            YL => 'U78A5.001.WIH55B2-P1',
            DS => 'Logical Host Ethernet Adapter (l-hea)'
        },
        {
            CD => '10140367',
            AX => 'ent0',
            YL => 'U78A5.001.WIH55B2-P1-C11-L2-T1',
            DS => 'Gigabit Ethernet-SX PCI-X Adapter (14106703)',
            RM => '03280000',
            PL => '06-20'
        },
        {
            AX => 'sas0',
            YL => 'U78A5.001.WIH55B2-P1-T5',
            DS => 'Controller SAS Protocol',
            PL => '00-08-00'
        },
        {
            AX => 'sata0',
            YL => 'U78A5.001.WIH55B2-P1-T5',
            DS => 'Controller SATA Protocol',
            PL => '00-08-00'
        },
        {
            AX => 'ses0',
            YL => 'U78A5.001.WIH55B2-P1-Y1',
            DS => 'SAS Enclosure Services Device',
            RM => '02',
            PL => '00-08-00'
        },
        {
            PN => '26K5267',
            EC => 'H17923Y',
            DS => 'Physical SAS Disk Drive',
            MF => 'IBM-ESXS',
            FN => '39R7370',
            PL => '00-08-00',
            SN => '3NP3SES6',
            AX => 'pdisk0',
            TM => 'ST973402SS',
            YL => 'U78A5.001.WIH55B2-P1-D2',
            RL => '42353241'
        },
        {
            PN => '26K5267',
            EC => 'H17923Y',
            DS => 'Physical SAS Disk Drive',
            MF => 'IBM-ESXS',
            FN => '39R7370',
            PL => '00-08-00',
            SN => '3NP3T53P',
            AX => 'pdisk1',
            TM => 'ST973402SS',
            YL => 'U78A5.001.WIH55B2-P1-D1',
            RL => '42353241'
        },
        {
            AX => 'kbd0',
            YL => 'U78A5.001.WIH55B2-P1-T2-L1',
            DS => 'USB keyboard',
            PL => '1.1-'
        },
        {
            AX => 'mouse0',
            YL => 'U78A5.001.WIH55B2-P1-T2-L1',
            DS => 'USB mouse',
            PL => '1.1-'
        },
        {
            CD => '1077014c',
            AX => 'fscsi0',
            YL => 'U78A5.001.WIH55B2-P1-C11-L1-T1',
            DS => 'FC SCSI I/O Controller Protocol Device',
            PL => '04-00-01'
        },
        {
            CD => '1077014c',
            AX => 'fscsi1',
            YL => 'U78A5.001.WIH55B2-P1-C11-L1-T2',
            DS => 'FC SCSI I/O Controller Protocol Device',
            PL => '04-01-01'
        },
        {
            TM => '1726-2xx  FAStT',
            AX => 'hdisk1',
            YL => 'U78A5.001.WIH55B2-P1-C10-T1-L500A0B8673860004-L0',
            RL => '30363137',
            DS => 'MPIO DS3200 SAS Disk',
            MF => 'IBM',
            PL => '03-08-00'
        },
        {
            TM => '1726-2xx  FAStT',
            AX => 'hdisk2',
            YL => 'U78A5.001.WIH55B2-P1-C10-T1-L500A0B8673860004-L1000000000000',
            RL => '30363137',
            DS => 'MPIO DS3200 SAS Disk',
            MF => 'IBM',
            PL => '03-08-00'
        },
        {
            SN => '1K10042208',
            TM => 'ULT3580-HH4',
            AX => 'rmt0',
            YL => 'U78A5.001.WIH55B2-P1-C10-T1-L500507631245DA6A-L0',
            FW => 'A23E',
            DS => 'IBM 3580 Ultrium Tape Drive (SAS)',
            MF => 'IBM',
            PL => '03-08-00'
        },
        {
            CD => '10140367',
            AX => 'ent1',
            YL => 'U78A5.001.WIH55B2-P1-C11-L2-T2',
            DS => 'Gigabit Ethernet-SX PCI-X Adapter (14106703)',
            RM => '03280000',
            PL => '06-21'
        },
        {
            AX => 'kbd1',
            DS => 'USB keyboard'
        },
        {
            TM => '1726-2xx  FAStT',
            AX => 'hdisk4',
            YL => 'U78A5.001.WIH55B2-P1-C10-T1-L500A0B8673860004-L4000000000000',
            RL => '30363137',
            DS => 'MPIO DS3200 SAS Disk',
            MF => 'IBM',
            PL => '03-08-00'
        },
        {
            TM => '1726-2xx  FAStT',
            AX => 'hdisk5',
            YL => 'U78A5.001.WIH55B2-P1-C10-T1-L500A0B8673860004-L2000000000000',
            RL => '30363137',
            DS => 'MPIO DS3200 SAS Disk',
            MF => 'IBM',
            PL => '03-08-00'
        },
        {
            TM => '1726-2xx  FAStT',
            AX => 'hdisk6',
            YL => 'U78A5.001.WIH55B2-P1-C10-T1-L500A0B8673860004-L3000000000000',
            RL => '30363137',
            DS => 'MPIO DS3200 SAS Disk',
            MF => 'IBM',
            PL => '03-08-00'
        },
        {
            TM => '1726-2xx  FAStT',
            AX => 'hdisk7',
            YL => 'U78A5.001.WIH55B2-P1-C10-T1-L500A0B8673860004-L5000000000000',
            RL => '30363137',
            DS => 'MPIO DS3200 SAS Disk',
            MF => 'IBM',
            PL => '03-08-00'
        }
    ],
);

my %lsdev_tests = (
    'aix-5.3a' => [
        {
            NAME        => 'ent0',
            DESCRIPTION => '2-Port 10/100/1000 Base-TX PCI-X Adapter (14108902)',
            TYPE        => '14108902'
        },
        {
            NAME        => 'ent1',
            DESCRIPTION => '2-Port 10/100/1000 Base-TX PCI-X Adapter (14108902)',
            TYPE        => '14108902'
        },
        {
            NAME        => 'ide0',
            DESCRIPTION => 'ATA/IDE Controller Device',
            TYPE        => '5a107512'
        },
        {
            NAME        => 'lai0',
            DESCRIPTION => 'GXT135P Graphics Adapter',
            TYPE        => '14103302'
        },
        {
            NAME        => 'sa0',
            DESCRIPTION => '2-Port Asynchronous EIA-232 PCI Adapter',
            TYPE        => '4f11c800'
        },
        {
            NAME        => 'sa1',
            DESCRIPTION => 'IBM 8-Port EIA-232/RS-422A (PCI) Adapter',
            TYPE        => '4f111100'
        },
        {
            NAME        => 'sisscsia0',
            DESCRIPTION => 'PCI-X Dual Channel Ultra320 SCSI Adapter',
            TYPE        => '14106602'
        },
        {
            NAME        => 'usbhc0',
            DESCRIPTION => 'USB Host Controller (33103500)',
            TYPE        => '33103500'
        },
        {
            NAME        => 'usbhc1',
            DESCRIPTION => 'USB Host Controller (33103500)',
            TYPE        => '33103500'
        },
        {
            NAME         => 'vsa0',
            DESCRIPTION => 'LPAR Virtual Serial Adapter',
            TYPE         => 'hvterm1'
        },
        {
            NAME        => 'vsa1',
            DESCRIPTION => 'LPAR Virtual Serial Adapter',
            TYPE        => 'hvterm-protocol'
        },
        {
            NAME        => 'vsa2',
            DESCRIPTION => 'LPAR Virtual Serial Adapter',
            TYPE        => 'hvterm-protocol'
        }
    ],
    'aix-5.3b' => [
        {
            NAME        => 'ent0',
            DESCRIPTION => 'Gigabit Ethernet-SX PCI-X Adapter (14101403)',
            TYPE        => '14101403'
        },
        {
            NAME        => 'ent1',
            DESCRIPTION => 'Gigabit Ethernet-SX PCI-X Adapter (14101403)',
            TYPE        => '14101403'
        },
        {
            NAME        => 'ent2',
            DESCRIPTION => 'EtherChannel / IEEE 802.3ad Link Aggregation',
            TYPE        => 'ibm_ech'
        },
        {
            NAME        => 'ent3',
            DESCRIPTION => 'VLAN',
            TYPE        => 'eth'
        },
        {
            NAME        => 'ent4',
            DESCRIPTION => 'VLAN',
            TYPE        => 'eth'
        },
        {
            NAME        => 'sisioa0',
            DESCRIPTION => 'PCI-XDDR Dual Channel SAS RAID Adapter',
            TYPE        => '14108d02'
        },
        {
            NAME        => 'usbhc0',
            DESCRIPTION => 'USB Host Controller (22106474)',
            TYPE        => '22106474'
        },
        {
            NAME        => 'usbhc1',
            DESCRIPTION => 'USB Host Controller (22106474)',
            TYPE        => '22106474'
        },
        {
            NAME        => 'vsa0',
            DESCRIPTION => 'LPAR Virtual Serial Adapter',
            TYPE        => 'hvterm1'
        }
    ],
    'aix-5.3c' => [
        {
            NAME        => 'ent0',
            DESCRIPTION => 'Logical Host Ethernet Port (lp-hea)',
            TYPE        => 'ethernet'
        },
        {
            NAME        => 'ent1',
            DESCRIPTION => 'Logical Host Ethernet Port (lp-hea)',
            TYPE        => 'ethernet'
        },
        {
            NAME        => 'ent2',
            DESCRIPTION => 'Virtual I/O Ethernet Adapter (l-lan)',
            TYPE        => 'IBM,l-lan'
        },
        {
            NAME        => 'lhea0',
            DESCRIPTION => 'Logical Host Ethernet Adapter (l-hea)',
            TYPE        => 'IBM,lhea'
        },
        {
            NAME        => 'vsa0',
            DESCRIPTION => 'LPAR Virtual Serial Adapter',
            TYPE        => 'hvterm1'
        },
        {
            NAME        => 'vscsi0',
            DESCRIPTION => 'Virtual SCSI Client Adapter',
            TYPE        => 'IBM,v-scsi'
        }
    ],
    'aix-6.1a' => [
        {
            NAME        => 'ent0',
            DESCRIPTION => 'Virtual I/O Ethernet Adapter (l-lan)',
            TYPE        => 'IBM,l-lan'
        },
        {
            NAME        => 'ent1',
            DESCRIPTION => 'Logical Host Ethernet Port (lp-hea)',
            TYPE        => 'ethernet'
        },
        {
            NAME        => 'ent2',
            DESCRIPTION => 'Logical Host Ethernet Port (lp-hea)',
            TYPE        => 'ethernet'
        },
        {
            NAME        => 'fcs0',
            DESCRIPTION => '4Gb FC PCI Express Adapter (df1000fe)',
            TYPE        => 'df1000fe'
        },
        {
            NAME        => 'fcs1',
            DESCRIPTION => '4Gb FC PCI Express Adapter (df1000fe)',
            TYPE        => 'df1000fe'
        },
        {
            NAME        => 'fcs2',
            DESCRIPTION => '4Gb FC PCI Express Adapter (df1000fe)',
            TYPE        => 'df1000fe'
        },
        {
            NAME        => 'fcs3',
            DESCRIPTION => '4Gb FC PCI Express Adapter (df1000fe)',
            TYPE        => 'df1000fe'
        },
        {
            NAME        => 'fcs4',
            DESCRIPTION => 'Virtual Fibre Channel Client Adapter',
            TYPE        => 'IBM,vfc-client'
        },
        {
            NAME        => 'lhea0',
            DESCRIPTION => 'Logical Host Ethernet Adapter (l-hea)',
            TYPE        => 'IBM,lhea'
        },
        {
            NAME        => 'vsa0',
            DESCRIPTION => 'LPAR Virtual Serial Adapter',
            TYPE        => 'hvterm1'
        },
        {
            NAME        => 'vscsi0',
            DESCRIPTION => 'Virtual SCSI Client Adapter',
            TYPE        => 'IBM,v-scsi'
        },
        {
            NAME        => 'vscsi1',
            DESCRIPTION => 'Virtual SCSI Client Adapter',
            TYPE        => 'IBM,v-scsi'
        }
    ],
    'aix-6.1b' => [
        {
            NAME        => 'ati0',
            DESCRIPTION => 'Native Display Graphics Adapter',
            TYPE        => '02105e51'
        },
        {
            NAME        => 'ent0',
            DESCRIPTION => 'Gigabit Ethernet-SX PCI-X Adapter (14106703)',
            TYPE        => '14106703'
        },
        {
            NAME        => 'ent1',
            DESCRIPTION => 'Gigabit Ethernet-SX PCI-X Adapter (14106703)',
            TYPE        => '14106703'
        },
        {
            NAME        => 'ent2',
            DESCRIPTION => 'Logical Host Ethernet Port (lp-hea)',
            TYPE        => 'ethernet'
        },
        {
            NAME        => 'ent3',
            DESCRIPTION => 'Logical Host Ethernet Port (lp-hea)',
            TYPE        => 'ethernet'
        },
        {
            NAME        => 'fcs0',
            DESCRIPTION => 'PCI Express 4Gb FC Adapter (77103224)',
            TYPE        => '77103224'
        },
        {
            NAME        => 'fcs1',
            DESCRIPTION => 'PCI Express 4Gb FC Adapter (77103224)',
            TYPE        => '77103224'
        },
        {
            NAME        => 'lhea0',
            DESCRIPTION => 'Logical Host Ethernet Adapter (l-hea)',
            TYPE        => 'IBM,lhea'
        },
        {
            NAME        => 'mptsas0',
            DESCRIPTION => 'SAS Expansion Card (00105000)',
            TYPE        => '00105000'
        },
        {
            NAME        => 'sissas0',
            DESCRIPTION => 'PCI-X266 Planar 3Gb SAS Adapter',
            TYPE        => '1410c102'
        },
        {
            NAME        => 'usbhc0',
            DESCRIPTION => 'USB Host Controller (33103500)',
            TYPE        => '33103500'
        },
        {
            NAME        => 'usbhc1',
            DESCRIPTION => 'USB Host Controller (33103500)',
            TYPE        => '33103500'
        },
        {
            NAME        => 'usbhc2',
            DESCRIPTION => 'USB Enhanced Host Controller (3310e000)',
            TYPE        => '3310e000'
        },
        {
            NAME        => 'vsa0',
            DESCRIPTION => 'LPAR Virtual Serial Adapter',
            TYPE        => 'hvterm1'
        }
    ]
);

plan tests =>
    (scalar keys %lsvpd_tests) +
    (scalar keys %lsdev_tests);

foreach my $test (keys %lsvpd_tests) {
    my $file = "resources/aix/lsvpd/$test";
    my @infos = getLsvpdInfos(file => $file);
    cmp_deeply(\@infos, $lsvpd_tests{$test}, "$test lsvpd parsing");
}

foreach my $test (keys %lsdev_tests) {
    my $file = "resources/aix/lsdev/$test-adapter";
    my @adapters = getAdaptersFromLsdev(file => $file);
    cmp_deeply(\@adapters, $lsdev_tests{$test}, "$test lsdev parsing");
}
