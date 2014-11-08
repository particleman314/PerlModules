package HP::UUID::UUIDFileList;

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

    $VERSION = 0.95;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
	                        'HP::CheckLib'                 => undef,
							
							'HP::UUID::Constants'          => undef,
							'HP::Array::Tools'             => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
	             $ENV{'debug_capsule_uuidfilelist_pm'} ||
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
sub add_file_uuids
  {
    my $self = shift;
	my $data = shift || return FALSE;
	
	return FALSE if ( ref($data) !~ m/^array/i );
	return FALSE if ( scalar(@{$data}) != 2 );
	
	$self->uuid_list()->add_elements({'entries' => $data->[0]});
	foreach ( keys(%{$data->[1]}) ) {
	  my $entry = &create_object('c__HP::UUID::UUIDFileEntry__');
	  $entry->uuid($_);
	  $entry->filename($data->[1]->{"$_"});
	  $self->uuid_association()->push_item($entry);
	}
	
	return TRUE;
  }
  
#=============================================================================
sub data_types
  {
    my $data_fields = {
					   'jarfile_uuid'     => ZERO_UUID,
					   'uuid_list'        => 'c__HP::Array::Set__',
					   'uuid_association' => '[] c__HP::UUID::UUIDFileEntry__',
					   'modify_date'      => undef,
		              };
    
    foreach ( @ISA ) {
	  my $parent_types = undef;
	  if ( &function_exists($_, 'data_types') eq TRUE ) {
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
sub pre_callback_write
  {
    my $self = shift;
	$self->modify_date(time);
	return TRUE;
  }
  
#=============================================================================
sub post_callback_read
  {
    my $self = shift;
	
	foreach ( @{$self->uuid_association()->get_elements()} ) {
	  $self->uuid_list()->push_item($_->uuid());
	}
	return TRUE;
  }
  
#=============================================================================
sub print
  {
    my $self = shift;
	
	$self->SUPER::print();
	return;
  }

#=============================================================================
sub rootnode_name
  {
	return 'uuidlist';
  }
  
#=============================================================================
sub skip_fields
  {
    my $self     = shift;
    my $specific = [ 'uuid_list' ];

    $specific    = &set_union($specific, $self->SUPER::skip_fields());
    return $specific;
  }

#=============================================================================
sub write_as_attributes
  {
    my $self     = shift;
    my $specific = [ 'modify_date' ];

    $specific    = &set_union($specific, $self->SUPER::write_as_attributes());
    return $specific;
  }

#=============================================================================
1;