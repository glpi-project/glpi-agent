package GLPI::Agent::Task::Inventory::Generic::Remote_Mgmt::DWService;

use strict;
use warnings;

use parent 'GLPI::Agent::Task::Inventory::Module';

use GLPI::Agent::Tools;
use Fcntl qw(SEEK_SET);
use JSON::PP;

# --- Helper: Dynamically find installation paths ---
sub _get_base_paths {
    my @paths;
    
    if ($^O eq 'MSWin32') {
        require GLPI::Agent::Tools::Win32;
        
        # Check standard registry keys and WOW6432Node
        foreach my $reg_key (
            'HKEY_LOCAL_MACHINE/SOFTWARE/Microsoft/Windows/CurrentVersion/Uninstall/DWAgent',
            'HKEY_LOCAL_MACHINE/SOFTWARE/WOW6432Node/Microsoft/Windows/CurrentVersion/Uninstall/DWAgent'
        ) {
            my $install_loc = GLPI::Agent::Tools::Win32::getRegistryValue(path => "$reg_key/InstallLocation");
            $install_loc =~ s{[\\/]+$}{} if $install_loc;
            push @paths, $install_loc if $install_loc && -d $install_loc;
        }
        
        # Windows fallbacks
        push @paths, 'C:/Program Files/DWAgent', 'C:/Program Files (x86)/DWAgent';
    } else {
        # Dynamic process detection on Unix systems (Linux / macOS)
        my $ps_cmd = $^O eq 'darwin' ? 'ps -A -o command' : 'ps -e -o args';
        
        if (open(my $ph, '-|', "$ps_cmd 2>/dev/null")) {
            while (my $line = <$ph>) {
                # Matches absolute paths in memory, extracting the base directory
                # macOS: /Library/DWAgent/native/DWAgentSvc.app/... -> /Library/DWAgent
                # Linux: /usr/share/dwagent/native/dwagsvc -> /usr/share/dwagent
                if ($line =~ m{(/.*?)/native/DWAgentSvc\.app}i || 
                    $line =~ m{(/.*?)/native/dwag(?:svc|ent)}i) {
                    push @paths, $1;
                }
            }
            close($ph);
        }
        
        # macOS fallback
        push @paths, '/Library/DWAgent' if $^O eq 'darwin';
        
        # Linux fallbacks
        push @paths, '/usr/share/dwagent', '/opt/dwagent' if $^O eq 'linux';
    }
    
    # Remove duplicates and ensure the directory exists
    my %seen;
    return grep { $_ && -d $_ && !$seen{$_}++ } @paths;
}

sub isEnabled {
    # Check if config.json exists in any of the found paths
    foreach my $path (_get_base_paths()) {
        return 1 if -f "$path/config.json";
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
        if (-f "$path/config.json") {
            $base_path = $path;
            last;
        }
    }

    return unless $base_path;
    $logger->debug("DWService: Active installation found at $base_path");

    # 2. Extract the unique ID (key) from config.json
    my $config;
    eval {
        local $/; 
        open(my $fh, '<:encoding(UTF-8)', "$base_path/config.json") or die "Cannot open config: $!";
        my $json_text = <$fh>;
        close($fh);
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

    $logger->debug("DWService: Preparing for inventory -> ID: $display_name, NAME: $display_name");
    
    # --- Commented out state and sessions_status extractions ---
    # if ($shm_data && $shm_data->{'state'}) {
    #      $logger->debug("DWService Extra Info: Current Agent state -> " . $shm_data->{'state'});
    # }
    # if ($shm_data && $shm_data->{'sessions_status'} && $shm_data->{'sessions_status'} ne '{}' && $shm_data->{'sessions_status'} ne '[]') {
    #      $logger->debug("DWService Extra Info: The agent has active sessions! -> " . $shm_data->{'sessions_status'});
    # }

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

    unless (-f $shm_file) {
        $logger->debug("DWService: SHM memory file not found. The agent might be offline.");
        return;
    }

    my %extracted_data;
    
    # Eval block catches failures in case DWService alters the binary structure in the future
    eval {
        open(my $fh, '<:raw', $shm_file) or die "Cannot open file: $!";

        # Read the first 4 bytes (header length)
        my $len_bytes;
        read($fh, $len_bytes, 4) == 4 or die "Could not read header length";
        
        # Unpack as unsigned 32-bit Big-Endian integer
        my $len_def = unpack("N", $len_bytes);

        # Read the JSON header describing the byte offsets
        my $json_header;
        read($fh, $json_header, $len_def) == $len_def or die "Could not read JSON header";
        
        my $fields = decode_json($json_header);

        # List of fields we want to extract from memory
        # 'state' and 'sessions_status' kept in comments for future use
        my @target_fields = ('name'); #, 'state', 'sessions_status');

        foreach my $target (@target_fields) {
            if (exists $fields->{$target}) {
                my $data_pos  = $fields->{$target}->{'pos'};
                my $data_size = $fields->{$target}->{'size'};
                my $raw_value;

                # Seek to the absolute position: 4 (length int) + JSON header length + data offset
                seek($fh, 4 + $len_def + $data_pos, SEEK_SET);

                # Read the fixed block of bytes
                read($fh, $raw_value, $data_size);

                # DWService pads strings with spaces (" "), clear them with regex
                $raw_value =~ s/\s+$//;
                
                $extracted_data{$target} = $raw_value if defined $raw_value && $raw_value ne "";
            }
        }
        
        close($fh);
    };

    if ($@) {
        $logger->debug("DWService: Failed to extract data from SHM - $@");
        return;
    }

    return \%extracted_data;
}

1;
