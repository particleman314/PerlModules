package HP::OOStudio::OOStudioFile;

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

    $VERSION = 0.85;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'HP::Constants'                  => undef,
							'HP::Support::Base'              => undef,
							'HP::Support::Base::Constants'   => undef,
							'HP::Support::Hash'              => undef,
							'HP::Support::Object'            => undef,
							'HP::Support::Object::Tools'     => undef,
							'HP::Support::Object::Constants' => undef,
	                        'HP::CheckLib'                   => undef,
							'HP::Utilities'                  => undef,
							
							'HP::OOStudio::Constants'        => undef,
							'HP::Array::Tools'               => undef,
							
							'HP::FileManager'                => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_oostudio_oostudiofile_pm'} ||
				 $ENV{'debug_oostudio_modules'} ||
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
sub __determine_nodes
  {
    my $self    = shift;
	my $nodes    = [];

	my $xmlobj  = shift || return $nodes;
	my $objtype = shift;
	
	my $oov_type = $self->oostudio_type();
	
	if ( $oov_type eq OO_VERSION_10 ) {
	  $nodes = $xmlobj->get_nodes_by_xpath( {'xpath' => "//$objtype"} );
	} else {
	  $nodes = [ $xmlobj->rootnode() ];
	}
	
	return $nodes;
  }
  
#=============================================================================
sub __determine_type
  {
    my $self     = shift;
	my $nodename = undef;

	my $xmlobj = shift || return $nodename;
	
	my $oov_type = $self->oostudio_type();
	
	if ( $oov_type eq OO_VERSION_9 || $oov_type eq OO_VERSION_10 ) {
	  $nodename = $xmlobj->rootnode()->nodeName();
	}
	
	return $nodename;
  }
  
#=============================================================================
sub __get_OO10_object
  {
    my $self    = shift;
	my $objtype = shift || return undef;
	
	my $oom = &OO_OBJECT_MAP;
	my $obj = undef;
	
	if ( exists($oom->{$objtype}) ) {
	  $obj = &create_object("c__HP::OOStudio::OO10::$oom->{$objtype}__");
	  &__print_output("Unable to instantiate object << $objtype >>!", WARN) if ( not defined($obj) );
	}
	
	return $obj;
  }
  
#=============================================================================
sub __readfile
  {
    my $self   = shift;
	my $result = FALSE;
	
	my $obj    = shift || return $result;
	my $node   = shift || return $result;
	my $xpath  = shift || '//'; 

	my $oov_type = $self->oostudio_type();
	
	if ( $oov_type eq OO_VERSION_9 ) {
	  $result = $obj->read_xml( $node, '' )
	} elsif ( $oov_type eq OO_VERSION_10 ) {
	  $result = $obj->read_xml( $node, "$xpath" )
	}
	
	return $result;
  }
  
#=============================================================================
sub cleanup_internals
  {
    my $self = shift;
	my $internal_fields   = [ 'compliant', 'mismatch', 'cached' ];
	my $additional_method = {
	                         'id'                 => [REMOTE, 'HP::UUID::Tools', 'is_zero_uuid'],
	                         'refId'              => [REMOTE, 'HP::UUID::Tools', 'is_zero_uuid'],
							 'template'           => [REMOTE, 'HP::Utilities', 'delete_field'],
							 'use_interior_nodes' => [REMOTE, 'HP::Utilities', 'delete_field'],
							};
	
	return &HP::Support::Object::__cleanup_internals($self->oostudio_obj(), $internal_fields, $additional_method);
  }

#=============================================================================
sub data_types
  {
    my $self = shift;
	my $which_fields = shift || COMBINED;
	
    # See if there is a way to read this from file.
    my $data_fields = {
					   'filename'      => undef,
					   'oostudio_type' => OO_VERSION_10,
					   'oostudio_obj'  => undef,
					   'valid'         => undef,
					   'cached'        => {},
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
sub get_toplevel_uuids
  {
    my $self = shift;
	return $self->get_uuids(1);
  }
  
#=============================================================================
sub get_uuids
  {
    my $self   = shift;
	my $result = &create_object('c__HP::Array::Set__');
	
	if ( exists($self->{'cached'}->{'defined'}) ) {
	  $result->add_elements({'entries' => $self->{'cached'}->{'defined'}});
	  $result->add_elements({'entries' => $self->{'cached'}->{'referenced'}});
	  return $result->get_elements();
	}

	return [] if ( not defined($self->oostudio_obj()) );
	my ($defined, $referenced) = $self->oostudio_obj()->get_uuids(@_);
	
	$self->{'cached'}->{'defined'}    = $defined;
	$self->{'cached'}->{'referenced'} = $referenced;
	
	return &set_union($defined, $referenced, FALSE);
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
sub print
  {
    my $self = shift;
	return;
  }

#=============================================================================
sub post_callback_read
  {
    my $self = shift;
	my $fields = &get_fields($self, FALSE);
	foreach ( @{$fields} ) {
	  next if ( &is_type($self->{"$_"}, 'HP::ArrayObject') eq FALSE );
	  delete($self->{"$_"}->{'template'});
	}
	return;
  }

#=============================================================================
sub readfile
  {
    my $self    = shift;
	my $xmlfile = shift;
	my $result  = FALSE;

	my $allow_fast_scan = shift || $result;
	
	my $oov_type = $self->oostudio_type();
	
	return if ( not defined($oov_type) );
	return if ( &set_contains($oov_type, OO_VERSIONS) eq FALSE );
	return $result if ( &valid_string($xmlfile) eq FALSE );
	
	my $xmlobj = &create_object('c__HP::XMLObject__');
	$xmlobj->xmlfile("$xmlfile");
	$xmlobj->readfile();
	if ( not defined($xmlobj->rootnode()) ) {
	  $xmlobj = undef;
	  return $result;
	}
		
	$self->filename("$xmlfile");	
	my $objtype = $self->__determine_type($xmlobj); # Determine how to proceed based on type
	return $result if ( not defined($objtype) );
	
	my $oom = &OO_OBJECT_MAP;
	if ( exists($oom->{$objtype}) ) {
	  my $obj = &create_object("c__HP::OOStudio::". $self->oostudio_type() ."::$oom->{$objtype}__");
	  $self->{'file_type'} = $oom->{$objtype};
      if ( defined($obj) ) {
	    my $nodes = $self->__determine_nodes($xmlobj, $objtype);  # Determine how to collect nodes based on type
		if ( scalar(@{$nodes}) != 1 ) {
		  &__print_output("Incorrect number of nodes expected for OOStudio file decoding!", WARN);
		  return $result;
		}
		
		# Fast scan feature allow for top level UUID collection of all files...
		if ( $allow_fast_scan eq TRUE ) {
		  my $toplvl_uuid = $nodes->[0]->getAttribute('id');
		  if ( defined($toplvl_uuid) ) {
		    $obj->id( $toplvl_uuid );
		    $self->valid(TRUE);
		  }
		} else {
		  my $read_result = $self->__readfile($obj, $nodes->[0], "//$objtype" );
		  $self->valid(TRUE) if ( $read_result eq TRUE );
		}
		
		$self->oostudio_obj( $obj );
		
		# Verify filename with UUID stored in file under OO9
		$result = ( $oov_type eq OO_VERSION_10 ) ? TRUE : $self->validate();
		
		# Reset cache...
		$self->{'cached'} = {};
		$self->cleanup_internals();
	  }
	}
	
	return $result;
  }

#=============================================================================
sub translate_OO9_2_OO10
  {
    my $self   = shift;
	my $result = undef;
	
	return $result if ( not defined($self->oostudio_obj()) );
	return $result if ( $self->oostudio_type() ne OO_VERSION_9 );
	
	# Start at the root...
	return $result if ( not defined($self->oostudio_obj()->{'node'}) );
	my $topnode = $self->oostudio_obj()->node();
	if ( not exists($topnode->{'type'}) ) {
	  &__print_output("Found node in object WITHOUT type specification.  Skipping!", WARN);
	  return $result;
	}
	  
	$result = $self->__get_OO10_object($topnode->type());
	if ( &function_exists($result, 'translate_OO9_2_OO10') eq TRUE ) {
	  $result->translate_OO9_2_OO10($topnode);
	} 
	return $result;
  }
  
#=============================================================================
sub validate
  {
    my $self = shift;
	return $self->oostudio_obj()->validate( &remove_extension(File::Basename::basename($self->filename())) );
  }

#=============================================================================
1;