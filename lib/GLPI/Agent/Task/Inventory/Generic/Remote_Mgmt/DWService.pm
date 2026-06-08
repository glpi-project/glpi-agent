package GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::DWService;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use Fcntl qw(SEEK_SET);
use Cpanel::JSON::XS;

# --- Helper: Dynamically find installation paths ---
sub _get_base_paths {
    my @paths;
    
    if (OSNAME eq 'MSWin32') {
        GLPI::Agent::Tools::Win32->require();
        
        # Check standard registry keys and WOW6432Node
        foreach my $reg_key (
            'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall/DWAgent',
            'HKEY_LOCAL_MACHINE/SOFTWARE/WOW6432Node/Microsoft/Windows/CurrentVersion/Uninstall/DWAgent'
        ) {
            my $install_loc = GLPI::Agent::Tools::Win32::getRegistryValue(path => "$reg_key/InstallLocation");
            $install_loc =~ s{[\\/]+$}{} if $install_loc;
            push @paths, $install_loc if $install_loc && has_folder($install_loc);
        }
        
        # Windows fallbacks using environment variables
        foreach my $env (qw(ProgramFiles ProgramFiles(x86) ProgramW6432)) {
            if (my $pf = $ENV{$env}) {
                $pf =~ s{\\}{/}g;
                push @paths, "$pf/DWAgent";
            }
        }
        # Hardcoded ultimate fallbacks
        push @paths, 'C:/Program Files/DWAgent', 'C:/Program Files (x86)/DWAgent';
    } else {
        # Dynamic process detection on Unix systems (Linux / macOS)
        GLPI::Agent::Tools::Unix->require();
        my @processes = GLPI::Agent::Tools::Unix::getProcesses();
        
        foreach my $process (@processes) {
            my $line = $process->{CMD};
            # Matches absolute paths in memory, extracting the base directory
            # macOS: /Library/DWAgent/native/DWAgentSvc.app/... -> /Library/DWAgent
            # Linux: /usr/share/dwagent/native/dwagsvc -> /usr/share/dwagent
            if ($line =~ m{(/.*?)/native/DWAgentSvc\.app}i || 
                $line =~ m{(/.*?)/native/dwag(?:svc|ent)}i) {
                push @paths, $1;
            }
        }
        
        # macOS fallback
        push @paths, '/Library/DWAgent' if OSNAME eq 'darwin';
        
        # Linux fallbacks
        push @paths, '/usr/share/dwagent', '/opt/dwagent' if OSNAME eq 'linux';
    }
    
    # Remove duplicates and ensure the directory exists
    my %seen;
    return grep { $_ && has_folder($_) && !$seen{$_}++ } @paths;
}

sub isEnabled {
    # Check if config.json exists in any of the found paths
    foreach my $path (_get_base_paths()) {
        return 1 if has_file("$path/config.json");
    }
    return;
}

sub doInventory {
    my (%params) = @_;
    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $base_path;

    # 1. Locate the valid installation path
    foreach my $path (_get_base_paths()) {
        if (has_file("$path/config.json")) {
            $base_path = $path;
            last;
        }
    }

    return unless $base_path;
    $logger->debug("DWService: Active installation found at $base_path");

    # 2. Extract the unique ID (key) from config.json
    my $json_text = getAllLines(
        file   => "$base_path/config.json",
        logger => $logger
    );

    if (empty($json_text)) {
        $logger->debug("DWService: config.json not found or is empty");
        return;
    }

    my $config;
    eval {
        $config = decode_json($json_text);
    };

    if ($@) {
        $logger->debug("DWService: Failed to parse config.json - $@");
        return;
    }

    my $dw_id = $config->{key} if $config;

    if (!$dw_id) {
        $logger->debug("DWService: Could not extract 'key' from config.json");
        return;
    }

    # 3. Intercept local data from shared memory (SHM)
    my $shm_data = _extract_shm_data("$base_path/sharedmem/status_config.shm", $logger);
    
    # Extract the friendly name (if available)
    my $dw_name = $shm_data->{'name'} if $shm_data;
    
    # Fallback logic for Display Name: try friendly name, otherwise fall back to unique ID.
    my $display_name = $dw_name ? $dw_name : $dw_id;

    $logger->debug("DWService: Preparing for inventory -> ID: $dw_id, NAME: $display_name");
    

    # 4. Feed the GLPI Inventory structure
    $inventory->addEntry(
        section => 'REMOTE_MGMT',
        entry   => {
            ID   => $display_name,
            TYPE => 'dwservice'
        }
    );
}

# --- Internal Helper: IPC Memory Map Parser ---
# Returns a HashRef with extracted SHM data
sub _extract_shm_data {
    my ($shm_file, $logger) = @_;

    unless (has_file($shm_file)) {
        $logger->debug("DWService: SHM memory file not found. The agent might be offline.");
        return;
    }

    my %extracted_data;
    
    # Eval block catches failures in case DWService alters the binary structure in the future
    eval {
        my $content = getAllLines(
            file   => $shm_file,
            mode   => '<:raw',
            logger => $logger
        );

        die "Cannot read $shm_file" unless defined $content;

        # Read the first 4 bytes (header length)
        my $len_bytes = substr($content, 0, 4);
        die "Could not read header length\n" unless length($len_bytes) == 4;
        
        # Unpack as unsigned 32-bit Big-Endian integer
        my $len_def = unpack("N", $len_bytes);

        # Read the JSON header describing the byte offsets
        my $json_header = substr($content, 4, $len_def);
        die "Could not read JSON header\n" unless length($json_header) == $len_def;
        
        my $fields = decode_json($json_header);

        # List of fields we want to extract from memory
        # 'state' and 'sessions_status' kept in comments for future use
        my @target_fields = ('name'); #, 'state', 'sessions_status');

        foreach my $target (@target_fields) {
            if (exists $fields->{$target}) {
                next if empty($fields->{$target}->{'pos'}) || $fields->{$target}->{'pos'} !~ /^\d+$/;
                next if empty($fields->{$target}->{'size'}) || $fields->{$target}->{'size'} !~ /^\d+$/;
                my $data_pos  = int($fields->{$target}->{'pos'});
                my $data_size = int($fields->{$target}->{'size'});

                # Read the fixed block of bytes: 4 (length int) + JSON header length + data offset
                # DWService pads strings with spaces (" "), clear them with regex
                my $raw_value = trimWhitespace(substr($content, 4 + $len_def + $data_pos, $data_size));
                
                $extracted_data{$target} = $raw_value unless empty($raw_value);
            }
        }
    };

    if ($@) {
        $logger->debug("DWService: Failed to extract data from SHM - $@");
        return;
    }

    return \%extracted_data;
}

1;
