package HP::ProviderList;

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

	use parent qw(HP::BaseObject HP::XML::XMLEnableObject);
	
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
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::Array::Tools'             => undef,
							
							'HP::Providers::Constants'     => undef,
							};
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_providerlist_pm'} ||
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
sub data_types
  {
    my $self        = shift;
	my $which_level = shift || COMBINED;
	
    my $data_fields = {
					   'internal'    => 'c__HP::Providers::Provider__',
					   'external'    => 'c__HP::Providers::Provider__',
					   'groups'      => 'c__HP::Providers::Groups__',
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
sub find_provider
  {
    my $self   = shift;
	my $result = undef;
	
	my $data   = shift || return $result;
	
	if ( ref($data) !~ m/hash/i ) {
	  my $temp = $data;
	  $data = {};
	  $data->{'value'} = $temp;
	}
	
	return $result if ( scalar(keys(%{$data})) < 1 || ( not exists($data->{'value'}) ) );
	
	my $support_types = $self->get_known_support_types();
	
	foreach ( @{$support_types} ) {
	  my $match = $self->{"$_"}->look_for_provider($data);
	  return $match if ( defined($match) && $match->number_elements() > 0 );
	}
		
	return $result;
  }

#=============================================================================
sub get_known_support_types
  {
    my $self   = shift;
	my $disallowed = [ 'groups' ];
	
	my $specific = &set_difference(&get_fields($self, TRUE), $disallowed);
	return $specific;
  }

#=============================================================================
sub get_reduced_group
  {
    my $self                = shift;
	my $all_capsules        = shift;
	my $current_capsule     = shift;
	my $result              = $all_capsules; # Should be all name fields...
	
	return $result if ( scalar(@{$all_capsules}) < 1 );
	return $result if ( &valid_string($current_capsule) eq FALSE );
	
	my $given_obj = &create_object('c__HP::ArrayObject__');
	$given_obj->add_elements({'entries' => $all_capsules});
	my $group_obj = &create_object('c__HP::ArrayObject__');
	
	my $group_members = $self->groups()->group()->get_elements();
	my $subgroup_obj = &create_object('c__HP::ArrayObject__');
	  
	foreach my $mbr ( @{$group_members} ) {
	  my $matched_provider = $self->find_provider($mbr->name());
      $matched_provider    = $matched_provider->get_element(0) if ( defined($matched_provider) );
	  my $matchable_name   = $matched_provider->name();
	  $subgroup_obj->push_item($matchable_name) if ( $mbr->type() eq SINGLE );
	}
	
	$group_obj->push_item($subgroup_obj) if ( $subgroup_obj->number_elements() > 0 );
	
	# Look for the case when the group members should be removed
	my $grp_idx_pos = [];
	for ( my $loop = 0 ; $loop < $group_obj->number_elements(); ++$loop ) {
	  my $diff = &set_difference($all_capsules, $group_obj->get_element($loop), TRUE);
	  if ( $diff->contains("$current_capsule") eq FALSE ) {
	    push ( @{$grp_idx_pos}, $loop );
      }
    }
	
	if ( scalar(@{$grp_idx_pos}) > 1 ) {
	  &__print_output("Cannot handle multiple matching groups (yet...)", WARN);
	  return $result;
    } else {
	  if ( scalar(@{$grp_idx_pos}) == 1 ) {
	    my $matched_group = $group_obj->get_element($grp_idx_pos->[0]);
	    foreach my $mbr ( @{$matched_group->get_elements()} ) {
	      $given_obj->delete_elements($mbr) if ( $mbr ne $current_capsule );
	    }
	  }
	}
	
	return $given_obj->get_elements();
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
	$self->internal()->hptype('internal');
	$self->external()->hptype('external');
	return $self;  
  }

#=============================================================================
sub post_callback_read
  {
    my $self = shift;
	
	$self->remove_invalid_entries();
	return;
  }

#=============================================================================
sub print
  {
    my $self = shift;
	return;
  }

#=============================================================================
sub remove_invalid_entries
  {
    my $self = shift;
	
	$self->internal()->remove_invalid_entries();
	$self->external()->remove_invalid_entries();
	
	return;
  }

#=============================================================================
1;