package HP::Process;

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

                $separate_output_types
				$vm_machine_defined
                $keep_temp_files
                $last_command
				
                @ISA
                @EXPORT
               );

    $VERSION     = 0.7;

    @ISA         = qw ( Exporter );
    @EXPORT      = qw (
                       &keep_temporaries
                       &runcmd
                       &run_and_print
					   &get_last_command
                      );


    $module_require_list = {
                            'File::Path'                   => undef,

							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Module'          => undef,
							'HP::Support::Module::Tools'   => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::Support::Os'              => undef,
							
							'HP::CheckLib'                 => undef,
                            'HP::String'                   => undef,
							'HP::Os'                       => undef,
                            'HP::Array::Tools'             => undef,						
                            'HP::Path'                     => undef,
							'HP::FileManager'              => undef,
                           };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_process_pm'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );

    $separate_output_types = 0;
    $vm_machine_defined    = 0;
    $keep_temp_files       = 0;
    $last_command          = { 'recent' => undef, 'success' => undef };
	
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
sub __determine_proper_method()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $currdir = &convert_path_to_client_machine("$FindBin::Bin");
	if ( &valid_string($currdir) eq TRUE ) {
	  my $testcmd = {
	                 'arguments'   => "\"$currdir\"",
	                 'application' => '',
	                 'prefix'      => '',
	                 'verbose'     => 0,
	                 'ignore_rval' => 0,
	                };
	  if ( &os_is_linux() eq FALSE ) {
	    $testcmd->{'command'} = 'dir';
	  } else {
	    $testcmd->{'command'} = 'ls';
	  }

	  if ( &os_is_windows_native() eq TRUE ) {
        my $pid          = '000001';
        my $tempdir      = "$currdir";
        $testcmd->{'stdout'} = "$tempdir/output_$pid\.out" if ( not defined($testcmd->{'stdout'}) );
        $testcmd->{'stderr'} = "$tempdir/output_$pid\.err" if ( not defined($testcmd->{'stderr'}) );
      }

	  &__validate_cmd($testcmd);
	  &__prepare_cmd($testcmd);	  
	  
	  my $working_method = undef;
	  
	  my $data = $HP::Support::Module::module_callback->{__PACKAGE__.'::__run_cmd'};

      my @keys = keys(%{$data});
      foreach my $key (@keys) {
        my $results = {};
	    my $cmd = "\&$key(\$testcmd)";
	    my $evalstr = "\$results = $cmd;";
		eval "$evalstr";
		
		if ( $results->{'error_code'} == FAIL ) {
		  delete($HP::Support::Module::module_callback->{'HP::Process::__run_cmd'}->{$key});
		}
	  }
	}
  }
  
#=============================================================================
sub __initialize()
  {     
    if ( not $is_init ) {
      $is_init = 1; 
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );

      my $linux_installations = {
	                             'IPC::System::Simple' => {
				                                           'subroutine' => '__use_ipc_system_simple',
							                               'alias'      => __PACKAGE__.'::__run_cmd',
							                              },
							     'IPC::Cmd'            => {
				                                           'subroutine' => '__use_ipc_cmd ',
							                               'alias'      => __PACKAGE__.'::__run_cmd',
							                              },
							     'IO::CaptureOutput'   => {
				                                           'subroutine' => '__use_io_capture_cmd ',
							                               'alias'      => __PACKAGE__.'::__run_cmd',
							                              },
								};
      my $windows_installations = {
								   'Win32::Job'        => {
				                                           'subroutine' => '__use_win32_job',
							                               'alias'      => __PACKAGE__.'::__run_cmd',
								                          },
								   'HP::Process'       => {
								                           'subroutine' => '__use_system_qq',
														   'alias'      => __PACKAGE__.'::__run_cmd',
														  },
								  };

      &__print_debug_output("Installing OS dependent modules where available...\n", __PACKAGE__) if ( $is_debug );

      &install_os_dependent_modules($linux_installations, $windows_installations);
      #if ( &os_is_windows_native() eq TRUE ) {
	    #if ( not exists($ENV{'PERL5SHELL'}) ) {
	    #  $ENV{'PERL5SHELL'} = "$ENV{'COMSPEC'}" . " /x /c";
	    #}
      #}
	  
	  &__determine_proper_method();
	  &use_packages( [ 'HP::DBContainer' ] );
    }     
  }       

#=============================================================================
sub __prepare_cmd($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $cmdhash     = shift;
    my $space_array = [ ' ' ];

	my @keys = qw(application command stdout stderr);
	
	foreach my $key (@keys) {
	  if ( defined($cmdhash->{"$key"}) ) {
	    my $has_space = &str_contains($cmdhash->{"$key"},$space_array);
		my $has_backslash = &str_contains($cmdhash->{"$key"}, [ '\\' ]);
		
        if ( $has_space eq TRUE || $has_backslash eq TRUE ) {
          my $quote_idx = index("$cmdhash->{$key}", '"' );
          if ( $quote_idx < 0 ) {
	        $cmdhash->{"$key"} = "\"$cmdhash->{$key}\"";
          }
        }
        $cmdhash->{"$key"} = &convert_path_to_client_machine("$cmdhash->{$key}");
	  }
	}
  }

#=============================================================================
sub __print_verbose_output($;$)
  {       
    my $msg     = shift;
    my $verbose = shift || FALSE;

    return if ( &valid_string($msg) eq FALSE );
    &__print_output("$msg") if ( $verbose );
  }   
   
#=============================================================================
sub __process_tempfiles($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    my ( $outfile, $errfile ) = ( shift, shift );
    my ( $outbuf, $errbuf );

    if ( defined($outfile) ) {
      &__print_debug_output("STDOUT file --> $outfile\n", __PACKAGE__) if ( $is_debug );
	  my $stream = &create_object('c__HP::Stream::IO::Input__');
	  if ( defined($stream) ) {
	    $stream->entry->set_path("$outfile");
        $outbuf = $stream->slurp();
        &__print_debug_output("STDOUT as read --> ".Dumper($outbuf), __PACKAGE__) if ( $is_debug );
      }
	}

    if ( defined($errfile) ) {
      &__print_debug_output("STDERR file --> $errfile\n", __PACKAGE__) if ( $is_debug );
	  my $stream = &create_object('c__HP::Stream::IO::Input__');
	  if ( defined($stream) ) {
	    $stream->entry->set_path("$errfile");
        $errbuf = $stream->slurp(); 
        &__print_debug_output("STDERR as read --> ".Dumper($errbuf), __PACKAGE__) if ( $is_debug );
      }
	}
	
    return ($outbuf, $errbuf);
  }

#=============================================================================
sub __run_cmd($;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $use_system = $_[1] || FALSE;
    my $results;

    if ( $use_system eq TRUE ) {
	  if ( &os_is_windows_native() eq FALSE ) {
        my @output = `$_[0]->{'command'} $_[0]->{'arguments'} 2>$_[0]->{'stderr'}`;
	    my $stream = &create_object('c__HP::Stream::IO::Input__');
		my $errbuf = undef;
		
	    if ( defined($stream) ) {
	      $stream->entry->set_path("$_[0]->{stderr}");
          $errbuf = $stream->slurp();
		}
		
        $results = {
	                'success' => TRUE,
		            'stdout'  => \@output,
				    'stderr'  => $errbuf,
                   };
		$last_command->{'success'} = "$_[0]->{'command'} $_[0]->{'arguments'}";
        return $results;
	  }
	}
	
    if ( exists($HP::Support::Module::module_callback->{__PACKAGE__.'::__run_cmd'}) ) {
      my $data = $HP::Support::Module::module_callback->{__PACKAGE__.'::__run_cmd'};
      &__print_debug_output("Hash structure -->".Dumper($data),__PACKAGE__) if ( $is_debug );
      my @keys = keys(%{$data});

      &__print_debug_output("Attempting to satisfy request...\n", __PACKAGE__) if ( $is_debug );
      foreach my $key (@keys) {
        $results = {};
	    &__print_debug_output("Checking aliased subroutine --> $key\n", __PACKAGE__) if ( $is_debug );
	    my $cmd = "\&$key(\@_)";
	    &__print_debug_output("Cmd to execute --> $cmd\n", __PACKAGE__) if ( $is_debug );
	    eval "\$results = $cmd;";
		if ( defined($_[0]->{'retry'}) ) {
		   next if ( defined($results->{'success'}) && $results->{'success'} eq FALSE );
		   last;
		} else {
	       last if ( ! $@ );
        }
	  }
      return $results;
    } else {
      return {};
    }
  }

#=============================================================================
sub __use_io_captureoutput($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(). " using IO::CaptureOutput", __PACKAGE__) if ( $is_debug );

    my $cmdhash = shift;
    my ( $outbuf, $errbuf );
    my $success = FALSE;

    ( $outbuf, $errbuf, $success ) = &IO::CaptureOutput::qxx("$cmdhash->{'prefix'} $cmdhash->{'application'} $cmdhash->{'command'} $cmdhash->{'arguments'}");

    &__print_debug_output("Result from \$! is $! :: $@", __PACKAGE__) if ( $is_debug );

	$last_command->{'recent'} = "$cmdhash->{'prefix'} $cmdhash->{'application'} $cmdhash->{'command'} $cmdhash->{'arguments'}";
	if ( $success eq TRUE ) {
	  $last_command->{'success'} = "$cmdhash->{'prefix'} $cmdhash->{'application'} $cmdhash->{'command'} $cmdhash->{'arguments'}";
	}
	
    return {
	        'success'    => $success,
		    'error_code' => ( $success ) ? PASS : FAIL,
	        'stdout'     => $outbuf,
	        'stderr'     => $errbuf,
           };
  }

#=============================================================================
sub __use_ipc_cmd($)
  {
    &__print_debug_output("Inside ". &get_method_name(). " using IPC::Cmd", __PACKAGE__) if ( $is_debug );

    my $cmdhash = shift;
    my ( $outbuf, $errbuf, $fullbuf );
	
    my $success    = FALSE;
    my $error_code = PASS;

    &__print_debug_output("Command elements --> ".Dumper($cmdhash), __PACKAGE__ ) if ( $is_debug );
    
    ( $success, $error_code, $fullbuf, $outbuf, $errbuf ) =
	IPC::Cmd::run( command => "$cmdhash->{'prefix'} $cmdhash->{'application'} $cmdhash->{'command'} $cmdhash->{'arguments'}",
		           verbose => $cmdhash->{'verbose'} );

    &__print_debug_output("Result from \$! is $! :: $@", __PACKAGE__) if ( $is_debug );

	$last_command->{'recent'} = "$cmdhash->{'prefix'} $cmdhash->{'application'} $cmdhash->{'command'} $cmdhash->{'arguments'}";
	if ( $success eq TRUE ) {
	  $last_command->{'success'} = "$cmdhash->{'prefix'} $cmdhash->{'application'} $cmdhash->{'command'} $cmdhash->{'arguments'}";
	}
    return {
	        'success'    => $success,
	        'error_code' => $error_code,
	        'stdout'     => $outbuf,
	        'stderr'     => $errbuf,
	        'full'       => $fullbuf,
           };
  }

#=============================================================================
sub __use_ipc_system_simple($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(). " using IPC::System::Simple", __PACKAGE__) if ( $is_debug );

    my $cmdhash = shift;
    my ( $outbuf, $errbuf );

    &__print_debug_output("Command elements --> ".Dumper($cmdhash), __PACKAGE__ ) if ( $is_debug );

    eval {
      my $fullcmd = ( $cmdhash->{'prefix'} eq '' ) ? "$cmdhash->{'application'} $cmdhash->{'command'}" : "$cmdhash->{'prefix'} $cmdhash->{'application'} $cmdhash->{'command'}";
      &__print_debug_output("Full cmd to pass --> $fullcmd", __PACKAGE__) if ( $is_debug ) ;
      $outbuf = IPC::System::Simple::capture( "$fullcmd", "$cmdhash->{'arguments'}" );
    };

	$last_command->{'recent'} = "$cmdhash->{'prefix'} $cmdhash->{'application'} $cmdhash->{'command'} $cmdhash->{'arguments'}";
	if ( ( $IPC::System::Simple::EXITVAL eq PASS ) ) {
	  $last_command->{'success'} = "$cmdhash->{'prefix'} $cmdhash->{'application'} $cmdhash->{'command'} $cmdhash->{'arguments'}";
	}
	
    &__print_debug_output("Result from \$! is $! :: $@", __PACKAGE__) if ( $is_debug ) ;

    return {
	        'success'    => ( $IPC::System::Simple::EXITVAL > 0 ) ? FALSE : TRUE,
		    'error_code' => $IPC::System::Simple::EXITVAL,
	        'stdout'     => $outbuf,
	        'stderr'     => $errbuf,
           };
  }

#=============================================================================
sub __use_system_qq($)
  {
    &__print_debug_output("Inside ". &get_method_name(). " using system call", __PACKAGE__) if ( $is_debug );

    my $cmdhash = shift;
    my ( $outbuf, $errbuf );

	&__print_debug_output("Running command --> << $cmdhash->{'command'} $cmdhash->{'arguments'} >>", __PACKAGE__) if ( $is_debug );
	my @outbuf = ();
	
	if ( defined($cmdhash->{'application'}) ) {
	  @outbuf = split(/\n/, qx($cmdhash->{'application'} $cmdhash->{'command'} $cmdhash->{'arguments'}));
	  $last_command->{'recent'} = "$cmdhash->{'application'} $cmdhash->{'command'} $cmdhash->{'arguments'}";
	} else {
	  @outbuf = split(/\n/, qx($cmdhash->{'command'} $cmdhash->{'arguments'}));
	  $last_command->{'recent'} = "$cmdhash->{'command'} $cmdhash->{'arguments'}";
	}
	
	if ( ! $@ ) {
	  if ( defined($cmdhash->{'application'}) ) {
	    $last_command->{'success'} = "$cmdhash->{'application'} $cmdhash->{'command'} $cmdhash->{'arguments'}";	  
	  } else {
	    $last_command->{'success'} = "$cmdhash->{'command'} $cmdhash->{'arguments'}";
	  }
    }
	
	my $return_struct = {
	                     'success'     => ( $@ ) ? FALSE : TRUE,
						 'error_code'  => ( $@ ) ? FAIL : PASS,
					     'stdout'      => \@outbuf,
						 'stderr'      => [],
                        };
	return $return_struct;
  }

#=============================================================================
sub __use_win32_job($)
  {
    &__print_debug_output("Inside ". &get_method_name(). " using Win32::Job", __PACKAGE__) if ( $is_debug );

    my $cmdhash = shift;
    my ( $outbuf, $errbuf );
    my $success = FALSE;

    my $return_struct = {
	                     'success'     => $success,
						 'error_code'  => ( $success ) ? PASS : FAIL,
					     'stdout'      => [],
					     'stderr'      => [],
					     'status_info' => FALSE,
                        };
	if ( $is_debug ) {
      &__print_debug_output("Keep temporary files? $keep_temp_files\n", __PACKAGE__);
      &__print_debug_output("Command elements --> ".Dumper($cmdhash), __PACKAGE__ );
	}
    
	if ( exists($cmdhash->{'cmd'}) ) { $cmdhash->{'command'} = $cmdhash->{'cmd'}; }
	if ( not exists($cmdhash->{'command'}) ) { return $return_struct; }
      
	my $command = $cmdhash->{'command'};
	my $fullcmd = undef;
	
	if ( defined($cmdhash->{'application'}) ) {
	  $command = ( $cmdhash->{'application'} eq '' ) ? "$cmdhash->{'command'}" : "$cmdhash->{'application'} $cmdhash->{'command'}";
	}
	if ( defined($cmdhash->{'prefix'}) ) {
      $fullcmd = ( $cmdhash->{'prefix'} eq '' ) ? "$command" : "$cmdhash->{'prefix'} $command";
	} else {
	  $fullcmd = $command;
	}
	
	if ( $is_debug ) {
      &__print_debug_output("Full cmd to pass --> <$fullcmd>", __PACKAGE__);
      &__print_debug_output("Stdout --> << $cmdhash->{'stdout'} >>", __PACKAGE__) if ( exists($cmdhash->{'stdout'}) );
	  &__print_debug_output("Stderr --> << $cmdhash->{'stderr'} >>", __PACKAGE__) if ( exists($cmdhash->{'stderr'}) );
	}
	
    my $job     = &create_object('c__Win32::Job__');
	my $jobopts = {
	               'no_window' => TRUE,
				   'stdout'    => "$cmdhash->{'stdout'}",
				   'stderr'    => "$cmdhash->{'stderr'}",
                  };

    if ( defined($job) ) {
	  &__print_debug_output("Job commandline --> << $fullcmd $cmdhash->{'arguments'} >>", __PACKAGE__) if ( $is_debug );
      $job->spawn($ENV{'PERL5SHELL'}, "cmd /C $fullcmd $cmdhash->{'arguments'}", $jobopts);
      $success = $job->run(0);
	  &__print_debug_output("Job has been issued successfully :: $success", __PACKAGE__) if ( $is_debug );
      if ( $success ) {
	    ( $outbuf, $errbuf ) = &__process_tempfiles("$cmdhash->{'stdout'}", "$cmdhash->{'stderr'}");
      }
    } else {
	  if ( $is_debug ) {
        &__print_debug_output("Unable to make a job to process request!!!\n", __PACKAGE__ ) if ( $is_debug );
        &__print_debug_output("Result from \$! is $! :: $@", __PACKAGE__);
	  }
    }

    my $status = $job->status();
	if ( $is_debug ) {
      &__print_debug_output("Status -->".Dumper($status), __PACKAGE__);
      &__print_debug_output("Output -->".Dumper($outbuf), __PACKAGE__);
    }
	
	$last_command->{'recent'} = "$fullcmd";
	$last_command->{'success'} = "$fullcmd" if ( $success );
	
    $return_struct = {
	                  'success'     => $success,
					  'error_code'  => ( $success ) ? PASS : FAIL,
					  'stdout'      => $outbuf,
					  'stderr'      => $errbuf,
					  'status_info' => $status,
                     };

    return $return_struct;
  }
  
#=============================================================================
sub __validate_cmd($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    my @keys = qw(prefix application command arguments stdout stderr);

    foreach my $key (@keys) {
      if ( not exists($_[0]->{"$key"}) ) { $_[0]->{"$key"} = ''; }
    }
  }

#=============================================================================
sub get_last_command(;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $cmdtype = shift || 'recent';
	if ( exists($last_command->{$cmdtype}) ) { return "$last_command->{$cmdtype}" };
	return undef;
  }
  
#=============================================================================
sub keep_temporaries($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $input = $_[0];
    if ( defined($input) ) {
      if ( &is_numeric($input) eq TRUE ) {
	    if ( $input <= 0 ) { $input = 0; } else { $input = 1; }
      } else {
	    $input = $HP::Process::keep_temp_files;
      }
      $HP::Process::keep_temp_files = $input;
    }
  }

#=============================================================================
sub runcmd($;$$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $cmd = shift;
    my $os_is_windows_native = &os_is_windows_native();
	
	my $updated_info = {};

    if ( ref($cmd) !~ m/hash/i ) {
      my $tempcmd           = "$cmd";
	  
      $cmd = {};
      $cmd->{'application'} = '';
      $cmd->{'command'}     = "$tempcmd";
      $cmd->{'arguments'}   = '';
      $cmd->{'prefix'}      = '';
      $cmd->{'verbose'}     = FALSE;
      $cmd->{'ignore_rval'} = FALSE;
    }

    my $use_system  = shift || FALSE;

    # Windows doesn't allow redirection, but cygwin and linux do.
    # We will isolate these calls to ensure they are ONLY done when
    # under windows
    if ( ( $use_system eq TRUE ) || ( $os_is_windows_native eq TRUE ) ) {
      my $pid          = &get_pid();
      my $tempdir      = &get_temp_dir();
      $cmd->{'stdout'} = &join_path(File::Spec->rel2abs("$tempdir"),"output_$pid\.out") if ( not defined($cmd->{'stdout'}) );
      $cmd->{'stderr'} = &join_path(File::Spec->rel2abs("$tempdir"),"output_$pid\.err") if ( not defined($cmd->{'stderr'}) );
  	  $updated_info->{'pid'} = $pid;
    }

    &__validate_cmd($cmd);
    &__prepare_cmd($cmd);

    &__print_debug_output("Cmd Hash --> ".Dumper($cmd), __PACKAGE__) if ( $is_debug );

    my $result;

	if ( not defined($use_system) ) { $use_system = $os_is_windows_native || FALSE; }
	
    &__print_debug_output("VM Detection --> $vm_machine_defined :: Use System Call --> $use_system :: Separation of Outputs --> $separate_output_types", __PACKAGE__) if ( $is_debug );

    $result = &HP::Process::__run_cmd($cmd, $use_system);

    &delete("$cmd->{'stdout'}") if ( ( not $HP::Process::keep_temp_files ) && &does_file_exist("$cmd->{'stdout'}") && $os_is_windows_native );
	&delete("$cmd->{'stderr'}") if ( ( not $HP::Process::keep_temp_files ) && &does_file_exist("$cmd->{'stderr'}") && $os_is_windows_native );

    &__print_debug_output("Returned structure of resultant data --> ".Dumper($result->{'stdout'}), __PACKAGE__ ) if ( $is_debug );
    $result->{'success'}    ||= FALSE;
    $result->{'error_code'} = FAIL if ( not defined($result->{'error_code'}) );

	if ( $is_debug ) {
      &__print_debug_output ("Success --> $result->{'success'} :: Return Code --> $result->{'error_code'}", __PACKAGE__);
      &__print_debug_output("STDOUT Buffer --> ".Dumper($result->{'stdout'}), __PACKAGE__);
	}
	
    if ( $cmd->{'ignore_rval'} ) { $result->{'success'} = TRUE; }

    my $unix_return = PASS;
    if ( $result->{'success'} eq TRUE ) {
      if ( $result->{'error_code'} =~ m/(\S*)\sexited with value\s(\d*)/ ) {
	    $unix_return = $2;
      }
    }
	
  	$updated_info->{'output_file'} = $cmd->{'stdout'};
  	$updated_info->{'error_file'}  = $cmd->{'stderr'};
	
    return ($unix_return, $result->{'stdout'}, $result->{'stderr'}, $updated_info);
  }

#=============================================================================
sub run_and_print($@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $cmd = shift;
    my @streams;

    # Check whether the last parameter passed to this function is a reference.
    # If it is a reference, assume it is an array for StreamManager named
    # streams.  Otherwise, just output to STDOUT by default.
    if (@_ and ref($_[-1])) {
      push (@streams, @{$_[-1]});
    } else {
      @streams = qw(STDOUT);
    }

    my ($unix_return, $output) = (FAIL, []);
    if ( ref($cmd) =~ m/hash/i ) {
      &__print_debug_output("Hash input found", __PACKAGE__) if ( $is_debug );
      ($unix_return, $output) = &runcmd($cmd);
    } else {
      ($unix_return, $output) = &runcmd("$cmd");
    }
    &__print_debug_output("Result from command --> << $unix_return >>", __PACKAGE__) if ( $is_debug );

	eval "use HP::DBContainer;";
	#my $installed_package = &has('HP::DBContainer');
	#&use_packages('HP::DBContainer') if ( $installed_package->[0] eq FALSE );
	
	my $streamDB = &getDB('stream');
	foreach ( @streams ) {
	  my $stream = $streamDB->find_stream_by_handle("$_");
	  next if ( not defined($stream) );
      foreach my $line (@{$output}) {
        $stream->raw_output("$line\n");
      }
    }
	
    return $unix_return;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;