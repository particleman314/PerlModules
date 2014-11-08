package HP::CSL::Build;

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
    
    $VERSION = 0.99;
 
    @ISA    = qw(Exporter);
    @EXPORT = qw(
               );

    $module_require_list = {
	                        'File::Find'                    => undef,
	                        'File::Basename'                => undef,
							
	                        'HP::Constants'                 => undef,
							'HP::Support::Base'             => undef,
							'HP::Support::Base::Constants'  => undef,
							'HP::Support::Configuration'    => undef,
							'HP::Support::Object::Tools'    => undef,
							'HP::Support::Screen'           => undef,
							'HP::Exception::Tools'          => undef,
							
							'HP::FileManager'               => undef,
                          };

    $module_request_list = {};

    $is_init     = 0;
    $is_debug    = (
		            $ENV{'debug_csl_build_pm'} ||
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
my $current_oo_projectdir = undef;

#=============================================================================
sub __cleanup_build_area($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
  
    my $argsref = &get_from_configuration('program->user_arguments');
	if ( $argsref->{'keep-all-products'} ) { return ; }
	
	my $content_directory = shift || return;
	my $content           = shift || return;
	my $handles           = shift || [ 'STDOUT' ];
	
	if ( $argsref->{'dryrun'} eq FALSE ) {
	  ###################################################################
	  # Cleanup after build
	  ###################################################################
	  my $cleanup_areas = &create_object('c__HP::ArrayObject__');
	  $cleanup_areas->push_item(&join_path("$content_directory", File::Basename::dirname("$argsref->{'tmp-maven-settings'}")));
	  $cleanup_areas->push_item(&join_path("$content_directory", 'assemble-content', 'zip-target'));
	  $cleanup_areas->push_item(&join_path("$content_directory", 'compile', 'target'));
	  
      &print_to_streams("\n".&get_linespace()."\n", $handles);
	  &print_to_streams("Deleting components used to build << $content >>\n\n", $handles);
      #&printlist_2_stream(
	  #                    {
		#				   'style'   => 'NUMERICAL',
		#				   'streams' => $streams,
		#				   'data'    => \@cleanupParts,
		#				  }
		#			     );
	  &print_to_streams(&get_linespace()."\n\n", $handles);
	  &delete($cleanup_areas->get_elements());
	}

    # # Need to check this change of directory
	my $errorcode = chdir ("$argsref->{'launch_directory'}");
	if ( $errorcode == 0 ) {
      &raise_exception(
		               {
			 			'type'       => 'DIRECTORY_ACCESS_DENIED',
						'severity'   => FAILURE,
						'addon_msg'  => "Unable to change to directory << $content_directory >>.  It has changed its permissions!",
						'callback'   => \&bypass_error,
						'streams'    => $handles,
					   }
					  );
    }
	
	# return;
  }
  
#=============================================================================
sub __initialize()
  {     
    if ( not $is_init ) {
      $is_init = 1;	  
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }       
  }       

#=============================================================================
sub __locate_OO9_project_file_dir
  {
    if ( $File::Find::dir =~ m/xml$/ ) {
 	  $current_oo_projectdir = File::Basename::dirname("$File::Find::dir");
      &save_to_configuration({'data' => [ 'derived_data->oo_toplevel', $current_oo_projectdir ]});
	}
  }

#=============================================================================
sub __locate_OO10_project_file_dir
  {
    if ( $File::Find::dir =~ m/Content$/ ) {
 	  $current_oo_projectdir = File::Basename::dirname("$File::Find::dir");
      &save_to_configuration({'data' => [ 'derived_data->oo_toplevel', $current_oo_projectdir ]});
	}
  }

#=============================================================================
&__initialize();

#=============================================================================
1;