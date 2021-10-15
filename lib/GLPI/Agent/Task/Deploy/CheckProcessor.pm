package FusionInventory::Agent::Task::Deploy::CheckProcessor;

use strict;
use warnings;

use constant OK => "ok";

use English qw(-no_match_vars);
use UNIVERSAL::require;

# Supported sub-class must be declared here
my %checkType_to_Module = (
    directoryExists    => "DirectoryExists",
    directoryMissing   => "DirectoryMissing",
    fileExists         => "FileExists",
    fileMissing        => "FileMissing",
    fileSizeEquals     => "FileSizeEquals",
    fileSizeGreater    => "FileSizeGreater",
    fileSizeLower      => "FileSizeLower",
    fileSHA512         => "FileSHA512",
    fileSHA512mismatch => "FileSHA512Mismatch",
    freespaceGreater   => "FreeSpaceGreater",
    winkeyExists       => "WinKeyExists",
    winkeyMissing      => "WinKeyMissing",
    winkeyEquals       => "WinKeyEquals",
    winkeyNotEquals    => "WinKeyNotEquals",
    winvalueExists     => "WinValueExists",
    winvalueMissing    => "WinValueMissing",
    winvalueType       => "WinValueType",
);

sub new {
    my ($class, %params) = @_;

    my $self = $params{check} || {};
    $self->{logger} = $params{logger};

    $self->{message} = 'no message';
    $self->{status}  = OK;
    $self->{return}  = "ko"  unless $self->{return};
    $self->{type}    = "n/a" unless $self->{type};

    # Expend the env vars from the path
    if ($self->{path}) {
        $self->{path} =~ s#\$(\w+)#$ENV{$1}#ge;
        $self->{path} =~ s#%(\w+)%#$ENV{$1}#ge;
    } else {
        $self->{path} = "~~ no path given ~~";
    }

    bless $self, $class;

    if ($checkType_to_Module{$self->{type}}) {
        my $module = $class . '::' . $checkType_to_Module{$self->{type}};
        $module->require();
        if ($EVAL_ERROR) {
            $self->error("Can't use $module module: load failure ($EVAL_ERROR)");
        } else {
            bless $self, $module;
        }
    }

    return $self;
}

sub debug2 {
    my ($self, $message) = @_;

    $self->{logger}->debug2($message) if $self->{logger};
}

sub debug {
    my ($self, $message) = @_;

    $self->{logger}->debug($message) if $self->{logger};
}

sub info {
    my ($self, $message) = @_;

    $self->{logger}->info($message) if $self->{logger};
}

sub error {
    my ($self, $message) = @_;

    $self->{logger}->error($message) if $self->{logger};
}

sub on_failure {
    my ($self, $message) = @_;

    $self->{on_failure} = $message;
}

sub on_success {
    my ($self, $message) = @_;

    $self->{on_success} = $message;
}

sub message {
    my ($self) = @_;

    return $self->{message};
}

sub is {
    my ($self, $type) = @_;

    return $type ? ($self->{return} eq $type) : $self->{return} ;
}

sub name {
    my ($self) = @_;

    return $self->{name} || $self->{type} || 'unsupported' ;
}

sub process {
    my ($self, %params) = @_;

    $self->prepare();

    my $message;
    if ($self->success()) {
        $message = $self->{on_success} || 'unknown reason';
        $self->debug("check success: $message") if $self->{on_success};
    } else {
        $message = $self->{on_failure} || 'unknown reason';
        $self->debug("check failure: $message") if $self->{on_failure};
        $self->{status} = $self->{return};
    }

    $self->{message} = $message;

    return $self->{status};
}

# Methods to overload
sub prepare {
    # This method should call on_failure & on_success parent method
    my ($self) = @_;

    $self->{message} = "Not implemented '$self->{type}' check processor";
}

sub success {
    # This method should just return true when the check is a success else false
    my ($self) = @_;

    $self->info("Unsupported check: ".$self->{message});

    return 1;
}

1;
