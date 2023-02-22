#!/usr/bin/perl

use strict;
use warnings;

use English qw(-no_match_vars);
use Test::Deep qw(cmp_deeply);
use Test::More;
use UNIVERSAL::require;

use GLPI::Agent::Tools;
use GLPI::Agent::Task::Inventory::Generic::Screen;

plan(skip_all => 'Parse::EDID >= 1.0.4 required')
    unless Parse::EDID->require('1.0.4');

Test::NoWarnings->use();

my %edid_tests = (
    'acer-al1716' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'AL1716',
        SERIAL       => '0000b051',
        DESCRIPTION  => '37/2006'
    },
    'acer-al1716.2' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'AL1716',
        ALTSERIAL    => 'L460C1184049',
        SERIAL       => 'L460C1187320c3844049',
        DESCRIPTION  => '32/2007'
    },
    'acer-al1717' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'AL1717',
        ALTSERIAL    => 'L56042344335',
        SERIAL       => 'L56042347220137b4335',
        DESCRIPTION  => '22/2007'
    },
    'acer-al1717.2' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer AL1717',
        ALTSERIAL    => 'L72080574223',
        SERIAL       => 'L7208057706026854223',
        DESCRIPTION  => '6/2007'
    },
    'acer-al1916w' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'AL1916W',
        ALTSERIAL    => 'L800C0014020',
        SERIAL       => 'L800C001717079874020',
        DESCRIPTION  => '17/2007'
    },
    'acer-al1917' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer AL1917',
        ALTSERIAL    => 'L730851342HM',
        SERIAL       => 'L73085138132779b42HM',
        DESCRIPTION  => '13/2008'
    },
    'acer-b226wl' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'B226WL',
        ALTSERIAL    => 'LXVEE0018511',
        SERIAL       => 'LXVEE0018030951c8511',
        DESCRIPTION  => '3/2018'
    },
    'acer-b247y' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'B247Y',
        ALTSERIAL    => 'TJYEE0068521',
        SERIAL       => 'TJYEE0061171bcd58521',
        DESCRIPTION  => '17/2021'
    },
    'acer-h6517abd' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer H6517ABD',
        ALTSERIAL    => 'JNB110015900',
        SERIAL       => 'JNB11001000005f25900',
        DESCRIPTION  => '11/2019'
    },
    'acer-k242hql' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer K242HQL',
        ALTSERIAL    => 'T2JEE0144223',
        SERIAL       => 'T2JEE0140160e81f4223',
        DESCRIPTION  => '16/2020'
    },
    'acer-p1203' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'ACER P1203',
        ALTSERIAL    => 'K17010015901',
        SERIAL       => 'K170100100000d0b5901',
        DESCRIPTION  => '8/2011'
    },
    'acer-p1206p' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'ACER P1206P',
        ALTSERIAL    => 'JCS010145901',
        SERIAL       => 'JCS01014000004fe5901',
        DESCRIPTION  => '15/2012'
    },
    'acer-p1283' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer P1283',
        ALTSERIAL    => 'JHG110015900',
        SERIAL       => 'JHG11001000014305900',
        DESCRIPTION  => '23/2015'
    },
    'acer-p5260i' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'ACER P5260i',
        ALTSERIAL    => 'J54010095911',
        SERIAL       => 'J5401009000001205911',
        DESCRIPTION  => '32/2008'
    },
    'acer-r240hy' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'R240HY',
        ALTSERIAL    => 'T4BEE00C2411',
        SERIAL       => 'T4BEE00C112089502411',
        DESCRIPTION  => '12/2021'
    },
    'acer-sa240y' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'SA240Y',
        ALTSERIAL    => 'T92EE0062460',
        SERIAL       => 'T92EE006034013032460',
        DESCRIPTION  => '34/2020'
    },
    'acer-v193' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer V193',
        ALTSERIAL    => 'LBZ080424212',
        SERIAL       => 'LBZ08042841063a64212',
        DESCRIPTION  => '41/2008'
    },
    'acer-v193.2' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer V193',
        ALTSERIAL    => 'LCC020014101',
        SERIAL       => 'LCC0200182202e3c4101',
        DESCRIPTION  => '22/2008'
    },
    'acer-v193.3' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'V193',
        ALTSERIAL    => 'LDQ0C0144000',
        SERIAL       => 'LDQ0C0148330a6184000',
        DESCRIPTION  => '33/2008'
    },
    'acer-v193l' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer V193L',
        ALTSERIAL    => 'LS2EE0024211',
        SERIAL       => 'LS2EE00224800a974211',
        DESCRIPTION  => '48/2012'
    },
    'acer-v193l.2' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'V193L',
        ALTSERIAL    => 'LX6EE0128501',
        SERIAL       => 'LX6EE012303056828501',
        DESCRIPTION  => '3/2013'
    },
    'acer-v196l' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'V196L',
        ALTSERIAL    => 'LYQEE0028500',
        SERIAL       => 'LYQEE0026120179b8500',
        DESCRIPTION  => '12/2016'
    },
    'acer-v193hqv' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'V193HQV',
        ALTSERIAL    => 'LKR0D0068501',
        SERIAL       => 'LKR0D0060320a5e28501',
        DESCRIPTION  => '32/2010'
    },
    'acer-v193w' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'V193W',
        ALTSERIAL    => 'LBP0C18340G0',
        SERIAL       => 'LBP0C1830291075740G0',
        DESCRIPTION  => '29/2010'
    },
    'acer-v203h' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'V203H',
        ALTSERIAL    => 'LGP0D0098500',
        SERIAL       => 'LGP0D009927082198500',
        DESCRIPTION  => '27/2009'
    },
    'acer-v203w' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer V203W',
        ALTSERIAL    => 'LC2080014200',
        SERIAL       => 'LC2080018190c7da4200',
        DESCRIPTION  => '19/2008'
    },
    'acer-v223hq' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'V223HQ',
        ALTSERIAL    => 'LES0C0034000',
        SERIAL       => 'LES0C00391408a254000',
        DESCRIPTION  => '14/2009'
    },
    'acer-v226hql' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'V226HQL',
        ALTSERIAL    => 'LY7EE016851C',
        SERIAL       => 'LY7EE016638103c5851C',
        DESCRIPTION  => '38/2016'
    },
    'acer-v226hql.2' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'V226HQL',
        ALTSERIAL    => 'LY7EE013851C',
        SERIAL       => 'LY7EE0137080f0a8851C',
        DESCRIPTION  => '8/2017'
    },
    'acer-v247y' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'V247Y',
        ALTSERIAL    => 'TJZEE0068574',
        SERIAL       => 'TJZEE00620704d948574',
        DESCRIPTION  => '7/2022'
    },
    'acer-v276hl' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'V276HL',
        ALTSERIAL    => 'T4JEE0058545',
        SERIAL       => 'T4JEE0059220304e8545',
        DESCRIPTION  => '22/2019'
    },
    'acer-x125h' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer X125H',
        ALTSERIAL    => 'JN9110015900',
        SERIAL       => 'JN91100100000f435900',
        DESCRIPTION  => '10/2017'
    },
    'acer-x128h' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer X128H',
        ALTSERIAL    => 'JQ8110015900',
        SERIAL       => 'JQ811001000013265900',
        DESCRIPTION  => '46/2017'
    },
    'acer-xga-pj' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer XGA PJ',
        ALTSERIAL    => 'JR81100Y5910',
        SERIAL       => 'JR81100Y000014775910',
        DESCRIPTION  => '10/2020'
    },
    'aic-e-191' => {
        MANUFACTURER => 'AG Neovo',
        CAPTION      => 'E-191',
        SERIAL       => '1409',
        DESCRIPTION  => '49/2009'
    },
    'crt.13' => {
        MANUFACTURER => 'Litronic Inc',
        CAPTION      => 'A1554NEL',
        SERIAL       => '926750447',
        DESCRIPTION  => '26/1999'
    },
    'crt.dell-d1626ht' => {
        MANUFACTURER => 'Dell Inc.',
        CAPTION      => 'DELL D1626HT',
        SERIAL       => '55347B06Z418',
        DESCRIPTION  => '4/1998'
    },
    'crt.dell-p1110' => {
        MANUFACTURER => 'Dell Inc.',
        CAPTION      => 'DELL P1110',
        SERIAL       => '9171RB0JCW89',
        DESCRIPTION  => '35/1999'
    },
    'crt.dell-p790' => {
        MANUFACTURER => 'Dell Inc.',
        CAPTION      => 'DELL P790',
        SERIAL       => '8757RH9QUY80',
        DESCRIPTION  => '33/2000'
    },
    'crt.dell-p190s' => {
        MANUFACTURER => 'Dell Inc.',
        CAPTION      => 'DELL P190S',
        SERIAL       => 'CHRYK07UAGUS',
        DESCRIPTION  => '30/2010'
    },
    'crt.dell-e190s' => {
        MANUFACTURER => 'Dell Inc.',
        CAPTION      => 'DELL E190S',
        SERIAL       => 'G448N08G0RYS',
        DESCRIPTION  => '34/2010'
    },
    'crt.E55' => {
        MANUFACTURER => 'Panasonic Industry Company',
        CAPTION      => undef,
        SERIAL       => '000018a6',
        DESCRIPTION  => '10/1999'
    },
    'crt.emc0313' => {
        MANUFACTURER => 'eMicro Corporation',
        CAPTION      => '0000000000011',
        SERIAL       => '0000198a',
        DESCRIPTION  => '21/2001'
    },
    'crt.hyundai-ImageQuest-L70S+' => {
        MANUFACTURER => 'IMAGEQUEST Co., Ltd',
        CAPTION      => 'L70S+',
        SERIAL       => '0000e0eb',
        DESCRIPTION  => '44/2004'
    },
    'crt.iiyama-1451' => {
        MANUFACTURER => 'Iiyama North America',
        CAPTION      => 'LS902U',
        SERIAL       => '0001f7be',
        DESCRIPTION  => '3/2003'
    },
    'crt.iiyama-404' => {
        MANUFACTURER => 'Iiyama North America',
        CAPTION      => undef,
        SERIAL       => '00000000',
        DESCRIPTION  => '52/1999'
    },
    'crt.iiyama-410pro' => {
        MANUFACTURER => 'Iiyama North America',
        CAPTION      => undef,
        SERIAL       => '00000000',
        DESCRIPTION  => '38/2000'
    },
    'crt.leia' => {
        MANUFACTURER => 'Compaq Computer Company',
        CAPTION      => 'COMPAQ P710',
        SERIAL       => '047ch67ha005',
        DESCRIPTION  => '47/2000'
    },
    'crt.LG-Studioworks-N2200P' => {
        MANUFACTURER => 'Goldstar Company Ltd',
        CAPTION      => 'Studioworks N 2200P',
        SERIAL       => '0000ce6e',
        ALTSERIAL    => '1J846',
        DESCRIPTION  => '10/2004'
    },
    'crt.med2914' => {
        MANUFACTURER => 'Messeltronik Dresden GmbH',
        CAPTION      => undef,
        SERIAL       => '108371572',
        DESCRIPTION  => '8/2001'
    },
    'crt.nokia-valuegraph-447w' => {
        MANUFACTURER => 'Nokia Display Products',
        CAPTION      => undef,
        SERIAL       => '00000d1b',
        DESCRIPTION  => '6/1997'
    },
    'crt.SM550S' => {
        MANUFACTURER => 'Samsung Electric Company',
        CAPTION      => undef,
        SERIAL       => 'HXAKB13419',
        ALTSERIAL    => 'DP15HXAKB13419',
        DESCRIPTION  => '48/1999'
    },
    'crt.SM550V' => {
        MANUFACTURER => 'Samsung Electric Company',
        CAPTION      => 'S/M 550v',
        SERIAL       => 'HXBN407938',
        ALTSERIAL    => 'DP15HXBN407938',
        DESCRIPTION  => '16/2000'
    },
    'crt.sony-gdm400ps' => {
        MANUFACTURER => 'Sony Corporation',
        CAPTION      => 'GDM-400PST9',
        SERIAL       => '6005379',
        DESCRIPTION  => '39/1999'
    },
    'crt.sony-gdm420' => {
        MANUFACTURER => 'Sony Corporation',
        CAPTION      => 'CPD-G420',
        SERIAL       => '6017706',
        DESCRIPTION  => '39/2001'
    },
    'crt.test_box_lmontel' => {
        MANUFACTURER => 'Compaq Computer Company',
        CAPTION      => 'COMPAQ MV920',
        SERIAL       => '008GA23MA966',
        DESCRIPTION  => '8/2000'
    },
    'lcd.20inches' => {
        MANUFACTURER => 'Rogen Tech Distribution Inc',
        CAPTION      => 'B102005',
        SERIAL       => '0000033f',
        DESCRIPTION  => '52/2004'
    },
    'iiyama-PL2779A' => {
        MANUFACTURER => 'Iiyama North America',
        CAPTION      => 'PL2779Q',
        SERIAL       => '01010101',
        DESCRIPTION  => '2013'
    },
    'lcd.acer-al1921' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer AL1921',
        SERIAL       => 'ETL2508043',
        ALTSERIAL    => 'ETL25080445001d943',
        DESCRIPTION  => '45/2004'
    },
    'lcd.acer-al19161.1' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer AL1916',
        SERIAL       => 'L4908669719030c64237',
        ALTSERIAL    => 'L49086694237',
        DESCRIPTION  => '19/2007'
    },
    'lcd.acer-al19161.2' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer AL1916',
        SERIAL       => 'L49086697190328f4237',
        ALTSERIAL    => 'L49086694237',
        DESCRIPTION  => '19/2007'
    },
    'lcd.acer-al19161.3' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer AL1916',
        SERIAL       => 'L4908669719032914237',
        ALTSERIAL    => 'L49086694237',
        DESCRIPTION  => '19/2007'
    },
    'lcd.acer-al19161.4' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer AL1916',
        SERIAL       => 'L4908669719032904237',
        ALTSERIAL    => 'L49086694237',
        DESCRIPTION  => '19/2007'
    },
    'lcd.acer-asp1680' => {
        MANUFACTURER => 'Quanta Display Inc.',
        CAPTION      => 'JPN4A1P049605 QD15TL021',
        SERIAL       => '00000000',
        DESCRIPTION  => '51/2004'
    },
    'lcd.acer-v193.1' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer V193',
        SERIAL       => 'LBZ081610080b6974233',
        ALTSERIAL    => 'LBZ081614233',
        DESCRIPTION  => '8/2010'
    },
    'lcd.acer-b226hql' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer B226HQL',
        SERIAL       => 'LXPEE01452707f0c4202',
        ALTSERIAL    => 'LXPEE0144202',
        DESCRIPTION  => '27/2015'
    },
    'lcd.acer-b226hql.28.2016' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'B226HQL',
        SERIAL       => 'LXYEE011628087078507',
        ALTSERIAL    => 'LXYEE0118507',
        DESCRIPTION  => '28/2016'
    },
    'lcd.acer-b196hql' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer B196HQL',
        SERIAL       => 'TAHEE00173205d434200',
        ALTSERIAL    => 'TAHEE0014200',
        DESCRIPTION  => '32/2017'
    },
    'lcd.acer-g227hql' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'G227HQL',
        SERIAL       => 'T0LEE0145350147f2431',
        ALTSERIAL    => 'T0LEE0142431',
        DESCRIPTION  => '35/2015'
    },
    'lcd.acer-g236hl' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer G236HL',
        SERIAL       => 'LVB080013127cc394200',
        ALTSERIAL    => 'LVB080014200',
        DESCRIPTION  => '12/2013'
    },
    'lcd.acer-r221q' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'R221Q',
        SERIAL       => 'T6KEE00160303ff52400',
        ALTSERIAL    => 'T6KEE0012400',
        DESCRIPTION  => '3/2016'
    },
    'lcd.acer-s273hl' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'S273HL',
        SERIAL       => 'LQA0C015140000358001',
        ALTSERIAL    => 'LQA0C0158001',
        DESCRIPTION  => '40/2011'
    },
    'lcd.acer-v193.2' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer V193',
        SERIAL       => 'LBZ081610050c5b24233',
        ALTSERIAL    => 'LBZ081614233',
        DESCRIPTION  => '5/2010'
    },
    'lcd.acer-ka240hq' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer KA240HQ',
        SERIAL       => 'T3SEE0058040f0164206',
        ALTSERIAL    => 'T3SEE0054206',
        DESCRIPTION  => '4/2018'
    },
    'lcd.acer-x193hq' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'X193HQ',
        SERIAL       => 'LEK0D09994003c0c8545',
        ALTSERIAL    => 'LEK0D0998545',
        DESCRIPTION  => '40/2009'
    },
    'lcd.acer-v246hl' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer V246HL',
        SERIAL       => 'LXMEE02080905d6c4222',
        ALTSERIAL    => 'LXMEE0204222',
        DESCRIPTION  => '9/2018'
    },
    'lcd.acer-v193.3' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'V193',
        SERIAL       => 'LHW0D03093901df58531',
        ALTSERIAL    => 'LHW0D0308531',
        DESCRIPTION  => '39/2009'
    },
    'lcd.acer-b243h' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'B243H',
        SERIAL       => 'LH30C0109500722b40D1',
        ALTSERIAL    => 'LH30C01040D1',
        DESCRIPTION  => '50/2009'
    },
    'lcd.acer-v243h' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'V243H',
        SERIAL       => 'LFV0C00391105c5a4030',
        ALTSERIAL    => 'LFV0C0034030',
        DESCRIPTION  => '11/2009'
    },
    'lcd.acer-h226hql' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'Acer H226HQL',
        SERIAL       => 'LX2EE0023497a1aa4200',
        ALTSERIAL    => 'LX2EE0024200',
        DESCRIPTION  => '49/2013'
    },
    'lcd.acer-k222hql' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'K222HQL',
        SERIAL       => 'T5XEE017725050102456',
        ALTSERIAL    => 'T5XEE0172456',
        DESCRIPTION  => '25/2017'
    },
    'lcd.acer-sa220q' => {
        MANUFACTURER => 'Acer Technologies',
        CAPTION      => 'SA220Q',
        SERIAL       => 'T90EE00273901d732410',
        ALTSERIAL    => 'T90EE0022410',
        DESCRIPTION  => '39/2017'
    },
    'lcd.b-101750' => {
        MANUFACTURER => 'Rogen Tech Distribution Inc',
        CAPTION      => 'B_101750',
        SERIAL       => '00000219',
        DESCRIPTION  => '6/2004'
    },
    'lcd.benq-t904' => {
        MANUFACTURER => 'BenQ Corporation',
        CAPTION      => 'BenQ T904',
        SERIAL       => '0000197a',
        DESCRIPTION  => '15/2004'
    },
    'lcd.blino' => {
        MANUFACTURER => 'AU Optronics',
        CAPTION      => 'AUO B150PG01',
        SERIAL       => '00000291',
        DESCRIPTION  => '35/2004'
    },
    'lcd.cmc-17-AD' => {
        MANUFACTURER => 'Chi Mei Optoelectronics corp.',
        CAPTION      => 'CMC 17" AD',
        SERIAL       => '00000000',
        DESCRIPTION  => '34/2004'
    },
    'lcd.compaq-evo-n1020v' => {
        MANUFACTURER => 'LGP',
        CAPTION      => undef,
        SERIAL       => '00000000',
        DESCRIPTION  => '0/1990'
    },
    'lcd.dell-2001fp' => {
        MANUFACTURER => 'Dell Inc.',
        CAPTION      => 'DELL 2001FP',
        SERIAL       => 'C064652L3KTL',
        DESCRIPTION  => '9/2005'
    },
    'lcd.dell-inspiron-6400' => {
        MANUFACTURER => 'LG Philips',
        CAPTION      => 'XD570',
        SERIAL       => '00000000',
        DESCRIPTION  => '0/2005',
    },
    'lcd.dell-U2410' => {
        MANUFACTURER => 'Dell Inc.',
        CAPTION      => 'DELL U2410',
        SERIAL       => 'F525M1AGAP6L',
        DESCRIPTION  => '42/2011'
    },
    'lcd.dell-U2413' => {
        MANUFACTURER => 'Dell Inc.',
        CAPTION      => 'DELL U2413',
        SERIAL       => '84K96386ACRL',
        DESCRIPTION  => '32/2013'
    },
    'lcd.dell-U2415' => {
        MANUFACTURER => 'Dell Inc.',
        CAPTION      => 'DELL U2415',
        SERIAL       => '7MT019AI34EU',
        DESCRIPTION  => '42/2019'
    },
    'lcd.eizo-l997' => {
        MANUFACTURER => 'Eizo Nanao Corporation',
        CAPTION      => 'L997',
        SERIAL       => '21211015',
        DESCRIPTION  => '5/2005'
    },
    'lcd.Elonex-PR600' => {
        MANUFACTURER => 'Chi Mei Optoelectronics corp.',
        CAPTION      => 'N154I2-L02 CMO N154I2-L02',
        SERIAL       => '00000000',
        DESCRIPTION  => '9/2006',
    },
    'lcd.fujitsu-a171' => {
        MANUFACTURER => 'Fujitsu Siemens Computers GmbH',
        CAPTION      => 'A17-1',
        SERIAL       => 'YEEP525344',
        DESCRIPTION  => '34/2005'
    },
    'lcd.gericom-cy-96' => {
        MANUFACTURER => 'Plain Tree Systems Inc',
        CAPTION      => 'CY965',
        SERIAL       => 'F3AJ3A0019190',
        DESCRIPTION  => '41/2003',
    },
    'lcd.hp-nx-7000' => {
        MANUFACTURER => 'LGP',
        CAPTION      => undef,
        SERIAL       => '00000000',
        DESCRIPTION  => '0/2003',
    },
    'lcd.hp-nx-7010' => {
        MANUFACTURER => 'LGP',
        CAPTION      => undef,
        SERIAL       => '00000000',
        DESCRIPTION  => '0/2003',
    },
    'lcd.HP-Pavilion-ZV6000' => {
        MANUFACTURER => 'Quanta Display Inc.',
        CAPTION      => 'JMN4A1P047325 QD15TL022',
        SERIAL       => '00000000',
        DESCRIPTION  => '51/2004',
    },
    'lcd.hp-l1950' => {
        MANUFACTURER => 'Hewlett Packard',
        CAPTION      => 'HP L1950',
        SERIAL       => 'CNK7420237',
        DESCRIPTION  => '42/2007'
    },
    'lcd.iiyama-pl2409hd' => {
        MANUFACTURER => 'Iiyama North America',
        CAPTION      => 'PL2409HD',
        SERIAL       => '11004M0C00313',
        DESCRIPTION  => '49/2010'
    },
    'lcd.lg-l1960.1' => {
        MANUFACTURER => 'Goldstar Company Ltd',
        CAPTION      => 'L1960TR ',
        SERIAL       => '9Y670',
        ALTSERIAL    => '00052aee',
        DESCRIPTION  => '11/2007'
    },
    'lcd.lg-l1960.2' => {
        MANUFACTURER => 'Goldstar Company Ltd',
        CAPTION      => 'L1960TR ',
        SERIAL       => '9Y676',
        ALTSERIAL    => '00052af4',
        DESCRIPTION  => '11/2007'
    },
    'lcd.lg.tv.22MT44DP-PZ' => {
        MANUFACTURER => 'Goldstar Company Ltd',
        CAPTION      => '2D FHD LG TV',
        SERIAL       => '01010101',
        DESCRIPTION  => '1/2013'
    },
    'lcd.lenovo-3000-v100' => {
        MANUFACTURER => 'AU Optronics',
        CAPTION      => 'AUO B121EW03 V2',
        SERIAL       => '00000000',
        DESCRIPTION  => '1/2006',
    },
    'lcd.lenovo-w500' => {
        MANUFACTURER => 'Lenovo Group Limited',
        CAPTION      => 'LTN154U2-L05',
        SERIAL       => '00000000',
        DESCRIPTION  => '0/2007',
    },
    'lcd.philips-150s' => {
        MANUFACTURER => 'Philips Consumer Electronics Company',
        CAPTION      => 'PHILIPS  150S',
        SERIAL       => ' HD  000237',
        DESCRIPTION  => '33/2001'
    },
    'lcd.philips-180b2' => {
        MANUFACTURER => 'Philips Consumer Electronics Company',
        CAPTION      => 'Philips 180B2',
        SERIAL       => ' HD  021838',
        DESCRIPTION  => '42/2002'
    },
    'lcd.philips-288p6-vga' => {
        MANUFACTURER => 'Philips Consumer Electronics Company',
        CAPTION      => 'Philips 288P6',
        SERIAL       => 'AU51430006456',
        DESCRIPTION  => '30/2014'
    },
    'lcd.philips-288p6-hdmi' => {
        MANUFACTURER => 'Philips Consumer Electronics Company',
        CAPTION      => 'Philips 288P6',
        SERIAL       => '006456',
        ALTSERIAL    => '00001938',
        DESCRIPTION  => '30/2014'
    },
    'lcd.presario-R4000' => {
        MANUFACTURER => 'LG Philips',
        CAPTION      => 'LGPhilipsLCD LP154W01-A5',
        SERIAL       => '00000000',
        DESCRIPTION  => '0/2004',
    },
    'lcd.rafael' => {
        MANUFACTURER => 'Rogen Tech Distribution Inc',
        CAPTION      => 'B101715',
        SERIAL       => '000005e5',
        DESCRIPTION  => '27/2004',
    },
    'lcd.regis' => {
        MANUFACTURER => 'Eizo Nanao Corporation',
        CAPTION      => 'L557',
        SERIAL       => '82522083',
        DESCRIPTION  => '33/2003',
    },
    'lcd.samsung-191n' => {
        MANUFACTURER => 'Samsung Electric Company',
        CAPTION      => 'SyncMaster',
        SERIAL       => 'HCHW600639',
        ALTSERIAL    => 'GH19HCHW600639',
        DESCRIPTION  => '23/2003'
    },
    'lcd.samsung-2494hm' => {
        MANUFACTURER => 'Samsung Electric Company',
        CAPTION      => 'SyncMaster',
        SERIAL       => 'H9XS933672',
        ALTSERIAL    => 'KI24H9XS933672',
        DESCRIPTION  => '39/2009'
    },
    'lcd.samsung-s22c450' => {
        MANUFACTURER => 'Samsung Electric Company',
        CAPTION      => 'S22C450',
        SERIAL       => '0276H4MF200047',
        ALTSERIAL    => 'H4MF200047',
        DESCRIPTION  => '6/2014'
    },
    'lcd.samsung-s24e450' => {
        MANUFACTURER => 'Samsung Electric Company',
        CAPTION      => 'S24E450',
        SERIAL       => 'ZZHAH4ZKA00739',
        ALTSERIAL    => 'H4ZKA00739',
        DESCRIPTION  => '42/2018'
    },
    'lcd.tv.VQ32-1T' => {
        MANUFACTURER => 'Fujitsu Siemens Computers GmbH',
        CAPTION      => 'VQ32-1T',
        SERIAL       => '00000001',
        DESCRIPTION  => '40/2006',
    },
    'lcd.viewsonic-vx715' => {
        MANUFACTURER => 'ViewSonic Corporation',
        CAPTION      => 'VX715',
        SERIAL       => 'P21044404507',
        DESCRIPTION  => '44/2004'
    },
    'lcd.internal' => {
        MANUFACTURER => 'Toshiba Corporation',
        CAPTION      => 'Internal LCD',
        SERIAL       => '00000004',
        DESCRIPTION  => '14/2006'
    },
    'IMP2262' => {
        MANUFACTURER => 'Impression Products Incorporated',
        CAPTION      => '*22W1*',
        SERIAL       => '74701944',
        DESCRIPTION  => '47/2007'
    },
    'EV2785' => {
        MANUFACTURER => 'Eizo Nanao Corporation',
        CAPTION      => 'EV2785',
        SERIAL       => "68056070",
        DESCRIPTION  => '28/2020'
    },
    'samsung-s22e390' => {
        MANUFACTURER => 'Samsung Electric Company',
        CAPTION      => 'S22E390',
        SERIAL       => "809585995",
        DESCRIPTION  => '33/2016'
    },
);

plan tests => (scalar keys %edid_tests) + 1;

foreach my $test (sort keys %edid_tests) {
    my $file = "resources/generic/edid/$test";
    my $edid = getAllLines(file => $file)
        or die "Can't read $file: $!\n";
    my $info = GLPI::Agent::Task::Inventory::Generic::Screen::_getEdidInfo(edid => $edid, datadir => './share');
    cmp_deeply($info, $edid_tests{$test}, $test);
}
