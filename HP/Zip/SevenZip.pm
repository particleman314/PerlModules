package HP::Zip::SevenZip;

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

	use parent qw(HP::Zip::Common);
	
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

    @EXPORT = qw(
		        );

    $module_require_list = {
                            'Cwd'                          => undef,
							'File::Basename'               => undef,
 
			                'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Configuration'   => undef,
							'HP::Support::Object::Tools'   => undef,
			                'HP::Os'                       => undef,
                            'HP::Path'                     => undef,
							'HP::FileManager'              => undef,
							'HP::Copy'                     => undef,
                          };

    $VERSION  = 0.7;

    $is_init  = 0;
    $is_debug = (
		         $ENV{'debug_zip_sevenzip_pm'} ||
		         $ENV{'debug_zip_modules'} ||
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
sub __store
  {
    my $self  = shift;
	my $error = PASS;
	
	if ( &valid_string($self->target_location_dir()) eq FALSE ||
	     &valid_string($self->target_location_file()) eq FALSE ) {
	  $error = FAIL;
	  goto FINISH; 
	}
	
	my $outdir  = $self->target_location_dir();
	my $outname = $self->target_location_file();
	
	my $fullpath = &join_path("$outdir", "$outname");
    &HP::FileManager::delete("$fullpath") if ( &does_file_exist("$fullpath") );
  
	my $gds = &get_from_configuration('derived_data->executables');
	my $a7z = $gds->{'7z'}->clone();
	
	if ( not defined($a7z) ) {
	  $error = FAIL;
	  goto FINISH;
	}
		
	# Hard-coded options here for now...  TODO
	$a7z->add_flags('u');         # Update method
	$a7z->add_flags("\"$fullpath\""); # Full path for output name
	$a7z->add_flags('-mx9');      # ultra compression
	$a7z->add_flags('-tzip');     # zip file archive
	$a7z->add_flags('-y');        # non-interactive (assume yes to any questions)

	foreach ( @{$self->files()->get_elements()} ) {
	  &__print_debug_output("Archiving file : $_") if ( $is_debug );
      $a7z->add_flags("\"$_\"");
    }
	
	foreach ( @{$self->directories()->get_elements()} ) {
	  &__print_debug_output("Archiving directory : $_") if ( $is_debug );
      $a7z->add_flags("\"$_\"");
    }
		
	$a7z->run();
	if ( $a7z->error_status() ne PASS ||
	     $a7z->scan_for_errors([ 'System Error', 'WARNING' ]) eq TRUE ) {
	  &__print_output('Unable to compress contents using 7z!', FAILURE);
	  &__print_output("Job output -->\n", FAILURE);
	  &__print_output(join("\n", $a7z->get_job_contents()), FAILURE);
	  $error = FAIL;
	  goto FINISH;
	}
	
  FINISH:
	return $error;
  }
  
#=============================================================================
sub data_types
  {
    my $self         = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
		              };
    
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
		  if ( exists($self->{"$key"}) ) { $self->{"$key"} = $_[0]->{"$key"}; }
		}
	  } else {
	    &__print_output("Please use a hash as input to construct this class << $class >>", 'STDERR');
		return undef;
	  }
	}
	
    bless $self, $class;
	$self->instantiate();
	return $self;  
  }

#=============================================================================
1;