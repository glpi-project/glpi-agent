package Win32;

use strict;
use warnings;

# Fake stub for non-Windows test runs. The version must be declared so that
# modules which load Win32 indirectly (e.g. via IPC::Cmd -> Win32::IsWinNT)
# do not fail XSLoader's version check with "version 0 does not match".
# 0.27 is the minimum required by the strictest consumer in the dependency chain.
our $VERSION = 0.27;

1;
