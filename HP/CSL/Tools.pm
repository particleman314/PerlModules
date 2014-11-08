package HP::CSL::Tools;

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
				
                @ISA
                @EXPORT
				
				$__global_datastore
				$__local_datastore
               );
    
    $VERSION = 0.99;
 
    @ISA    = qw(Exporter);
    @EXPORT = qw(
	             &collect_all_user_stories
				 &collect_local_settings
	             &collect_global_settings
				 &determine_csl_log
				 &display_information
				 &get_global_datastore
				 &get_local_datastore
				 &get_product_output_dir
	             &handle_hybrid_versioning
				 &query_jenkins
	             &record_arguments_to_history
				 &setup_help_screen
	             &store_user_arguments
				 &validate_executables
                );

    $module_require_list = {
							'Cwd'                                       => undef,
							
                            'HP::Constants'                             => undef,
                            'HP::Support::Base'                         => undef,
							'HP::Support::Base::Constants'              => undef,
							'HP::Support::Hash'                         => undef,
							'HP::Support::Configuration'                => undef,
							'HP::Support::Screen'                       => undef,
							'HP::Support::ProgramManagement'            => undef,
							'HP::Support::ProgramManagement::Constants' => undef,
							'HP::Support::Module::Tools'                => undef,
							'HP::Support::Object::Tools'                => undef,
							'HP::Support::Shell'                        => undef,
							'HP::Support::Os'                           => undef,
							'HP::Array::Tools'                          => undef,
							
							'HP::DBContainer'                           => undef,
							'HP::Os'                                    => undef,
							'HP::String'                                => undef,
							'HP::Timestamp'                             => undef,
							'HP::FileManager'                           => undef,
							'HP::Path'                                  => undef,
							'HP::Exception::Tools'                      => undef,
							'HP::Utilities'                             => undef,
							'HP::Process'                               => undef,
							
							'HP::StreamDB::Constants'                   => undef,
							'HP::Stream::Constants'                     => undef,
							'HP::StreamDB::Tools'                       => undef,
							'HP::CSL::Constants'                        => undef,
							'HP::OOStudio::Constants'                   => undef,
                          };

    $module_request_list = {};

    $is_init     = 0;
    $is_debug    = (
		            $ENV{'debug_csl_tools_pm'} ||
		            $ENV{'debug_csl_modules'} ||
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
my @error_keys   = ();
my $cslloghandle = '__CSL_LOGFILE__';

$__global_datastore = undef;
$__local_datastore  = undef;

#=============================================================================
sub __classify_usecase($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $user_story_hash = shift;
	my $uc_dir          = shift || return;

	my $buildpath       = &get_from_configuration('program->user_arguments->build-path');
	my $uc_object       = undef;
	
	my $xmlfile = &join_path("$buildpath", "$uc_dir", 'local_data.xml');
	if ( &does_file_exist("$xmlfile") eq TRUE ) {
	  $uc_object = &create_object('c__HP::Capsule::UseCaseCapsule__');
	  $uc_object->local_data()->readfile("$xmlfile");
	  $uc_object->workflow("$uc_dir");
	  $uc_object->usecase_dir(&join_path("$buildpath", "$uc_dir"));
	  &save_to_configuration({'data' => [ "derived_data->local->$uc_dir", $uc_object->local_data() ]});
	  &save_to_configuration({'data' => [ "derived_data->local->usecase_capsules->$uc_dir", $uc_object ]});
	} else {
	  return;
	}
	
	my $classification = $uc_object->classify();
	
  RETRY:
	if ( exists($user_story_hash->{$classification}) ) {
	  $user_story_hash->{$classification}->push_item("$uc_dir");
	} else {
	  $user_story_hash->{$classification} = &create_object('c__HP::Array::Set__');
	  goto RETRY;
	}
	return;
  }

#=============================================================================
sub __display_maven_component($$)
  {
    my $key          = shift || return;
    my $text_string  = shift;
	my $streamhandle = $cslloghandle;
	my $argsref      = &get_from_configuration('program->user_arguments');
	 
	if ( defined($argsref->{"$key"}) && scalar(@{$argsref->{"$key"}}) > 0 ) {
	  my @components = &convert_to_array($argsref->{"$key"});
	  &print_to_streams({ 'message' => "$text_string : ". join(' ',@components). "\n" }, 'STDOUT', $streamhandle);
	}
	
	return;
  }
  
#=============================================================================
sub __find_hinted_maven()
  {
    if ( defined($ENV{'MANAGED'}) || &does_directory_exist('C:\ManagedSoftware') eq TRUE ) {
	  if ( defined($ENV{'MAVEN_VERSION'}) ) {
	    return "C:/ManagedSoftware/Maven/Maven-$ENV{'MAVEN_VERSION'}/bin" if ( &does_directory_exist("C:/ManagedSoftware/Maven/Maven-$ENV{'MAVEN_VERSION'}/bin") eq TRUE );
	  } else {
	    return "C:/ManagedSoftware/Maven/Maven/bin" if ( &does_directory_exist("C:/ManagedSoftware/Maven/Maven/bin") eq TRUE );
	  }
	} else {
	  if ( &does_directory_exist('C:\Program Files\Maven') eq TRUE ) {
	    return 'C:/Program Files/Maven/bin' if ( &does_directory_exist("C:/Program Files/Maven/Maven/bin") eq TRUE );
	  } else {
	    return undef;
	  }
	}
	return undef;
  }

#=============================================================================
sub __generate_CSL_history_file($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    my ( $homedir ) = @_;
	
    my $history_file = &join_path("$homedir", ".$main::progname\_history");
	return "$history_file";
  }
  
#=============================================================================
sub __initialize()
  {     
    if ( not $is_init ) {
      $is_init = 1;
	  
	  &save_to_configuration({'data' => [ 'program->progname', &get_script_name($0) ]});
	  &set_temp_dir(&join_path(&get_temp_dir(),'CSL_BUILD'));
	  &HP::Support::Screen::__define_linespace("#");
	  
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }       
  }       

#=============================================================================
sub __update_debug()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    $ENV{'debug_csltools_pm'} = $HP::CSL::Tools::is_debug = 1;
    eval "use Data::Dumper";
  }

#=============================================================================
sub add_default_error_keys()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
 
    push ( @error_keys, '[ERROR]' );
	push ( @error_keys, '[FAILURE]' );
	push ( @error_keys, '[FAIL]' );
  }

#=============================================================================
sub add_error_key($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    if ( &valid_string($_[0]) ) { push ( @error_keys, "$_[0]" ); }
  }
  
#=============================================================================
sub collect_all_user_stories(;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $ignore_cache = FALSE;
	$ignore_cache    = TRUE if ( defined($_[0]) );
	
	my $cachedata    = &get_from_configuration("derived_data->user_stories_list");
	return $cachedata if ( $ignore_cache eq FALSE && defined($cachedata) );
	
	my $buildpath    = &get_from_configuration('program->user_arguments->build-path');

	&ignore_hidden('directories', TRUE);
	&ignore_hidden('files', TRUE);
	
    my $organization = &collect_directory_contents("$buildpath");
	
	if ( $is_debug ) {
	  &__print_debug_output("Contents for << $buildpath >> :");
	  &__print_debug_output(Dumper($organization));
	}
	
	my $directory_set = {};
	
	if ( scalar(@{$organization->{'directories'}}) > 0 ) {
	  $organization->{'directories'} = &set_difference($organization->{'directories'}, &collect_skiplist_entries());
	  
	  #######################################################################
	  # Loop over directories since these house user stories
	  #######################################################################
	  
	  foreach my $dir (@{$organization->{'directories'}}) {
	    &__print_debug_output("Interrogating directory << $dir >>", INFO);
	    #my $expected_file = &join_path("$buildpath", "$dir", '.usecase');
		#$directory_set->push_item("$dir") if ( &does_directory_exist("$expected_file") eq TRUE );
		&__classify_usecase($directory_set, "$dir");
	  }
	}
	
	&__print_debug_output(Dumper($directory_set->get_elements())) if ( $is_debug );
	&save_to_configuration({'data' => [ "derived_data->user_stories_list", $directory_set ]});
	
	return $directory_set;
  }

#=============================================================================
sub collect_global_settings(;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $derived         = &get_from_configuration('derived_data');
	my $argsref         = &get_from_configuration('program->user_arguments');
	my $global_datafile = shift || &join_path($derived->{'devtools'}, 'bldtools', 'configuration', 'global_data.xml');
	
	if ( not &does_file_exist("$global_datafile") ) {
	  my $driveDB = &getDB('drive');
	  &raise_exception(
					 {
				      'type'          => 'FILE_NOT_FOUND',
					  'severity'      => WARN,
					  'addon_msg'     => "Could not find global data information << ". $driveDB->expand_drivepath("$global_datafile") ." >> necessary for build process.",
					  'handles'       => [ 'STDERR', $cslloghandle ],
					 }
		  			  );
	}
	
	&__print_output("Parsing global XML data << $global_datafile >>...\n", INFO);
	
	# This will pick up the provider list, basic support matrix, and the global build information
	my $gdi = &create_object('c__HP::CSL::DAO::GlobalData__');
	$gdi->readfile("$global_datafile");
	
	if ( not defined($derived) ) {
	  &save_to_configuration({'data' => [ 'derived_data->global', $gdi ]});
	} else {
	  $derived->{'global'} = $gdi;
	}
	&__print_debug_output(Dumper($gdi)) if ( $is_debug );
	return TRUE;
  }

#=============================================================================
sub collect_local_settings(;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $inputdata = {};
	if ( ref($_[0]) !~ m/hash/i ) {
	  $inputdata = &convert_input_to_hash([ 'identification', \&valid_string, 'local_datafile', \&valid_string ], @_);
	}
	return if ( scalar(keys(%{$inputdata})) == 0 );
	
	my $identification = $inputdata->{'identification'};
	my $local_datafile = $inputdata->{'local_datafile'};
	
	return FALSE if ( not defined($local_datafile) );
	
	if ( not &does_file_exist("$local_datafile") ) {
	  my $driveDB = &getDB('drive');
	  &raise_exception(
					   {
				        'type'          => 'FILE_NOT_FOUND',
					    'severity'      => WARN,
					    'addon_msg'     => "Could not find local data information << ". $driveDB->expand_drivepath("$local_datafile") ." >> necessary for build process.",
					    'handles'       => [ 'STDERR', $cslloghandle ],
					   }
		  			  );
	}
	
	&__print_output("Parsing local XML data << $local_datafile >>...\n", INFO);
	
	# This will pick up the local build information
	my $ldi = &create_object('c__HP::CSL::DAO::LocalData__');
	$ldi->readfile("$local_datafile");
	
	$identification = $ldi->get_build_parameter('human->name') if ( not defined($identification) );
	
	return FALSE if ( &valid_string($identification) eq FALSE );
	
	my $gds  = &get_global_datastore();
	my $name = $gds->get_normalized_provider_name("$identification");
	return FALSE if ( &valid_string($name) eq FALSE );
	
	my $derived = &get_from_configuration('derived_data->local->stories');
	if ( not defined($derived) ) {
	  &save_to_configuration({'data' => [ "derived_data->local->stories->$name", $ldi ]});
	} else {
	  $derived->{'local'}->{'stories'}->{"$name"} = $ldi;
	}
	&__print_debug_output(Dumper($ldi)) if ( $is_debug );
	return TRUE;
  }

#=============================================================================
sub collect_skiplist_entries
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $gdi = &get_from_configuration("derived_data->global");
	
	return [] if ( not defined($gdi) );
	
	my $gdi_ign_content = $gdi->get_ignored_content();
	my $gdi_ign_lrc     = $gdi->get_ignored_lrc();
	
	my $result = &set_union($gdi_ign_content, $gdi_ign_lrc);
	return $result;
  }
  
#=============================================================================
sub determine_csl_log($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
  
	my $logtype = shift;
	return if ( &valid_string($logtype) eq FALSE );
	
    my $argsref         = &get_from_configuration('program->user_arguments');
    my $default_logfile = &join_path(&get_temp_dir(),"$logtype-".&get_pid().'.log');
	
	if ( exists($argsref->{'logfile'}) ) {
	  if ( &valid_string($argsref->{'logfile'}) eq FALSE ) {
	    if ( exists($argsref->{"$logtype"}) && defined($argsref->{"$logtype"}) ) {
	      #my $logdir = $argsref->{"$logtype"}->getProperty("csl.$logtype.logdir");
		  
		  #if ( defined($logdir) ) {
	      #  my $logfile = &join_path("$logdir", $argsref->{"$logtype"}->getProperty("csl.$logtype.local.logfile"));
	      #  if ( &does_file_exist("$logfile") eq TRUE ) {
	      #    &__print_output("<< $logfile >> currently exists -- erasing...", WARN);
		  #    &delete("$logfile");
	      #  }
		  #  $argsref->{'temp-logfile'} = "$logfile";
		  #	goto SETUP_LOGFILE;
		  #}
		}
	  }
    }

	delete($argsref->{'temp-logfile'});
	
   SETUP_LOGFILE:
	if ( ( not exists($argsref->{'temp-logfile'}) ) ||
	     ( &valid_string($argsref->{'temp-logfile'}) eq FALSE ) ) {
	  $argsref->{'temp-logfile'} = "$default_logfile";
	  $argsref->{'logfile'} = "$logtype.log" if ( not defined($argsref->{'logfile'}) );
	}
	
	my $strDB  = &getDB('stream');
	
	# We won't close this stream since we need to use it throughout the process
	my $stream = $strDB->make_stream("$argsref->{'temp-logfile'}", OUTPUT, $cslloghandle);
	if ( not defined($stream) ) {
	  &raise_exception(
		               {
					    'type'      => 'FILE_NOT_FOUND',
						'severity'  => WARN,
					    'addon_msg' => 'Could not generate logfile to record information.',
					    'callback'  => \&bypass_error,
						'handles'   => [ 'STDERR', $cslloghandle ],
					   }
					  );
    }
  }

#=============================================================================
sub display_information()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $argsref   = &get_from_configuration('program->user_arguments');
	my $derived   = &get_from_configuration('derived_data');
	
	my $strm_list = [ 'STDOUT', $cslloghandle ];
	my $conversion_data = { &TRUE => 'Yes', &FALSE => 'No' };

	&print_to_streams({ 'message' => "\n".&get_linespace()."\n" }, $strm_list); 
	 
	&print_to_streams({ 'message' => &minimize_pathnames("Current Launch directory    :", ${$derived->{'launch_directory'}})."\n" }, $strm_list);
	&print_to_streams({ 'message' => "Controller Script           : $main::progname\n" }, $strm_list);
	&print_to_streams({ 'message' => &minimize_pathnames("Java Home                   :",File::Basename::dirname($derived->{'executables'}->{'javac'}->get_executable()))."\n" }, $strm_list) if ( exists($argsref->{'capsule-xml'}) );
	&print_to_streams({ 'message' => &minimize_pathnames("Default Logfile             :", "$argsref->{'logfile'}")."\n" }, $strm_list) if ( exists($argsref->{'logfile'}) );
	 
	&__display_maven_component('maven-target', 'Basic Maven Target(s)      ');
	&__display_maven_component('maven-define', 'Basic Maven Defines(s)     ');
	&__display_maven_component('maven-param',  'Masic Maven Parameter(s)   ');

	&print_to_streams({ 'message' => "Allow Packaging after Build : ". &convert_boolean_to_string( $argsref->{'package'}, $conversion_data) ."\n" }, $strm_list);
	#&print_to_streams("Skip Post Processing Tools  : $clo{'skip-compliance-check'}\n" }, 'STDOUT', $streamhandle);
	
	&print_to_streams({ 'message' => "Capsule Build Requested     : ". &convert_boolean_to_string( exists($argsref->{'capsule-xml'}), $conversion_data ) ."\n" }, $strm_list);
	&print_to_streams({ 'message' => "Is Dryrun                   : ". &convert_boolean_to_string( $argsref->{'dryrun'}, $conversion_data) ."\n" }, $strm_list);
	
	my $numOObuilds = scalar(@{$argsref->{'hpoo'}});
	if ( $numOObuilds > 1 ) {
	  &print_to_streams({ 'message' => "Number of OO builds         : $numOObuilds -- HP OO versions --> [ ". join(' ', @{$argsref->{'hpoo'}}). " ] \n" }, $strm_list);
	}
	 
	&display_svn_info();
	&print_to_streams({ 'message' => &get_linespace()."\n" }, $strm_list);
	
	if ( not exists($argsref->{'capsule-xml'}) ) {
	  #&display_skiplist(&join_path("$clo{'build-path'}",$clo{'build'}->getProperty('csl.build.skip.CP.dirs')));
	  #&display_skiplist(&join_path("$clo{'build-path'}",$clo{'build'}->getProperty('csl.build.skip.LRC.dirs')));
    }
  }
  
#=============================================================================
sub display_svn_info()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	 
	my $argsref = &get_from_configuration('program->user_arguments');
	if ( $argsref->{'no-svn'} eq FALSE ) {
	  my $streamhandle = $cslloghandle;
		
	  #======================================================================
	  # Need to use SVN to query for information...
	  #======================================================================
	  my $svnobj = &get_from_configuration("derived_data->executables->svn");

	  return if ( not defined($svnobj) );
	  
	  my $currdir = &get_full_path(&getcwd());
	
	  my $buildpath = $argsref->{'build-path'};
	  my $errorcode = chdir "$buildpath";
	  # if ( $errorcode == 0 ) {
        # &raise_exception(
		                 # {
						  # 'type'          => 'DIRECTORY_ACCESS_DENIED',
						  # 'severity'      => FAILURE,
						  # 'addon_msg'     => "Unable to change to directory << $buildpath >>.",
						  # 'callback'      => \&bypass_error,
						  # 'handles'       => [ 'STDERR', $streamhandle ],
						 # }
						# );
		# return;
	  # }
	  my ($returncode, $joboutput) = &runcmd(
		                                     {
											  'command'   => $svnobj->get_executable(),
											  'arguments' => 'info',
											  'verbose'   => $argsref->{'verbose'},
											  #'stdout'    => &join_path(&get_temp_dir(), $clo{'build'}->getProperty('csl.svn.tempfile')),
											 }
											);
		
	  $errorcode = chdir "$currdir";
	  #if ( $errorcode == 0 ) {
        # &raise_exception(
		                 # {
						  # 'type'      => 'DIRECTORY_ACCESS_DENIED',
						  # 'severity'  => FAILURE,
						  # 'addon_msg' => "Unable to change to directory << $currdir >>.",
						  # 'handles'   => [ 'STDERR', $streamhandle ],
						 # }
						# );
      # }

	  if ( $returncode ne PASS ) {
		&__print_output("Unable to properly use SVN executable to query for information", WARN);
		return;
	  }
	  #my $svndata = &decode_svn_data('info', $stdoutref);
	}
  }
  
#=============================================================================
sub erase_previous_build($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $buildpath   = &get_from_configuration('program->user_arguments->build-path');
	
	&__print_output("Purging previously built directories...");
	
	#my $product_dir = &join_path("$buildpath", $cloref->{'packaging'}->getProperty('csl.packaging.productdir'));
    #my $release_dir = &join_path("$buildpath", $cloref->{'packaging'}->getProperty('csl.packaging.releasedir'));
	#if ( (not &does_directory_exist("$product_dir")) && (not &does_directory_exist("$release_dir")) ) { return; }
	#my $num_deleted = &delete( "$product_dir", "$release_dir" );
	
	#if ( $num_deleted < 2 ) {
	#  &__print_output("Was unable to erase all necessary vestiges of previous built content.  Results may not be as expected!", INFO);
    #} else {
	#  &__print_output("Erased the product and release directories ($num_deleted)", INFO);
	#}
  }
  
#=============================================================================
sub extract($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $splitfield = shift;
	my $data       = shift;
	my $chunks     = shift;
	my $extracted  = shift;
	 
	if ( &valid_string($splitfield) eq FALSE ) { return $data; }
	if ( &valid_string($data) eq FALSE ) { return $data; }
	if ( (not defined($chunks)) || &is_numeric($chunks) eq FALSE ) { $chunks = undef };
	 
	 if ( (not defined($extracted)) || &is_numeric($extracted) eq FALSE ) { $extracted = 1; }
	 if ( $extracted < 1 ) { $extracted = 1; }
	 
	 my @datachunks = ();
	 if ( not defined($chunks) ) {
	    @datachunks = split("$splitfield", "$data");
		if ( $extracted > scalar(@datachunks) ) { $extracted = scalar(@datachunks); }
	 } else {
	    @datachunks = split("$splitfield", "$data", $chunks);
		if ( $extracted > scalar(@datachunks) ) { $extracted = scalar(@datachunks); }
	 }
	 return $datachunks[$extracted - 1];
  }

#=============================================================================
sub extract_warehouses
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    
	if ( not defined($HP::CSL::Tools::__global_datastore) ) {
	  $__global_datastore = &get_from_configuration('derived_data->global');
	}
	
	if ( not defined($HP::CSL::Tools::__local_datastore) ) {
	  $__local_datastore = &get_from_configuration('derived_data->local');
	}
	
	return TRUE;
  }
  
#=============================================================================
sub get_global_datastore
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $extraction = 0;
  RETRY:
	if ( (not defined($HP::CSL::Tools::__global_datastore)) && $extraction < 2 ) {
	  &extract_warehouses();
	  ++$extraction;
	  goto RETRY;
	}
    
	return $HP::CSL::Tools::__global_datastore;
  }

#=============================================================================
sub get_local_datastore
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $extraction = 0;
  RETRY:
	if ( (not defined($HP::CSL::Tools::__local_datastore)) && $extraction < 2 ) {
	  &extract_warehouses();
	  ++$extraction;
	  goto RETRY;
	}
    
	return $HP::CSL::Tools::__local_datastore;
  }

#=============================================================================
sub get_product_output_dir
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
  
	my $argsref   = &get_from_configuration('program->user_arguments');
	my $gdi       = &get_global_datastore();
	
	&raise_exception(
	                 {
					  'type'      => 'NO_EXECUTABLE',
				      'addon_msg' => 'Global Data store CANNOT be found or not command line argument ref available!',
					  'handles'   => [ 'STDERR '],
					 }
					) if ( (not defined($argsref)) || (not defined($gdi)) );
					
	my $buildpath = $argsref->{'build-path'};
	&raise_exception(
	                 {
					  'type'      => 'NO_EXECUTABLE',
				      'addon_msg' => 'No buildpath defined!',
					  'handles'   => [ 'STDERR '],
					 }
					) if ( not defined($buildpath) );
	
	my $relative_proddir = $gdi->get_build_parameter('package->productdir') || '__product_output__';
	&__print_output("Using DEFAULT product directory name since it could not be discerned from build parameters!", WARN) if ( $relative_proddir eq '__product_output__' );
	return &join_path("$buildpath", $relative_proddir);
  }
  
#=============================================================================
sub handle_hybrid_versioning($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $argsref = shift || return;
	
	my $version_choices    = {};
	my $final_version_keys = [];
	   
	foreach my $hybridtype (@{$argsref->{'hybrid'}}) {
	  my @version_pkg_ids = split(':', $hybridtype);
	  if ( &match_OO_version_id($version_pkg_ids[0]) eq FALSE ) {
		&__print_output("Unknown HP OO Version ID < $version_pkg_ids[0] >", WARN);
		next;
	  }
	  
	  my ( $result, $matched_hybrid_version ) = &match_hybrid_version_id($version_pkg_ids[1]);
	  if ( $result eq FALSE ) {
		&__print_output("Unknown manifest/packaging version identification < $1 >.  Skipping this entry!", WARN);
		next;
	  } else {
		++$version_choices->{$matched_hybrid_version};
		if ( &set_contains($version_pkg_ids[0], $argsref->{'hpoo'}) eq FALSE ) {
		  push(@{$final_version_keys}, join(':',@version_pkg_ids));
	      push(@{$argsref->{'hpoo'}}, $version_pkg_ids[0]);
	    }
	  }
	}
	
	$final_version_keys = join(',',$final_version_keys);
	my $numkeys = scalar(keys(%{$version_choices}));
	
	if ( $numkeys > 1 ) {
	  $argsref->{'unified'} = TRUE;
	  $argsref->{'hybrid'}  = $final_version_keys;
	} else {
	  my @only_key = keys(%{$version_choices});
	  if ( scalar(@only_key) != 0 ) {	  
	    $argsref->{'unified'} = $version_choices->{"$only_key[0]"} - 1;
	    $argsref->{'unified'} = TRUE if ( $argsref->{'unified'} > 0 );
	  }
	  delete($argsref->{'hybrid'});
	}
	return;
  }

#=============================================================================
sub handle_logs($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $argsref = &get_from_configuration('program->user_arguments');
	if ( $argsref->{'save-log'} ) {
      &__print_output("Writing back logfile << $argsref->{'temp-logfile'} >> into content directory as << $argsref->{'logfile'} >>", INFO);
	  &duplicate("$argsref->{'temp-logfile'}", &join_path("$argsref->{'launch_directory'}", "$argsref->{'logfile'}"));
	}

	if ( $argsref->{'show-log'} ) {
	  my $strDB = &getDB('stream');
	  my $stream = $strDB->make_stream("$argsref->{'temp-logfile'}", OUTPUT, '__SLURP__');
	  
      my @logcontents = $stream->slurp();
	  &print_to_streams({'message' => "\n\n",join("\n",@logcontents)."\n\n"}, 'STDOUT');
	}
	  
	&delete("$argsref->{'temp-logfile'}");
  }

#=============================================================================
sub install_executable
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $data   = shift || return;
	my $exes   = shift || return;
	
	goto CHECK_FOR_ERROR_CONDITION if ( ref($data) !~ m/hash/i );
	
    my $argsref = &get_from_configuration('program->user_arguments');
	my $executable = &create_object('c__HP::Job__');
	goto CHECK_FOR_ERROR_CONDITION if ( not defined($executable) );
	
	if ( exists($data->{'argspath_id'}) ) {
	  goto CHECK_FOR_ERROR_CONDITION if ( &valid_string($data->{'argspath_id'}) eq FALSE );
	}
	
	my $clikey  = $data->{'argspath_id'};
	my $envkeys = &convert_to_array($data->{'environment_id'}, TRUE);
	
    my $hintdir = undef;

	foreach ( @{$envkeys} ) {
	  my ( $key, $addon_path ) = ( $_, undef );
	  if ( ref($_) =~ m/hash/i ) {
	    ( $key, $addon_path ) = each($_);
	  }
	  if ( &valid_string($key) eq TRUE ) {
	    my $hint = $ENV{"$key"};
	    $hintdir = $hint if ( &valid_string($hint) eq TRUE && &does_directory_exist("$hint") eq TRUE );
		$hintdir = &normalize_path(&join_path($hintdir, $addon_path)) if ( &valid_string($addon_path) eq TRUE && ref($addon_path) eq '' );
		last if ( &valid_string($hintdir) eq TRUE );
	  }
	}
	
	my $hintdir_os = $data->{'machine_path'}->{&get_os_type()} if ( exists($data->{'machine_path'}->{&get_os_type()}) );
	if ( ref($hintdir_os) =~ m/code/i ) {
	  no strict;
	  my $hint = &{$hintdir_os}();
	  $hintdir = $hint if ( &valid_string($hint) eq TRUE && &does_directory_exist("$hint") eq TRUE );
	  use strict;
	} else {
	  $hintdir = $hintdir_os if ( &valid_string($hintdir_os) eq TRUE && &does_directory_exist("$hintdir_os") eq TRUE);
	}
	
	if ( &valid_string($data->{'hinted_path'}) eq TRUE ) {
	  my $hint = $data->{'hinted_path'};
	  $hintdir = $hint if ( &does_directory_exist("$hint") eq TRUE );
	}
	
	if ( defined($clikey) ) {
	  $hintdir = ( exists($argsref->{"$clikey"}) && &does_directory_exist("$argsref->{$clikey}") eq TRUE ) ? "$argsref->{$clikey}" : $hintdir;
	}
	
	if ( &valid_string($data->{'executable'}) eq TRUE ) {
	  my $binary = &which($data->{'executable'}, $hintdir);
	  if ( &valid_string($binary) eq TRUE ) {
	    $binary = &convert_path_to_client_machine("$binary", &get_os_type());
	    &__print_debug_output("Binary executable --> << $binary >>") if ( $is_debug );
	    $executable->set_executable($binary);
	  }
	} else {
	  goto CHECK_FOR_ERROR_CONDITION;
	}
	
  CHECK_FOR_ERROR_CONDITION:
    if ( ref($data) !~ m/hash/i ) {
	  $data = {};
	}
	$data->{'error_type'} ||= 'NO_EXECUTABLE';
	$data->{'skip_error'} = FALSE if ( not defined($data->{'skip_error'}) );
	
	&main::end_build($data->{'error_type'}) if ( not defined($executable->get_executable()) &&
	                                             ( exists($data->{'skip_error'}) && $data->{'skip_error'} eq FALSE ) );
	
	if ( &valid_string($data->{'identification'}) eq FALSE ) {
	  my $num_entries = scalar(keys(%{$exes}));
	  $data->{'identification'} = "exe-$num_entries";
	}
	
	$exes->{$data->{'identification'}} = $executable;

	return TRUE;
  }
  
#=============================================================================
sub match_hybrid_version_id($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	if ( $_[0] =~ m/[vV](\d*)/ ) {
	  my $hybrid_version = $1;
	  return ( &set_contains($hybrid_version, HYBRID_VERSIONS), $hybrid_version );
	} else {
	  return ( FALSE, undef );
	}
  }
  
#=============================================================================
sub match_hybrid_OO_version_id($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $vobj = &create_object('c__HP::VersionObject__');
	
    my $vid = shift || return $vobj;
	$vid =~ s/OO// if ( &str_starts_with($vid, [ 'OO' ]) eq TRUE );
	
	$vobj->set_version($vid);
	return &set_contains('OO'.$vobj->major(), OO_VERSIONS);
  }
  
#=============================================================================
sub query_jenkins
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $data = shift;
	my $type = shift || JENKINS_ENVIRONMENT_QUERY;
	
	if ( $type eq JENKINS_ENVIRONMENT_QUERY ) {
	  my $key = JENKINS_QUERY_MAP->{&JENKINS_ENVIRONMENT_QUERY}->{"$data"}->[0];
	  return $ENV{"$key"} if ( defined($key) && defined($ENV{"$key"}) );
	}
	return JENKINS_QUERY_MAP->{&JENKINS_ENVIRONMENT_QUERY}->{"$data"}->[1];
  }
  
#=============================================================================
sub record_arguments_to_history()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $input_args   = &get_from_configuration('program->user_arguments');
	my $program_name = &get_from_configuration('program->progname', TRUE);
	
	return if ( not defined($input_args) );
	return if ( not defined($program_name) );
	
	my $homedir = &get_homedir();
	
	return if ( (not defined($homedir)) || &does_directory_exist("$homedir") eq FALSE );
	my $history_file = &__generate_CSL_history_file("$homedir", "$program_name");
	my $current_time = &get_formatted_datetime();
	
	my $data = [ "[ $current_time ] :: $^X $program_name.pl @{$input_args->{'args'}}" ];
	
	my $strDB = &getDB('stream');
	if ( defined($strDB) ) {
	  my $strhndl = '__HISTORY__';
	  
	  my $history_stream = $strDB->make_stream("$history_file", OUTPUT, $strhndl);
	  if ( defined($history_stream) ) {
	    # TODO :  Need to apply spin lock to make sure we are next in case of parallel access
	    $history_stream->set_rotating(TRUE, MAX_HISTORY_FILELINES);
		$history_stream->raw_output($data);
	  }
	  
	  $strDB->remove_stream($strhndl);
	}
	
	return;
  }

#=============================================================================
sub run_packaging($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $number_errors = shift || 0;
	
    my $argsref = &get_from_configuration('program->user_arguments');
	my $derived = &get_from_configuration('derived_data');
	my $gdi     = $derived->{'global'};

	&__print_debug_output("Returning to launch directory") if ( $is_debug );
	
	my $driveDB = &getDB('drive');
	
	chdir $driveDB->expand_drivepath("$argsref->{'launch_directory'}");
	if ( $number_errors == 0 ) {
	  if ( $argsref->{'package'} ) {
        delete($argsref->{'hpoo'}) if ( exists($argsref->{'hybrid'}) );
 	    my $build_stories = &get_from_configuration("derived_data->userstories->build");
        if ( scalar(@{$build_stories}) == 1 && $build_stories->[0] eq $gdi->get_installer_srcdir() ) {
          &raise_exception(
		                   {
						    'type'       => 'NO_CONTENT_BUILT',
						    'severity'   => FAILURE,
						    'addon_msg'  => "NO user content built when requesting package and installer generation.",
						    'callback'   => \&main::end_build,
						    'handles'    => [ 'STDERR', $HP::CSL::Tools::cslloghandle ],
						   }
						  );
        }
		
	    my $packscript    = &normalize_path(&join_path("$FindBin::Bin", 'package.pl'));
	    my @list_of_passthru = @{$argsref->{'packaging_options'}};
		my @pack_options  = ();
		
		&__print_output("Calling packaging script...", INFO);
		foreach my $item ( @list_of_passthru ) {
		  &__print_debug_output("Interrogating pass thru option --> $item");
		  my @components = split(/:/, $item, 2);
		  next if ( not exists($argsref->{"$components[0]"}) );
		  if ( scalar(@components) == 2 ) {
		    if ( $components[1] eq 'p' ) {
			  push( @pack_options, "--$components[0]='".$driveDB->expand_drivepath("$argsref->{$components[0]}")."'" );
			  &__print_debug_output("Current pack options --> @pack_options");
		      next;
			}
		    if ( $components[1] eq 's' ) {
			  my $refparts = &convert_to_array($argsref->{"$components[0]"}, TRUE);
			  next if ( scalar(@{$refparts}) < 1 );
			  my $parts = join(',', @{$refparts});
			  push( @pack_options, "--$components[0]=\"$parts\"" );
			  &__print_debug_output("Current pack options --> @pack_options");
			  next;
			}
		  }
		  push ( @pack_options, "--$components[0]" ) if ( $argsref->{"$components[0]"} );
		}
		  
		$packscript = $driveDB->expand_drivepath("$packscript");
	    $driveDB->clear_drive($derived->{'rootpath'});
		&__print_debug_output("Package options --> @pack_options");
		my $cmdhash = {
				       'command'   => "$^X",
				       'arguments' => "\"$packscript\" @pack_options",
				       'verbose'   => $is_debug,
		              };
 
        my ($packerror, $joboutput) = &runcmd($cmdhash);
		if ( $packerror ne PASS ) {
		  &__print_output("Problem in packaging after building...", FAILURE);
		  ++$number_errors;
		}
	  }
	}
	 
	$driveDB->clear_drive($derived->{'rootpath'});

	return $number_errors;
  }

#=============================================================================
sub run_release()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
  
    my $argsref = &get_from_configuration('program->user_arguments');
	my $gdi     = &get_from_configuration("derived_data->global");
	
	if ( $argsref->{'installer'} ) {
      &__print_output("Building installer executable necessary for final packaging", INFO);
		
	  my $errorcode = &update_installer_delivery($argsref->{'updateXMLfile'});
		
	  my $build_stories = &get_from_configuration("derived_data->userstories->build");
	  &main::end_build($errorcode) if ( $errorcode ne PASS );
		
	  push( @{$build_stories}, $gdi->get_installer_srcdir() );
	}
	
	return &run_maven();
  }

#=============================================================================
sub setup_help_screen()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	#======================================================================
	# Add the information for the help screen, etc...
	#======================================================================
	my $basicInfo = {
					 'progname'       => $main::progname,
					 'exceptions'     => [],
					 'terminate_func' => \&main::end_build,
					 'terminate_args' => [ 255 ],
					};
	my $programInputs = {
						 'info' => {
								    'deployment_date'    => '08/20/2014',
									'VERSION'            => $main::BUILD_VERSION,
									'maintainer'         => 'Mike Klusman',
									'email'              => 'michael.edw.klusman-iii',
								   },
						 };
	$programInputs->{'progname'} = $basicInfo->{'progname'};
	 
	$programInputs->{'info'}->{'program_input'} = $basicInfo;
	$programInputs->{'info'}->{'program_input'}->{'usage_clause'}    = "[mandatory opts] [optional opts] ";
	$programInputs->{'info'}->{'program_input'}->{'descript_clause'} = "This Perl script allows for local building (possibly selective) of content from the CSL Team.  It is written with a fair amount of flexibility to ensure usage both from local building and well as from the Automated Build System running Jenkins.  Options marked with [M] are mandatory while other marked [O] are optional.";
	$programInputs->{'info'}->{'program_input'}->{'examples_clause'} = [
	                                                                     '--build-path="<path to proxy branch>" --version',
	                                                                     '--build-path="<path to proxy branch>" --info',
	                                                                     '--build-path="<path to proxy branch>" --match "CP4"',
                           							 		             '--build-path="<path to proxy branch>" --path-javaexe="<path to exe>" --dryrun',
																		 '--build-path="<path to proxy branch>" --debug --hpoo="9.07.003" -cc "Amazon EC2"',
	                                									 '--build-path="<path to proxy branch>" --save-log --hpoo="OO9" --hpoo="OO10"',
                           							 		             '--build-path="<path to proxy branch>" --skip-jar',
                           							 		             '--build-path="<path to proxy branch>" --match "CP3.01" --match "CP4" --show-match',
                           							 		             '--build-path="<path to proxy branch>" --debug --hybrid="OO10:v1" --hybrid="OO9:v2" --hpoo="OO9" --hpoo="OO10" --save-log --match="CP4" --package --installer',
                           							 		             '--build-path="<path to proxy branch>" --debug --capsule-xml="capsule_config.xml" --save-log',
	     	                                                           ];

	$programInputs->{'info'}->{'program_input'}->{'options_clause'} = {
							'-a,--automated'                   => [ 'Determine whether process managed by JENKINS.', OPTIONAL, '' ],
							'-all=<>,--complete_bp_process=<>' => [ 'Build, package, and wrap up with installer while pushing to test area.', OPTIONAL, '' ],
							'-bp=<>,--build-path=<>'           => [ 'Path to user content.', MANDATORY, '=s' ],
							'-c=<>,--user-content=<>'          => [ 'Specific content to build in addition to normal matching rules.', OPTIONAL, '=s@' ],
							'-cc=<>,--exclusive-content=<>'    => [ 'Exclusive content to build in lieu of normal matching rules.', OPTIONAL, '=s@' ],
							'-cf=<>,--config-file=<>'          => [ 'Drive build/packaging via configuration file.', OPTIONAL, '=s' ],
							'-cap=<>,--capsule-xml=<>'         => [ 'Capsule XML file for build/packaging.', OPTIONAL, '=s' ],
							'-d,--debug'                       => [ 'Turn on debugging.', OPTIONAL, '', FALSE ],
							'-e,--erase'                       => [ 'Erase all toplevel generated directories [products/release directories]', OPTIONAL, '' ],
							'-ek=<>,--error-keys=<>'           => [ 'List of additional error keys to search logfile', OPTIONAL, '=s@' ],
							'-f,--force'                       => [ 'Force compilation for ALL directories found regardless of content type.', OPTIONAL, '' ],
							'-gp=<>,--global-propfile=<>'      => [ 'Define global properites file for build.', OPTIONAL, '=s' ],
							'-hyb=<>,--hybrid=<>'              => [ 'Hybrid model for packaging of build.  Entries are in key-value pairs separated by colon.  Keys are "OO9" or "OO10" and values represent version of packaging style.  v1 = individual zip files for use cases.  v2 = capsule zip files for all use cases.  v3 = mixture of v1 and v2 with suitable collection and reorganization of data items.', OPTIONAL, '=s@' ],
							'-hig,--hpln-idx-gen'              => [ 'Run HPLN Index Generator for posting content to HPLN.', OPTIONAL, '' ],
							'-I,--installer'                   => [ 'Force build of installer code with build.', OPTIONAL, '' ],
							'-nojar,--skip-jar'                => [ 'Skip building jar and force zipfile (default is off [0]).', OPTIONAL, '' ],
							'-k,--keep-all-products'           => [ 'Keep all intermediate build products for post-mortem.', OPTIONAL, '' ],
							'-l=<>,--logfile=<>'               => [ 'Designate logfile for build/packaging. The default directory for logfile if not specified is <'. &get_temp_dir() .'> using the process ID embedded in logfile name.', OPTIONAL, '=s' ],
							'-m=<>,--match=<>'                 => [ 'List user stories matching content type specification for build/packaging.', OPTIONAL, '=s@' ],
							'-md=<>,--maven-define=<>'         => [ 'Directive to add define for Maven call.', OPTIONAL, '=s@' ],
							'-mp=<>,--maven-param=<>'          => [ 'Directive to add parameter for Maven call.', OPTIONAL, '=s@' ],
							'-mt=<>,--maven-target=<>'         => [ 'Directive to employ with Maven [ test | clean | package ]', OPTIONAL, '=s@' ],
							'-n,--dryrun'                      => [ 'Do a dryrun -- no processing actually done.', OPTIONAL, '' ],
							'-o=<>,--hpoo=<>'                  => [ 'Selection of HP OO Versions to produce. The default is produce profiles for HP OO-10.x supported versions. Multiple versions can be given and results will be merged.  HP OO version information can be specified by <x.y.(z)> or by OO<major.version minor.version>', OPTIONAL, '=s@' ],
							'-p,--package'                     => [ 'Allow packaging to commence upon build completion (old content pack style).', OPTIONAL, '' ],
							'--path-7z=<>'                     => [ 'Define the path for the 7z commandline exe.', OPTIONAL, '=s' ],
							'--path-mavenexe=<>'               => [ 'Define the path for the Maven commandline exe.', OPTIONAL, '=s' ],
							'--path-javaexe=<>'                => [ 'Define the path for Java (i.e. "C:/Program Files/Java/jdk-x.y.z")', OPTIONAL, '=s' ],
							'--path-svnexe=<>'                 => [ 'Define the path for the SVN commandline exe.', OPTIONAL, '=s' ],
							'-r=<>,--releaseID=<>'             => [ 'Tell builder it is a release candidate.', OPTIONAL, '=s' ],
							'-s,--no-svn'                      => [ 'Isolate from SVN and ignore SVN usage calls.', OPTIONAL, '', FALSE ],
							'-sl,--save-log'                   => [ 'Save build logfile for post-mortem investigation.', OPTIONAL, '', FALSE ],
							'-shl,--show-log'                  => [ 'Display build logfile.', OPTIONAL, '' ],
							'-sm,--show-match'                 => [ 'Display matching user stories, but do not build.', OPTIONAL, '' ],
							'-sup=<>,--suppress=<>'            => [ 'Suppress jarfile and service designs from use within installer.', OPTIONAL, '=s' ],
							'-t=<>,--test=<>'                  => [ 'Allow for build zip artifact to be pushed to Test Harness SVN location for Jenkins Test Automation.', OPTIONAL, '=s' ],
							'-u,--unified'                     => [ 'Package for Unified Installation (old content pack style).', OPTIONAL, '' ],
							'-uxml=<>,--updateXMLfile=<>'      => [ 'Supply custom installation update file for installer build (old content pack style).', OPTIONAL, '=s' ],
                            '--use-premade-xml'                => [ 'Use premade enablement and requirements XML files instead of building from content pieces (old content pack style).', OPTIONAL, '' ],
							#'-y,--skip-compliance-check'       => [ 'Skip Compliance Checker tool invocation for content.', OPTIONAL, '' ],
							'-z,--allow-lrc'                   => [ 'Allow LRC content.', OPTIONAL, '' ],
							'-zip,--build-zip'                 => [ 'Build zip in addition to jarfile (where applicable with OO9 -- default is off [0]).', OPTIONAL, '' ],
																		};
	
	#======================================================================
	# Install this "startup" information
	#======================================================================
	&initial_setup($programInputs);
    return;
  }
  
#=============================================================================
sub store_user_arguments()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    # Save commandline as it was given...
    my @args  = @ARGV;
    my $cla   = { 'args' => \@args };
	
	&save_to_configuration({'data' => [ 'program->user_arguments', $cla ]});
	
	return;
  }
  
#=============================================================================
sub validate_executables()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $argsref = &get_from_configuration('program->user_arguments');
	my $exes    = {};
	
  	#======================================================================
	# Validate executables and other applications necessary
	#======================================================================
	if ( not exists($argsref->{'no-svn'}) ) {
	  &install_executable(
	                      {
						   'executable'     => 'svn',
						   'argspath_id'    => 'svnexe-path',
						   'environment_id' => 'SVN',
						   'machine_path'   => {
						                        'win' => 'C:/Program Files/TortoiseSVN/bin',
											    'lin' => '/usr/local/bin',
											   },
						   'identification' => 'svn',
						  }, $exes
						 );
	}
	
	if ( not exists($argsref->{'capsule-xml'}) ) {
	  my $derived = &get_from_configuration('derived_data');
	  &install_executable(
	                      {
						   'executable'     => 'mvn',
						   'argspath_id'    => 'mavenexe-path',
						   'environment_id' => 'M2_HOME',
						   'machine_path'   => {
						                        'win' => &__find_hinted_maven(),
											    'lin' => '/usr/local/bin',
											   },
						   'hinted_path'    => &join_path("$derived->{'devtools'}", 'apache-maven-2.2.1','bin'),
						   'identification' => 'maven',
						  }, $exes
						 );
	}
	
	&install_executable(
	                    {
						 'executable'     => 'javac',
						 'argspath_id'    => 'javaexe-path',
						 'environment_id' => [ {'JDK_HOME' => 'bin'}, {'JAVA_HOME' => 'bin'} ],
						 'machine_path'   => {
						                      'win' => 'C:/Program Files/Java/jdk1.7.0/bin',
											  'lin' => '/usr/local/bin',
											 },
						 'identification' => 'javac',
						}, $exes
					);
	
	&install_executable(
	                    {
						 'executable'     => 'java',
						 'argspath_id'    => 'javaexe-path',
						 'environment_id' => [ {'JDK_HOME' => 'bin'}, {'JAVA_HOME' => 'bin'} ],
						 'machine_path'   => {
						                      'win' => 'C:/Program Files/Java/jdk1.7.0/bin',
											  'lin' => '/usr/local/bin',
											 },
						 'identification' => 'java',
						}, $exes
					);

	&install_executable(
	                    {
						 'executable'     => '7z',
						 'argspath_id'    => '7zip-path',
						 'environment_id' => 'SEVENZIP',
						 'machine_path'   => {
						                      'win' => 'C:/7Zip',
											  'lin' => '/usr/local/bin',
											 },
						 'identification' => '7z',
						}, $exes
					);

	&install_executable(
	                    {
						 'executable'     => 'perl',
						 'hinted_path'    => undef,
						 'argspath_id'    => 'perl-path',
						 'identification' => 'perl',
						 'error_type'     => 'NO_EXECUTABLE',
						}, $exes
					);

	&save_to_configuration({'data' => [ 'derived_data->executables' , $exes ]});
	&__print_debug_output("Executables -->\n".Dumper($exes)) if ( $is_debug );
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;