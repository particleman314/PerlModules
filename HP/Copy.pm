package HP::Copy;

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
    use lib "$FindBin::Bin/..";

    use vars qw(
                $VERSION
                $is_debug
                $is_init

                $module_require_list
                $module_request_list

                $broken_install

                $min_timeout
                $wait_time

                @ISA
                @EXPORT
               );

    @ISA    = qw(Exporter);
    @EXPORT = qw(
                 &copy_with_retry
                 &copy_with_retry_and_exclusions
                 &copy_with_mkdir
                 &copy_with_rsync
                 &copy_with_rsync_no_svn
				 &duplicate
				 &duplicate_file
				 &duplicate_directory
				 &move_contents
                );

    $module_require_list = {
                            'File::Basename'               => undef,
                            'File::Copy'                   => undef,
                            'File::Copy::Recursive'        => undef,
                            'File::Path'                   => undef,
                            'File::Spec'                   => undef,
							'Text::ParseWords'             => undef,

							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Os'              => undef,
							'HP::Support::Os::Constants'   => undef,
							'HP::Support::Object::Tools'   => undef,
							
							'HP::Copy::Constants'          => undef,
							'HP::CheckLib'                 => undef,
							'HP::Os'                       => undef,
							'HP::Array::Tools'             => undef,
							'HP::FileManager'              => undef,
							'HP::Path'                     => undef,
							'HP::Process'                  => undef,
                           };
    $module_request_list = {};

    $VERSION     = 1.0;
    $min_timeout = undef;
    $wait_time   = undef;

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_copy_pm'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

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
sub __convert_options_to_arrays($)
  {
    return if ( scalar(@_) < 1 );
	return if ( ref($_[0]) !~ m/hash/i );
	  
	foreach my $oskey ( keys(%{$_[0]}) ) {
	  if ( ref($_[0]->{$oskey}) =~ m/hash/i ) {
	    foreach ( keys(%{$_[0]->{$oskey}}) ) {
	      my $stropts = $_[0]->{$oskey}->{$_};
		  if ( &valid_string($stropts) ) {
	        $_[0]->{$oskey}->{$_} = &create_object('c__HP::Array::Queue__');
		    my @contents = parse_line('\s+', 0, $stropts);
		    $_[0]->{$oskey}->{$_}->add_elements({'entries' => \@contents});
		  }
		}
	  }
	}
  }

#=============================================================================
sub __copy_using_unix($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'src', \&valid_string, 'dest', \&valid_string, 'rsync_opts', undef ], @_);
    } else {
	  $inputdata = $_[0];
	}
	
    return undef if ( scalar(keys(%{$inputdata})) == 0 );

    my $src                   = $inputdata->{'src'};
    my $dest                  = $inputdata->{'dest'};
    my $additional_rsync_opts = $inputdata->{'rsync_opts'};

    my $exe_rsync = &path_to_mixed(&which('rsync'));

    &__print_debug_output("Rsync executable --> $exe_rsync\n", __PACKAGE__) if ( $is_debug );
    if ( not defined($exe_rsync) ) {
      &raise_exception(
	                   {
					    'type'    => 'c__HP::Path::NoExecutableFoundException__',
						'msg'     => "Could not find reliable executable under Linux/Cygwin [ ". &get_method_name() ." ].",
						'streams' => [ 'STDERR' ],
						'bypass'  => TRUE,
					   }
					  );
      return FALSE;
    }

    # This enforces NO colons since rsync uses this as a reserved means
    # of testing for port and protocol of connection.
    if ( &os_is_cygwin() eq TRUE ) {
      $src  = &path_to_unix("$src");
      $dest = &path_to_unix("$dest");
    }

    # This will translate multiple ../ embedded within path since that
    # can have unusual side-effects elsewhere in the code base.
    $src  = &normalize_path("$src");
    $dest = &normalize_path("$dest");

    &__print_debug_output("RSYNC :: Source --> $src\nRSYNC :: Destination --> $dest", __PACKAGE__) if ( $is_debug );

    my $dest_parent_dir = File::Basename::dirname($dest);

    &__print_debug_output("Destination parent --> $dest_parent_dir\n", __PACKAGE__) if ( $is_debug );
    &make_recursive_dirs("$dest_parent_dir", 0777) if ( &does_directory_exist( "$dest_parent_dir" ) eq FALSE );
    return FALSE if ( &does_directory_exist( "$dest_parent_dir" ) eq FALSE );

    my $hashcmd = {
	               'command'   => "$exe_rsync",
		           'arguments' => "'$src' '$dest'",
		           'verbose'   => $is_debug,
                  };
				  
	if ( defined($additional_rsync_opts->{'linux'}) ) {
	  $hashcmd->{'arguments'} = "-al $additional_rsync_opts->{'linux'} ".$hashcmd->{'arguments'};
	}
	
    my ($exitcode, $output) = &runcmd($hashcmd, 1);

    if ($exitcode != PASS ) {
      &raise_exception(
	                   {
					    'type'    => 'c__HP::Copy::CopyFailureException__',
						'msg'     => "Could not copy << $src >> to << $dest >>.  Exit code $exitcode.\nError : ".join("\n",@${output}),
						'streams' => [ 'STDERR' ],
						'bypass'  => TRUE,
					   }
					  );
      return FALSE;
    }
    return TRUE;
  }
  
#=============================================================================
sub __copy_using_windows($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'src', \&valid_string,
	                                        'dest', \&valid_string,
											'rsync_opts', undef ], @_);
    } else {
	  $inputdata = $_[0];
	}
	
    return undef if ( scalar(keys(%{$inputdata})) == 0 );

    my $src                   = $inputdata->{'src'};
    my $dest                  = $inputdata->{'dest'};
    my $additional_rsync_opts = $inputdata->{'rsync_opts'};

    $src  = &path_to_win(&normalize_path("$src"));
    $dest = &path_to_win(&normalize_path("$dest"));

	if ( $is_debug ) {
      &__print_debug_output("(B) Source path      --> $src\n", __PACKAGE__ );
      &__print_debug_output("(B) Destination path --> $dest\n", __PACKAGE__ );
	}
	
	my $issrcdir  = &does_directory_exist( "$src" );
	
	##########################################################################
	# What possibilities exist?
	#
	# 1) copy(src, dest)   --> copy srcdir (+ internals) to internals of dest
	# 2) copy(src/, dest)  --> copy internals of src to internals of dest
	# 3) copy(src, dest/)  --> see #1
	# 4) copy(src/, dest/) --> see #2
	##########################################################################
	
	$dest = &HP::Path::__remove_trailing_slash("$dest");

	if ( $issrcdir eq TRUE ) {
	  my ($modified_src, $has_last_slash) = &HP::Path::__remove_trailing_slash("$src");
	  if ( $has_last_slash eq FALSE ) {
	    $dest = &join_path("$dest", File::Basename::basename("$src"));
	    &make_recursive_dirs("$dest", 0777);
	    &__print_debug_output("New destination directory is $dest\n", __PACKAGE__) if ( $is_debug );
      }
      $src = "$modified_src";
	}

	my $jobobj = &__determine_copy_method($additional_rsync_opts, $issrcdir, $src, $dest);

	if ( defined($jobobj->get_executable()) ) {
	  if ( $is_debug ) {
        &__print_debug_output("(E) Source path      --> $src\n", __PACKAGE__ );
        &__print_debug_output("(E) Destination path --> $dest\n", __PACKAGE__ );
	  }

	  #$jobobj->add_flags("\"$src\"", 1);
	  #$jobobj->add_flags("\"$dest\"", 2);
	  
      #&__print_output("Command to invoke --> ". $jobobj->get_cmd(). "\n", INFO ) ;
      &__print_debug_output("Command to invoke --> ". $jobobj->get_cmd(). "\n", __PACKAGE__ ) if ( $is_debug );

	  $jobobj->run();
	  
	  my $status = $jobobj->get_error_status();
	  my $output = $jobobj->get_file_output_contents();
	  my $error  = $jobobj->get_file_error_contents();
	  
      if ( $is_debug ) {
        &__print_debug_output("exit code = $status\n", __PACKAGE__);
        &__print_debug_output("Output generated --> ".Dumper($output).Dumper($error), __PACKAGE__);
	  }
		
      if ( $status eq FAIL ) {
	    my $msg = "Could not copy << $src >> to << $dest >>.  Exit code $status.";
		if ( defined($output) ) { $msg .= join("\n",@{$output}); }
		if ( defined($error) ) { $msg .= join("\n",@{$error}); }
        &raise_exception(
	                     {
					      'type'    => 'c__HP::Copy::CopyFailureException__',
						  'msg'     => "$msg",
						  'streams' => [ 'STDERR' ],
						  'bypass'  => TRUE,
					     }
					    );
	    return FALSE;
      }
      return TRUE;
    } else {
	  # Fallback to using File::Copy::Recursive
	  my ($num_of_files_and_dirs, $num_of_dirs, $depth_traversed) = File::Copy::Recursive::rcopy("$src", "$dest");
	  if ( $num_of_files_and_dirs < 1 ) {
        &raise_exception(
	                     {
					      'type'    => 'c__HP::Path::NoExecutableFoundException__',
						  'msg'     => "Could not find reliable executable under Windows [ ". &get_method_name(). " ].",
						  'streams' => [ 'STDERR' ],
						  'bypass'  => TRUE,
					     }
					    );
        return FALSE;
	  }
	  return TRUE;
    }
  }

#=============================================================================
sub __determine_copy_method($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $additional_opts = shift;
	my $isdir           = shift || FALSE;
	my $src             = shift;
	my $dest            = shift;
	
	my @copy_options    = ();
	
	if ( $isdir eq TRUE ) {
	  @copy_options = qw( __find_robocopy __find_xcopy );
	} else {
	  @copy_options = qw( __find_robocopy __find_copy );
	}
	
	my ( $exe, $options, $filename, $use_robocopy ) = ( undef, {}, undef, FALSE );
	
	for ( my $loop = 0; $loop < scalar(@copy_options); ++$loop ) {
	  no strict;
	  ( $exe, $options ) = &{$copy_options[$loop]}($additional_opts);
	  use strict;
	  if ( defined($exe) ) {
	    if ( $isdir eq FALSE && $loop == 0 ) {
		  $filename = File::Basename::basename("$src");
		  $src      = File::Basename::dirname("$src");
		  $options->delete_elements('/E', '/COPYALL', '/MIR', '/S');
		}
	    last;
	  }
	}
	
	if ( not defined($exe) ) {  
	  &__print_output("Attempting to use perl File::Recursive::Copy to accomodate request!", WARN);
	  return undef;
	}
	
	my $jobobj = &create_object('c__HP::Job__');
	$jobobj->set_executable($exe);
	
	$jobobj->add_flags("\"$src\"");
	$jobobj->add_flags("\"$dest\"");
	$jobobj->add_flags("\"$filename\"") if ( $isdir eq FALSE && &valid_string($filename) eq TRUE );
	
	foreach ( @{$options->get_elements()} ) {
	  $jobobj->add_flags("$_") if ( &valid_string($_) eq TRUE );
	}
	
	return $jobobj;
  }
  
#=============================================================================
sub __find_copy($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $additional_options = shift;
	my $exe                = &which('copy');
	my $cmd_options        = ( ref($additional_options) =~ m/hash/i ) ? $additional_options->{&WINDOWS_SHORTNAME}->{'copy'} : {};
	
	return ( $exe, $cmd_options );
  }

#=============================================================================
sub __find_robocopy($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $additional_options = shift;
	my $exe                = &which('robocopy');
	my $cmd_options        = ( ref($additional_options) =~ m/hash/i ) ? $additional_options->{&WINDOWS_SHORTNAME}->{'robocopy'} : {};
	
	return ( $exe, $cmd_options );
  }
  
#=============================================================================
sub __find_xcopy($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $additional_options = shift;
	my $exe                = &which('xcopy');
	my $cmd_options        = ( ref($additional_options) =~ m/hash/i ) ? $additional_options->{&WINDOWS_SHORTNAME}->{'xcopy'} : {};
	
	return ( $exe, $cmd_options );
  }

#=============================================================================
sub __handle_exclusions($$$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'entries', undef, 'rellocation', \&valid_string,
	                                        'topsource', \&valid_string, 'exclusions', undef ], @_);
    } else {
	  $inputdata = $_[0];
	}
	
    return undef if ( scalar(keys(%{$inputdata})) == 0 );

    my $entries          = $inputdata->{'entries'};
    my $relativeLocation = $inputdata->{'rellocation'};
    my $topsource        = $inputdata->{'topsource'};
    my $exclusions       = $inputdata->{'exclusions'};

	my $d2t = &create_object('c__HP::Array::Queue__');
	my $fsd = &create_object('c__HP::ArrayObject__');

    foreach my $entry ( @{$entries} ) {

      # if entry is a directory check to see if it is one where we
      # should exclude.

      my $relpathName = "$entry";
      $relpathName = File::Spec->catfile("$relativeLocation", "$entry")
        if ( length("$relativeLocation") );

      $relpathName = File::Spec->canonpath("$relpathName");
	  
	  if ( &is_type($exclusions, 'HP::ArrayObject') eq TRUE ) {
        $exclusions->delete_elements("$relpathName") if ( $exclusions->contains("$relpathName") eq TRUE );
	  }

      my $fullpathName = File::Spec->catfile("$topsource", "$relpathName");
      if ( &does_directory_exist("$fullpathName") eq TRUE ) {
	    $d2t->push("$fullpathName");
      } else {
	    $fsd->push("$fullpathName");
      }
    }
    return ($d2t, $fsd)
  }

#=============================================================================
sub __initialize()          
  {                         
    if ( not $is_init ) {   
      $is_init = 1;
	  
	  &__update_copy_timeout_interval($ENV{'COPY_TIMEOUT_LIMIT'});
	  &__update_copy_timeout_interval($ENV{'COPY_WAIT_PERIOD'});
	  &__verify_timeout();
	  
      print STDERR "INIITALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  } 

#=============================================================================
sub __reset_timeouts()
  {
    $wait_time = undef;
	$min_timeout = undef;
	&__verify_timeout();
  }
  
#=============================================================================
sub __update_copy_wait_interval($)
  {
    return if ( scalar(@_) < 1 || ( not defined($_[0]) ) );
    if ( ( defined($_[0]) ) &&
	     ( &is_integer($_[0]) eq TRUE ) &&
		 ( $_[0] > 0 ) ) {
      $wait_time = $_[0];
      &__print_output("Redefined the copy wait period to << $wait_time >> seconds", __PACKAGE__) if ( $is_debug );
    }
	&__verify_timeout('wait_time');
  }
  
#=============================================================================
sub __update_copy_timeout_interval($)
  {
    return if ( scalar(@_) < 1 || ( not defined($_[0]) ) );
    if ( ( defined($_[0]) ) &&
	     ( &is_integer($_[0]) eq TRUE ) &&
		 ( $_[0] > 0 ) ) {
      $min_timeout = $_[0];
      &__print_output("Redefined the copy timeout limit to << $min_timeout >> seconds", __PACKAGE__) if ( $is_debug );
    }
	&__verify_timeout('min_timeout');
  }

#=============================================================================
sub __verify_timeout(;$)
  {
    if ( scalar(@_) < 1 || $_[0] eq 'wait_time') {
	  $wait_time = DEFAULT_WAIT_TIME if ( not defined($wait_time) );
	}
    if ( scalar(@_) < 1 || $_[0] eq 'min_timeout') {	
	  $min_timeout = DEFAULT_MINIMUM_TIMEOUT if ( not defined($min_timeout) );
	}
	return;
  }
  
#=============================================================================
sub copy_with_mkdir($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    if ( &os_is_windows() eq TRUE ) {
	  my $inputdata = {};
      if ( ref($_[0]) !~ m/hash/i ) {
        $inputdata = &convert_input_to_hash([ 'src', \&valid_string,
		                                      'dest', \&valid_string ], @_);
      } else {
	    $inputdata = $_[0];
	  }
	
      return undef if ( scalar(keys(%{$inputdata})) == 0 );

      my $source = $inputdata->{'src'};
      my $dest   = $inputdata->{'dest'};

      return FALSE if ( ( not defined($source) ) || ( not defined($dest) ) );

      $source = &normalize_path("$source");
      $dest   = &normalize_path("$dest");

      &__print_debug_output("NATIVE :: Source --> $source :: Destination --> $dest", __PACKAGE__) if ( $is_debug );

      if ( &does_directory_exist( "$source" ) eq FALSE ) {
	    return FALSE;
      } else {
	    if ( &does_directory_exist( "$dest" ) eq FALSE ) {
		  &make_recursive_dirs("$dest", 0777);
		  return FALSE if ( &does_directory_exist( "$dest" ) eq FALSE );
		}
		return &copy_with_rsync("$source", "$dest");
		#my ($num_of_files_and_dirs, $num_of_dirs, $depth_traversed) = File::Copy::Recursive::rcopy("$source", "$dest");
		#if ( $is_debug ) {
        #  &__print_debug_output("Number of files       copied : ".($num_of_files_and_dirs - $num_of_dirs), __PACKAGE__);
        #  &__print_debug_output("Number of directories copied : $num_of_dirs", __PACKAGE__);
		#}
		#if ( $num_of_files_and_dirs != 0 || $num_of_dirs != 0 ) { return TRUE; }
		#return FALSE;
	  }
    }
	
    return &copy_with_rsync(@_);
  }

#=============================================================================
sub copy_with_retry($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'src', \&valid_string,
	                                        'dest', \&valid_string,
	                                        'timeout', \&is_integer ], @_);
    } else {
	  $inputdata = $_[0];
	}
	
    return undef if ( scalar(keys(%{$inputdata})) == 0 );

    my $source      = $inputdata->{'src'};
    my $destination = $inputdata->{'dest'};
    my $timeout     = $inputdata->{'timeout'} || $min_timeout;
    my $timesup     = time() + $timeout;

    return FALSE if ( ( not defined($source) ) || ( not defined($destination) ) );

    $source      = &normalize_path("$source");
    $destination = &normalize_path("$destination");

    &__print_debug_output("Source :: $source || Destination :: $destination", __PACKAGE__) if ( $is_debug );

    if ( not -e "$source" ) {
	  &raise_exception(
	                   {
					    'type'    => 'c__HP::FileManager::FileNotFoundException__',
						'msg'     => "Source file << $source >> does not exist [ ". &get_method_name(). " ]",
						'streams' => [ 'STDERR' ],
						'bypass'  => TRUE,
					   }
					  );
      return FALSE;
    }

    while ( &copy_with_mkdir("$source", "$destination") eq FALSE ) {
      if ( $timesup < time() ) {
	    &raise_exception(
	                     {
					      'type'    => 'c__HP::Copy::CopyFailureException__',
						  'msg'     => "Timed out trying to copy file to share ($source => $destination)",
						  'streams' => [ 'STDERR' ],
						  'bypass'  => TRUE,
					     }
						);
	    return FALSE;
      }

      sleep($wait_time);
    }
    return TRUE;
  }

#=============================================================================
sub copy_with_rsync($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'src', \&valid_string,
	                                        'dest', \&valid_string,
											'addon_opts', undef ], @_);
    } else {
	  $inputdata = $_[0];
	}
	
    return undef if ( scalar(keys(%{$inputdata})) == 0 );

    my $src  = $inputdata->{'src'};
    my $dest = $inputdata->{'dest'};
	$inputdata->{'addon_opts'} = {} if ( ( not defined($inputdata->{'addon_opts'}) ) || 
	                                     ( not exists($inputdata->{'addon_opts'}) ) );
	
    return FALSE if ( ( not defined($src) ) || ( not defined($dest) ) );

	# Use ROBOCOPY to handle long pathnames
	my $basic_options = { &WINDOWS_SHORTNAME => 
	                                           {
									        	'robocopy' => "/COPYALL /MIR /S /E /V /R:2 /W:$wait_time",
									          	'xcopy'    => '/V /Y',
									        	'copy'     => '/V /Y',
									           },
	                      &LINUX_SHORTNAME   => '',
						};
    my $additional_rsync_opts = &HP::Support::Hash::__hash_merge($inputdata->{'addon_opts'},$basic_options);
	&__convert_options_to_arrays($additional_rsync_opts);
	
    #if ( ref($additional_rsync_opts) !~ m/hash/i ) {
    #  my $current_os = &get_os_type();
    #  $additional_rsync_opts = { "$current_os" => "$additional_rsync_opts" }
    #}

    &__print_debug_output("Sync program options --> \n".Dumper($additional_rsync_opts), __PACKAGE__) if ( $is_debug );

    if ( not -e "$src" ) {
	  &raise_exception(
	                   {
					    'type'    => 'c__HP::FileManager::FileNotFoundException__',
						'msg'     => "Source file << $src >> does not exist [ ". &get_method_name(). " ]",
						'streams' => [ 'STDERR' ],
						'bypass'  => TRUE,
					   }
					  );
      return FALSE;
    }

    if ( &os_is_windows_native() eq TRUE ) {
      &__print_debug_output("Running Windows variant...\n", __PACKAGE__) if ( $is_debug );
      return &__copy_using_windows($src, $dest, $additional_rsync_opts);
    } else {
      &__print_debug_output("Running Unix variant...\n", __PACKAGE__) if ( $is_debug );
      return &__copy_using_unix($src, $dest, $additional_rsync_opts);
    }
  }

#=============================================================================
sub copy_with_rsync_no_svn($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    # Need to provide a file with listing of all .svn directories to pass
    # necessary flag "/EXCLUDE:<fileexclude.list>" to ensure windows
    # works properly.
    return &copy_with_rsync(@_, {'windows' => '',
				                 'linux' => "--exclude '.svn'"});
  }

#=============================================================================
sub copy_with_retry_and_exclusions($$$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'topsource', \&valid_string, 'dest', \&valid_string,
                                            'exclusions', undef, 'addon_opts', undef ], @_);
    } else {
	  $inputdata = $_[0];
	}
	
    return undef if ( scalar(keys(%{$inputdata})) == 0 );

    my $topsource     = $inputdata->{'topsource'};
    my $destination   = $inputdata->{'dest'};
    my $exclusions    = $inputdata->{'exclusions'};
    my $addition_opts = $inputdata->{'addon_opts'} || {};

    my $source        = $topsource;

	if ( &is_type($exclusions, 'HP::ArrayObject') eq FALSE ) {
      return FALSE if ( ref($exclusions) !~ m/array/i );
	  my $exclusion_obj = &create_object('c__HP::ArrayObject__');
	  $exclusion_obj->add_elements({'entries' => $exclusions});
	  $exclusions = $exclusion_obj;
	}
	
    my $exclude_list = '';
    foreach my $exclude (@{$exclusions->get_elements()}) {
      $exclude_list .= " --exclude '$exclude'";
    }

    if ( &os_is_windows() eq FALSE ) {
      return &copy_with_rsync("$source","$destination","$exclude_list $addition_opts");
    } else {

	  my $directories2traverse = &create_object('c__HP::Array::Queue__');
	  my $filesdiscovered      = &create_object('c__HP::ArrayObject__');
      #my @directories2traverse = ();
      #my @filesdiscovered      = ();

    NON_RECURSIVE_LOOP:

      # read in contents of current directory
	  my $entries          = &HP::FileManager::__get_directory_contents("$source");
      my $relativeLocation = File::Spec->abs2rel("$source", "$topsource");

      if ( $exclusions->number_elements() > 0 ) {
	    my ($d2t, $fsd) = &__handle_exclusions($entries, "$relativeLocation",
					                           "$topsource", $exclusions);
		if ( $is_debug ) {
	      &__print_debug_output(@{$d2t->get_elements()}, __PACKAGE__);
	      &__print_debug_output(@{$fsd->get_elements()}, __PACKAGE__);
		}
		
		$directories2traverse->merge($d2t);
		$filesdiscovered->merge($fsd);
		
      } else {
	    foreach my $entry ( @{$entries} ) {
	      my $fullpathName = File::Spec->catfile("$source", "$entry");
		  $filesdiscovered->push_item("$fullpathName");
	    }
		
		$filesdiscovered->add_elements({'entries' => $directories2traverse->get_elements()});
		$directories2traverse->clear();
      }

      if ( $directories2traverse->number_elements() > 0 ) {
	    if ( $exclusions->number_elements() < 1 ) {
		  $filesdiscovered->add_elements({'entries' => $directories2traverse->get_elements()});
		  $directories2traverse->clear();
	    } else {
		  my $removalElements = &create_object('c__HP::ArrayObject__');
	      for ( my $loop = 0; $loop < $directories2traverse->number_elements(); ++$loop ) {
	        my $relpathName   = File::Spec->abs2rel($directories2traverse->get_element($loop), "$topsource");
			if ( $exclusions->contains("$relpathName") ) {
	          $exclusions->delete_elements("$relpathName");
			  $removalElements->push_item($loop);
	        }
	      }

		  $directories2traverse->delete_elements_by_index($removalElements->get_elements());
		  $source = $directories2traverse->next();
	      goto NON_RECURSIVE_LOOP;
	    }
      }

      if ( $filesdiscovered->number_elements() == 0 ) { 
        if ( not mkdir "$destination" ) {
          &__print_output("Unable to make directory << $destination >>!", __PACKAGE__);
        }
        return FALSE;
      }

      foreach my $fileordir (@{$filesdiscovered->get_elements()}) {
	    &__print_debug_output("Table entry :: $fileordir", __PACKAGE__) if ( $is_debug );
	
	    my $relpathName = File::Spec->abs2rel("$fileordir", "$topsource");
	    my $success     = &copy_with_retry("$fileordir", File::Spec->catfile("$destination", "$relpathName"));
	    if ( not $success eq FALSE ) {
	      &raise_exception(
	                       {
					        'type'    => 'c__HP::Copy::CopyFailureException__',
						    'msg'     => 'Copy with retry failed',
						    'streams' => [ 'STDERR' ],
						    'bypass'  => TRUE,
					       }
						  );
	      return FALSE;
	    }
      }
      return TRUE;
    }
  }

#=============================================================================
sub duplicate($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	if ( &does_file_exist("$_[0]") eq TRUE ) { return &duplicate_file(@_); }
	if ( &does_directory_exist("$_[0]") eq TRUE ) { return &duplicate_directory(@_); }
  }
  
#=============================================================================
sub duplicate_directory($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    return &copy_with_mkdir(@_);
  }

#=============================================================================
sub duplicate_file($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    return &copy_with_rsync(@_);
  }

#=============================================================================
sub move_contents($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'src', \&valid_string,
	                                        'dest', \&valid_string, 'method', \&valid_string ], @_);
    } else {
	  $inputdata = $_[0];
	}
	
    return undef if ( scalar(keys(%{$inputdata})) == 0 );

    my $source      = $inputdata->{'src'};
    my $destination = $inputdata->{'dest'};
	my $method      = $inputdata->{'method'} || 'rename';

	return FALSE if ( ( &does_file_exists( "$source" ) eq FALSE ) ||
	                  ( &does_directory_exist( "$source" ) eq FALSE ) );
	
	if ( $method =~ m/^ren/i ) {
      return ! move("$source", "$destination");
	}

	my $result = TRUE || &copy_with_rsync("$source", "$destination");
	if ( -e "$destination" ) {
	  return TRUE if ( &delete("$source") > 0 )
	}
	return $result;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;