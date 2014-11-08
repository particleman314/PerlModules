package HP::OOStudio::OO9::OOStudioObject;

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
    use lib "$FindBin::Bin/../../..";

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
							'XML::LibXML'                  => undef,
							'File::Basename'               => undef,
	                        'UUID::Tiny'                   => undef,
							
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
	                        'HP::CheckLib'                 => undef,
							'HP::Utilities'                => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
							
							'HP::Array::Tools'             => undef,
							
							'HP::OOStudio::Constants'      => undef,
							'HP::OOStudio::Tools'          => undef,
							'HP::UUID::Constants'          => undef,
							'HP::UUID::Tools'              => undef,
							
							'HP::FileManager'              => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_oostudio_oo9_oostudioobject_pm'} ||
				 $ENV{'debug_oostudio_oo9_modules'} ||
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
sub __determine_obj_type
  {
    my $self   = shift;
	my $node   = shift;
	my $xmlobj = shift;
	
	my $attrmarker = shift || 'type';
	
	my $result = undef;

	if ( not defined($xmlobj) ) {
	  $xmlobj = &create_object('c__HP::XMLObject__');
	  goto WRAP_UP;
	}
	
	$xmlobj->rootnode($node);
	
	$result = $xmlobj->get_attribute_content($node, $attrmarker); # Determine how to proceed based on type
	
  WRAP_UP:
	return $result if ( not wantarray() );
	return ( $result, $xmlobj );
  }
  
#=============================================================================
sub __get_attribute_node_classification
  {
    my $self   = shift;
	my $node   = shift || return UNKNOWN;
	
	my @childnodes = $node->childNodes();
	return SIMPLE_ATTRIBUTE if ( scalar(@childnodes) == 1 && $childnodes[0]->nodeType() == XML_TEXT_NODE );
	return COMPLEX_ATTRIBUTE;
  }
  
#=============================================================================
sub __get_uuids
  {
    my $self        = shift;
	my $currdepth   = shift || 0;
	my $maxdepth    = shift || UUID_MAXIMUM_DEPTH;
    my $specialties = shift || [];
	
	my $result = [];
	
	++$currdepth;
	&__print_debug_output("Current Depth : $currdepth", __PACKAGE__) if ( $is_debug );
	
	if ( $currdepth >= $maxdepth && $maxdepth != UUID_MAXIMUM_DEPTH ) {
	  my $level_uuid = $self->id();
	  if ( &is_zero_uuid($level_uuid) eq FALSE ) {
	    push ( @{$result}, $level_uuid );
	  }
	  &__print_debug_output("Maximal Depth Id: $level_uuid", __PACKAGE__) if ( $is_debug );

	  goto WRAPUP;
	}
	
	my $obj_fields   = &get_object_fields($self);
	my $array_fields = &get_array_fields($self);
	
	&__print_debug_output("Scanning obj fields: @{$obj_fields}", __PACKAGE__) if ( $is_debug );
	&__print_debug_output("Scanning array fields: @{$array_fields}", __PACKAGE__) if ( $is_debug );

	foreach ( @{$array_fields} ) {
	  &__print_debug_output("(A) Interrogating field: $_ [ ". ref($self->{"$_"}). " ]", __PACKAGE__) if ( $is_debug );

	  my $ptr = $self->{"$_"};
	  foreach my $sub ( @{$ptr} ) {
	    my $blessed = &is_blessed_obj($sub);
		my $hasfunc = &function_exists($sub, '__get_uuids');
		
		&__print_debug_output("Parameters : (B) $blessed , (HF) $hasfunc", __PACKAGE__) if ( $is_debug );
	    if ( $blessed eq TRUE && $hasfunc eq TRUE ) {
		  my $uuids = $sub->__get_uuids($currdepth, $maxdepth, $specialties);
		  &__print_debug_output("Returned UUIDS --> @{$uuids}", __PACKAGE__) if ( $is_debug );
		  $result = &set_union( $result, $uuids, FALSE );
	    }
	  }
	}

	&__print_debug_output("(A) Current Total List of UUIDS --> @{$result}", __PACKAGE__) if ( $is_debug );
	
	foreach ( @{$obj_fields} ) {
	  &__print_debug_output("(O) Interrogating field: $_ [ ". ref($self->{"$_"}). " ]", __PACKAGE__) if ( $is_debug );
	  
	  my $ptr = undef;
	  if ( &is_type($self->{"$_"}, 'HP::ArrayObject') eq FALSE ) {
	    $ptr = [ $self->{"$_"} ];
	  } else {
	    $ptr = $self->{"$_"}->get_elements();
	  }
	  foreach my $i ( @{$ptr} ) {
	    my $hasfunc = &function_exists($i, '__get_uuids');

	    &__print_debug_output("Parameters : (HF) $hasfunc", __PACKAGE__) if ( $is_debug );
	    if ( $hasfunc eq TRUE ) {
		  my $uuids = $i->__get_uuids($currdepth, $maxdepth, $specialties);
		  &__print_debug_output("Returned UUIDS --> @{$uuids}", __PACKAGE__) if ( $is_debug );
          $result = &set_union( $result, $uuids, FALSE );
	    }
	  }
	}
	
	&__print_debug_output("(A+O) Current Total List of UUIDS --> @{$result}", __PACKAGE__) if ( $is_debug );

	foreach ( @{$specialties} ) {
	  &__print_debug_output("Looking for field [ id ]", __PACKAGE__) if ( $is_debug );

	  if ( exists($self->{"$_"}) ) {
	    $result = &set_union( $result, $self->{"$_"}, FALSE );
	  }
	}

	&__print_debug_output("Final Total List of UUIDS --> @{$result}", __PACKAGE__) if ( $is_debug );

  WRAPUP:
	my $setR = &create_object('c__HP::Array::Set__');
	$setR->add_elements( {'entries' => $result} );
	$setR->delete_elements(ZERO_UUID);
	
	return $setR->get_elements(); 
  }
  
#=============================================================================
sub __store_attributes
  {
    my $self   = shift;
	my $xmlobj = shift || return;
	
	my $attrs = $xmlobj->get_attributes();
	foreach my $attr ( @{$attrs} ) {
	  my $attrdata = $xmlobj->rootnode()->getAttribute("$attr");
      if ( exists($self->{"$attr"}) ) {
		$self->{"$attr"} = $attrdata;
	  } else {
		$self->add_data("$attr", $attrdata);
	  }
	}
	
	return;
  }
  
#=============================================================================
sub check_compliance
  {
    my $self = shift;
	if ( $self->compliant() eq FALSE ) {
	}
	return;
  }

#=============================================================================
sub clear_cache
  {
    my $self = shift;
	
	$self->{'cached'} = {};
	return;
  }

#=============================================================================
sub create_node_type
  {
    my $self    = shift;
	my $objtype = shift || return undef;
	
	my $oom = &OO_OBJECT_MAP;
	if ( exists($oom->{$objtype}) ) {
	  my $obj = &create_object("c__HP::OOStudio::OO9::$oom->{$objtype}__");
      return $obj if ( defined($obj) );
	}
	return undef;
  }
  
#=============================================================================
sub data_types
  {
    my $self = shift;
	my $which_fields = shift || COMBINED;
	
    # See if there is a way to read this from file.
    my $data_fields = {
					   'id'        => ZERO_UUID,
					   'compliant' => FALSE,
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
sub get_uuids
  {
    my $self  = shift;
	my $depth = shift || UUID_MAXIMUM_DEPTH;
	
	my $defined_uuids = $self->get_uuids_defined($depth);
	my $ref_uuids     = $self->get_uuids_referenced($depth);
	
	return ($defined_uuids, $ref_uuids);
  }
  
#=============================================================================
sub get_uuids_defined
  {
    my $self  = shift;
	my $depth = shift || UUID_MAXIMUM_DEPTH;
	
	my @options = ( 0, $depth, [ 'id' ]);
	
	if ( &is_type($self, 'HP::OOStudio::OO9::XMLRoot') eq TRUE ) {
	  return $self->node()->__get_uuids(@options);
	} else {
	  return $self->__get_uuids(@options);
	}
  }

#=============================================================================
sub get_uuids_referenced
  {
    my $self  = shift;
	my $depth = shift || UUID_MAXIMUM_DEPTH;
	
	my @options = ( 0, $depth, [ 'refId', 'startSteps' ] );
	
	if ( &is_type($self, 'HP::OOStudio::OO9::XMLRoot') eq TRUE ) {
	  return $self->node()->__get_uuids(@options);
	} else {
	  return $self->__get_uuids(@options);
	}
  }
  
#=============================================================================
sub handle_attributes
  {
    my $self     = shift;
	my $xmlobj   = shift || return;
	my $rootpath = shift || '';
	
	my $attrrp = "$rootpath".'attribute';
	my $nodes  = $xmlobj->get_nodes_by_xpath({'xpath' => "$attrrp"});
	my $result = TRUE;
	
	foreach ( @{$nodes} ) {
	  my $node_classification = $self->__get_attribute_node_classification($_);
	  
	  my $obj = &create_object('c__HP::OOStudio::OO9::XMLAttribute__');
      if ( not defined($obj) ) {
		&__print_output("[A] Unable to create sub-node type...", WARN);
	    $result &= FALSE;
		next;
	  }
	  
	  if ( $node_classification eq SIMPLE_ATTRIBUTE ) {
		my $objresult = $obj->read_xml($_);
		$self->attribute()->push_item($obj) if ( $objresult eq TRUE );
      } elsif ( $node_classification eq COMPLEX_ATTRIBUTE ) {
	    my $objtype = $self->__determine_obj_type($_, $xmlobj, 'name');
		if ( not defined($obj) ) {
		  &__print_output("[A] Unable to create sub-node type << $objtype >>", WARN);
		  $result &= FALSE;
		  next;
        } else {
		  my $objresult = $obj->read_xml($_);
		  $self->attribute()->push_item($obj) if ( $objresult eq TRUE );
		  $result &= $objresult;
		}
	  }
	}

	return $result;
  }
  
#=============================================================================
sub handle_children
  {
    my $self     = shift;
	my $xmlobj   = shift || return;
	my $rootpath = shift || '';
	
	my $childrp = "$rootpath".'child';
	my $nodes  = $xmlobj->get_nodes_by_xpath({'xpath' => "$childrp"});
	my $result = TRUE;

	foreach ( @{$nodes} ) {
	  my $obj = &create_object('c__HP::OOStudio::OO9::XMLChild__');
	  if ( not defined($obj) ) {
		&__print_output("[C] Unable to create sub-node type...", WARN);
	    $result &= FALSE;
		next;
      }
      my $objresult = $obj->read_xml($_);
      $self->child()->push_item($obj) if ( $objresult eq TRUE );
	  $result &= $objresult;
	}

	return $result;
  }

#=============================================================================
sub handle_nodes
  {
    my $self     = shift;
	my $xmlobj   = shift || return;
	my $rootpath = shift || '';
	
	my $noderp = "$rootpath".'node';
	my $nodes  = $xmlobj->get_nodes_by_xpath({'xpath' => "$noderp"});
	my $result = TRUE;

	foreach ( @{$nodes} ) {
	  my $obj = &create_object('c__HP::OOStudio::OO9::XMLNode__');
	  if ( not defined($obj) ) {
		&__print_output("[N] Unable to create sub-node type << ". $self->type() .">>", WARN);
	    $result &= FALSE;
		next;
      }
	  
      my $objresult = $obj->read_xml($_);
	  if ( &is_type($self, 'HP::OOStudio::OO9::XMLRoot') eq TRUE ) {
	    $self->node($obj) if ( $objresult eq TRUE );
	  } else {
        $self->node()->push($obj) if ( $objresult eq TRUE );
	  }
	  
	  $result &= $objresult;
	}

	return $result;
  }
  
#=============================================================================
sub is_compliant
  {
    my $self = shift;
	return $self->compliant();
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
sub read_xml
  {
    my $self         = shift;
    my $node         = shift || return FALSE;
    my $rootpath     = shift;
	my $skip_prepost = shift || FALSE;
	
	my $xmlobj = &create_object('c__HP::XMLObject__');
	return FALSE if ( not defined($xmlobj) );
	
	$xmlobj->rootnode($node);
	
    $self->pre_callback_read() if ( $skip_prepost eq FALSE &&
	                                &function_exists($self, 'pre_callback_read') eq TRUE );
	
	$self->__store_attributes($xmlobj);

	# Need to collect node nodes, attribute nodes, and child nodes
	# Process the node nodes first...
	$self->handle_nodes($xmlobj);
	$self->handle_attributes($xmlobj);
	$self->handle_children($xmlobj);
	
	$self->post_callback_read() if ( $skip_prepost eq FALSE &&
	                                 &function_exists($self, 'post_callback_read') eq TRUE );

    $self->validate() if ( $skip_prepost eq FALSE );
    return TRUE;
  }
  
#=============================================================================
sub skip_fields
  {
    my $self     = shift;
	my $specific = [ 'compliant', 'mismatch' ];

	$specific    = &set_union($specific, $self->SUPER::skip_fields());
	return $specific;
  }

#=============================================================================
sub validate
  {
    my $self     = shift;
	my $filename = shift || return FALSE;
	
	$filename    = &remove_extension(File::Basename::basename("$filename"));
	my $obj_uuid = $self->id();
	
	return FALSE if ( not defined($obj_uuid) );
	return &equal("$obj_uuid", "$filename");
  }

#=============================================================================
sub write_as_attributes
  {
    my $self = shift;

    my $specific = [ 'version', 'libraryDocVersion', 'id' ];

    $specific = &set_union($specific, $self->SUPER::write_as_attributes());
    return $specific;
  }

#=============================================================================
1;