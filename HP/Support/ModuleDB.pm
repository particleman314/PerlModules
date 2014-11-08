package HP::Support::ModuleDB;

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

	use parent qw(HP::DB);
	
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

    $VERSION = 0.75;

    @EXPORT  = qw (
                  );

    $module_require_list = {							
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::Support::Module'          => undef,
							
							'HP::CheckLib'                 => undef,
							'HP::Utilities'                => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_support_moduledb_pm'} ||
                 $ENV{'debug_support_modules'} ||
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
my $local_true    = TRUE;
my $local_false   = FALSE;

#=============================================================================
sub _new_instance
  {
    return &new(@_);
  }

#=============================================================================
sub add_module_id
  {
    my $self      = $_[0];

	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    if ( ref($_[1]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'module_id', undef,
	                                        'order',     undef,
											'rtinit',    undef, ], @_[ 1..scalar(@_)-1 ]);
    } else {
	  $inputdata = $_[1];
	}

	# No input, return FALSE exit status
    goto __END_OF_SUB if ( scalar(keys(%{$inputdata})) == 0 );
	
    my $module_id = $inputdata{'module_id'} || goto __END_OF_SUB;
	my $order     = $inputdata{'order'}     || 1;
	my $rtinit    = $inputdata{'rtinit'}    || 'runtime_initialize';
	
	my $map = $self->installed_hp_modules();

	goto __END_OF_SUB if ( &valid_string($module_id) eq $local_false );
	if ( &valid_string($module_id) eq $local_false || &is_integer($order) eq $local_false ) {
	  $order = scalar(keys(%{$map}));
	}
	
	goto __END_OF_SUB if ( &valid_string($rtinit) eq $local_false );
	
	$module_id       = &convert_from_colon_module($module_id);
	$module_colon_id = &convert_to_colon_module($module_id);
	
	
	if ( &function_exists($module_colon_id, $rtinit) eq $local_true &&
	     not exists($map->{"$module_id"}) ) {
	  my $result = &{"$module_colon_id".'::'.$rtinit}();
	  $self->installed_hp_modules->{"$module_id"} = [ $order, &convert_status_to_string($result) ];
	}
	
  __END_OF_SUB:
	return;
  }
  
#=============================================================================
sub clear
  {
    my $self = $_[0];
	
	$self->installed_hp_modules({}};
	$self->valid(FALSE);
	return;
  }

#=============================================================================
sub data_types
  {
    my $data_fields = {
					   'installed_hp_modules' => {},
					   'valid'                => $Local_false,
		              };
    
    foreach ( @ISA ) {
	  my $parent_types = undef;
	  if ( &function_exists($_, 'data_types') eq $local_true ) {
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
    my $self = $_[0];

    &__print_debug_output("Calling destructor for object ".ref($self)."\n") if ( $is_debug );
	return;
  }

#=============================================================================
sub new
  {	
    my $class       = $_[0];
    my $data_fields = &data_types();

    my $self = {
		        %{$data_fields},
	           };
	
    bless $self, $class;
	$self->instantiate();

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

	$self->validate();
    return $self;
  }

#=============================================================================
sub number_modules
  {
    my $self = $_[0];
	return scalar(keys(%{$self->installed_hp_modules()}));
  }
  
#=============================================================================
sub validate
  {
    my $self = $_[0];
	
	$self->SUPER::validate();
	$self->valid($local_true);
	return;
  }

#=============================================================================
1;