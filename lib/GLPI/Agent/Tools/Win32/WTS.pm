package GLPI::Agent::Tools::Win32::WTS;

use strict;
use warnings;
use parent 'Exporter';

use UNIVERSAL::require();
use English qw(-no_match_vars);

use Encode;
use GLPI::Agent::Tools::Win32;

use constant WTS_CURRENT_SERVER_HANDLE  => 0x00000000;

# Constant values, see: winuser.h & wtsapi32.h
# or https://msdn.microsoft.com/en-us/library/aa383842(v=vs.85).aspx
use constant IDOK       => 1;
use constant IDCANCEL   => 2;
use constant IDABORT    => 3;
use constant IDRETRY    => 4;
use constant IDIGNORE   => 5;
use constant IDYES      => 6;
use constant IDNO       => 7;
use constant IDTRYAGAIN => 10;
use constant IDCONTINUE => 11;
use constant IDTIMEOUT  => 32000;
use constant IDASYNC    => 32001;

# Enum description, see:
# https://msdn.microsoft.com/en-us/library/aa383861(v=vs.85).aspx
use constant WTSUserName    => 5;

our @EXPORT = qw(
    WTSEnumerateSessions
    WTSSendMessage
    IDOK IDCANCEL IDABORT IDRETRY
    IDIGNORE IDYES IDNO IDTRYAGAIN
    IDCONTINUE IDTIMEOUT IDASYNC
);

sub _newSessionInfo {
    # API description, see:
    # https://msdn.microsoft.com/en-us/library/aa383864(v=vs.85).aspx

    # Load Win32::API as late as possible
    Win32::API->require() or return;

    my $SessionInfo;
    eval {
        Win32::API::Type->typedef( 'WTS_CONNECTSTATE_CLASS', 'DWORD' );
        Win32::API::Struct->typedef('WTS_SESSION_INFO', qw(
            DWORD                  SessionId;
            LPTSTR                 pWinStationName;
            WTS_CONNECTSTATE_CLASS State;
        ));

        # Initialize new WTS_SESSION_INFO struct
        $SessionInfo = Win32::API::Struct->new('WTS_SESSION_INFO');
        $SessionInfo->{SessionId} = 0;
        $SessionInfo->{pWinStationName} = "";
        $SessionInfo->{State} = 0;
        $SessionInfo->Pack();
    };
    #~ print STDERR "ERR: $@\n" if $@;

    return $SessionInfo;
}

sub WTSEnumerateSessions {
    # API description, see:
    # https://msdn.microsoft.com/en-us/library/aa383833(v=vs.85).aspx

    # Load Win32::API as late as possible
    Win32::API->require() or return;

    my @sessions = ();
    eval {
        my $apiWTSEnumerateSessions = Win32::API->new(
            'wtsapi32',
            'WTSEnumerateSessions',
            [ 'N', 'N', 'N', 'P', 'P' ],
            'N'
        );

        my ( $Count, $ppSessionInfo ) = ( 0, 0 );
        Win32::API::Type->Pack('DWORD', $Count);
        Win32::API::Type->Pack('LPARAM', $ppSessionInfo);

        if ($apiWTSEnumerateSessions->Call(WTS_CURRENT_SERVER_HANDLE, 0, 1, $ppSessionInfo, $Count)) {
            Win32::API::Type->Unpack('DWORD', $Count);
            Win32::API::Type->Unpack('LPARAM', $ppSessionInfo);

            my $index = 0;
            while ( $Count-- > 0 ) {
                # Allocate a new SessionInfo struct and update it with
                # read memory indexed content
                my $SessionInfo = _newSessionInfo() or last;
                my $memaddr = $ppSessionInfo + ($index++)*$SessionInfo->sizeof;
                $SessionInfo->FromMemory($memaddr);

                push @sessions, {
                    sid   => $SessionInfo->{SessionId},
                    name  => $SessionInfo->{pWinStationName},
                    state => $SessionInfo->{State},
                    user  => _WTSSessionUser($SessionInfo->{SessionId})
                };
            }
            # Don't forget to free memory allocated by API
            _WTSFreeMemory($ppSessionInfo);
        }
    };
    #~ print STDERR "ERR: $@\n" if $@;

    return @sessions;
}

sub WTSSendMessage {
    my ($sid, $message) = @_;

    # API description, see:
    # https://msdn.microsoft.com/en-us/library/aa383842(v=vs.85).aspx

    # Load Win32::API as late as possible
    Win32::API->require() or return;

    # Setup defaults for message
    $message = {} unless (ref($message) eq 'HASH');

    my $title   = $message->{title}     || "Notification";
    my $text    = $message->{text}      || "About to proceed...";
    my $buttons = $message->{buttons}   || "ok" ;
    my $icon    = $message->{icon}      || "info";

    my $timeout = defined($message->{timeout}) ?
        $message->{timeout} : 60 ;

    my $wait = (!defined($message->{wait}) || $message->{wait} =~ /^0|no|false$/i) ? 0 : 1 ;

    # Buttons/icons definitions, see:
    # https://msdn.microsoft.com/en-us/library/ms645505(v=vs.85).aspx
    my %buttons = (
        ok                  =>  0x00000000,
        okcancel            =>  0x00000001,
        abortretryignore    =>  0x00000002,
        yesnocancel         =>  0x00000003,
        yesno               =>  0x00000004,
        retrycancel         =>  0x00000005,
        canceltrycontinue   =>  0x00000006
    );

    my %icons = (
        none        =>  0x00000000,
        error       =>  0x00000010,
        question    =>  0x00000020,
        warn        =>  0x00000030,
        info        =>  0x00000040
    );

    # Prepare messagebox style
    my $style = defined($buttons{$buttons}) ?
        $buttons{$buttons} : $buttons{"ok"};
    $style |= $icons{$icon} if ($icon && defined($icons{$icon}));

    # Finally text and title must be encoded in local codepage
    eval {
        $title = encode( getLocalCodepage(), $title );
        $text  = encode( getLocalCodepage(), $text );
    };
    #~ print STDERR "ERR: $@\n" if $@;

    my $Response = IDOK;
    eval {
        my $apiWTSSendMessage = Win32::API->new(
            'wtsapi32',
            'WTSSendMessage',
            [ 'N', 'N', 'P', 'N', 'P', 'N', 'N', 'N', 'P', 'N' ],
            'N'
        );

        my $lenTitle = length($title);
        my $lenMesg  = length($text);
        Win32::API::Type->Pack('LPTSTR', $title);
        Win32::API::Type->Pack('LPTSTR', $text);
        Win32::API::Type->Pack('DWORD',  $Response);

        # Directly unpack the response while obtaining one
        Win32::API::Type->Unpack('DWORD', $Response)
            if (
                $apiWTSSendMessage->Call(
                    WTS_CURRENT_SERVER_HANDLE, $sid,
                    $title, $lenTitle, $text, $lenMesg,
                    $style, $timeout, $Response, $wait
                )
            );
    };
    #~ print STDERR "ERR: $@\n" if $@;

    return $Response;
}

sub _WTSFreeMemory {
    my ($pMemory) = @_;

    # API description, see:
    # https://msdn.microsoft.com/en-us/library/aa383834(v=vs.85).aspx

    # Load Win32::API as late as possible
    Win32::API->require() or return;

    eval {
        my $apiWTSFreeMemory = Win32::API->new(
            'wtsapi32',
            'VOID WTSFreeMemory( PVOID pMemory )'
        );
        $apiWTSFreeMemory->Call($pMemory);
    };
    #~ print STDERR "ERR: $@\n" if $@;
}

sub _WTSSessionUser {
    my ($sid) = @_;

    return _WTSQuerySessionInformation( $sid, WTSUserName );
}

sub _WTSQuerySessionInformation {
    my ($sid, $info_class) = @_;

    # API description, see:
    # https://msdn.microsoft.com/en-us/library/aa383838(v=vs.85).aspx

    # Load Win32::API as late as possible
    Win32::API->require() or return;

    my $buffer = "";
    eval {
        my $apiWTSQuerySessionInformation = Win32::API->new(
            'wtsapi32',
            'WTSQuerySessionInformation',
            [ 'N', 'N', 'N', 'P', 'P' ],
            'N'
        );

        my ( $Buffer, $BytesReturned ) = ( 0, 0 );
        Win32::API::Type->Pack('LPARAM', $Buffer);
        Win32::API::Type->Pack('DWORD',  $BytesReturned);

        if ($apiWTSQuerySessionInformation->Call(WTS_CURRENT_SERVER_HANDLE, $sid, $info_class, $Buffer, $BytesReturned)) {
            Win32::API::Type->Unpack('LPARAM', $Buffer);
            Win32::API::Type->Unpack('DWORD',  $BytesReturned);
            if ($BytesReturned > 0) {
                # While directly reading memory, we need to skip last NULL byte
                my $zero = Win32::API::ReadMemory($Buffer+$BytesReturned-1, 1) eq '\0' ? 0 : 1 ;
                if ($BytesReturned-$zero) {
                    $buffer = Win32::API::ReadMemory($Buffer, $BytesReturned-$zero);
                }
            }
            # Don't forget to free memory allocated by API
            _WTSFreeMemory($Buffer);
        }
    };
    #~ print STDERR "ERR: $@\n" if $@;

    return $buffer;
}

1;
