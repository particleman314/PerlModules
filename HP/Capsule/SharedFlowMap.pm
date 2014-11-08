package HP::Capsule::SharedFlowMap;

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

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'HP::Constants'                           => undef,
							'HP::Support::Base'                       => undef,
							'HP::Support::Base::Constants'            => undef,
							'HP::Support::Hash'                       => undef,
							'HP::Support::Object'                     => undef,
							'HP::Support::Object::Tools'              => undef,
							'HP::Support::Object::Constants'          => undef,
							'HP::CheckLib'                            => undef,
							
							'HP::Array::Tools'                        => undef,
							'HP::Array::Constants'                    => undef,
							};
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_capsule_sharedflowmap_pm'} ||
                 $ENV{'debug_capsule_modules'} ||
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
sub available_for_building
  {
    my $self    = shift;
	my $usecase = shift;
	
	return FALSE if ( &valid_string($usecase) eq FALSE );
	
	my $item_container  = $self->items();
	my $specific_fields = &get_fields($item_container);
	
	my ($wrkflw, $proper_uc) = $self->find_associated_usecase_wrkflw_pair("$usecase");
	
	return NOT_FOUND if ( not defined($wrkflw) );
	return FALSE if ( exists($self->shared_flow_list()->{'__delete_'.$wrkflw.'__'}) );
	return NOT_FOUND if ( scalar(@{$specific_fields}) < 1 );
	
	$specific_fields = &set_difference($specific_fields, [ $usecase ]);
	
	if ( exists($item_container->{"$usecase"}) ) {	  
	  foreach ( @{$specific_fields} ) {
	    delete($item_container->{"$_"}) if ( $item_container->{"$_"} eq "$proper_uc" );
	  }
	  
	  my $sfl = $self->shared_flow_list();
	  my $delete_key = undef;
	  
	  foreach ( keys($sfl) ) {
	    next if ( $_ =~ m/^__delete_/ || &is_type($sfl->{"$_"}, 'HP::Array::Set') eq FALSE );
		if ( $sfl->{"$_"}->contains("$proper_uc") eq TRUE ) {
		  $delete_key = $_;
		  last;
		}
	  }
	  
	  $sfl->{"__delete_".$delete_key."__"} = TRUE;
	  delete($item_container->{"$usecase"});
	  return TRUE;
	}
	
	return FALSE;
  }
  
#=============================================================================
sub data_types
  {
    my $self        = shift;
	my $which_level = shift || COMBINED;
	
    my $data_fields = {
	                   'items'            => {},
	                   'shared_flow_list' => {},
		              };
					  
    if ( $which_level eq COMBINED ) {
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
sub find_associated_usecase_wrkflw_pair
  {
    my $self    = shift;
	my $usecase = shift;

	return ( undef, $usecase ) if ( &valid_string($usecase) eq FALSE );
	
	my $wrkflw    = $self->find_workflow_from_usecase("$usecase");
	my $proper_uc = undef;
	
	if ( defined($wrkflw) ) {
	  $proper_uc = $self->shared_flow_list()->{"$wrkflw"}->get_element(0);
	}
	
	return ( $wrkflw, $proper_uc );
  }
  
#=============================================================================
sub find_workflow_from_usecase
  {
    my $self    = shift;
	my $usecase = shift;
	
	return undef if ( &valid_string($usecase) eq FALSE );
	
	my $sfl = $self->shared_flow_list();
	  
	foreach ( keys($sfl) ) {
	  next if ( &is_type($sfl->{"$_"}, 'HP::Array::Set') eq FALSE );
      return "$_" if ( $sfl->{"$_"}->contains("$usecase") eq TRUE );
	}
	
	return undef;
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
		  if ( exists($self->{"$key"}) ) {
		    $self->{"$key"} = $_[0]->{"$key"};
		  }
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
sub number_of_available_builds
  {
    my $self   = shift;
	my $wrkflw = shift;
	
	return 0 if ( &valid_string("$wrkflw") eq FALSE );
	
	my $sfl = $self->shared_flow_list();
	if ( exists($sfl->{"__delete_$wrkflw\__"}) ) {
	  my $marker = $sfl->{"__delete_$wrkflw\__"};
	  return 0 if ( defined($marker) );
	}
	return $sfl->{"$wrkflw"}->number_elements();
  }
  
#=============================================================================
sub print
  {
    my $self = shift;
	return;
  }

#=============================================================================
sub prepare_usage
  {
    my $self              = shift;
	my $item_container    = $self->items();
	my $shared_list_items = $self->shared_flow_list();
	my $specific_fields   = &get_fields($item_container);
	
	return if ( scalar(@{$specific_fields}) < 1 );
	
	foreach ( keys(%{$shared_list_items}) ) {
	  my $pairing = [];
	  push ( @{$pairing}, "$_", $shared_list_items->{"$_"}->get_element(0) );
	  
	  foreach my $spf ( @{$specific_fields} ) {
	    $item_container->{"$spf"} = $pairing->[1] if ( $item_container->{"$spf"} eq $pairing->[0] );
	  }
	}
	
	return;
  }
  
#=============================================================================
sub update_map
  {
    my $self = shift;

    my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'wrkflw_path', \&valid_string, 'usecase', \&valid_string ], @_);
    } else {
      $inputdata = $_[0];
    }

 	my $workflow_path = $inputdata->{'wrkflw_path'};
	my $usecase       = $inputdata->{'usecase'};
	
	return FALSE if ( ( not defined($workflow_path) ) || ( not defined($usecase) ) );
	
	my $item_container = $self->items();
	
	if ( not defined($item_container->{"$usecase"}) ) {
	  $item_container->{"$usecase"} = "$workflow_path";
	  my $mappinghash = $self->shared_flow_list();
	  if ( not exists($mappinghash->{"$workflow_path"}) ) {
	    $mappinghash->{"$workflow_path"} = &create_object('c__HP::Array::Set__');
	  }
	  $mappinghash->{"$workflow_path"}->push_item("$usecase");
	} else {
	  &__print_output("Duplicate setting detected.  This shouldn't be possible", WARN);
	  return FALSE;
	}
	
	return TRUE;
  }
#=============================================================================
1;