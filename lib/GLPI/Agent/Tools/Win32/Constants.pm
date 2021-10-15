package GLPI::Agent::Tools::Win32::Constants;

use warnings;
use strict;

use parent 'Exporter';

use constant CATEGORY_SYSTEM_COMPONENT => 'system_component';
use constant CATEGORY_APPLICATION => 'application';
use constant CATEGORY_UPDATE => 'update';
use constant CATEGORY_SECURITY_UPDATE => 'security_update';
use constant CATEGORY_HOTFIX => 'hotfix';

our @EXPORT = qw(
    CATEGORY_SYSTEM_COMPONENT
    CATEGORY_APPLICATION
    CATEGORY_UPDATE
    CATEGORY_SECURITY_UPDATE
    CATEGORY_HOTFIX
);

1;
