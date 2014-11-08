package HP::Flare;

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

    $VERSION = 1.00;

    @EXPORT  = qw ();

    $module_require_list = {
	                        'HP::Constants'              => undef,
							'HP::Support::Base'          => undef,
							'HP::Support::Hash'          => undef,
							'HP::Support::Module'        => undef,
							'HP::Support::Object'        => undef,
							'HP::Support::Object::Tools' => undef,
							'HP::Support::Configuration' => undef,
							
							'HP::Array::Constants'       => undef,
							'HP::Array::Tools'           => undef,

							'HP::Flare::Constants'       => undef,
							'HP::CheckLib'               => undef,
                          };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_array_set_pm'} ||
				 $ENV{'debug_array_modules'} ||
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

# BEGIN
  # {
    # use Exporter();

    # use FindBin;
    # use lib "$FindBin::Bin/..";

    # use vars qw(
                # $VERSION
                # $is_debug
                # $is_init

                # $module_require_list
                # $module_request_list

                # $broken_install

                # @ISA
                # @EXPORT
               # );

    # $VERSION     = 1.0;

    # @ISA         = qw ( Exporter );
    # @EXPORT      = qw (
					   # $add_flare_exception_types
	                   # &add_injection_point
					   # &add_print_stream
					   # &add_scan_log_text
					   # &default_routine
					   # &get_flare_log
					   # &get_injection_point
					   # &get_injection_point_names
					   # &has_injection_point
					   # &initialize_injection_points
					   # &make_flaregroup_module_name
					   # &make_flaregroup_dir
					   # &print_output
					   # &process_injection_point
					   # &scan_log
					   # &transfer_properties
					   # &validate_flare_settings
					   # &validate_requirements
                      # );

	# #======================================================================
	# # Required modules (system and HP centric) for accomplishing tasks
	# #======================================================================
    # $module_require_list = {
							# 'Cwd'            => undef,
							# 'File::Basename' => undef,
							# 'MIME::Base64'   => undef,
							# 'Tie::IxHash'    => undef,
							
 							# 'HP::String'        => undef,
							# 'HP::RegexLib'      => undef,
							# 'HP::BasicTools'    => undef,
							# 'HP::Process'       => undef,
							# 'HP::ArrayTools'    => undef,
							# 'HP::Copy'          => undef,
							# 'HP::StreamManager' => undef,
							# 'HP::Path'          => undef,
							# 'HP::FileManager'   => undef,
                           # };
						   
    # $module_request_list = {};

    # $is_init  = 0;
    # $is_debug = (
                 # $ENV{'debug_hp_flare_pm'} ||
                 # $ENV{'debug_flare_modules'} ||
                 # $ENV{'debug_all_modules'} || 0
                # );

	# if ( $is_debug ) { $module_require_list->{'Data::Dumper'} = undef; }
	
    # $broken_install = 0;

    # print STDERR "BEGIN <". __PACKAGE__ .">\n" if ( $is_debug );

    # eval "use HP::ModuleLoader;";
    # if ( $@ ) {
       # print STDERR "\t--> Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
       # $broken_install = 1;
    # }

    # $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    # if ( $broken_install ) {
       # foreach my $usemod (keys(%{$module_require_list})) {
          # if ( defined($module_require_list->{$usemod}) ) {
             # print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
             # eval "use $usemod $module_require_list->{$usemod};";
          # } else {
             # print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug ); 
             # eval "use $usemod;";
          # }
          # if ( $@ ) {
             # print STDERR "\t--> Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
             # die "Exiting!\n$@";
          # }
       # }
    # } else {
       # my $use_cmd = &load_required_modules( __PACKAGE__, $module_require_list);
       # eval "$use_cmd";
    # }

    # if ( $broken_install ) {
       # foreach my $usemod (keys(%{$module_request_list})) {
         # if ( defined($module_request_list->{$usemod}) ) {
            # print STDERR "\t--> REQUESTED [". __PACKAGE__ ."]:: use $usemod $module_request_list->{$usemod};\n" if ( $is_debug );
            # eval "use $usemod $module_request_list->{$usemod};";
         # } else {
            # print STDERR "\t--> REQUESTED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug );
            # eval "use $usemod;";
         # }
         # if ( $@ ) {
            # print STDERR "\t--> Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
         # }
       # }
    # } else {
       # my $use_cmd = &load_required_modules( __PACKAGE__, $module_request_list);
       # eval "$use_cmd";
    # }

    # # Print a message stating this module has been loaded.
    # print STDERR "LOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  # }


  # }

# Add injection points into appropriate location to run
# Inject personal module
# 

#=============================================================================
sub __process_injection_point
  {
    my $self = shift;
     my $injptr    = shift;
	 my $cloref    = shift;
	 
     my $errcondition = 0;
	 my $is_default   = 0;
	 
	 if ( ! defined($injptr) ) { return 1; }
	 if ( ! defined($cloref) ) { return 2; }

	 my $routine_name = undef;
	 
	 if ( ! &has_injection_point($injptr) ) { 
	    $routine_name = 'default_routine';
		$is_default = 1;
	 } else {
	    $routine_name = &get_injection_point($injptr);
	    $routine_name = &lowercase_all("$cloref->{'flaregroup'}")."_$injptr";
     }
	 
	 &print_output("Processing $routine_name");
	 my $module = &make_flaregroup_module_name($cloref);
	 if ( &function_exists($module, "$routine_name") ) {
		my $routine = \&{$routine_name};
		
		no strict 'refs';
	    if ( ! $is_default ) {
	       $errcondition = &{$routine}($cloref, @_);
		} else {
	       $errcondition = &{$routine}($cloref, $injptr);
		}
		use strict 'refs';
     } else {
	    $errcondition = 255;
	 }
	 
	 if ( $errcondition != 0 ) {
        &print_output("Injection point <$injptr> failed using routine $routine_name.", FAILURE);
		return 255;
	 }
  }
  
#=============================================================================
sub add_injection_point
  {
    my $self           = shift;
	my $inject_name    = shift;
	my $inject_routine = shift;
	my $location       = shift || APPEND;
	
	return FALSE if ( ( &valid_string($inject_name) eq FALSE ) ||
	                  ( &valid_string($inject_routine) eq FALSE ) );
	
	$self->injection_points()->add_elements({'entries' => {"$inject_name" => "$inject_routine"},
	                                         'location' => $location});
  }

#=============================================================================
sub data_types
  {
    my $self = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
		               'scannable_items'  => 'c__HP::ArrayObject__',
					   'injection_points' => 'c__HP::Array::Queue__',
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
sub run
  {
    my $self  = shift;
	my $steps = $self->injection_points();
	
	foreach ( @{$steps} ) {
	  $self->__process_injection_point($_);
	}
  }

#=============================================================================
1;
