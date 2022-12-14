#!/usr/bin/perl

use strict;
use warnings;

use Test::Deep;
use Test::More;

use GLPI::Agent::Tools::Linux;

my %udev_tests = (
    'ssd' => {
        NAME         => 'sda',
        FIRMWARE     => 'VBM24DQ1',
        SCSI_UNID    => '0',
        SERIALNUMBER => 'DFW1W11002SE002B3117',
        TYPE         => 'disk',
        SCSI_CHID    => '0',
        SCSI_COID    => '0',
        SCSI_LUN     => '0',
        DESCRIPTION  => 'ata',
        MODEL        => 'SAMSUNG_SSD_PM800_TM_128GB'
    },
);

my %cpuinfo_tests = (
    'linux-686-1' => [
        {
            'cache size' => '2048 KB',
            'clflush size' => '64',
            'model' => '13',
            'cpu family' => '6',
            'bogomips' => '3462.27',
            'hlt_bug' => 'no',
            'stepping' => '8',
            'cpuid level' => '2',
            'flags' => 'fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat clflush dts acpi mmx fxsr sse sse2 ss tm pbe nx bts est tm2',
            'cpu mhz' => '1729.038',
            'processor' => '0',
            'vendor_id' => 'GenuineIntel',
            'model name' => 'Intel(R) Pentium(R) M processor 1.73GHz',
            'fpu' => 'yes',
            'f00f_bug' => 'no',
            'fpu_exception' => 'yes',
            'fdiv_bug' => 'no',
            'coma_bug' => 'no',
            'wp' => 'yes'
        },
    ],
    'linux-686-samsung-nc10-1' => [
        {
            'cache size' => '512 KB',
            'address sizes' => '32 bits physical, 32 bits virtual',
            'clflush size' => '64',
            'physical id' => '0',
            'model' => '28',
            'cpu family' => '6',
            'bogomips' => '3192.60',
            'hlt_bug' => 'no',
            'cache_alignment' => '64',
            'stepping' => '2',
            'cpuid level' => '10',
            'core id' => '0',
            'flags' => 'fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe constant_tsc arch_perfmon pebs bts aperfmperf pni dtes64 monitor ds_cpl est tm2 ssse3 xtpr pdcm movbe lahf_lm',
            'cpu mhz' => '800.000',
            'processor' => '0',
            'vendor_id' => 'GenuineIntel',
            'cpu cores' => '1',
            'initial apicid' => '0',
            'model name' => 'Intel(R) Atom(TM) CPU N270 @ 1.60GHz',
            'fpu' => 'yes',
            'siblings' => '2',
            'apicid' => '0',
            'fpu_exception' => 'yes',
            'f00f_bug' => 'no',
            'fdiv_bug' => 'no',
            'wp' => 'yes',
            'coma_bug' => 'no'
          },
          {
            'cache size' => '512 KB',
            'address sizes' => '32 bits physical, 32 bits virtual',
            'clflush size' => '64',
            'physical id' => '0',
            'model' => '28',
            'cpu family' => '6',
            'bogomips' => '3192.61',
            'hlt_bug' => 'no',
            'cache_alignment' => '64',
            'stepping' => '2',
            'cpuid level' => '10',
            'core id' => '0',
            'flags' => 'fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe constant_tsc arch_perfmon pebs bts aperfmperf pni dtes64 monitor ds_cpl est tm2 ssse3 xtpr pdcm movbe lahf_lm',
            'cpu mhz' => '800.000',
            'processor' => '1',
            'vendor_id' => 'GenuineIntel',
            'cpu cores' => '1',
            'initial apicid' => '1',
            'model name' => 'Intel(R) Atom(TM) CPU N270 @ 1.60GHz',
            'fpu' => 'yes',
            'siblings' => '2',
            'apicid' => '1',
            'fpu_exception' => 'yes',
            'f00f_bug' => 'no',
            'fdiv_bug' => 'no',
            'wp' => 'yes',
            'coma_bug' => 'no'
        }
    ],
    'linux-alpha-1' => [
        {
            'platform string' => 'AlphaServer ES45 Model 3B',
            'system serial number' => 'AY31001636',
            'cpus detected' => '3',
            'page size [bytes]' => '8192',
            'bogomips' => '2484.04',
            'phys. address bits' => '44',
            'cpus active' => '3',
            'l2 cache' => 'n/a',
            'cpu variation' => '7',
            'system variation' => 'Privateer',
            'user unaligned acc' => '0 (pc=0,va=0)',
            'kernel unaligned acc' => '0 (pc=0,va=0)',
            'system type' => 'Titan',
            'cycle frequency [hz]' => '1250000000',
            'l1 icache' => '64K, 2-way, 64b line',
            'system revision' => '0',
            'l3 cache' => 'n/a',
            'cpu serial number' => 'JA30502089',
            'cpu' => 'Alpha',
            'cpu active mask' => '0000000000000007',
            'l1 dcache' => '64K, 2-way, 64b line',
            'cpu model' => 'EV68CB',
            'timer frequency [hz]' => '1024.00',
            'cpu revision' => '0',
            'max. addr. space #' => '255'
        }
    ],
    'linux-armel-1' => [
        {
            'd size' => '32768',
            'i line length' => '32',
            'cpu variant' => '0x0',
            'i sets' => '32',
            'features' => 'swp half fastmult edsp',
            'i size' => '32768',
            'bogomips' => '593.10',
            'cpu implementer' => '0x69',
            'd sets' => '32',
            'processor' => 'XScale-80219 rev 0 (v5l)',
            'cpu architecture' => '5TE',
            'd line length' => '32',
            'cache type' => 'undefined 5',
            'cache clean' => 'undefined 5',
            'd assoc' => '32',
            'i assoc' => '32',
            'cache lockdown' => 'undefined 5',
            'cache format' => 'Harvard',
            'cpu revision' => '0',
            'cpu part' => '0x2e3'
        },
    ],
    'linux-armel-3' => [
        {
            'bogomips' => '2.00',
            'cpu architecture' => '7',
            'cpu implementer' => '0x41',
            'cpu part' => '0xb76',
            'cpu revision' => '7',
            'cpu variant' => '0x0',
            'features' => 'swp half thumb fastmult vfp edsp java tls',
            'model name' => 'ARMv6-compatible processor rev 7 (v6l)',
            'processor' => '0',
        }
    ],
    'linux-ia64-1' => [
        {
            'cpu mhz' => '1600.000009',
            'features' => 'branchlong',
            'archrev' => '0',
            'arch' => 'IA-64',
            'processor' => '0',
            'model' => '2',
            'cpu regs' => '4',
            'siblings' => '1',
            'bogomips' => '2392.06',
            'itc mhz' => '1600.009464',
            'cpu number' => '0',
            'revision' => '1',
            'vendor' => 'GenuineIntel',
            'family' => 'Itanium 2'
        },
        {
            'cpu mhz' => '1600.000009',
            'features' => 'branchlong',
            'archrev' => '0',
            'arch' => 'IA-64',
            'processor' => '1',
            'model' => '2',
            'cpu regs' => '4',
            'siblings' => '1',
            'bogomips' => '2392.06',
            'itc mhz' => '1600.009464',
            'cpu number' => '0',
            'revision' => '1',
            'vendor' => 'GenuineIntel',
            'family' => 'Itanium 2'
        }
    ],
    'linux-mips-1' => [
        {
            'vcei exceptions' => '9972559',
            'processor' => '0',
            'cpu model' => 'R4400SC V5.0 FPU V0.0',
            'vced exceptions' => '640580539',
            'microsecond timers' => 'yes',
            'wait instruction' => 'no',
            'bogomips' => '74.75',
            'shadow register sets' => '1',
            'tlb_entries' => '48',
            'hardware watchpoint' => 'yes',
            'system type' => 'SGI Indigo2',
            'extra interrupt vector' => 'no'
        }
    ],
    'linux-ppc-1' => [
        {
            'l2 cache' => '512KiB, parity disabled SRAM:synchronous, pipelined, no parity',
            'revision' => '49.2 (pvr 0009 3102)',
            'cpu' => '604r',
            'clock' => '???',
            'processor' => '0',
            'machine' => 'PReP Utah (Powerstack II Pro4000)',
            'bogomips' => '299.00'
          }
    ],
    'linux-ppc-2' => [
        {
            'revision' => '2.1',
            'cpu' => 'POWER4+ (gq)',
            'clock' => '1452.000000MHz',
            'processor' => '0'
        },
        {
            'revision' => '2.1',
            'cpu' => 'POWER4+ (gq)',
            'clock' => '1452.000000MHz',
            'processor' => '1'
        },
    ],
    'linux-ppc-3' => [
        {
            'revision' => '3.1 (pvr 003c 0301)',
            'cpu' => 'PPC970FX, altivec supported',
            'clock' => '2700.000000MHz',
            'processor' => '0'
        },
        {
            'revision' => '3.1 (pvr 003c 0301)',
            'cpu' => 'PPC970FX, altivec supported',
            'clock' => '2700.000000MHz',
            'processor' => '1'
        }
    ],
    'linux-sparc-1' => [
        {
            'cpu1clktck' => '000000003bb94e80',
            'cpu' => 'TI UltraSparc IIIi (Jalapeno)',
            'i$ parity tl1' => '0',
            'fpu' => 'UltraSparc IIIi integrated FPU',
            'mmu type' => 'Cheetah+',
            'cpu0clktck' => '000000003bb94e80',
            'd$ parity tl1' => '0',
            'prom' => 'OBP 4.13.2 2004/03/29 10:11',
            'cpu1' => 'online',
            'type' => 'sun4u',
            'ncpus active' => '2',
            'ncpus probed' => '2',
            'cpu0' => 'online'
          },
          ],
    'linux-2.6.35-1-core-2-thread' => [
          {
            'cache size' => '512 KB',
            'address sizes' => '32 bits physical, 32 bits virtual',
            'clflush size' => '64',
            'physical id' => '0',
            'model' => '28',
            'cpu family' => '6',
            'bogomips' => '3192.08',
            'hlt_bug' => 'no',
            'cpu mhz' => '800.000',
            'cache_alignment' => '64',
            'stepping' => '2',
            'cpuid level' => '10',
            'core id' => '0',
            'flags' => 'fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe constant_tsc arch_perfmon pebs bts aperfmperf pni dtes64 monitor ds_cpl est tm2 ssse3 xtpr pdcm movbe lahf_lm',
            'processor' => '0',
            'vendor_id' => 'GenuineIntel',
            'cpu cores' => '1',
            'initial apicid' => '0',
            'model name' => 'Intel(R) Atom(TM) CPU N270 @ 1.60GHz',
            'fpu' => 'yes',
            'siblings' => '2',
            'apicid' => '0',
            'fpu_exception' => 'yes',
            'f00f_bug' => 'no',
            'fdiv_bug' => 'no',
            'wp' => 'yes',
            'coma_bug' => 'no'
          },
          {
            'cache size' => '512 KB',
            'address sizes' => '32 bits physical, 32 bits virtual',
            'clflush size' => '64',
            'physical id' => '0',
            'model' => '28',
            'cpu family' => '6',
            'bogomips' => '3191.96',
            'hlt_bug' => 'no',
            'cpu mhz' => '800.000',
            'cache_alignment' => '64',
            'stepping' => '2',
            'cpuid level' => '10',
            'core id' => '0',
            'flags' => 'fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe nx constant_tsc arch_perfmon pebs bts aperfmperf pni dtes64 monitor ds_cpl est tm2 ssse3 xtpr pdcm movbe lahf_lm',
            'processor' => '1',
            'vendor_id' => 'GenuineIntel',
            'cpu cores' => '1',
            'initial apicid' => '1',
            'model name' => 'Intel(R) Atom(TM) CPU N270 @ 1.60GHz',
            'fpu' => 'yes',
            'siblings' => '2',
            'apicid' => '1',
            'fpu_exception' => 'yes',
            'f00f_bug' => 'no',
            'fdiv_bug' => 'no',
            'wp' => 'yes',
            'coma_bug' => 'no'
          }
        ],
        'linux-hp-dl180' => [
          {
            'cache size' => '4096 KB',
            'address sizes' => '40 bits physical, 48 bits virtual',
            'clflush size' => '64',
            'physical id' => '1',
            'model' => '26',
            'cpu family' => '6',
            'bogomips' => '4000.18',
            'hlt_bug' => 'no',
            'cpu mhz' => '2000.090',
            'cache_alignment' => '64',
            'stepping' => '5',
            'cpuid level' => '11',
            'core id' => '0',
            'flags' => 'fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe nx rdtscp lm con$',
            'processor' => '0',
            'vendor_id' => 'GenuineIntel',
            'cpu cores' => '4',
            'initial apicid' => '16',
            'model name' => 'Intel(R) Xeon(R) CPU E5504 @ 2.00GHz',
            'fpu' => 'yes',
            'siblings' => '4',
            'apicid' => '16',
            'fpu_exception' => 'yes',
            'f00f_bug' => 'no',
            'fdiv_bug' => 'no',
            'wp' => 'yes',
            'coma_bug' => 'no'
          },
          {
            'cache size' => '4096 KB',
            'address sizes' => '40 bits physical, 48 bits virtual',
            'clflush size' => '64',
            'physical id' => '1',
            'model' => '26',
            'cpu family' => '6',
            'bogomips' => '4000.00',
            'hlt_bug' => 'no',
            'cpu mhz' => '2000.090',
            'cache_alignment' => '64',
            'stepping' => '5',
            'cpuid level' => '11',
            'core id' => '1',
            'flags' => 'fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe nx rdtscp lm con$',
            'processor' => '1',
            'vendor_id' => 'GenuineIntel',
            'cpu cores' => '4',
            'initial apicid' => '18',
            'model name' => 'Intel(R) Xeon(R) CPU E5504 @ 2.00GHz',
            'fpu' => 'yes',
            'siblings' => '4',
            'apicid' => '18',
            'fpu_exception' => 'yes',
            'f00f_bug' => 'no',
            'fdiv_bug' => 'no',
            'wp' => 'yes',
            'coma_bug' => 'no'
          },
          {
            'cache size' => '4096 KB',
            'address sizes' => '40 bits physical, 48 bits virtual',
            'clflush size' => '64',
            'physical id' => '1',
            'model' => '26',
            'cpu family' => '6',
            'bogomips' => '4000.00',
            'hlt_bug' => 'no',
            'cpu mhz' => '2000.090',
            'cache_alignment' => '64',
            'stepping' => '5',
            'cpuid level' => '11',
            'core id' => '2',
            'flags' => 'fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe nx rdtscp lm con$',
            'processor' => '2',
            'vendor_id' => 'GenuineIntel',
            'cpu cores' => '4',
            'initial apicid' => '20',
            'model name' => 'Intel(R) Xeon(R) CPU E5504 @ 2.00GHz',
            'fpu' => 'yes',
            'siblings' => '4',
            'apicid' => '20',
            'fpu_exception' => 'yes',
            'f00f_bug' => 'no',
            'fdiv_bug' => 'no',
            'wp' => 'yes',
            'coma_bug' => 'no'
          }
        ],
        'toshiba-r630-2-core' => [
          {
            'cache size' => '3072 KB',
            'address sizes' => '36 bits physical, 48 bits virtual',
            'clflush size' => '64',
            'physical id' => '0',
            'model' => '37',
            'cpu family' => '6',
            'bogomips' => '4521.44',
            'cpu mhz' => '933.000',
            'cache_alignment' => '64',
            'stepping' => '5',
            'core id' => '0',
            'cpuid level' => '11',
            'flags' => 'fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm sse4_1 sse4_2 popcnt lahf_lm arat tpr_shadow vnmi flexpriority ept vpid',
            'processor' => '0',
            'vendor_id' => 'GenuineIntel',
            'cpu cores' => '2',
            'initial apicid' => '0',
            'model name' => 'Intel(R) Core(TM) i3 CPU M 350 @ 2.27GHz',
            'fpu' => 'yes',
            'siblings' => '4',
            'apicid' => '0',
            'fpu_exception' => 'yes',
            'wp' => 'yes'
          },
          {
            'cache size' => '3072 KB',
            'address sizes' => '36 bits physical, 48 bits virtual',
            'clflush size' => '64',
            'physical id' => '0',
            'model' => '37',
            'cpu family' => '6',
            'bogomips' => '4521.44',
            'cpu mhz' => '933.000',
            'cache_alignment' => '64',
            'stepping' => '5',
            'core id' => '0',
            'cpuid level' => '11',
            'flags' => 'fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm sse4_1 sse4_2 popcnt lahf_lm arat tpr_shadow vnmi flexpriority ept vpid',
            'processor' => '1',
            'vendor_id' => 'GenuineIntel',
            'cpu cores' => '2',
            'initial apicid' => '1',
            'model name' => 'Intel(R) Core(TM) i3 CPU M 350 @ 2.27GHz',
            'fpu' => 'yes',
            'siblings' => '4',
            'apicid' => '1',
            'fpu_exception' => 'yes',
            'wp' => 'yes'
          },
          {
            'cache size' => '3072 KB',
            'address sizes' => '36 bits physical, 48 bits virtual',
            'clflush size' => '64',
            'physical id' => '0',
            'model' => '37',
            'cpu family' => '6',
            'bogomips' => '4521.44',
            'cpu mhz' => '933.000',
            'cache_alignment' => '64',
            'stepping' => '5',
            'core id' => '2',
            'cpuid level' => '11',
            'flags' => 'fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm sse4_1 sse4_2 popcnt lahf_lm arat tpr_shadow vnmi flexpriority ept vpid',
            'processor' => '2',
            'vendor_id' => 'GenuineIntel',
            'cpu cores' => '2',
            'initial apicid' => '4',
            'model name' => 'Intel(R) Core(TM) i3 CPU M 350 @ 2.27GHz',
            'fpu' => 'yes',
            'siblings' => '4',
            'apicid' => '4',
            'fpu_exception' => 'yes',
            'wp' => 'yes'
          },
          {
            'cache size' => '3072 KB',
            'address sizes' => '36 bits physical, 48 bits virtual',
            'clflush size' => '64',
            'physical id' => '0',
            'model' => '37',
            'cpu family' => '6',
            'bogomips' => '4521.44',
            'cpu mhz' => '933.000',
            'cache_alignment' => '64',
            'stepping' => '5',
            'core id' => '2',
            'cpuid level' => '11',
            'flags' => 'fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx rdtscp lm constant_tsc arch_perfmon pebs bts rep_good xtopology nonstop_tsc aperfmperf pni dtes64 monitor ds_cpl vmx est tm2 ssse3 cx16 xtpr pdcm sse4_1 sse4_2 popcnt lahf_lm arat tpr_shadow vnmi flexpriority ept vpid',
            'processor' => '3',
            'vendor_id' => 'GenuineIntel',
            'cpu cores' => '2',
            'initial apicid' => '5',
            'model name' => 'Intel(R) Core(TM) i3 CPU M 350 @ 2.27GHz',
            'fpu' => 'yes',
            'siblings' => '4',
            'apicid' => '5',
            'fpu_exception' => 'yes',
            'wp' => 'yes'
          }
    ],
    'rhel-6.3-esx-1vcpu' => [
        {
            'flags' => 'fpu vme de pse tsc msr pae mce cx8 apic mtrr pge mca cmov pat pse36 clflush dts mmx fxsr sse sse2 ss syscall nx rdtscp lm constant_tsc up arch_perfmon pebs bts xtopology tsc_reliable nonstop_tsc aperfmperf unfair_spinlock pni pclmulqdq ssse3 cx16 sse4_1 sse4_2 x2apic popcnt aes xsave avx hypervisor lahf_lm ida arat epb xsaveopt pln pts dts',
            'stepping' => '7',
            'wp' => 'yes',
            'cpu family' => '6',
            'cpu mhz' => '2694.293',
            'model' => '42',
            'fpu' => 'yes',
            'vendor_id' => 'GenuineIntel',
            'address sizes' => '40 bits physical, 48 bits virtual',
            'cpuid level' => '13',
            'fpu_exception' => 'yes',
            'cache_alignment' => '64',
            'cache size' => '6144 KB',
            'model name' => 'Intel(R) Core(TM) i5-2500S CPU @ 2.70GHz',
            'clflush size' => '64',
            'bogomips' => '5388.58',
            'processor' => '0'
        }
    ]
);

my %hal_tests = (
    'dell-xt2' => [
        {
            NAME         => 'sda',
            FIRMWARE     => 'VBM24DQ1',
            DISKSIZE     => 122104,
            MANUFACTURER => 'ATA',
            MODEL        => 'SAMSUNG SSD PM80',
            SERIALNUMBER => 'SAMSUNG_SSD_PM800_TM_128GB_DFW1W11002SE002B3117',
            TYPE         => 'disk'
        }
    ]
);

my %smartctl_tests = (
    sample1 => {
        TYPE         => 'disk',
        DESCRIPTION  => 'SATA',
        SERIALNUMBER => 'DFW1W11002SE002B3117',
        DISKSIZE     => 128035,
        MANUFACTURER => 'Samsung',
        FIRMWARE     => 'VBM24D1Q',
        MODEL        => 'SAMSUNG SSD PM800 TM 128GB',
    },
    sample2 => {
        TYPE         => 'disk',
        DESCRIPTION  => 'SATA',
    },
    sample3 => {
        TYPE         => 'disk',
        DESCRIPTION  => 'SAS',
        SERIALNUMBER => '3LM0L0FJ00009733Y46W',
        INTERFACE    => 'SAS',
    },
    sample4 => {
        TYPE         => 'enclosure',
        DESCRIPTION  => 'SATA',
    },
    sample5 => {
        DESCRIPTION  => 'SATA',
        TYPE         => 'disk',
        DISKSIZE     => 480103,
        MANUFACTURER => 'Micron',
        FIRMWARE     => 'D1DF003',
        MODEL        => 'MTFDDAK480TDC',
        SERIALNUMBER => '202028413FA9',
        INTERFACE    => 'SATA',
        WWN          => '500a075128413fa9',
    },
    sample6 => {
        MANUFACTURER => 'Hewlett-Packard',
        DESCRIPTION  => 'SAS',
        SERIALNUMBER => 'EA01PB107H5K1103',
        MODEL        => 'EG0600FBDSR',
        DISKSIZE     => 600127,
        FIRMWARE     => 'HPD2',
        TYPE         => 'disk',
        INTERFACE    => 'SAS',
    },
    sample7 => {
        TYPE         => 'disk',
        DISKSIZE     => 11756399,
        MODEL        => 'HUH721212AL5200',
        SERIALNUMBER => 'D5G7WG8L',
        DESCRIPTION  => 'SAS',
        FIRMWARE     => 'NS07',
        MANUFACTURER => 'Hitachi',
        INTERFACE    => 'SAS',
    },
    sample8 => {
        TYPE         => 'disk',
        DISKSIZE     => 480103,
        MODEL        => 'OCZ-VECTOR150',
        SERIALNUMBER => 'A21WN061452000199',
        DESCRIPTION  => 'SATA',
        FIRMWARE     => '1.2',
        MANUFACTURER => 'Indilinx',
        INTERFACE    => 'SATA',
        WWN          => '5e83a9710002cb71',
    },
    sample9 => {
        TYPE         => 'CD',
        DISKSIZE     => 7757100351738,
        MODEL        => 'DVD',
        FIRMWARE     => '1HE3',
        DESCRIPTION  => 'SATA',
        MANUFACTURER => 'Hewlett-Packard'
    },
);

my %ifconfig_tests = (
    'dell-xt2' => [
        {
            MACADDR     => 'A4:BA:DB:A5:F5:FA',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            DESCRIPTION => 'eth0',
            IPMASK      => '255.255.255.0',
            IPADDRESS   => '192.168.0.5',
            IPADDRESS6  => 'fe80::a6ba:dbff:fea5:f5fa/64'
        },
        {
            DESCRIPTION => 'lo',
            STATUS      => 'Up',
            TYPE        => undef,
            IPMASK      => '255.0.0.0',
            IPADDRESS   => '127.0.0.1',
            IPADDRESS6  => '::1/128',
        },
        {
            MACADDR     => '4E:8C:81:ED:9B:35',
            DESCRIPTION => 'pan0',
            STATUS      => 'Down',
            TYPE        => 'ethernet',
        },
        {
            DESCRIPTION => 'sit0',
            STATUS      => 'Down',
            TYPE        => undef,
        },
        {
            MACADDR     => '00:24:D6:6F:81:3A',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            DESCRIPTION => 'wlan0',
            IPMASK      => '255.255.192.0',
            IPADDRESS   => '78.251.91.204',
            IPADDRESS6  => 'fe80::224:d6ff:fe6f:813a/64'
        }
    ],
    'linux-bonding' => [
        {
            IPMASK      => '255.255.255.0',
            MACADDR     => '00:50:56:AD:00:0E',
            DESCRIPTION => 'bond0',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            IPADDRESS6  => 'fe80::250:56ff:fead:e/64',
            IPADDRESS   => '192.168.1.181'
        },
        {
            MACADDR     => '00:50:56:AD:00:0E',
            DESCRIPTION => 'eth0',
            STATUS      => 'Up',
            TYPE        => 'ethernet'
        },
        {
            IPMASK      => '255.0.0.0',
            DESCRIPTION => 'lo',
            STATUS      => 'Up',
            TYPE        => undef,
            IPADDRESS6  => '::1/128',
            IPADDRESS   => '127.0.0.1'
        }
    ],
    'linux-rhel5.6' => [
        {
            IPMASK      => '255.255.252.0',
            MACADDR     => '00:1E:68:2F:85:D8',
            DESCRIPTION => 'eth0',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            IPADDRESS6  => 'fe80::21e:68ff:fe2f:85d8/64',
            IPADDRESS   => '10.202.0.31'
        },
        {
            IPMASK      => '255.0.0.0',
            DESCRIPTION => 'lo',
            STATUS      => 'Up',
            TYPE        => undef,
            IPADDRESS6  => '::1/128',
            IPADDRESS   => '127.0.0.1'
        },
        {
            MACADDR     => '00:1E:68:2F:85:D8',
            DESCRIPTION => 'peth0',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            IPADDRESS6  => 'fe80::21e:68ff:fe2f:85d8/64'
        },
        {
            MACADDR     => 'FE:FF:FF:FF:FF:FF',
            DESCRIPTION => 'vif1.0',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            IPADDRESS6  => 'fe80::fcff:ffff:feff:ffff/64'
        },
        {
            MACADDR     => 'FE:FF:FF:FF:FF:FF',
            DESCRIPTION => 'vif2.0',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            IPADDRESS6  => 'fe80::fcff:ffff:feff:ffff/64'
        },
        {
            MACADDR     => 'FE:FF:FF:FF:FF:FF',
            DESCRIPTION => 'vif3.0',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            IPADDRESS6  => 'fe80::fcff:ffff:feff:ffff/64'
        },
        {
            MACADDR     => 'FE:FF:FF:FF:FF:FF',
            DESCRIPTION => 'vif4.0',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            IPADDRESS6  => 'fe80::fcff:ffff:feff:ffff/64'
        },
        {
            MACADDR     => 'FE:FF:FF:FF:FF:FF',
            DESCRIPTION => 'vif5.0',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            IPADDRESS6  => 'fe80::fcff:ffff:feff:ffff/64'
        },
        {
            MACADDR     => 'FE:FF:FF:FF:FF:FF',
            DESCRIPTION => 'vif6.0',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            IPADDRESS6  => 'fe80::fcff:ffff:feff:ffff/64'
        }
    ],
    'linux-fc17' => [
        {
            IPMASK      => '255.255.0.0',
            MACADDR     => '00:23:ae:8c:33:b6',
            DESCRIPTION => 'em1',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
            IPADDRESS6  => 'fe80::223:aeff:fe8c:33b6',
            IPADDRESS   => '10.1.65.145'
        }
    ],
    'linux-el8' => [
        {
            DESCRIPTION => 'docker0',
            IPADDRESS   => '172.17.0.1',
            IPMASK      => '255.255.0.0',
            MACADDR     => '02:42:0c:d5:0f:d7',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
        },
        {
            DESCRIPTION => 'eth0',
            MACADDR     => 'e4:11:5b:ed:36:0c',
            STATUS      => 'Up',
            TYPE        => 'ethernet'
        },
        {
            DESCRIPTION => 'eth1',
            TYPE        => 'ethernet',
            STATUS      => 'Down',
            MACADDR     => 'e4:11:5b:ed:36:38'
        },
        {
            DESCRIPTION => 'eth2',
            MACADDR     => 'e4:11:5b:ed:36:0e',
            STATUS      => 'Down',
            TYPE        => 'ethernet',
        },
        {
            DESCRIPTION => 'eth3',
            STATUS      => 'Down',
            TYPE        => 'ethernet',
            MACADDR     => 'e4:11:5b:ed:36:3a'
        },
        {
            DESCRIPTION => 'eth0:srv',
            IPADDRESS   => '10.10.220.100',
            IPMASK      => '255.255.255.255',
            MACADDR     => 'e4:11:5b:ed:36:0c',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
        },
        {
            DESCRIPTION => 'lo',
            IPADDRESS6  => '::1',
            STATUS      => 'Up',
        },
        {
            DESCRIPTION => 'macvlan0',
            IPADDRESS   => '10.10.220.101',
            IPADDRESS6  => 'fe80::260f:e9bb:60de:58f4',
            IPMASK      => '255.255.255.0',
            MACADDR     => '4e:05:62:03:69:e7',
            STATUS      => 'Up',
            TYPE        => 'ethernet',
        }
    ]
);

my %ipaddrshow_tests = (
    'ip_addr-1' => [
        {
            DESCRIPTION => 'lo',
            MACADDR     => '00:00:00:00:00:00',
            STATUS      => 'Up',
            IPADDRESS   => '127.0.0.1',
            IPSUBNET    => '127.0.0.0',
            IPMASK      => '255.0.0.0',
        },
        {
            DESCRIPTION => 'lo',
            MACADDR     => '00:00:00:00:00:00',
            STATUS      => 'Up',
            IPADDRESS6  => '::1',
            IPSUBNET6   => '::',
            IPMASK6     => 'fff0::',
        },
        {
            DESCRIPTION => 'eth0',
            STATUS      => 'Up',
            MACADDR     => '00:23:18:91:db:8d',
            IPADDRESS   => '192.168.0.10',
            IPSUBNET    => '192.168.0.0',
            IPMASK      => '255.255.255.0',
        },
        {
            DESCRIPTION => 'eth0',
            MACADDR     => '00:23:18:91:db:8d',
            STATUS      => 'Up',
            IPADDRESS6  => '2a01:e34:ef9c:64d0:223:18ff:fe91:db8d',
            IPSUBNET6   => '2a01:e34:ef9c:64d0::',
            IPMASK6     => 'ffff:ffff:ffff:ffff::',
        },
        {
            DESCRIPTION => 'eth0',
            MACADDR     => '00:23:18:91:db:8d',
            STATUS      => 'Up',
            IPADDRESS6  => 'fe80::223:18ff:fe91:db8d',
            IPSUBNET6   => 'fe80::',
            IPMASK6     => 'ffff:ffff:ffff:ffff::',
        },
        {
            DESCRIPTION => 'tun0',
            MACADDR     => undef,
            STATUS      => 'Up',
            IPADDRESS   => '192.168.41.6',
            IPSUBNET    => undef,
            IPMASK      => undef,
        },
        {
            DESCRIPTION => 'tun1',
            MACADDR     => undef,
            STATUS      => 'Up',
            IPADDRESS   => '192.168.222.14',
            IPSUBNET    => undef,
            IPMASK      => undef,
        },
        {
            DESCRIPTION => 'wlan0',
            MACADDR     => 'e8:39:df:3f:7d:ef',
            STATUS      => 'Up',
        },
        {
            DESCRIPTION => 'tap0',
            MACADDR     => '8a:84:99:29:46:05',
            STATUS      => 'Up',
            IPADDRESS   => '172.28.218.101',
            IPSUBNET    => '172.28.218.0',
            IPMASK      => '255.255.255.0',
        },
        {
            DESCRIPTION => 'tap0',
            MACADDR     => '8a:84:99:29:46:05',
            STATUS      => 'Up',
            IPADDRESS6  => 'fe80::8884:99ff:fe29:4605',
            IPSUBNET6   => 'fe80::',
            IPMASK6     => 'ffff:ffff:ffff:ffff::',
        }
    ],
    'ip_addr-2' => [
        {
            DESCRIPTION => 'lo',
            MACADDR     => '00:00:00:00:00:00',
            STATUS      => 'Up',
            IPADDRESS   => '127.0.0.1',
            IPSUBNET    => '127.0.0.0',
            IPMASK      => '255.0.0.0',
        },
        {
            DESCRIPTION => 'lo',
            MACADDR     => '00:00:00:00:00:00',
            STATUS      => 'Up',
            IPADDRESS6  => '::1',
            IPSUBNET6   => '::',
            IPMASK6     => 'fff0::',
        },
        {
            DESCRIPTION => 'eth0',
            MACADDR     => '0f:0f:0f:0f:0f:0f',
            STATUS      => 'Up',
            IPADDRESS   => '11.11.11.11',
            IPSUBNET    => '11.11.11.0',
            IPMASK      => '255.255.255.128',
        },
        {
            DESCRIPTION => 'eth0',
            MACADDR     => '0f:0f:0f:0f:0f:0f',
            STATUS      => 'Up',
            IPADDRESS   => '172.16.0.201',
            IPSUBNET    => '172.16.0.0',
            IPMASK      => '255.255.128.0',
        },
        {
            DESCRIPTION => 'eth0',
            MACADDR     => '0f:0f:0f:0f:0f:0f',
            STATUS      => 'Up',
            IPADDRESS6  => 'fe80::201:29ff:fed1:feb4',
            IPSUBNET6   => 'fe80::',
            IPMASK6     => 'ffff:ffff:ffff:ffff::',
        },
        {
            DESCRIPTION => 'eql',
            MACADDR     => undef,
            STATUS      => 'Down',
        },
        {
            DESCRIPTION => 'sit0',
            MACADDR     => undef,
            STATUS      => 'Down',
        },
        {
            DESCRIPTION => 'wlan0',
            MACADDR     => '0f:0f:0f:0f:0f:0f',
            STATUS      => 'Up',
        }
    ],
    # RHEL 5.6
    'ip_addr-3' => [
        {
            DESCRIPTION => 'lo',
            MACADDR     => '00:00:00:00:00:00',
            STATUS      => 'Up',
            IPSUBNET    => '127.0.0.0',
            IPMASK      => '255.0.0.0',
            IPADDRESS   => '127.0.0.1',
        },
        {
            DESCRIPTION => 'lo',
            MACADDR     => '00:00:00:00:00:00',
            STATUS      => 'Up',
            IPADDRESS6  => '::1',
            IPSUBNET6   => '::',
            IPMASK6     => 'fff0::',
        },
        {
            DESCRIPTION => 'eth0',
            MACADDR     => '00:50:56:8b:70:b7',
            STATUS      => 'Up',
            IPADDRESS   => '10.40.1.16',
            IPSUBNET    => '10.40.1.0',
            IPMASK      => '255.255.255.0',
        },
        {
            DESCRIPTION => 'eth0',
            MACADDR     => '00:50:56:8b:70:b7',
            STATUS      => 'Up',
            IPADDRESS6  => 'fe80::250:56ff:fe8b:70b7',
            IPSUBNET6   => 'fe80::',
            IPMASK6     => 'ffff:ffff:ffff:ffff::',
        },
        {
            DESCRIPTION => 'sit0',
            MACADDR     => undef,
            STATUS      => 'Down',
        },
    ],
    'ip_addr-4' => [
        {
            DESCRIPTION => 'ib0',
            MACADDR     => 'a0:00:01:00:fe:80:00:00:00:00:00:00:00:02:c9:03:00:15:94:d1',
            STATUS      => 'Up',
            IPADDRESS   => '10.89.96.11',
            IPSUBNET    => '10.89.96.0',
            IPMASK      => '255.255.240.0',
        }
    ],
    'ip_addr-5' => [
        {
            DESCRIPTION => 'lo',
            MACADDR     => '00:00:00:00:00:00',
            STATUS      => 'Up',
            IPSUBNET    => '127.0.0.0',
            IPADDRESS   => '127.0.0.1',
            IPMASK      => '255.0.0.0',
        },
        {
            DESCRIPTION => 'lo',
            MACADDR     => '00:00:00:00:00:00',
            STATUS      => 'Up',
            IPADDRESS6  => '::1',
            IPSUBNET6   => '::',
            IPMASK6     => 'fff0::',
        },
        {
            DESCRIPTION => 'wlan0',
            MACADDR     => '00:1a:6b:0d:78:03',
            STATUS      => 'Up',
            IPADDRESS   => '128.93.189.62',
            IPSUBNET    => '128.93.188.0',
            IPMASK      => '255.255.252.0'
        },
        {
            DESCRIPTION => 'wlan0:0',
            MACADDR     => '00:1a:6b:0d:78:03',
            STATUS      => 'Up',
            IPADDRESS   => '192.168.1.11',
            IPSUBNET    => '192.168.1.0',
            IPMASK      => '255.255.255.0',
        },
        {
            DESCRIPTION => 'wlan0',
            MACADDR     => '00:1a:6b:0d:78:03',
            STATUS      => 'Up',
            IPADDRESS6  => 'fe80::21a:6bff:fe0d:7803',
            IPSUBNET6   => 'fe80::',
            IPMASK6     => 'ffff:ffff:ffff:ffff::'
        },
        {
            DESCRIPTION => 'eth0',
            MACADDR     => 'f0:1f:af:0f:a4:0c',
            STATUS      => 'Up',
        },
        {
            DESCRIPTION => 'eth0:0',
            MACADDR     => 'f0:1f:af:0f:a4:0c',
            STATUS      => 'Up',
            IPADDRESS   => '192.168.1.11',
            IPSUBNET    => '192.168.1.0',
            IPMASK      => '255.255.255.0',
        },
        {
            DESCRIPTION => 'bond0',
            MACADDR     => '8e:b2:64:1a:0b:00',
            STATUS      => 'Up'
        },
        {
            DESCRIPTION => 'br0',
            STATUS      => 'Up',
            MACADDR     => 'aa:4b:c2:02:31:15'
        },
    ],
    'ip_addr-el8' => [
        {
            DESCRIPTION => 'lo',
            MACADDR     => '00:00:00:00:00:00',
            STATUS      => 'Up',
            IPADDRESS   => '127.0.0.1',
            IPSUBNET    => '127.0.0.0',
            IPMASK      => '255.0.0.0',
        },
        {
            DESCRIPTION => 'lo',
            MACADDR     => '00:00:00:00:00:00',
            STATUS      => 'Up',
            IPADDRESS6  => '::1',
            IPSUBNET6   => '::',
            IPMASK6     => 'fff0::',
        },
        {
            DESCRIPTION => 'eth0',
            MACADDR     => 'e4:11:5b:ed:36:0c',
            STATUS      => 'Up',
        },
        {
            DESCRIPTION => 'eth0:srv',
            IPADDRESS   => '10.10.220.100',
            IPSUBNET    => '10.10.220.100',
            IPMASK      => '255.255.255.255',
            MACADDR     => 'e4:11:5b:ed:36:0c',
            STATUS      => 'Up',
        },
        {
            DESCRIPTION => 'eth2',
            STATUS      => 'Down',
            MACADDR     => 'e4:11:5b:ed:36:0e',
        },
        {
            DESCRIPTION => 'eth1',
            STATUS      => 'Down',
            MACADDR     => 'e4:11:5b:ed:36:38',
        },
        {
            DESCRIPTION => 'eth3',
            STATUS      => 'Down',
            MACADDR     => 'e4:11:5b:ed:36:3a',
        },
        {
            DESCRIPTION => 'macvlan0',
            IPADDRESS   => '10.10.220.101',
            IPSUBNET    => '10.10.220.0',
            IPMASK      => '255.255.255.0',
            MACADDR     => '4e:05:62:03:69:e7',
            STATUS      => 'Up',
        },
        {
            DESCRIPTION => 'macvlan0@eth0',
            IPADDRESS6  => 'fe80::260f:e9bb:60de:58f4',
            IPSUBNET6   => 'fe80::',
            IPMASK6     => 'ffff:ffff:ffff:ffff::',
            MACADDR     => '4e:05:62:03:69:e7',
            STATUS      => 'Up',
        },
        {
            DESCRIPTION => 'docker0',
            IPADDRESS   => '172.17.0.1',
            IPMASK      => '255.255.0.0',
            IPSUBNET    => '172.17.0.0',
            MACADDR     => '02:42:0c:d5:0f:d7',
            STATUS      => 'Up',
        },
    ]
);

plan tests =>
    (scalar keys %udev_tests)     +
    (scalar keys %cpuinfo_tests)  +
    (scalar keys %hal_tests)      +
    (scalar keys %smartctl_tests) +
    (scalar keys %ifconfig_tests) +
    (scalar keys %ipaddrshow_tests);

foreach my $test (keys %udev_tests) {
    my $file = "resources/linux/udev/$test";
    my $result = GLPI::Agent::Tools::Linux::_parseUdevEntry(
        file => $file, device => 'sda'
    );
    cmp_deeply($result, $udev_tests{$test}, "$test udev parsing");
}

foreach my $test (keys %cpuinfo_tests) {
    my $file = "resources/linux/proc/cpuinfo/$test";
    my @cpus = getCPUsFromProc(file => $file);
    cmp_deeply(\@cpus, $cpuinfo_tests{$test}, "$test cpuinfo parsing");
}

foreach my $test (keys %hal_tests) {
    my $file = "resources/linux/hal/$test";
    my @devices = getDevicesFromHal(file => $file);
    cmp_deeply(\@devices, $hal_tests{$test}, "$test hal parsing");
}

foreach my $test (keys %smartctl_tests) {
    my $file = "resources/linux/smartctl/$test";
    my $result = getInfoFromSmartctl(file => $file);
    cmp_deeply($result, $smartctl_tests{$test}, "$test smartctl parsing");
}

foreach my $test (keys %ifconfig_tests) {
    my $file = "resources/generic/ifconfig/$test";
    my @interfaces = getInterfacesFromIfconfig(file => $file);
    cmp_deeply(\@interfaces, $ifconfig_tests{$test}, $test);
}

foreach my $test (keys %ipaddrshow_tests) {
    my $file = "resources/linux/ip/$test";
    my @interfaces = getInterfacesFromIp(file => $file);
    cmp_deeply(\@interfaces, $ipaddrshow_tests{$test}, $test);
}
