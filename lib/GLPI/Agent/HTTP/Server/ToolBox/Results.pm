package GLPI::Agent::HTTP::Server::ToolBox::Results;

use strict;
use warnings;

use parent "GLPI::Agent::HTTP::Server::ToolBox";

use English qw(-no_match_vars);
use Encode qw(encode);
use HTML::Entities;
use File::stat;

use GLPI::Agent::Logger;
use GLPI::Agent::Tools;
use GLPI::Agent::XML;

use GLPI::Agent::HTTP::Server::ToolBox::Results::Device;

use constant    results => "results";

sub index {
    return results;
}

sub log_prefix {
    return "[toolbox plugin, results] ";
}

sub new {
    my ($class, %params) = @_;

    my ($name) = $class =~ /::(\w+)$/;

    my $self = {
        logger      => $params{toolbox}->{logger} ||
                        GLPI::Agent::Logger->new(),
        toolbox     => $params{toolbox},
        name        => $name,
        _mtime      => {},
        _macs       => {},
        _devices    => {},
        need_init   => 1,
        _xml        => GLPI::Agent::XML->new(),
    };

    bless $self, $class;

    return $self;
}

sub init {
    my ($self) = @_;

    $self->_register_supported_modules();
}

sub reset {
    my ($self) = @_;

    $self->_register_supported_modules();
    delete $self->{_mtime};
    $self->xml_analysis();
}

sub yaml_config_specs {
    my ($self, $yaml_config) = @_;

    return {
        display_options => {
            category    => "ToolBox User Interface",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "text" : "readonly",
            value       => $yaml_config->{'display_options'} || '30|0|5|10|20|40|50|100|500',
            text        => "Number of row to display options",
            tips        => "Numbers separated by pipes,\nfirst value used as default,\n0=no limit\n(default=30|0|5|10|20|40|50|100|500)",
        },
        default_columns => {
            category    => "Results",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "text" : "readonly",
            value       => $yaml_config->{'default_columns'} || 'name|mac|ip|serial|tag|source|type',
            text        => "Defaut columns for results list view",
            tips        => "Ordered columns list separated by pipes\n(default=name|mac|ip|serial|tag|source|type)",
        },
        results_navbar  => {
            category    => "Navigation bar",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "bool" : "readonly",
            value       => $self->yesno($yaml_config->{'results_navbar'} || 1),
            text        => "Show Results in navigation bar",
            navbar      => "Results",
            link        => $self->index(),
            index       => 20, # index in navbar
        },
        custom_fields_yaml => {
            category    => "Results",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "option" : "readonly",
            value       => $yaml_config->{'custom_fields_yaml'} || (
                $self->isyes($yaml_config->{'updating_support'}) ? "" : "[default]"),
            options     => $self->yaml_files(),
            text        => "Custom fields YAML file",
            yaml_base   => 'container',
        },
        archive_format  => {
            category    => "Results",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "option" : "readonly",
            value       => $yaml_config->{'archive_format'} || $self->_supported_archive_formats()->[0],
            options     => $self->_supported_archive_formats(),
            text        => "Exported archive format",
        },
        other_fields    => {
            category    => "Results",
            type        => $self->isyes($yaml_config->{'updating_support'}) ? "textarea" : "readonly",
            value       => $yaml_config->{'other_fields'} || '',
            text        => "Other fields to show in dedicated section",
            cols        => 40,
            rows        => 3,
            tips        => "List of fields to show in 'Other fields' section with a field definition by line
                            A line definition should be in the following format
                            NAME;TEXT;NODE;FILTER
                            &nbsp;
                            NAME is the simple reference string you may need set in default columns to list configuration
                            TEXT is the text to show as field name in the section
                            NODE is a list of node names separated by commas which should
                            be the path to the XML node in inventory XML file
                            FILTER can be set to select a node when the NODE match on a node list
                            In that case, FILTER could be a test like KEY=VALUE where KEY is another value name of the nodes
                            and VALUE the expected value and it is interpreted as a perl regex
                            &nbsp;
                            NODE can match on any kind of XML
                            NODE path is expect to be under the first 'REQUEST' node
                            As examples, 'DEVICEID' and 'CONTENT,VERSIONCLIENT' are valid paths",
        }
    };
}

sub xml_analysis {
    my ($self, $base_folder, $recursion) = @_;

    $recursion = 0 unless $recursion;
    # Many recursion can occur on deduplication
    return if $recursion > 100;

    unless ($base_folder) {
        my $yaml_config = $self->yaml('configuration') || {};;
        $base_folder = $yaml_config->{networktask_save} || '.';
        $base_folder =~ s{\\}{/}g if $OSNAME eq 'MSWin32';
    }
    my $file_match_re = qr{^$base_folder/([^/]*)/(.*)\.xml$};

    # Index known files to detect deleted ones
    my %missing = ();
    foreach my $device (values(%{$self->{_devices}})) {
        map { $missing{$_} = $device } $device->getFiles();
    }

    my %dirty = ();

    # Scan all files under netdiscovery, netinventory & inventory
    foreach my $file (File::Glob::bsd_glob("$base_folder/{netdiscovery,netinventory,inventory}/*.xml")) {
        if ($OSNAME eq 'MSWin32') {
            $file =~ s{\\}{/}g;
        }

        my ($folder, $name) = $file =~ $file_match_re
            or next;

        my $mtime = stat($file)->mtime;

        delete $missing{$file};

        # Don't reload file if still loaded and has not been updated
        next if $self->{_mtime}->{$file} && $self->{_mtime}->{$file} == $mtime;

        my $tree = $self->{_xml}->file($file)->dump_as_hash()
            or next;

        $self->{_mtime}->{$file} = $mtime;

        # Check filename has not been linked to another device
        $name = $self->{_linked}->{$name} if $self->{_linked}->{$name};

        my $device = $self->{_devices}->{$name};
        unless ($device) {
            $device = GLPI::Agent::HTTP::Server::ToolBox::Results::Device->new(
                name    => $name,
            );
            $self->{_devices}->{$name} = $device;
        }
        $device->set_xml($file, $tree);
        $dirty{$name} = $device;
    }

    # Invalidate any device with missing file
    foreach my $missing (keys(%missing)) {
        my $device = $missing{$missing};
        my $name   = $device->name;
        $self->debug("Got $name device invalidated by missing $missing XML");
        delete $self->{_mtime}->{$missing};
        $device->deleted_xml($missing);

        if ($device->getFiles() > 0) {
            $dirty{$name} = $device;
        } else {
            # Just delete device if no more related file is known
            delete $self->{_devices}->{$name};
        }
    }

    # Now analyse all dirty devices
    foreach my $device (values(%dirty)) {
        $device->analyse_with($self->{_any_sources}, $self->{_sources});
        # Try to deduplicate and then link to the duplicated entry
        my $linked = $device->deduplicate($self->{_devices});
        if ($linked) {
            $self->debug("Linked ".$linked->name." to ".$device->name);
            $self->{_linked}->{$linked->name} = $device->name;
            delete $self->{_devices}->{$linked->name};
            # Finally, we need to analyse again the device as known files and XML trees should have been merged
            $device->analyse_with($self->{_any_sources}, $self->{_sources});
        }
    }
}

sub update_template_hash {
    my ($self, $hash) = @_;

    return unless $hash;

    my $yaml_config = $self->yaml('configuration') || {};
    my $credentials = $self->yaml('credentials') || {};
    my $ip_ranges   = $self->yaml('ip_range') || {};

    # Firstly always verify XML analysis has not changed
    $self->xml_analysis();

    # Keep light ip_range & credentials list versions encoding html entities
    $hash->{credentials} = {};
    foreach my $name (keys(%{$credentials})) {
        my $entry = $credentials->{$name};
        $hash->{credentials}->{$name}->{name} = encode('UTF-8', encode_entities($entry->{name} || ''));
    }
    $hash->{ip_range} = {};
    foreach my $name (keys(%{$ip_ranges})) {
        my $entry = $ip_ranges->{$name};
        $hash->{ip_range}->{$name}->{name} = encode('UTF-8', encode_entities($entry->{name} || ''));
    }

    my $tag_filter = $self->get_from_session('tag_filter');
    my $devices = $self->{_devices} || {};
    if (defined($tag_filter) && length($tag_filter)) {
        $devices = {
            map { $_ => $self->{_devices}->{$_} }
                grep {
                    my $tag = $self->{_devices}->{$_}->tag;
                    defined($tag) && $tag eq $tag_filter;
                } keys(%{$self->{_devices}})
        };
        $hash->{tag_filter} = $tag_filter;
    }
    $self->{columns} = $yaml_config->{'default_columns'} || 'name';
    $hash->{columns} = [ map { [ $_, $self->{_columns}->{$_}->{text} ] }
        grep { $_ && $self->{_columns}->{$_} } split(/[|]/, $self->{columns})
    ];
    $hash->{order} = $self->get_from_session('results_order') || "ascend";
    my $ordering = $hash->{ordering_column} = $self->get_from_session('results_ordering_column') || $hash->{columns}->[0]->[0];
    $hash->{devices} = $devices;
    my $sortable = $self->{_columns}->{$ordering}->{tosort} || sub { shift->{$ordering} || ''; };
    my @devices_order = $hash->{order} eq 'ascend' ?
        sort { &$sortable($devices->{$a}) cmp &$sortable($devices->{$b}) } keys(%{$devices})
        :
        sort { &$sortable($devices->{$b}) cmp &$sortable($devices->{$a}) } keys(%{$devices})
        ;
    $hash->{devices_order} = \@devices_order;
    my @display_options = grep { /^\d+$/ } split(/[|]/,$yaml_config->{display_options} || '30|0|5|10|20|40|50|100|500');
    $hash->{display_options} = [ sort { $a <=> $b } keys(%{{map { $_ => 1 } @display_options}}) ];
    my $display = $self->get_from_session('display');
    $hash->{display} = length($display) ? $display : $display_options[0];
    $hash->{list_count} = scalar(keys(%{$devices}));
    $self->delete_in_session('results_start') unless $hash->{display};
    $hash->{start} = $self->get_from_session('results_start') || 0;
    $hash->{start} = $hash->{list_count} if $hash->{start} > $hash->{list_count};
    $hash->{page} = $hash->{display} ? int(($hash->{start}-1)/$hash->{display})+1 : 1;
    $hash->{pages} = $hash->{display} ? int(($hash->{list_count}-1)/$hash->{display})+1 : 1;
    $hash->{start} = $hash->{display} ? $hash->{start} - $hash->{start}%$hash->{display} : 0;
    if (my $edit = $self->edit()) {
        $hash->{edit} = $edit;
        $hash->{index} = first { $devices_order[$_] eq $edit } 0..$#devices_order;
        $hash->{sections} = [];
        my $device = $devices->{$edit};
        foreach my $section (@{$self->{_sections}}) {
            if ($section->{match}) {
                my $re_match = qr/^$section->{match}$/;
                next if !$device->type && $section->{match} eq 'COMPUTER';
                next if $device->type !~ $re_match;
            }
            $hash->{need_datetime} += scalar(grep { $_->{type} =~ /^date/ } values(%{$section->{fields}}));
            push @{$hash->{sections}}, $section;
        }
        $hash->{checked_fields} = $self->get_from_session('checked_fields');
        $hash->{next_on_deletion} = $self->get_from_session('next_on_deletion') ? 1 : 0;
        $hash->{tasks} = $self->{tasks};
    }
    $hash->{tags} = [ split(/,/, $yaml_config->{'inventory_tags'} || '') ];
    $hash->{do} = delete $self->{_do} || '';
    $hash->{title} = "Results";

    # Analysis sources can update hash too
    map { $_->update_template_hash($hash, $devices) } @{$self->{_sources}};
}

sub handle_form {
    my ($self, $form) = @_;

    return unless $form && $form->{form} && $form->{form} =~ /^results$/;

    my $yaml_config = $self->yaml('configuration') || {};

    # Set some values in session
    $self->store_in_session( 'results_ordering_column' => $form->{'col'} )
        if $form->{'col'} && $self->{columns} &&
            $form->{'col'} =~ /^$self->{columns}$/;

    $self->store_in_session( 'results_order' => $form->{'order'} )
        if $form->{'order'} && $form->{'order'} =~ /^ascend|descend$/;

    $self->store_in_session( 'results_start' => int($form->{'start'}))
        if defined($form->{'start'}) && $form->{'start'} =~ /^\d+$/;

    $self->store_in_session( 'display' => $form->{'display'} =~ /^\d+$/ ? $form->{'display'} : 0 )
        if defined($form->{'display'});

    $self->store_in_session( 'tag_filter' => $form->{'input/tag_filter'} )
        if defined($form->{'input/tag_filter'});

    my $next_on_deletion = $form->{'next-on-deletion'};
    if (defined($next_on_deletion) && $next_on_deletion eq 'on') {
        $self->store_in_session('next_on_deletion' => 1);
        $next_on_deletion = 1;
    } elsif (defined($form->{'next-edit'})) {
        $self->delete_in_session('next_on_deletion');
        $next_on_deletion = 0;
    }

    $self->edit($form->{'edit'}) if defined($form->{'edit'});

    my $device;
    if (my $edit = $self->edit()) {
        $device = $self->{_devices}->{$edit};
        # Check Source for the entry is NetDiscovery or Edition
        if ($device->source =~ /^NetDiscovery|Edition$/) {
            $self->{_do} = 'edit';
        } elsif ($device->source =~ /^Local|NetInventory$/) {
            if ($device->source eq 'NetInventory' && $device->type !~ /^NETWORKING|PRINTER|STORAGE$/) {
                # First we fix noedit for values provided by NetInventory
                foreach my $key ($device->noedit()) {
                    next if $device->noedit($key);
                    next unless length($device->get($key));
                    $device->dontedit($key);
                }
                # Then permit to change type as it won't be supported on server side
                $device->editfield('type');
                # Finally, this can permit to also fix serial or even mac when also not found by netdiscovery
            } else {
                # Only custom fields can be edited
                foreach my $key ($device->noedit()) {
                    next if $device->noedit($key);
                    next if $key =~ m|^custom/|;
                    $device->dontedit($key);
                }
            }
            $self->{_do} = (grep { not $device->noedit($_) } $device->noedit()) ? 'edit' : '';
        }
    }

    my $changes = 0;
    if ($form->{'submit/delete'}) {
        my @delete = map { m{^checkbox/(.*)$} }
            grep { /^checkbox\// && $form->{$_} eq 'on' } keys(%{$form});

        return $self->errors("Deleting results: No result selected")
            unless @delete;

        map { $self->_delete_device($_) } @delete;
    } elsif ($form->{'submit/update'}) {
        my @fields_update = $self->{_do} ?
            map { m{^edit/(.*)$} } grep { /^edit\// && defined($form->{$_}) } keys(%{$form})
            : ();
        foreach my $field (@fields_update) {
            next if $device->noedit($field);
            next if $device->get($field) eq $form->{"edit/$field"};
            $device->set($field => $form->{"edit/$field"});
            $changes++;
        }
    } elsif ($form->{'submit/scan'}) {
        my @devices = $self->edit() ? ($self->edit()) : map { m{^checkbox/(.*)$} }
            grep { /^checkbox\// && $form->{$_} eq 'on' } keys(%{$form});
        foreach my $device (map { $self->{_devices}->{$_} } @devices) {
            next unless $device->ip && $device->get('ip_range');
            next if $device->isLocalInventory();
            my $inventory = $self->page('inventory')
                or next;
            my $netscan = $inventory->netscan($device->get('ip_range'), $device->ip);
            $self->{tasks}->{$device->ip} = $inventory->{tasks}->{$netscan};
        }
        $self->send_redirect('inventory')
            unless $self->edit();
    } elsif ($form->{'submit/delete-device'}) {
        $self->_delete_device($self->edit());
        if ($next_on_deletion && defined($form->{'next-edit'}) && length($form->{'next-edit'})) {
            $self->edit($form->{'next-edit'});
        } else {
            $self->reset_edit();
        }
    } elsif ($form->{'submit/export'} || $form->{'submit/full-export'}) {
        $self->debug("Doing export for GLPI integration");
        my $archiver = $self->_get_archiver();
        my @time = localtime();
        my $tag_filter = $self->get_from_session('tag_filter');
        my $base_folder = $yaml_config->{networktask_save} || '.';
        my $file = sprintf("%s/%s%s-%d-%02d-%02d-%02dh%02d.%s", $base_folder,
            $form->{'submit/export'} ? "scan-results" : "full-datas-export",
            $tag_filter ne "" ? "-tag_$tag_filter" : "",
            $time[5] + 1900, $time[4]+1, $time[3], $time[2], $time[1],
            $archiver->file_extension()
        );
        $archiver->new_archive($file);
        my $count = 0;
        if ($form->{'submit/export'}) {
            if ($tag_filter ne "") {
                $self->debug("Archiving '$tag_filter' tag results in $file");
            } else {
                $self->debug("Archiving all results in $file");
            }
            foreach my $devid (sort keys(%{$self->{_devices}})) {
                my $device = $self->{_devices}->{$devid};
                next unless ($tag_filter eq "" || $device->tag eq $tag_filter);
                foreach my $xml (sort $device->getFiles()) {
                    next if $xml =~ m|/netdiscovery/|;
                    $self->debug2("Archiving $xml");
                    $archiver->add_file($xml);
                    $count++;
                }
            }
        } else {
            $self->debug("Archiving all export datas in $file");
            foreach my $file (File::Glob::bsd_glob("$base_folder/{netdiscovery,netinventory,inventory}/*")) {
                if ($OSNAME eq 'MSWin32') {
                    $file =~ s{\\}{/}g;
                }
                next if -d $file;
                next unless -s $file;
                $self->debug2("Archiving $file");
                $archiver->add_file($file);
                $count++;
            }
        }
        if ($count && $archiver->save_archive()) {
            $self->info("Sent archive: $file");
            $form->{'send_file'} = $file;
        } elsif ($count) {
            $self->error("Failed to prepare $file export archive: $!");
            $self->errors("Can't prepare archive: $file: $!");
        } else {
            $self->debug("No archive sent: nothing to export");
            $self->errors("Found no file to export");
        }
    } elsif ($form->{'submit/select-fields'} && $device) {
        my %checked = map { $_ => $device->get($_) }
            map { m{^field-checkbox/(.*)$} } grep { m{^field-checkbox/} && $form->{$_} eq 'on' } keys(%{$form});
        $self->store_in_session('checked_fields', \%checked);
    } elsif ($form->{'submit/stop-propagation'}) {
        $self->delete_in_session('checked_fields');
    } elsif ($form->{'submit/set-selected-fields'} && $device) {
        my $checked_fields = $self->get_from_session('checked_fields');
        if ($checked_fields) {
            foreach my $field (keys(%{$checked_fields})) {
                next if $device->noedit($field);
                next if ($device->get($field) eq $checked_fields->{$field});
                if (length($checked_fields->{$field})) {
                    $device->set( $field => $checked_fields->{$field} );
                } else {
                    $device->del($field);
                }
                $changes++;
            }
        }
    }

    if ($changes) {
        $device->set(source => "Edition");

        $self->_save_inventory($device);

        # Finally we should update our results against XMLs
        $self->xml_analysis();
    }
}

sub _delete_device {
    my ($self, $name) = @_;

    my $device = delete $self->{_devices}->{$name}
        or return;

    foreach my $file ($device->getFiles()) {
        $self->debug("Removing $file XML");
        unlink $file
            or $self->errors("Deleting results: Can't remove file: $file, $!");
        delete $self->{_mtime}->{$file};
    }
}

sub _save_inventory {
    my ($self, $device) = @_;

    return unless $device && $device->ip;

    my $yaml_config = $self->yaml('configuration') || {};
    my $kind_base = $device->isLocalInventory ? 'inventory' : 'netinventory';
    my $file;
    if ($device->isLocalInventory) {
        ($file) = grep { m|/inventory/| } $device->getFiles();
    } else {
        $file = ($yaml_config->{networktask_save} || '.')."/netinventory/".$device->ip;
        $file .= "_".$device->tag if $device->tag;
        $file .= ".xml";
    }

    my $xml;
    if (-e $file) {
        $xml = $self->{_xml}->file($file)->dump_as_hash();
    } else {
        # Without existing inventory we suppose this is a new netinventory
        $xml = {
            REQUEST => {
                CONTENT => {
                    DEVICE  => {
                        INFO    => {}
                    },
                },
                QUERY       => 'SNMPQUERY'
            }
        };
    }

    # We don't update inventory if it's a local one
    unless ($device->isLocalInventory) {
        my $info = $xml->{REQUEST}->{CONTENT}->{DEVICE}->{INFO};
        $xml->{REQUEST}->{DEVICEID} = "toolbox";
        $xml->{REQUEST}->{CONTENT}->{MODULEVERSION} =
            "ToolBox v".$GLPI::Agent::HTTP::Server::ToolBox::VERSION;

        my %from = ();
        foreach my $field (GLPI::Agent::HTTP::Server::ToolBox::Results::NetInventory->fields()) {
            $from{$field->{from}} = $field->{name}
                if ($field->{from} && $field->{from} ne 'ips');
        }
        foreach my $key (keys(%from)) {
            next if $device->noedit($from{$key});
            my $value = $device->get($from{$key});
            next unless length($value);
            $info->{$key} = decode_entities($value);
        }

        unless ($device->noedit('ips')) {
            my @ips = ();
            if ($device->ips) {
                @ips = map { decode_entities($_) } split(/\s*,\s*/, $device->ips);
                push @ips, $device->ip
                    unless grep { $device->ip eq $_ } @ips;
            } else {
                push @ips, $device->ip;
            }
            $info->{IPS}->{IP} = \@ips;
        }
    }

    # Handle CUSTOM Fields
    foreach my $source (@{$self->{_any_sources}}) {
        $source->update_xml($xml, $device);
    }

    $self->info("Saving updated $kind_base: $file");
    $self->{_xml}->writefile($file, $xml);
}

sub _register_supported_modules {
    my ($self) = @_;

    # Register all supported fields
    my ($pages_path) = $INC{module2file(__PACKAGE__)} =~ /(.*)\.pm/;
    my @sources;
    my @any;
    foreach my $file (File::Glob::bsd_glob("$pages_path/*.pm")) {
        if ($OSNAME eq 'MSWin32') {
            $file =~ s{\\}{/}g;
            $pages_path =~ s{\\}{/}g;
        }

        my ($name) = $file =~ m{$pages_path/(\S+)\.pm$};
        next unless $name;

        my $module = __PACKAGE__ . "::" . $name;
        $module->require();
        if ($EVAL_ERROR) {
            $self->debug("Failed to load $name Results plugin");
            $self->debug2("Failed to load $name Results plugin: $EVAL_ERROR");
            next;
        }

        # Load module and keep it as fields definition source
        my $module_object = $module->new( results => $self )
            or next;

        if ($module_object->{archive}) {
            push @{$self->{_archive_formats}}, $module_object;
        } elsif ($module_object->any) {
            $self->debug("Loaded $name Results fields module");
            push @any, $module_object;
        } else {
            $self->debug("Loaded $name Results fields module");
            push @sources, $module_object;
        }
    }

    return unless @sources;

    # Order sources by analysis priority
    $self->{_sources} = [
        sort { $a->order <=> $b->order } @sources
    ];
    if (@any) {
        $self->{_any_sources} = [
            sort { $a->order <=> $b->order } @any
        ];
    }

    # Extract and index sections
    my %sections = map { $_->{name} => $_ }
        map { $_->sections() } @any, @sources;

    # Order sections
    $self->{_sections} = [
        sort { $a->{index} <=> $b->{index} } values(%sections)
    ];

    # Index columns & fields
    my %seen = ();
    foreach my $source (@{$self->{_any_sources}}, @{$self->{_sources}}) {
        foreach my $field ($source->fields()) {
            my $column = $field->{name};
            if ($seen{$column} && $source->name ne 'CustomFields') {
                #$self->debug2("Still aware of $column definition from ".$source->name." as still loaded from $seen{$column} results");
                next;
            }
            $self->{_columns}->{$column} = $field;
            $seen{$column} = $source->name;
            # Include field in right section for edit support
            my $section = $sections{$field->{section}};
            $section->{fields}->{$column} = $field;
        }
    }
}

sub _supported_archive_formats {
    my ($self) = @_;

    my @supported = map { $_->format() } sort { $a->order <=> $b->order } @{$self->{_archive_formats}};

    return \@supported;
}

sub _get_archiver {
    my ($self) = @_;

    my $yaml_config = $self->yaml('configuration') || {};
    my $format = $yaml_config->{'archive_format'} || $self->_supported_archive_formats()->[0];
    my ($archiver) = grep { $_->format() eq $format } @{$self->{_archive_formats}};
    return $archiver;
}

1;
