package HP::CapsuleMetadata::CloudCapsule::TierTable;

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

    $VERSION = 0.92;

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
							'HP::Array::Tools'             => undef,
							'HP::Array::Constants'         => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_capsulemetadata_cloudcapsule_tiertable_pm'} ||
                 $ENV{'debug_capsulemetadata_cloudcapsule_modules'} ||
				 $ENV{'debug_capsulemetadata_modules'} ||
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
my $local_true  = TRUE;
my $local_false = FALSE;

my $skip_cloning  = $local_false;
my $cached_object = undef;

#=============================================================================
sub __read_xml
  {
    my $self   = $_[0];
	my $xmlobj = $_[1] || goto __END_OF_SUB;
	
	my $nodes = $xmlobj->get_nodes_by_xpath( {'xpath' => "//tier"} );
	foreach ( @{$nodes} ) {
	  my $obj = $self->read_entry($_);
	  $self->add_entry( $obj ) if ( defined($obj) );
	}

  __END_OF_SUB:
	return;
  }
  
#=============================================================================
sub add_entry
  {
	my $result = $local_false;
	
    my $self   = $_[0];
	my $entry  = $_[1] || goto FINISH;
	
	goto FINISH if ( &is_type($entry, 'HP::CapsuleMetadata::CloudCapsule::TierEntry') eq FALSE );
	
	my $current_entries = $self->tier_elements();
	
	if ( $current_entries->contains($entry->name()) eq FALSE ) {
	  $result = $self->push_entry($entry);
	  goto FINISH;
	} else {
	  &__print_output("Previous entry exists for requested Tier Table!", WARN);
	}
	
  FINISH:
    return $result;
  }
  
#=============================================================================
sub data_types
  {
    my $self         = $_[0];
    my $which_fields = $_[1] || COMBINED;
	
    # See if there is a way to read this from file.
    my $data_fields = {
					   'tier_elements' => 'c__HP::Array::PriorityQueueSet__',
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
sub DESTROY
  {
    my $self = $_[0];

    &__print_debug_output("Calling destructor for object ".ref($self)."\n") if ( $is_debug );
	return;
  }

#=============================================================================
sub find_tier
  {
	my $result = undef;
	
    my $self   = $_[0];	
	my $data   = $_[1] || goto __END_OF_SUB;
	
	my $pq = $self->tier_elements();
	
	if ( &is_type($data, 'HP::CapsuleMetadata::CloudCapsule::TierEntry') ne TRUE ) {
	  return $result if ( &valid_string($data) eq FALSE );
	  
	  foreach my $i ( @{$pq->get_priorities()} ) {
	    my $q   = $pq->get_queue($i);
		$result = $q->contains($data);
		if ( $result eq TRUE ) {
		  $result = $i;
		  last;
		} else {
		  $result = undef;
		}
      }
	} else {
	  $result = $pq->find_priority($data->name());
	}
	
  __END_OF_SUB:
	return $result;
  }

#=============================================================================
sub force_xml_output
  {
    my $self     = $_[0];
	my $specific = &get_fields($self);

	$specific    = &set_union($specific, $self->SUPER::force_xml_output());
	return $specific;
  }

#=============================================================================
sub get_tier_entry
  {
	my $result = undef;
    my $self   = $_[0];
	my $entry  = $_[1] || goto __END_OF_SUB;

	my $pq    = $self->tier_elements();
	my $pqidx = $self->find_tier($entry);
	
    if ( defined($pqidx) ) {
	  $result = &create_object('c__HP::CapsuleMetadata::CloudCapsule::TierEntry__');
	  if ( defined($result) ) {
	    $result->name($entry);
		$result->tierid($pqidx);
	  }
	}
	
  __END_OF_SUB:
    return $result;
  }
  
#=============================================================================
sub has_tier_entry
  {
    my $self   = $_[0];
	my $result = $local_false;
	
	my $entry  = $_[1] || goto __END_OF_SUB;

	my $pq = $self->tier_elements();
	$result = $pq->contains($entry);
	
  __END_OF_SUB:
    return $result;
  }

#=============================================================================
sub make_node
  {
    my $self = $_[0];

    my $nodename = $_[1] || $self->rootnode_name();

    my $xmlobj   = &create_object('c__HP::XMLObject__');
    my $doctree  = $xmlobj->make_document();
    my $rootnode = $doctree->createElement($nodename);

	my $pq = $self->tier_elements();
	my $template = &get_template_obj($pq);
	
	foreach my $i ( sort(@{$pq->get_priorities()}) ) {
	  my $q = $pq->get_queue($i);
	  foreach my $e ( @{$q->get_elements()} ) {
	    my $te = $template->clone();
		$te->name($e);
		$te->tierid($i);
	    my $node = $te->make_node();
		$rootnode->appendChild($node);
	  }
	}
    return $rootnode;
  }
  
#=============================================================================
sub new
  {
    my $class = shift;
	my $self  = undef;

	if ( ref($_[0]) =~ m/hash/i ) {
	  if ( exists($_[0]->{&TIERTABLE_SKIP_CLONE_OPTION}) ) {
	    $skip_cloning = $_[0]->{&TIERTABLE_SKIP_CLONE_OPTION};
		delete($_[0]->{&TIERTABLE_SKIP_CLONE_OPTION});
		shift (@_) if ( scalar(keys(%{$_[0]})) < 1 );
	  }
	}
	
	# Ask the cached object container to clone a matching object otherwise
	# go through the construction process.
	if ( $skip_cloning eq $local_false ) {
	  if ( defined($HP::CapsuleMetadata::CloudCapsule::TierTable::cached_object) ) {
	    $self = $HP::CapsuleMetadata::CloudCapsule::TierTable::cached_object->clone();
	    &__print_debug_output("Using cloned object to make new one...", __PACKAGE__) if ( $is_debug );
	    goto UPDATE;
	  }
	}
	
    my $data_fields = &data_types();

    $self = {
		     %{$data_fields},
	        };
			   
    bless $self, $class;
	$self->instantiate();
	
	&__print_debug_output("Using constructed object to seed cloneable storage item...", __PACKAGE__) if ( $is_debug );
	$HP::CapsuleMetadata::CloudCapsule::TierTable::cached_object = $self if ( not defined($HP::CapsuleMetadata::CloudCapsule::TierTable::cached_object) );

  __UPDATE:
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
	
	$self->tier_elements()->template(&create_object('c__HP::CapsuleMetadata::CloudCapsule::TierEntry__'));
	$self->tier_elements()->type('HP/CapsuleMetadata/CloudCapsule/TierEntry');
	return $self;  
  }

#=============================================================================
sub number_elements
  {
    my $self = $_[0];
    return $self->tier_elements()->number_elements();
  }
  
#=============================================================================
sub prepare_xml
  {
    my $self  = $_[0];
	my $node = $self->make_node();

    my $xmlobj = &create_object('c__HP::XMLObject__');
    if ( defined($xmlobj) ) {
      $xmlobj->rootnode($node);
      $xmlobj->make_document() if ( not defined($xmlobj->doctree()) );
      $xmlobj->doctree()->setDocumentElement($xmlobj->{'rootnode'});

      my $xmloutput = $xmlobj->rootnode()->toString();
      return undef if ( &valid_string($xmloutput) eq FALSE );
      return $xmloutput;
    }

    return undef;
  }
  
#=============================================================================
sub print
  {
    my $self        = $_[0];
	my $indentation = $_[1] || '';
	
	my $result   = '';
	return $result;
  }

#=============================================================================
sub push_entry
  {
    my $result = $local_false;
    my $self   = $_[0];
	my $entry  = $_[1] || goto __END_OF_SUB;
	
	$self->tier_elements()->push_item({$entry->get_tier() => $entry->get_name()});
	
	$result = $local_true;
	
  __END_OF_SUB:
	return $result;
  }

#=============================================================================
sub read_entry
  {
    my $result = undef;

    my $self   = $_[0];
    my $node   = $_[1] || goto __END_OF_SUB;

	my $template = &get_template_obj($self->tier_elements());
	return $result if ( not defined($template) );
	
    $self->pre_callback_read() if ( &function_exists($self, 'pre_callback_read') eq $local_true );

	my $xmlobj = &create_object('c__HP::XMLObject__');
	$xmlobj->rootnode($node);

	my $entry = $template->clone();
	if ( defined($entry) ) {
	  my $attrs = $xmlobj->get_attributes();
	  foreach ( @{$attrs} ) {
	    $entry->{$_} = $xmlobj->get_attribute_content($node, $_);
	  }
    }
	
    $self->post_callback_read() if ( &function_exists($self, 'post_callback_read') eq $local_true );
	$result = $entry;
	
  __END_OF_SUB:
    return $result;
  }

#=============================================================================
sub read_xml
  {
    my $result = $local_false;
    my $self   = $_[0];
	my $node   = $_[1];
	
	goto __END_OF_SUB if ( not defined($node) );
	
    my $xmlobj = &create_object('c__HP::XMLObject__');
	$xmlobj->rootnode($node);	
	$result = $self->__read_xml($xmlobj);
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub readfile
  {
    my $result  = $local_false;
    my $self    = $_[0];
    my $xmlfile = $_[1];

    goto __END_OF_SUB if ( &valid_string($xmlfile) eq $local_false );

    my $xmlobj = &create_object('c__HP::XMLObject__');
    $xmlobj->xmlfile("$xmlfile");
    $xmlobj->readfile();
	
    if ( not defined($xmlobj->rootnode()) ) {
      $xmlobj = undef;
      return $result;
    }
	
	$result = $self->__read_xml($xmlobj);
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub remove_entry
  {
    my $self   = $_[0];
	my $result = $local_false;

	my $entry  = $_[1] || goto __END_OF_SUB;
  
	my $pq = $self->tier_elements();
    if ( $self->has_tier_entry($entry) eq TRUE ) {
	  my ($q, $priority) = $pq->find_queue($entry);
	  if ( defined($q) ) {
	    my $idx = $q->find_instance($entry);
	    my $success = $q->delete_elements_by_index([ $idx ]);
	    $self->count($self->number_elements()) if ( $success eq TRUE );
	    $result = $success;
		
		$pq->clear_priority($priority) if ( $q->number_elements() == 0 );
	  }
	}
	
  __END_OF_SUB:
    return $result;
  }
  
#=============================================================================
sub rootnode_name
  {
    return 'tiertable';
  }

#=============================================================================
sub write_as_attributes
  {
    my $self     = $_[0];
	my $specific = [];

	$specific    = &set_union($specific, $self->SUPER::write_as_attributes());
	return $specific;
  }

#=============================================================================
1;