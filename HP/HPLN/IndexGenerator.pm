package HP::HPLN::IndexGenerator;

################################################################################
# Copyright (c) 2013-2014 HP.   All rights reserved
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

use strict;
use warnings;
use diagnostics;

#=============================================================================
BEGIN 
  {
    use Exporter();

    use FindBin;
    use lib "$FindBin::Bin/../..";

	use parent qw(HP::BaseObject HP::JSON::JSONEnableObject HP::XML::XMLEnableObject);
	
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

    $VERSION = 1.02;

    @EXPORT  = qw (
                  );

    $module_require_list = {
	                        'File::Spec'                   => undef,
							'File::Basename'               => undef,
							
	                        'HP::Constants'                => undef,
							'HP::Support::Hash'            => undef,
                            'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Module'          => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
							
							'HP::Array::Tools'             => undef,
							'HP::CheckLib'                 => undef,
							'HP::FileManager'              => undef,
							'HP::Path'                     => undef,
							
							'HP::DBContainer'              => undef,
							'HP::Stream::Constants'        => undef,
                          };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_hpln_indexgenerator_pm'} ||
                 $ENV{'debug_hpln_pm'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );

    $broken_install = 0;

    print STDERR "BEGIN <". __PACKAGE__ .">\n" if ( $is_debug );

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "\t-->Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
        if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod\n" if ( $is_debug ); 
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
sub __install_exeobj
  {
    my $self = shift;
	
    my $jobexe = &create_object('c__HP::Job::Executable__');
	$jobexe->set_executable($self->hpln_jarfile());
	$self->hpln_jarfile($jobexe);
    return;
  }
  
#=============================================================================
sub clear
  {
    my $self = shift;
	
	$self->index_directory(undef);
	$self->index_files()->clear();
	$self->jarfiles()->clear();
	$self->success(FALSE);
	
	return;
  }
  
#=============================================================================
sub convert_json_to_xml
  {
    my $self        = shift;
	my $jsonidxfile = shift;
	
	return if ( &valid_string($jsonidxfile) eq FALSE );
	return if ( &does_file_exists("$jsonidxfile") eq FALSE );

	my $streamDB = &getDB('stream');
	  
	my $jsonstream = $streamDB->make_stream("$jsonidxfile", INPUT, '__JSON__');
	
	if ( not defined($jsonstream) ) {
	  &__print_output("Unable to open stream to << $jsonidxfile >> for decoding...", WARN);
	  return;
	}
	
	my $jsondata = $jsonstream->slurp();
	$streamDB->remove_stream('__JSON__');
	
	return if ( not defined($jsondata) );
	  
	my $hash_of_jsondata = $self->read_json($jsondata);
	
	my $jsondirname     = File::Basename::dirname("$jsonidxfile");
	my $filename_wo_ext = &remove_extension(File::Basename::basename("$jsonidxfile"));
	my $xmlfile         = &normalize_path(&join_path("$jsondirname", "$filename_wo_ext".'.xml'));
	
	my $xmldata = $self->as_xml($hash_of_jsondata);
	if ( not defined($xmldata) ) {
	  &__print_output("Unable to convert JSON data into XML data for << $jsonidxfile >>...", WARN);
	  return;
	}
	
	my $xmlobj = &create_object('c__HP::XMLObject__');
	$xmlobj->filename("$xmlfile");
	return $xmlobj->write($xmldata);
  }
  
#=============================================================================
sub data_types
  {
    my $self = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
	                   'hpln_jarfile'     => undef,
					   'index_directory'  => undef,
					   'index_files'      => 'c__HP::Array::Set__',
		               'jarfiles'         => 'c__HP::Array::Set__',
					   
					   'success'          => FALSE,
		              };
    
	# Collect all parent related fields if selected
	if ( $which_fields eq COMBINED ) {
      foreach ( @ISA ) {
	    my $parent_types = undef;
	    my $evalstr      = "\$parent_types = $_->data_types()";
	    eval "$evalstr";
	    $data_fields     = &HP::Support::Hash::__hash_merge( $data_fields, $parent_types ) if ( defined($parent_types) );
	  }
	}
	
    return $data_fields;
  }

#=============================================================================
sub get_hpln_executable
  {
    my $self  = shift;
    my $count = 0;
	
  REDO:
    my $fieldvalue = $self->hpln_jarfile();
	
	if ( &is_type($fieldvalue, 'HP::Job::Executable') eq TRUE ) {
	  return $fieldvalue->get_executable();
	} elsif ( $count > 1 || ( not defined($fieldvalue) ) ) {
	  $self->hpln_jarfile(undef) if ( defined($fieldvalue) );
	  return undef;
	}
	$self->__install_exeobj();
	
	++$count;
	goto REDO;
  }
  
#=============================================================================
sub get_index_directory
  {
    my $self = shift;
	return $self->index_directory();
  }

#=============================================================================
sub get_index_files
  {
    my $self = shift;
	return $self->index_files()->get_elements();
  }
  
#=============================================================================
sub get_jarfiles
  {
    my $self = shift;
	return $self->jarfiles()->get_elements();
  }
  
#=============================================================================
sub is_success
  {
    my $self = shift;
	return $self->success();
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
    return $self;
  }

#=============================================================================
sub run
  {
    my $self               = shift;
	my $location_to_search = shift;
	
	# Convert to Job::Executable class if not already so...
	if ( &is_type($self->hpln_jarfile(), 'HP::Job::Executable') eq FALSE ) {
	  return if ( &does_file_exist($self->hpln_jarfile()) eq FALSE );
	  $self->__install_exeobj();
	}
	
	# Ensure executable is valid to run...
	if ( $self->hpln_jarfile()->valid() eq FALSE ) {
	  &__print_output('Invalid executable defined for the HPLN Index Generator...', WARN);
	  &__print_output($self->hpln_jarfile(), WARN);
	  return;
	}
	
	# Collect jarfiles to index...
	if ( &valid_string($location_to_search) eq TRUE ) {
	  if ( &does_directory_exist("$location_to_search") eq TRUE ) {
		my $contents = &collect_directory_contents("$location_to_search");
		foreach ( @{$contents->{'files'}} ) {
		  next if ( &is_jar_file("$_") eq FALSE );
	      $self->jarfiles()->push_item(&join_path("$location_to_search", "$_"));
		}
	  }
	}
	
	if ( $self->jarfiles()->is_empty() eq TRUE &&
	     ( &valid_string($self->get_index_directory()) eq TRUE && 
		 ( &does_directory_exist( $self->get_index_directory() ) eq TRUE ) )
	   ) {
	  my $idxdir = $self->get_index_directory();
	  my $contents = &collect_directory_contents("$idxdir");
	  foreach ( @{$contents->{'files'}} ) {
		next if ( &is_jar_file("$_") eq FALSE );
	    $self->jarfiles()->push_item(&join_path("$idxdir", "$_"));
	  }
	}
	
	my $job = &create_object('c__HP::Job::Java__');
	
	if ( not defined($self->index_directory()) ) {
	  $self->index_directory(File::Basename::dirname($self->hpln_jarfile()->get_executable()));
	}

	$job->add_flags({'name' => '-jar', 'value' => '"'. $self->hpln_jarfile()->get_executable() .'"', 'connector' => ' '});
	
	my $success_array = [];
	foreach ( @{$self->jarfiles()->get_elements()} ) {
	  next if ( &is_jar_file("$_") eq FALSE );
	  
	  my $jarfilename = File::Basename::basename($_);
	  &__print_output("Generating HPLN index file for jarfile < $jarfilename >", INFO);
	  
	  my $idxfile = "$_.index";
	  
	  $job->add_flags({'name' => '--content-pack', 'value' => "\"$_\"", 'connector' => ' '});
	  $job->add_flags({'name' => '--hpln-index', 'value' => "\"$idxfile\"", 'connector' => ' '});

	  &__print_debug_output("Running command : ". $job->get_cmd(), __PACKAGE__) if ( $is_debug );
	  $job->run();
	  if ( $job->get_error_status() ne PASS ) {
	    &__print_output("Problem running HPLN Index Generator with content pack jarfile << $_ >>", WARN);
		&__print_output("Job contents :\n", WARN);
		&__print_output(join("\n", $self->get_job_contents()), WARN);  # Might need to read the HplnIndexGenerator.log file
		CORE::push( @{$success_array}, FALSE );
	  } else {
		CORE::push( @{$success_array}, TRUE );
	  }
	  
	  $job->remove_flags('--content-pack');
	  $job->remove_flags('--hpln-index');
	  $job->reset();
	  
	  if ( &does_file_exist("$idxfile") eq TRUE ) {
	    &__print_output("Successfully generated HPLN index file for < $jarfilename > capsule.", INFO);
		$self->index_files()->push_item("$idxfile");
	  }

	  # Need to cleanup...
	  &delete(&join_path(File::Spec->curdir(), 'HplnIndexGenerator.log'));
	  #$self->convert_json_to_xml();
	}
	
	$self->{'success'} = ( &sum_array($success_array) == $self->jarfiles()->number_elements() ) ? TRUE : FALSE;
	return ( $self->is_success() ) ? PASS : FAIL;
  }

#=============================================================================
1;