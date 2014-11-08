package HP::UUID::UUIDManager;

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

    $VERSION = 0.95;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'File::Basename'               => undef,
							
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
	                        'HP::CheckLib'                 => undef,
							
							'HP::Array::Tools'             => undef,
							'HP::Array::Constants'         => undef,
							'HP::UUID::Constants'          => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
	             $ENV{'debug_uuid_uuidmanager_pm'} ||
                 $ENV{'debug_uuid_modules'} ||
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
sub _new_instance
  {
    return &new(@_);
  }

#=============================================================================
sub add_jarfile_uuid
  {
    my $self   = shift;
	my ($entry, $jfuuid) = ( undef, ZERO_UUID );
	
	if ( &is_type($_[0], 'HP::UUID::UUIDFileEntry') eq FALSE ) {
      my $inputdata = {};
      if ( ref($_[0]) !~ m/hash/i ) {
        $inputdata = &convert_input_to_hash([
	                                         'jarfile_name', \&valid_string,
	                                         'jarfile_uuid', \&valid_string,
										    ], @_);
      }
      return FALSE if ( scalar(keys(%{$inputdata})) == 0 );
	  
	  my $jfname = $inputdata->{'jarfile_name'} || return FALSE;
	  $jfuuid = $inputdata->{'jarfile_uuid'} || return FALSE;

	  return FALSE if ( $jfuuid eq ZERO_UUID );
	  
	  $entry = &create_object('c__HP::UUID::UUIDFileEntry__');
	  $entry->uuid($jfuuid);
	  $entry->filename("$jfname");
	} else {
	  $entry  = shift;
	  $jfuuid = $entry->uuid();
	}
	
	$self->uuid_jarfile->push_item($entry);
	$self->uuids()->push_item($jfuuid);
	return TRUE;
  }

#=============================================================================
sub add_uuid_list
  {
    my $self = shift;
	
	if ( &is_type($_[0], 'HP::ArrayObject') eq TRUE ) {
	  my $uuidlist = shift;
	  my $number_elements = $uuidlist->number_elements();
	  if ( $number_elements > 0 ) {
	    foreach ( @{$uuidlist->get_elements()} ) {
		  if ( &is_type($_, 'HP::UUID::UUIDFileEntry') eq TRUE ) {
		    $self->add_uuid_list($_);
		  } else {
		    if ( ref($_) =~ m/hash/i ) {
			  $self->add_uuid_list($_);
			}
		  }
		}
	  }
	} elsif ( &is_type($_[0], 'HP::UUID::UUIDFileEntry') eq TRUE ) {
	  my ($result, $err) = $self->add_uuid($_[0]);
	  &__print_output("Unable to add UUID File Entry.  Error condition is $err", WARN) if ( $result eq FALSE );
	} elsif ( ref($_[0]) =~ m/hash/i ) {
	  if ( not exists($_[0]->{'uuid'}) && not exists($_[0]->{'fileId'}) ) {
	    foreach ( keys(%{$_[0]}) ) {
	      my $uuidentry = &create_object('c__HP::UUID::UUIDFileEntry__');
	      $uuidentry->uuid($_);
	      $uuidentry->filename($_[0]->{"$_"});
	      $self->add_uuid_list($uuidentry);
		}
	  } else {
	    my $uuidentry = &create_object('c__HP::UUID::UUIDFileEntry__');
	    $uuidentry->uuid($_[0]->{'uuid'}) if ( exists($_[0]->{'uuid'}) );
	    $uuidentry->filename($_[0]->{'fileId'}) if ( exists($_[0]->{'fileId'}) );
	    if ( $uuidentry->is_valid() eq FALSE ) {
	      &__print_output('Unable to add UUID File Entry < '. $uuidentry->uuid() .'|'. $uuidentry->filename() .'>', WARN);
	    } else {
	      $self->add_uuid_list($uuidentry);
	    }
	  }
	}
	
	return;
  }

#=============================================================================
sub add_uuid
  {
    my $self = shift;
	my $item = shift || return (FALSE, '"Empty input provided"');
	
	return (FALSE, '"Improper input provided"') if ( &is_type($item, 'HP::UUID::UUIDFileEntry') eq FALSE );
	return (FALSE, '"Invalid input provided"')  if ( $item->is_valid() eq FALSE );
	
	if ( $self->allow_duplicate_uuid() eq FALSE ) {
	  if ( $self->uuids()->contains($item->uuid()) eq TRUE ) {
	    $self->duplicate_seen->push_item($item->filename());
	    return (FALSE, '"Previous UUID seen for '. $item->filename .'"', WARN);
	  }
	}
	
	foreach ( @{$self->uuid_2_file()->get_elements()} ) {
	  &__print_debug_output('Comparing '. $_->filename() .'with '. $item->filename(),__PACKAGE__);
	  if ( $_->filename() eq $item->filename() ) {
	    $self->duplicate_seen->push_item($item->filename());
		return (FALSE, '"Previous Filename seen (i.e. multiple UUID assigned to file)"', WARN);
	  }
	}
	
	my $item_dir  = File::Basename::dirname($item->filename());
	my $item_file = File::Basename::basename($item->filename());
	
	#foreach ( keys(%{$self->usecase_2_file()}) ) {
	#  next if ( $_ eq $item_dir );
	#  if ( ($_ ne $item_dir) && ($self->{'usecase_2_file'}->{"$_"} eq $item_file) ) {
	#    $self->potential_duplicate->push_item($item->filename());
	#	last;
	#  }
	#}
	
	$self->uuid_2_file()->push_item($item);
	$self->uuids()->push_item($item->uuid());
	
	return (TRUE, undef);
  }

#=============================================================================
sub data_types
  {
    my $data_fields = {
					   'uuids'                => 'c__HP::Array::Set__',
					   'uuid_jarfile'         => '[] c__HP::UUID::UUIDFileEntry__',
					   'uuid_2_file'          => '[] c__HP::UUID::UUIDFileEntry__',
					   
					   'potential_duplicate'  => 'c__HP::Array::Set__',
					   'duplicate_seen'       => 'c__HP::Array::Set__',
					   'allow_duplicate_uuid' => TRUE,  # Useful to toggle with multiple content packaged together
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
sub find_file_by_uuid
  {
    my $self = shift;
	my $uuid = shift || return undef;
	
	return undef if ( (&valid_string($uuid) eq FALSE) || ($uuid eq ZERO_UUID) );
	foreach ( @{$self->uuid_2_file()->get_elements()} ) {
	  return $_->filename() if ( $_->uuid eq $uuid );
	}
	
	return undef;
  }

#=============================================================================
sub find_uuid_by_file
  {
    my $self     = shift;
	my $filename = shift || return undef;
	
	return undef if ( &valid_string($filename) eq FALSE );
	foreach ( @{$self->uuid_2_file()->get_elements()} ) {
	  return $_->uuid() if ( $_->filename eq $filename );
	}
	
	return undef;
  }

# #=============================================================================
# sub find_usecase_by_file
  # {
    # my $self     = shift;
	# my $filename = shift || return undef;
	
	# return undef if ( &valid_string($filename) eq FALSE );
	
	# my $result = &create_object('c__HP::Array::Set__');
	
	# foreach ( keys(%{$self->usecase_2_file()}) ) {
	  # $result->push_item($self->{'usecase_2_file'}->{"$_"}) if ( $_ eq $filename );
	# }
	
	# my $numelem = $result->number_elements();
	
	# return undef if ( $numelem == 0 );
	# return $result->get_element(0) if ( $numelem == 1 );
	# return $result->get_elements();
  # }

#=============================================================================
sub get_uuids
  {
    my $self = shift;
	my $result = $self->uuids()->get_elements();
	return $result;
  }
  
#=============================================================================
sub has_uuid
  {
    my $self = shift;
	my $uuid = shift;
	
	return FALSE if ( &valid_string($uuid) eq FALSE || $uuid eq ZERO_UUID );
	return $self->uuids()->contains($uuid);
  }

#=============================================================================
sub has_file
  {
    my $self     = shift;
	my $filename = shift;
	
	return FALSE if ( &valid_string($filename) eq FALSE );
	foreach ( @{$self->uuid_2_file()->get_elements()} ) {
	  return TRUE if ( $_->filename() eq $filename );
	}
	
	return FALSE;
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
sub number_uuids
  {
    my $self = shift;
	return $self->uuids()->number_elements();
  }
  
#=============================================================================
sub print
  {
    my $self = shift;
	
	$self->SUPER::print();
	return;
  }

#=============================================================================
sub remove_uuid
  {
    my $self = shift;
	my $uuid = shift;
	
	return FALSE if ( &valid_string($uuid) eq FALSE || $uuid eq ZERO_UUID );
	
	my $entries = $self->uuid_2_file()->get_elements();
	my $removal_idx = undef;
	
	for ( my $loop = 0; $loop < scalar(@{$entries}); ++$loop ) {
	  if ( $entries->[$loop]->uuid() eq $uuid ) {
	    $self->uuids()->delete_elements($uuid);
		$removal_idx = $loop;
	  }
	}
	
	if ( defined($removal_idx) ) {
	  return $self->uuid_2_file()->delete_elements_by_index($removal_idx);
	}
	return FALSE;
  }

#=============================================================================
sub validate
  {
    my $self = shift;
	
	#$self->SUPER::validate();
	#$self->valid(TRUE);
	return;
  }

#=============================================================================
1;