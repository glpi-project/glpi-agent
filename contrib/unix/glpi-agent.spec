## Disabling debug package
%global debug_package %{nil}

Name:        glpi-agent
Summary:     GLPI inventory agent
Group:       Applications/System
License:     GPLv2+
URL:         https://glpi-project.org/

Version:     %(perl -Ilib -MFusionInventory::Agent::Version -e '$v = $FusionInventory::Agent::Version::VERSION; $v =~ s/-.*//; print $v')
Release:     %{?rev}%{?dist}
Source0:     %{name}-%{version}-%{release}.tar.gz

Requires: perl(LWP)
Requires: perl(Net::SSLeay)
Requires: perl(Proc::Daemon)
Requires: perl(Socket::GetAddrInfo)
#Recommended for inventory module
#Requires: perl(Net::CUPS)
#Requires: perl(Parse::EDID)

BuildArch:   noarch

BuildRequires: coreutils
BuildRequires: findutils
BuildRequires: make
BuildRequires: perl-generators
BuildRequires: perl-interpreter
BuildRequires: perl(Config)
BuildRequires: perl(English)
BuildRequires: perl(inc::Module::Install)
BuildRequires: perl(Module::AutoInstall)
BuildRequires: perl(Module::Install::Include)
BuildRequires: perl(Module::Install::Makefile)
BuildRequires: perl(Module::Install::Metadata)
BuildRequires: perl(Module::Install::Scripts)
BuildRequires: perl(Module::Install::WriteAll)
BuildRequires: perl(strict)
BuildRequires: perl(warnings)
BuildRequires: sed

# excluding internal requires and windows stuff
# excluding perl(setup) and windows stuff
%{?perl_default_filter}
%global __provides_exclude %{?__provides_exclude:%__provides_exclude|}^perl\\(setup\\)$
%global __requires_exclude %{?__requires_exclude:%__requires_exclude|}^perl\\(Win32|setup\\)$

%description
GLPI Agent is an application designed to help a network
or system administrator to keep track of the hardware and software
configurations of computers that are installed on the network.

This agent can send information about the computer to a GLPI server with native
inventory support or with the FusionInventory for GLPI plugin.

You can add additional packages for optional tasks:

* glpi-agent-task-network
    Network Discovery and Inventory
* glpi-agent-inventory
    Local inventory
* glpi-agent-task-deploy
    Package deployment
* glpi-agent-task-esx
    vCenter/ESX/ESXi remote inventory
* glpi-agent-task-collect
    Custom information retrieval
* glpi-agent-task-wakeonlan
    Wake on lan task

You can also install the following package if you prefer to start the agent via
a cron scheduled each hour:
* glpi-agent-cron


%package task-esx
Summary:    vCenter/ESX/ESXi inventoy task for GLPI agent
Requires:   %{name} = %{version}-%{release}

%description task-esx
glpi-agent-task-ESX ask the running service agent to inventory a
VMWare vCenter/ESX/ESXi server through SOAP interface

%package task-network
Summary:    NetDiscovery and NetInventory task for GLPI agent
Requires:   %{name} = %{version}-%{release}

%description task-network
glpi-task-netdiscovery and glpi-task-netinventory

%package task-deploy
Summary:    Software deployment support for GLPI agent
Requires:   %{name} = %{version}-%{release}
Requires:   perl(Archive::Extract)

%description task-deploy
This package provides software deployment support for GLPI agent

%package task-wakeonlan
Summary:    WakeOnLan task for GLPI agent
Requires:   %{name} = %{version}-%{release}

%description task-wakeonlan
glpi-task-wakeonlan

%package task-collect
Summary:    Custom information retrieval support for GLPI agent
Requires:   %{name} = %{version}-%{release}

%description task-collect
This package provides custom information retrieval support for
GLPI agent

%package cron
Summary:    Cron for GLPI agent
Requires:   %{name} = %{version}-%{release}
Requires:   cronie

%description cron
GLPI agent cron task


%prep
%setup -q -n %{name}-%{version}-%{release}

# Remove bundled modules
rm -rf ./inc
# Remove MANIFEST unneeded file (and missing from git clone)
rm -f MANIFEST

# Remove files only used under win32
rm -rf lib/FusionInventory/Agent/Task/WMI*
rm -rf lib/FusionInventory/Agent/Daemon

sed \
    -e "s/logger = .*/logger = syslog/" \
    -e "s/logfacility = .*/logfacility = LOG_DAEMON/" \
    -e 's|#include "conf\.d/"|include "conf\.d/"|' \
    -i etc/agent.cfg

cat <<EOF | tee %{name}.conf
#
# GLPI Agent Configuration File
# used by hourly cron job to override the %{name}.cfg setup.
#
# /!\
# USING THIS FILE TO OVERRIDE SERVICE OPTIONS NO MORE SUPPORTED!
# See %{_unitdir}/%{name}.service notice
#
# Add tools directory if needed (tw_cli, hpacucli, ipssend, ...)
PATH=/sbin:/bin:/usr/sbin:/usr/bin
# Global options (debug for verbose log)
OPTIONS="--debug "

# Mode, change to "cron" to activate
# - none (default on install) no activity
# - cron (inventory only) use the cron.hourly
AGENTMODE[0]=none
# AGENT Inventory or FusionInventory server URI
# AGENTSERVER[0]=your.server.name
# AGENTSERVER[0]=http://your.server.name/front/inventory.php
# AGENTSERVER[0]=http://your.glpiserveur.name/glpi/plugins/fusioninventory/
# corresponds with --local=%{_localstatedir}/lib/%{name}
# AGENTSERVER[0]=local
# Wait before inventory (for cron mode)
AGENTPAUSE[0]=120
# Administrative TAG (optional, must be filed before first inventory)
AGENTTAG[0]=

EOF


%build
perl Makefile.PL \
     PREFIX=%{_prefix} INSTALL_BASE= \
     SYSCONFDIR=%{_sysconfdir}/%{name} \
     LOCALSTATEDIR=%{_localstatedir}/lib/%{name} \
     COMMENTS="Build on $(uname -a),Source time: $(date -u +'%%F %%X UTC' -r %{SOURCE0})"

make %{?_smp_mflags}


%install
rm -rf %{buildroot}
make install DESTDIR=%{buildroot}
find %{buildroot} -type f -name .packlist -exec rm -f {} ';'

%{_fixperms} %{buildroot}/*

mkdir -p %{buildroot}%{_localstatedir}/lib/%{name}
mkdir -p %{buildroot}%{_sysconfdir}/%{name}/conf.d
mkdir -p %{buildroot}%{_sysconfdir}/systemd/system/%{name}.service.d

install -m 644 -D  %{name}.conf                 %{buildroot}%{_sysconfdir}/sysconfig/%{name}
install -m 755 -Dp contrib/unix/%{name}.cron    %{buildroot}%{_sysconfdir}/cron.hourly/%{name}
install -m 644 -D  contrib/unix/%{name}.service %{buildroot}%{_unitdir}/%{name}.service


%check
#make test


%files
%doc Changes LICENSE THANKS
%dir %{_sysconfdir}/%{name}
%config(noreplace) %{_sysconfdir}/%{name}/agent.cfg
%config(noreplace) %{_sysconfdir}/%{name}/conf.d
%config(noreplace) %{_sysconfdir}/%{name}/inventory-server-plugin.cfg
%config(noreplace) %{_sysconfdir}/%{name}/server-test-plugin.cfg
%config(noreplace) %{_sysconfdir}/%{name}/ssl-server-plugin.cfg
%config(noreplace) %{_sysconfdir}/%{name}/proxy-server-plugin.cfg
%config(noreplace) %{_sysconfdir}/%{name}/proxy2-server-plugin.cfg

%{_unitdir}/%{name}.service

%dir %{_sysconfdir}/systemd/system/%{name}.service.d

%{_bindir}/glpi-agent
%{_bindir}/glpi-injector
%{_bindir}/glpi-inventory
%{_bindir}/glpi-remote
%{_mandir}/man1/glpi-agent*
%{_mandir}/man1/glpi-injector*
%{_mandir}/man1/glpi-inventory.1*
%{_mandir}/man1/glpi-remote.1*

%dir %{_localstatedir}/lib/%{name}
%dir %{_datadir}/%{name}
%dir %{_datadir}/%{name}/lib
%dir %{_datadir}/%{name}/lib/FusionInventory
%dir %{_datadir}/%{name}/lib/FusionInventory/Agent
%dir %{_datadir}/%{name}/lib/FusionInventory/Agent/Task
%dir %{_datadir}/%{name}/lib/GLPI
%dir %{_datadir}/%{name}/lib/GLPI/Agent

%{_datadir}/%{name}/*.ids
%{_datadir}/%{name}/html/*.tpl
%{_datadir}/%{name}/html/favicon.ico
%{_datadir}/%{name}/html/logo.png
%{_datadir}/%{name}/html/site.css
%{_datadir}/%{name}/lib/FusionInventory/Agent.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Config.pm
%{_datadir}/%{name}/lib/setup.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Daemon.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/HTTP/Server.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/HTTP/Client*
%{_datadir}/%{name}/lib/FusionInventory/Agent/HTTP/Protocol
%{_datadir}/%{name}/lib/FusionInventory/Agent/HTTP/Session.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/HTTP/Server/Inventory.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/HTTP/Server/Plugin.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/HTTP/Server/Proxy.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/HTTP/Server/SecondaryProxy.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/HTTP/Server/SSL.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/HTTP/Server/Test.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Inventory.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Logger*
%{_datadir}/%{name}/lib/FusionInventory/Agent/SOAP/WsMan*
%{_datadir}/%{name}/lib/FusionInventory/Agent/Storage.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Target*
%{_datadir}/%{name}/lib/FusionInventory/Agent/Task.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Task/Inventory*
%{_datadir}/%{name}/lib/FusionInventory/Agent/Task/RemoteInventory*
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/AIX.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/BSD.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/Batteries.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/Constants.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/Expiration.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/Generic.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/HPUX.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/Hostname.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/IpmiFru.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/License.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/Linux.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/MacOS.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/Network.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/PartNumber*
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/PowerSupplies.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/Screen*
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/Solaris.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/Standards*
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/Storages/
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/UUID.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/Unix.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/Virtualization.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/Win32*
%{_datadir}/%{name}/lib/FusionInventory/Agent/Version.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/XML/
%{_datadir}/%{name}/lib/GLPI/Agent/Inventory/
%{_datadir}/%{name}/lib/GLPI/Agent/Protocol/

%preun
if [ $1 -eq 0 ] ; then
    # Package removal, not upgrade
    systemctl --no-reload disable --now %{name}.service &>/dev/null || :
fi

%postun
if [ $1 -ge 1 ] ; then
    # Package upgrade, not uninstall
    systemctl try-restart %{name}.service &>/dev/null || :
fi

%files task-esx
%{_bindir}/glpi-esx
%{_mandir}/man1/glpi-esx.1*
%{_datadir}/%{name}/lib/FusionInventory/Agent/Task/ESX*
%{_datadir}/%{name}/lib/FusionInventory/Agent/SOAP/VMware*

%files task-network
%config(noreplace) %{_sysconfdir}/%{name}/toolbox-plugin.cfg
%{_bindir}/glpi-netdiscovery
%{_bindir}/glpi-netinventory
%{_mandir}/man1/glpi-netdiscovery.1*
%{_mandir}/man1/glpi-netinventory.1*
%{_datadir}/%{name}/lib/FusionInventory/Agent/Task/NetDiscovery*
%{_datadir}/%{name}/lib/FusionInventory/Agent/Task/NetInventory*
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/SNMP.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/SNMP*
%{_datadir}/%{name}/lib/FusionInventory/Agent/Tools/Hardware*
%{_datadir}/%{name}/lib/FusionInventory/Agent/HTTP/Server/ToolBox*
%{_datadir}/%{name}/html/toolbox

%files task-deploy
%{_datadir}/%{name}/lib/FusionInventory/Agent/Task/Deploy.pm
%{_datadir}/%{name}/lib/FusionInventory/Agent/Task/Deploy

%files task-wakeonlan
%{_bindir}/glpi-wakeonlan
%{_mandir}/man1/glpi-wakeonlan.1*
%{_datadir}/%{name}/lib/FusionInventory/Agent/Task/WakeOnLan*

%files task-collect
%{_datadir}/%{name}/lib/FusionInventory/Agent/Task/Collect*

%files cron
%{_sysconfdir}/cron.hourly/%{name}
%config(noreplace) %{_sysconfdir}/sysconfig/%{name}


%changelog
* Fri Jun 11 2021 Guillaume Bougard <gbougard AT teclib DOT com>
- Update to support new GLPI Agent protocol

* Mon May 10 2021 Guillaume Bougard <gbougard AT teclib DOT com>
- Updates to make official and generic GLPI Agent rpm packages
- Remove dmidecode, perl(Net::CUPS) & perl(Parse::EDID) dependencies as they are
  indeed only recommended
- Replace auto-generated systemd scriptlets with raw scriplets and don't even try
  to enable the service on install as this is useless without a server defined in conf

* Thu Sep 17 2020 Johan Cwiklinski <jcwiklinski AT teclib DOT com>
- Package of GLPI Agent, based on FusionInventory Agent officials specfile
