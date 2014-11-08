package HP::Zip::Common;

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

	use parent qw(HP::BaseObject);
	
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
                            'Cwd'                        => undef,
							'File::Basename'             => undef,
 
			                'HP::Constants'              => undef,
							'HP::Support::Base'          => undef,
							'HP::Support::Object::Tools' => undef,
							'HP::CheckLib'               => undef,
			                'HP::Os'                     => undef,
                            'HP::Path'                   => undef,
							'HP::FileManager'            => undef,
							'HP::Copy'                   => undef,
                          };

    $VERSION  = 0.7;

    $is_init  = 0;
    $is_debug = (
		         $ENV{'debug_zip_common_pm'} ||
		         $ENV{'debug_zip_modules_pm'} ||
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
sub add
  {
    my $self = shift;
	my $item = shift;
	
	return FALSE if ( &valid_string($item) eq FALSE );
	
	my $is_file      = &does_file_exist("$item");
	my $is_directory = &does_directory_exist("$item");
	
	$item = &convert_path_to_client_machine("$item", &get_os_type());
	return FALSE if ( $is_file eq FALSE && $is_directory eq FALSE );
	
	$self->files()->push_item("$item") if ( $is_file );
	$self->directories()->push_item("$item") if ( $is_directory );
	
	return TRUE;
  }
  
#=============================================================================
sub add_contents
  {
    my $self  = shift;
	my $entry = shift || return FALSE;
	
	return FALSE if ( &valid_string($entry) eq FALSE );
	return FALSE if ( &does_directory_exist("$entry") eq FALSE );
	
	my $contents = &collect_directory_contents("$entry");
	
	foreach ( @{$contents->{'directories'}} ) {
	  $self->add(&join_path("$entry", "$_"));  # Use Relative path from search location
	}
	foreach ( @{$contents->{'files'}} ) {
	  $self->add(&join_path("$entry", "$_"));
	}
	return TRUE;
  }
  
#=============================================================================
sub data_types
  {
    my $self         = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
	                   'files'                => 'c__HP::ArrayObject__',
					   'directories'          => 'c__HP::ArrayObject__',
					   'target_location_dir'  => undef,
					   'target_location_file' => undef,
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
sub store
  {
    my $self = shift;
	if ( &valid_string($self->target_location_dir()) eq FALSE ||
	     &valid_string($self->target_location_file()) eq FALSE ) {
	  return FAIL; 
	}
	
	my $tgtdir  = $self->target_location_dir();
	my $tgtfile = $self->target_location_file();
	
	&make_recursive_dirs("$tgtdir") if ( &does_directory_exist("$tgtdir") eq FALSE );
	
	my $error = undef;
	if ( &function_exists($self, '__store') eq TRUE ) {
	  #$error = &work_in_directory("$outdir", sub { $self->__store() }, $self);
	  $error = $self->__store();
	}
	return $error;
  }

#=============================================================================
sub store_location
  {
    my $self            = shift;
	my $target_location = shift || return FALSE;
	
	return FALSE if ( &valid_string($target_location) eq FALSE );
	if ( &path_is_rel("$target_location") eq TRUE ) {
	  $target_location = &normalize_path(&join_path(&getcwd(), "$target_location"));
	}
	$self->target_location_dir(File::Basename::dirname("$target_location"));
	$self->target_location_file(File::Basename::basename("$target_location"));
  }
  
#=============================================================================
1;