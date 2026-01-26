## Disabling debug package
%global debug_package %{nil}

%global perl_vendorarch     %(perl -MConfig -e 'print $Config{installvendorarch}')
%global iec61850_opts       %(perl -MConfig -e 'print join(" ", @Config{qw(ccflags optimize cccdlflags)}, "-I$Config{archlib}/CORE")')
%global iec61850_hardening  -fstack-protector-strong -D_FORTIFY_SOURCE=2
%global iec61850_ldopts     -Wl,-z,relro,-z,now -D_FORTIFY_SOURCE=2

Name:        glpi-agent-iec61850
Summary:     iec61850 library perl interface for glpi-agent
Group:       Applications/System
License:     GPLv2+
URL:         https://glpi-project.org/

Version:     %{version}
Release:     %{?rev}%{?dist}
Source0:     libiec61850-%{iec61850_version}.tar.gz

Requires:    glpi-agent-task-network = %{version}-%{release}

BuildRequires: coreutils
#BuildRequires: findutils
BuildRequires: make
BuildRequires: perl-generators
BuildRequires: perl-interpreter
BuildRequires: perl(Config)
#BuildRequires: perl(English)
#BuildRequires: perl(strict)
#BuildRequires: perl(warnings)
#BuildRequires: sed
BuildRequires: swig

%description
This package enables iec61850 protocol support for GLPI agent netdiscovery task

%prep
%setup -q -n libiec61850-%{iec61850_version}
%build
make %{?_smp_mflags} CFLAGS="-fPIC -O2 %{iec61850_hardening}" CPP_FLAGS="%{iec61850_ldopts}"
swig -Wall -O -Isrc/common/inc -Isrc/iec61850/inc -Isrc/mms/inc -Isrc/goose -perl5 iec61850-perl/iec61850.i
gcc %{iec61850_hardening} -c iec61850-perl/iec61850_wrap.c -Isrc/common/inc -Isrc/iec61850/inc -Isrc/mms/inc -Ihal/inc -Isrc/logging -Isrc/r_session %{iec61850_opts} -fmax-errors=5 -Wno-deprecated-declarations -o iec61850-perl/iec61850_wrap.o
gcc -shared %{iec61850_ldopts} iec61850-perl/iec61850_wrap.o build/libiec61850.a -o iec61850-perl/iec61850.so

%install
rm -rf %{buildroot}
make install DESTDIR=%{buildroot}

#%{_fixperms} %{buildroot}/*

# Install iec61850 support
install -m 755 -D iec61850-perl/iec61850.so %{buildroot}%{perl_vendorarch}/auto/iec61850/iec61850.so
install -m 644 -D iec61850-perl/iec61850.pm %{buildroot}%{perl_vendorarch}/iec61850.pm

%check
#make test

%files
%{perl_vendorarch}/auto/iec61850/iec61850.so
%{perl_vendorarch}/iec61850.pm

%changelog
* Mon Jan 26 2026 Guillaume Bougard <gbougard AT teclib DOT com>
- Perl library dedicated to glpi-agent usage with embbeded libiec61850 
