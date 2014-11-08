package HP::Drive::MapperDB;

################################################################################
# Copyright (c) 2013 HP.   All rights reserved
# HP
# HP IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
# COURTESY TO YOU.   BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
# ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
# STANDARD, HP IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
# IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
# FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
# HP EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
# THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
# ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
# FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.
################################################################################

use warnings;
use strict;
use diagnostics;

#=============================================================================
BEGIN
  {
    use Exporter();

    use FindBin;
    use lib "$FindBin::Bin/../..";

	use parent qw(HP::BaseObject Class::Singleton);
	
    use vars qw(
                $VERSION
                $is_debug
                $is_init

                $module_require_list
                $module_request_list

                $broken_install

                @ISA
                @EXPORT
               );

    $VERSION     = 1.2;

    @EXPORT      = qw (
                      );


    $module_require_list = {
	                        'Tie::File'                      => undef,
							
							'HP::Constants'                  => undef,
							'HP::Support::Base'              => undef,
							'HP::Support::Base::Constants'   => undef,
							'HP::Support::Hash'              => undef,
							'HP::Support::Os'                => undef,
							'HP::Os'                         => undef,
							'HP::Support::Object'            => undef,
							'HP::Support::Object::Tools'     => undef,
	                        'HP::CheckLib'                   => undef,
							
							'HP::Array::Constants'           => undef,
							'HP::Path'                       => undef,
							'HP::FileManager'                => undef,
							'HP::String'                     => undef,
							
							'HP::Drive::MapperDB::Constants' => undef,
							'HP::Process'                    => undef,
                          };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_drive_mapperdb_pm'} ||
                 $ENV{'debug_drive_modules'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );

    $broken_install = 0;

    print STDERR "BEGIN <". __PACKAGE__ .">\n" if ( $is_debug );

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "\t--> Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
        if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug ); 
          eval "use $usemod;";
        }
        if ( $@ ) {
          print STDERR "\t--> Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
          die "Exiting!\n$@";
        }
      }
    } else {
      my $use_cmd = &load_required_modules( __PACKAGE__, $module_require_list);
      eval "$use_cmd";
    }

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_request_list})) {
        if ( defined($module_request_list->{$usemod}) ) {
          print STDERR "\t--> REQUESTED [". __PACKAGE__ ."]:: use $usemod $module_request_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_request_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUESTED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug );
          eval "use $usemod;";
        }
        if ( $@ ) {
          print STDERR "\t--> Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
        }
      }
    } else {
      my $use_cmd = &load_required_modules( __PACKAGE__, $module_request_list);
      eval "$use_cmd";
    }

    # Print a message stating this module has been loaded.
    print STDERR "LOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
END 
  {
    print STDERR "UNLOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
sub _new_instance
  {
    return &new(@_);
  }

#=============================================================================
sub __calculate_effective_length_value
  {
    my $self  = shift;
	my $fnlen = shift || return 0;
	return ( int($fnlen * 1.2) );
  }
  
#=============================================================================
sub __divide_and_conquer
  {
    my $self     = shift;
	my $filename = shift || return;
	
	my $os_filename_limit = &get_fn_limit();
	
  RECHECK_FILENAME:
	my $fnlen = length($filename);
	my $calculation = $self->__calculate_effective_length_value($fnlen);
	
	if ( $calculation > $os_filename_limit ) {
	  my @path_components = split('/', &path_to_unix("$filename"));
	  my ( $done, $subpath ) = ( FALSE, '' );
	  while ( $done eq FALSE ) {
	    $subpath .= shift(@path_components);
		$calculation = $self->__calculate_effective_length_value(length($subpath));
		$done = ( $calculation > $os_filename_limit );
	  }
	  my $dl = $self->set_drive("$subpath");
	  $filename = join('/', "$dl", @path_components);
	  $filename = &convert_path_to_client_machine("$filename", &get_os_type());
	  goto RECHECK_FILENAME;
	}
	
	return $filename;
  }

#=============================================================================
sub __is_unc
  {
    my $self = shift;
    my $unc  = shift || return FALSE;
    return &HP::Path::__is_unc_style("$unc");
  }

#=============================================================================
sub __make_drivepath_key
  {
    my $self = shift;
	my $path = shift || return;
	
	$path = &lowercase_first(&path_to_unix("$path"));
	return "$path";
  }

#=============================================================================
sub __make_drive_key
  {
    my $self  = shift;
	my $drive = shift || return;
	
	$drive = &lowercase_all($drive);
	return $drive;
  }
  
#================================================================
sub __parse_net_use_output
  {
    my $self      = shift;
	
    my $outputref = shift;
    my $map       = shift || {};
	
	return $map if ( not defined($outputref) );
	return $map if ( ref($outputref) !~ m/^array/i );
	
    my @output    = @{$outputref};

    my $prevline  = undef;
    my $fullregex = undef;
    my $baseregex = '(\S*)\s+(\S:)\s+(\S+.*\S+)\s+';

    my $MWN       = '\s*Microsoft Windows Network';

    foreach my $line (@output) {
      if ( not $prevline ) {   # first time through
	    $prevline = $line;
	    next;
      }
      if ( $line =~ m/^${MWN}$/) {
	    $fullregex = $baseregex;
      } else {
	    $fullregex = $baseregex . $MWN;
      }
      if ($prevline =~ m/^$fullregex$/) {
	    my ($status, $drive, $unc) = ($1, $2, $3);
	    $unc         = $self->__make_drivepath_key("$unc");
	    $map->{$unc} = $self->__make_drive_key($drive);
      }
      $prevline = $line;
    }
    return $map;
  }

#================================================================
sub __parse_subst_output
  {
    my $self      = shift;
    my $outputref = shift;
    my $map       = shift || {};
	
	return $map if ( not defined($outputref) );
	return $map if ( ref($outputref) !~ m/^array/i );
	
    my @output    = @{$outputref};
    my $baseregex = '^(\S:)\\\\: => (\S+.*)$';

    foreach my $line (@output) {
      if ($line =~ /$baseregex/) {
	    my ($drive, $unc) = ($1, $2);
	    $unc =~ s/^UNC/\\/;
	    $unc           = $self->__make_drivepath_key("$unc");
	    $map->{"$unc"} = $self->__make_drive_key($drive);
      }
    }
    return $map;
  }

#=============================================================================
sub __remove_internal_drive_info
  {
    my $self  = shift;
	my $drive = shift || return FALSE;
	
	return FALSE if ( &os_is_windows() eq FALSE );
	return FALSE if ( $drive eq $self->base_drive() );
	
	# Remove from letter list
	$self->drive_letters()->delete_elements($drive);

	# Remove from mapping
	my $drivemap = $self->drive_map();
	foreach my $key ( keys(%{$drivemap}) ) {
	  my $value = $drivemap->{"$key"};
	  next if ( $value eq $self->base_drive() );
	  delete($drivemap->{"$key"}) if ( $value eq $drive );
	}
	return TRUE;
  }
  
#=============================================================================
sub __run_drive_process
  {
    my $self   = shift;
	my $cmd    = shift || return FAIL;
	
	my $param_array = shift;
	my $retry       = shift;
	
	my $params = [];
	
	$retry = TRUE if ( not defined($retry) );
	
	if ( defined($param_array) && &is_type($param_array, 'HP::Job::ParameterArray') eq TRUE ) {
	  $params = $param_array->get_parameters();  # This is a HP::Job::ParameterArray (array of executableflag)
	} else {
	  $params = $param_array if ( ref($param_array) =~ m/^array/i );
	}
	
	my ( $rval, $stdout, $stderr, $otherdata ) = ( FAIL, undef, undef, {} );
	goto FINISH if ( not defined($cmd) );
	
	my $process_hash = {
	                    'command'   => "$cmd",
					    'arguments' => join(' ', @{$params}),
						'verbose'   => $is_debug,
						'retry'     => $retry,
					   };
	
	&__print_debug_output("Process input hash :\n". Dumper($process_hash)) if ( $is_debug );
	
	( $rval, $stdout, $stderr, $otherdata ) = &runcmd( $process_hash );
	$rval = FAIL if ( not defined($rval) );
  FINISH:
	my $job_output = &create_object('c__HP::Job::JobOutput__');
	
	$job_output->stdout($stdout) if ( defined($stdout) );
	$job_output->stderr($stderr) if ( defined($stderr) );
	
	$job_output->file_out($otherdata->{'file_out'}) if ( defined($otherdata->{'file_out'}) &&
														 &does_file_exist($otherdata->{'file_out'}) );
	$job_output->file_err($otherdata->{'file_err'}) if ( defined($otherdata->{'file_err'}) &&
														 &does_file_exist($otherdata->{'file_err'}) );
	
	return ( $rval, $job_output );
  }

#=============================================================================
sub __used_list
  {
    my $self = shift;
    my $map  = shift;

	my $usedmap = {};
	
    if ( &os_is_windows() eq TRUE ) {
	  foreach my $drive ('c'..'z') {
	    next if ( "$drive:" eq $self->base_drive() );
	    if ( -e "$drive:/" ) {
		  $drive = $self->__make_drive_key("$drive");
	      $usedmap->{"$drive:"} = TRUE;
	      $self->drive_letters()->push_item("$drive:");
			
		  if ( ref($map) =~ m/hash/i ) {
			my $path = undef;
			foreach  my $key ( keys(%{$map}) ) {
			  my $value = $map->{"$key"};
			  if ( $value eq "$drive:" ) {
				$path = $self->__make_drivepath_key("$key");
				last;
			  }
			}
			$self->drive_map()->{"$path"} = "$drive:" if ( defined($path) );
	      }
	    }
      }
	  $self->validate();
    }
	
    return $usedmap;
  }

#=============================================================================
sub add_mapping
  {
    my $self   = shift;
	my $result = FALSE;
	
	return $result if ( &os_is_windows() eq FALSE );
	
	my $path = shift || return $result;
	my $dl   = shift || return $result;
	
	$path = &deblank("$path");
	$dl   = &deblank("$dl");
	
	return $result if ( &valid_string("$path") eq FALSE );
	return $result if ( $path !~ m/^(\S:)/ );
	return $result if ( $dl !~ m/^(\S:)/ || $dl !~ m/^\\\\/ );
	
	$path = $self->__make_drivepath_key("$path");
	$dl   = $self->__make_drive_key("$dl");
	
	my $drivemap = $self->drive_map();
	
	if ( exists($drivemap->{"$dl"}) ) {
	  if ( $drivemap->{"$dl"} ne "$path" ) {
	    &__print_output("Drive mapping for << $dl >> was changed somehow... Recalibrating...", WARN );
		$drivemap->{"$dl"} = "$path";
	  } else {
	    $result = TRUE;
      }
	} else {
	  return $self->set_drive("$path", "$dl");
	}
	return $result;
  }
  
#=============================================================================
sub clear_path
  {
    my $self = shift;
    my $unc  = shift;

    return DRIVE_CLEARED if ( &os_is_windows() eq FALSE );
	
    if ( &valid_string($unc) eq TRUE  ) {
      $unc = $self->__make_drivepath_key("$unc");
      my $drive = $self->find_drive("$unc");
      if ( defined($drive) ) {
	    my $cmd = 'net';
	    my @params = ('use', $drive, '/delete');
	    if ( $self->has_drive_letter("$unc") eq TRUE ) {
	      $cmd = "subst";
	      @params = ($drive, "/d");
	    }

	    my ($rval, $job_outputs) = $self->__run_drive_process("$cmd",\@params, TRUE);
	    $self->__remove_internal_drive_info($drive) if ( $rval eq PASS );
	    return $rval;
      } else {
	    &__print_output("No path/drive mapping found for << $unc >>.", INFO);
	    return DRIVE_CLEARED; # Success because it is not mapped
      }
    }
	return FAIL;
  }

#=============================================================================
sub clear_drive
  {
    my $self  = shift;
    my $drive = shift || return FAIL;
	my $cmd   = shift || 'subst';
	
	return FAIL if ( &valid_string($drive) eq FALSE );
    return DRIVE_CLEARED if ( &os_is_windows() eq FALSE );

	$drive = $self->__make_drive_key("$drive");
	
	if ( &HP::Path::__is_letter_drive($drive) eq TRUE ) {
	  my @params = ();
	  if ( $cmd eq 'net' ) {
	    @params = ('use', $drive, '/delete');
	  } else {
	    @params = ($drive, "/d");
	  }

	  my ($rval, $job_outputs) = $self->__run_drive_process("$cmd", \@params, TRUE);
	  $self->__remove_internal_drive_info($drive) if ( $rval eq PASS );
	  return $rval;
	}
	
	return DRIVE_CLEARED;
  }

#=============================================================================
sub collapse_drivepath
  {
    my $self = shift;
	my $unc  = shift;
	
    return undef if ( &valid_string($unc) eq FALSE );
	return "$unc" if ( &os_is_windows() eq FALSE );
	
	$unc = &eat_quotations("$unc");
	$unc = $self->__make_drivepath_key("$unc");
	my @parts = split('/', "$unc");
	
	my $test_paths    = [ '' ];
	
	foreach ( @parts ) {
	  foreach my $tp ( @{$test_paths} ) {
	    $tp  = &join_path("$tp", "$_");
	    my $reduced_dl = $self->find_drive("$tp");
		if ( defined($reduced_dl) ) {
		  push( @{$test_paths}, "$tp" );
	      $tp  = "$reduced_dl";
		  last;
		}
	  }
	}
	
	my $smallest_path = 0;
	my $test_length   = undef;
	for ( my $loop = 0; $loop < scalar(@{$test_paths}); ++$loop ) {
	  my $len = length($test_paths->[$loop]);
	  if ( not defined($test_length) ) {
	    $test_length = $len;
		next;
	  }
	  if ( $len <= $test_length ) {
	    $test_length = $len;
		$smallest_path = $loop;
	  }
	}
	return &convert_path_to_client_machine("$test_paths->[$smallest_path]", &get_os_type());
  }
  
#=============================================================================
sub data_types
  {
    my $data_fields = {
					   'win2nixmap' => {},
					   'nix2winmap' => {},
					   
					   'sitemap' => {
								     'win2nixmap' => {},
								     'nix2winmap' => {},
								     'binding'    => {},
					                },
								  
					   'drive_letters' => 'c__HP::Array::Set__',
					   'drive_map'     => {},
					   'base_drive'    => 'c:',
		              };
    
    foreach ( @ISA ) {
	  my $parent_types = undef;
	  if ( &function_exists($_, 'data_types') eq TRUE ) {
	    my $evalstr      = "\$parent_types = $_->data_types()";
	    eval "$evalstr";
	    $data_fields     = &HP::Support::Hash::__hash_merge( $data_fields, $parent_types ) if ( defined($parent_types) );
	  }
	}
	
    return $data_fields;
  }

#=============================================================================
sub DESTROY
  {
    my $self = shift;

	#my $tempdir   = &get_temp_dir();
	#my $queuefile = &join_path("$tempdir", QUEUE_FILE);
	
	#$self->remove_process("$queuefile") if ( &does_file_exist("$queuefile") eq TRUE &&
	#                                         &get_file_size("$queuefile") < 1 );
	
	$self->SUPER::DESTROY();
	return;
  }

#=============================================================================
sub enumerate
  {
    my $self = shift;	
    my $map  = {};
	
    if ( &os_is_windows() eq TRUE ) {
      # Run `net use` to see which shares are mapped.
      my ($rval, $job_outputs) = $self->__run_drive_process('net', ['use'], TRUE);
      $map = $self->__parse_net_use_output($job_outputs->stdout(), $map) if ($rval eq PASS);

      # Run `subst` to see which local drives/paths are mapped.
      ($rval, $job_outputs) = $self->__run_drive_process('subst', [], TRUE );
      $map = $self->__parse_subst_output($job_outputs->stdout(),$map) if ($rval eq PASS);
	}

    return $map;
  }

#=============================================================================
sub expand_drivepath
  {
    my $self = shift;
    my $unc  = shift;
	
    return undef if ( &valid_string($unc) eq FALSE );
	return "$unc" if ( &os_is_windows() eq FALSE );
	
	$unc = &eat_quotations("$unc");
	$unc = &path_to_unix("$unc");
	
  	if ( $unc =~ m/^(\w:)\/?(.*)?/ ) {
	  my $letterdrive = $self->__make_drive_key($1);
	  my $continued_path = ( defined($2) ) ? $2 : '';
	  my ($original_path, $needs_expanding) = $self->find_path("$letterdrive");
	  &__print_debug_output("Original path for drive $letterdrive is $original_path") if ( $is_debug );
	  
	  if ( defined($original_path) && $needs_expanding eq TRUE ) {
	    if ( &valid_string($continued_path) eq TRUE ) {
	      $unc = &join_path("$original_path", "$continued_path");
		} else {
		  $unc = "$original_path";
		}
		$unc = $self->expand_drivepath("$unc");  # Recursively expand until run into drive letter which cannot be expanded
	  }
	  &__print_debug_output("Final path to return is $unc") if ( $is_debug );
	}
	
	return &convert_path_to_client_machine("$unc", &get_os_type());
  }

#=============================================================================
sub find_drive
  {
	my $self = shift;
	my $unc  = shift;
    return undef if ( &valid_string($unc) eq FALSE );

	#=========================================================================
	# Check whether input is a full path, partial path (includes letter drive
	# or network path) or is just a network/letter path
	#=========================================================================
    if ( &os_is_windows() eq TRUE ) {
      $unc = &HP::Path::__remove_trailing_slash("$unc");       # Strip trailing slashes
      $unc = $self->__make_drivepath_key("$unc");
	  
      if ( $unc =~ m/\/(\w)(\/\S*)/ ) { $unc = "/".&lowercase_all($1)."$2"; };
      return undef if ( not "$unc" );
	  
      my $mounts = $self->enumerate();
      return $mounts->{"$unc"} if (exists($mounts->{"$unc"}));
      return undef;
    } else {
      # On Unix, the UNC will be treated as a normal path.
      return ( -e "$unc" ) ? "$unc" : undef;
    }
  }

#=============================================================================
sub find_path
  {
    my $self  = shift;
    my $drive = shift;
	return undef if ( &valid_string($drive) eq FALSE );
	
    if ( &HP::Path::__is_letter_drive($drive) ) {
	  $drive = $self->__make_drive_key("$drive");
	  
      my $mounts = $self->enumerate();
	  my %reverse_mounts = reverse %{$mounts};
	  &__print_debug_output(Dumper(\%reverse_mounts)) if ( $is_debug );
	  
      foreach my $dl (keys(%reverse_mounts)) {
	    #&__print_output("Checking drive letter $dl");
	    if ( $dl eq $drive ) { return ( $reverse_mounts{$dl}, TRUE ); }
	  }
    }   
	return ("$drive", FALSE);
  }

#=============================================================================
sub get_drives
  {
    my $self = shift;
	if ( &os_is_windows() eq TRUE ) {
	  my $mapped_drives = $self->drive_letters()->get_elements();
	  push( @{$mapped_drives}, $self->base_drive() );
	  return $mapped_drives;
	}
	return [];
  }
  
#=============================================================================
sub has_drive_letter
  {
    my $self = shift;
    if ( &os_is_windows() eq TRUE ) {
      my $path = shift;
      my $drv_ltr = $self->__make_drive_key("$path");
      $path = "$drv_ltr" if ( $drv_ltr ne "$path" );
      return &HP::Path::__is_letter_drive("$path");
	}
	
	return FALSE;
  }

#=============================================================================
sub install_map
  {
    my $self = shift;
	my $map  = shift || return;
	
	return if ( &os_is_windows() eq FALSE );
	
	my $drivemap = $self->drive_map();
	
	foreach ( keys(%{$map}) ) {
	  my $path = $_;
	  my $dl   = $map->{"$_"};
	  
	  my $drivemap_setting = $drivemap->{"$dl"};
	  if ( defined($drivemap_setting) ) {
	    if ( $drivemap_setting ne "$path" ) {
		  # DriveMap was switched outside of this MapperDB interface...
		  &__print_output("Drive mapping for << $dl >> was changed somehow... Recalibrating...", WARN );
		  $drivemap->{"$dl"} = "$path";
		}
	  } else {
	    $self->set_drive("$path", "$dl", FALSE, TRUE, TRUE);
	  }
	}
  }
  
#=============================================================================
sub new
  {	
    my $class       = shift;
    my $data_fields = &data_types();

    my $self = {
		        %{$data_fields},
	           };
	
	if ( @_ ) {
	  if ( ref($_[0]) =~ m/hash/i ) {
	    foreach my $key (keys{%{$_[0]}}) {
		  $self->{"$key"} = $_[0]->{"$key"} if ( exists($self->{"$key"}) );
		}
	  } else {
	    &__print_output("Please use a hash as input to construct this class < $class >", 'STDERR');
		return undef;
	  }
	}

    bless $self, $class;
	$self->instantiate();
	$self->setup();
	my $current_map = $self->enumerate();
	$self->__used_list($current_map);  # Ensure we get the C: drive if it is windows...
    return $self;
  }

#=============================================================================
sub release_drives
  {
    my $self = shift;
	if ( &os_is_windows() eq TRUE ) {
	  foreach ( @{$self->get_drives()} ) {
	    next if ( $_ eq $self->base_drive() );
	    $self->clear_drive("$_");
	  }
	}
	return;
  }

#=============================================================================
sub set_base_drive
  {
    my $self = shift;
	my $base_dl = shift || $self->data_types()->{'base_drive'};
	
	$self->base_drive("$base_dl");
	return;
  }

#=============================================================================
sub set_drive
  {
    my $self = shift;
    my $unc  = shift;
    return undef if ( &valid_string($unc) eq FALSE );
	
    if ( &os_is_windows() eq TRUE ) {
      my $preferred_letter   = shift;
      my $persistent         = shift;
	  my $smallest_footprint = shift;
	  my $force              = shift || FALSE;
	  
      $unc              = $self->__make_drivepath_key("$unc");
      $preferred_letter = $self->__make_drive_key($preferred_letter) if ( defined($preferred_letter) );
      $persistent       = $persistent ? '/persistent:yes' : '';

	  $smallest_footprint = TRUE if ( not defined($smallest_footprint) );
	  
	  if ( $is_debug ) {
	    &__print_debug_output("Path --> << $unc >>", __PACKAGE__);
	    &__print_debug_output("Preferred Drive Letter --> << $preferred_letter >>", __PACKAGE__) if ( defined($preferred_letter) );
	    &__print_debug_output("Persistent --> << $persistent >>", __PACKAGE__);
      }
	
      $unc = &HP::Path::__remove_trailing_slash("$unc"); # Strip trailing slashes
      return undef if ( &valid_string("$unc") eq FALSE );

      my $mounts = $self->enumerate();

      return $mounts->{"$unc"} if (exists($mounts->{"$unc"})); # Return if already completely mapped.

	  $unc = $self->collapse_drivepath("$unc") if ( $smallest_footprint eq TRUE ); # Attempt to find smallest representation
	  $unc = $self->__divide_and_conquer("$unc") if ( $force eq FALSE );
	  
	  return $unc if ( &HP::Path::__is_only_letter_drive("$unc") eq TRUE );
	  
      my $drive   = undef;
      my $usedmap = $self->__used_list();
      if ( defined($preferred_letter) ) {
	    $preferred_letter.= ':' if (length("$preferred_letter") == 1);
	    if ($preferred_letter =~ /^[a-z]\:$/) {
	      $drive = $preferred_letter if ( not exists($usedmap->{$preferred_letter}) );
	    }
      }

      if ( not defined($drive) ) {
	    my $found_available_driveletter = FALSE;
	    foreach (reverse 'c'..'z') {
	      if ( not exists($usedmap->{"$_:"}) ) {
	        $drive = "$_:";
	        $found_available_driveletter = TRUE;
	        last;
	      }
	    }
	    if ( $found_available_driveletter eq FALSE ) {
	      &__print_output("Unable to find an available drive letter (ALL USED!!!)");
	      return undef;
	    }
      }

	  &__print_debug_output("Drive letter found --> << $drive >>", __PACKAGE__) if ( $is_debug );
	  
      $unc = &path_to_win("$unc");
      my $cmd    = 'net';
      my @params = ( 'use', $drive, "\"$unc\"", $persistent );
      if ( $self->has_drive_letter("$unc") eq TRUE ) {
	    $cmd    = "subst";
	    @params = (  $drive, "\"$unc\"" );
      }
	  &__print_debug_output("Command --> $cmd ".join(" ", @params), __PACKAGE__) if ( $is_debug );
	  
      my ($rval, $job_outputs) = $self->__run_drive_process( "$cmd", \@params, TRUE );

	  &__print_debug_output("Return code = $rval", __PACKAGE__) if ( $is_debug );
	  
      return undef if (($rval != PASS) || (scalar(@{$job_outputs->stderr()}) and $job_outputs->stderr()->[0] =~ m/error/i));
	  $self->drive_letters()->push_item("$drive");
	  $self->drive_map()->{$self->__make_drivepath_key("$unc")} = "$drive";
      return $drive;
    } else {
      return (-e "$unc") ? "$unc" : undef;
    }
  }

#=============================================================================
sub setup
  {
    my $self = shift;
	
	if ( 0 ) {
	my $tempdir = &get_temp_dir();
	my $pid     = &get_pid();
	my $qfile   = &join_path("$tempdir", QUEUE_FILE);
	
	my $lockDB  = &getDB('lock');
	my $key     = 'mapperDB';

	if ( &does_file_exist("$qfile") eq TRUE ) {
	  my $is_in_qfile = $self->find_pid_in_queue($pid, "$qfile");
	  if ( $is_in_qfile eq FALSE ) {
	    $self->add_pid_to_queue($pid, "$qfile");
		# WAIT
	  } else {
	    my $pids = $self->get_pids_for_queue("$qfile");
		if ( $pids->[0] eq $pid ) {
	      my $mtxlck  = $lockDB->find_lock($key);
		  if ( not defined($mtxlck) ) {
		    $mtxlck = $self->add_mutex_lock($key);
		  }
		  my $mutexfile = $mtxlck->filepath();
		  if ( &does_file_exist("$mutexfile") eq TRUE ) {
		    # WAIT
		  } else {
		    $self->remove_pid_from_queue($pid, "$qfile");
			if ( $self->qfile_empty() eq TRUE ) {
			  &delete("$qfile");
			}
			$mtxlck->lock();
	        $self->write_mappings();
			$mtxlck->unlock();
		  }
		}
	  }
	}
	}
	
	
	
	
	
	
	
	
	
	
	# if ( queuefile present ) {
	  # if ( my pid not in queuefile ) {
	    # push pid to queuefile
		# wait till my pid at front of queue
	  # } else {
	    # if ( my pid at front of queue ) {
	      # if ( mutex file present ) {
		    # wait for mutex to disappear
		  # } else {
		    # remove pid from queue
			# if ( queuefile has no other entries ) {
			  # remove queuefile
			# }
			# create mutex file
			# do work
			# remove mutex file
		  # }
		# } else {
		  # wait till my pid at front of queue
		# }
	  # }
	# } else {
	  # if ( mutex file present ) {
	    # push pid to queuefile
		# wait for mutex to disappear
	  # } else {
	    # create mutex file
		# do work
		# remove mutex file
	  # }
	# }
	
	# Check to see if a mutex filelock is in play [ need to use a STANDARD location ]
	# my $tempdir = &get_temp_dir();
	# my $pid     = &get_pid();
	
	# my $lockDB  = &getDB('lock');
	# my $key     = 'mapper_'.$pid;
	# my $mtxlck  = $lockDB->find_lock($key);

	# if ( not defined($mtxlck) ) {
	  # my $mtxfile = &join_path("$tempdir", MUTEX_FILE);
	  # if ( &does_file_exist("$mtxfile") eq TRUE ) {
	  
	    # # Some other process has a lock for DRIVE ACCESS management, need to wait...
		# my $timedlock    = &create_object('c__HP::Lock::TimedMutex__');
		# my $timedmtxfile = &join_path("$tempdir", 'timer_'.$pid);
		# $timedlock->filepath("$timedmtxfile");
		# $timedlock->start();
		
		# while ( &does_file_exist("$timedmtxfile") eq TRUE ) {
		  # sleep 5;
		# }
	  # }
	  
	  # $mtxlck = &create_object('c__HP::Lock::Mutex__');
	  # $mtxlck->filepath();
	  # $mtxlck->key($key);
	  # $lockDB->add_lock($mtxlck);
	# }
	
	# my $queuefile = &join_path("$tempdir", QUEUE_FILE);
	
	# my $numtries  = DEFAULT_TIEFILE_COUNT;
	# my $timeout   = DEFAULT_TIEFILE_TIME;
	# my $algo      = DEFAULT_TIEFILE_ALGORITHM;
	
	# my $job_q = &create_object('c__HP::Array::Queue__');
	
	# my $has_mtx_file = &does_file_exist("$mutexfile");
	# if ( $has_mtx_file eq TRUE ) {
	  # my $has_q_file = &does_file_exist("$queuefile");
	  # if ( $has_q_file eq TRUE ) {
	    # $self->import_queued_processes
		# $job_q->add_elements({'entries' => \@q});
	  # }
	# } else {
	  # # Should not have queue file if no mutexfile present
	  # if ( &delete("$queuefile") != 1 ) {
	    # &__print_output("Unable to remove (likely) outmoded queue file.  Stopping process now until this can be manually resolved!", FAILURE);
	    # exit 1;
	  # }
	# }
	# my $order_in_q   = ( $has_cue_file eq FALSE ) ? -1 : $self->find_in_queue("$queuefile");
	
	# my $must_wait    = $self->__check_for_wait_status($order_in_q, $has_mtx_file);
	
	# if ( $must_wait eq TRUE ) {
	  # $self->add_to_cue($queuefile, &get_pid());
	# }
	# my $trial = 0;
	# while ( &does_file_exist("$mutexfile") eq TRUE && $trial < $numtries ) {
	   # sleep($timeout);
	   # ++$trial;
	# }
	
	
	# my $xmlfile   = $ENV{'DRIVE_INSTANTIATION_FILE'} || &join_path("$tempdir", 'DRIVE_ACCESS.map');
	# my $xmlfile = $ENV{'DRIVE_INSTANTIATION'} || undef;
	# if ( defined($xmlfile) &&
	     # ( &does_file_exist("$xmlfile") eq TRUE ) ) {
	  # my $xmlobj = &create_object('c__HP::XMLObject__');
	  # $xmlobj->xmlfile("$xmlfile");
	  # $xmlobj->readfile();
	  
	  # my $drivemappings = $xmlobj->get_nodes_by_xpath({'xpath' => '//drive_maps'});
      # &__print_debug_output( $drivemappings, __PACKAGE__ ) if ( $is_debug );
	  
	  # if ( defined($drivemappings) ) {
	    # my $mapnodes = $xmlobj->get_nodes_by_xpath({'xpath' => '', 'node' => $drivemappings->[0]});
		# foreach ( @{$mapnodes} ) {
		  # my $attrs = $xmlobj->get_attributes($_);
		  
		  # my ($unixpath, $windowspath) = (undef, undef);
		  
		  # if ( &set_contains('multi_match_unix', $attrs) eq TRUE ) {
		    # $unixpath    = $_->get_attribute_content('unix')    if ( &set_contains('unix', $attrs) eq TRUE );
			# $windowspath = $_->get_attribute_content('windows') if ( &set_contains('windows', $attrs) eq TRUE );
			# $site        = $_->get_attribute_content('site')    if ( &set_contains('site', $attrs) eq TRUE );
			
			# $site = 'LOCAL' if ( not defined($site) );
			# if ( defined($unixpath) && defined($windowspath) ) {
			  # $self->{'win2nixmap'}->{"$windowspath"} = "$unixpath";
 	          # $self->{'site'}=>{'win2nixmap'}->{$site}->{"$windowspath"} = "$unixpath";
			# }
		  # }
		# }
		
		# foreach my $site (keys(%site_win2nixmap)) {
 	      # my %temp = %{$site_win2nixmap{"$site"}};
 	      # %temp    = reverse %temp;
 	      # $site_nix2winmap{"$site"} = \%temp;
 	    # }

	    # # multi-mappings (unix -> windows)
	    # foreach my $drive_rec (@drives) {
	      # next if ( not exists($drive_rec->{'multi_match_unix'}) );
	      # my @mmu = split(" ",$drive_rec->{'multi_match_unix'});
	      # my $windowspath = $drive_rec->{'windows'};
	      # foreach my $MMU (@mmu) {
	        # my $unixpath = $drive_rec->{'unix'};
            # if ( defined($unixpath) and defined($windowspath) ) {
	          # $unixpath    =~ s/\$MMU/$MMU/g;
	          # $nix2winmap{"$unixpath"} = "$windowspath";
	          # $site_nix2winmap{$drive_rec->{'site'}}{"$unixpath"} = "$windowspath";
	        # }
          # }
	    # }
	  # }
	  
	  # if ( exists($drivemappings->{'bind'}) ) {
        # my @drives = &convert_2_array($drivemappings->{'bind'});
        # foreach my $bind_rec (@drives) {
          # my $bindsite = $bind_rec->{'site'} || $ENV{'XLNX_SITE'};
          # my $bindtype = $bind_rec->{'type'};
          # my $path1 = $bind_rec->{'path1'};
          # my $path2 = $bind_rec->{'path2'};
          # if ( defined($path1) and defined($path2) and defined($bindtype) ) {
            # $site_binding{"$bindsite"}{"$bindtype"}{"$path1"} = "$path2";
          # }
        # }
      # }
	# }
  }

#=============================================================================
sub validate
  {
    my $self = shift;
  }
  
#=============================================================================
1;