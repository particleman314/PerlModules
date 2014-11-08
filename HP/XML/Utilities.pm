package HP::XML::Utilities;

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

    $VERSION    = 1.00;

	@ISA    = qw(Exporter);
    @EXPORT = qw(
				 &collect_special_xml_data
				 &get_xml_translation
				 &remove_xml_header
                );

    $module_require_list = {
							'HP::Constants'                => undef,
							'HP::String'                   => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::CheckLib'                 => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::Support::Module'          => undef,
							
							'HP::Array::Tools'             => undef,						
						   };
    $module_request_list = {
	                       };

    $is_init  = 0;
    $is_debug = (
			     $ENV{'debug_xml_utilities_pm'} ||
			     $ENV{'debug_xml_modules'} ||
			     $ENV{'debug_hp_modules'} ||
			     $ENV{'debug_all_modules'} || 0
		        );

    $broken_install = 0;

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
	    if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "REQUIRED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug ); 
          eval "use $usemod;";
        }
	    if ( $@ ) {
	      print STDERR "Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
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
          print STDERR "REQUESTED [". __PACKAGE__ ."]:: use $usemod $module_request_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_request_list->{$usemod};";
        } else {
          print STDERR "REQUESTED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug );
          eval "use $usemod;";
        }
        if ( $@ ) {
          print STDERR "Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
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

#=============================================================================
sub __convert_xml_data($$$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $obj = $_[0];
	my $key = "$_[1]";
	
	my $converter_hash = $_[2];
	my $direction = ( defined($_[3]) ) ? $_[3] : FORWARD;
	
  	my $data = $obj->{"$key"};
	
	my $convert_field_keys = &get_fields($converter_hash);
	
	if ( &set_contains("$key", $convert_field_keys) eq $local_true ) {
	  my $converter = ( exists($converter_hash->{"$key"}) ) ?
			            $converter_hash->{"$key"} :
						undef;
	  if ( ref($converter) =~ m/hash/i ) {
	    if ( exists($converter->{$direction}) && defined($converter->{$direction}) ) {
	      if ( ref($converter->{$direction}) =~ m/^array/i ) {
		    if ( ( not defined($converter->{$direction}->[1]) ) &&
			     ( defined($converter->{$direction}->[0]) ) ) {
		      my $newdata = undef;
		      my $evalstr = "\$newdata = &$converter->{$direction}->[0](\$data);";
			  eval "$evalstr";
			  $data = $newdata if ( ! $@ );
		    } else {
		      my $evalstr = "\$data = \$obj->". $converter->{$direction}->[0] ."(\$data);";
			  eval "$evalstr";
			  if ( $@ ) {
		        my $newdata = undef;
		        $evalstr = "\$newdata = &$converter->{$direction}->[0](\$data);";
			    eval "$evalstr";
			    ( ! $@ ) ? $data = $newdata
				         : &__print_output("Unable to convert data [ using key ($key) ] for XML encoding. Error returned is $@!", WARN);
			  }
		    }
		  } else {
		    $data = &{$converter->{$direction}}($data);
		  }
		}
	  } else {
		my $newdata = undef;
		my $evalstr = "\$newdata = &$converter(\$data);";
	    eval "$evalstr";
	    $data = $newdata if ( ! $@ );
	  }
	} elsif ( &is_blessed_obj($data) eq $local_true ) {
	  $data = $data->to_string() if ( &function_exists($data, 'toString') eq $local_true );
	}
	
    return $data;
  }
  
#=============================================================================
sub __get_xml_control_data($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    my $obj    = $_[0];
	
	my $result = &create_object('c__HP::XML::ControlStructure__');	
	my $fields = &get_fields($obj);	
	
	my $methodref = $result->{'method'};
	foreach ( keys ( %{$methodref} ) ) {
	  if ( &function_exists($obj, $methodref->{"$_"}->[0]) eq $local_true ) {
	    if ( $_ eq 'convertible_fields' ) {
	      my $evalstr = "\$methodref->{\"$_\"}->[1] = \$obj->". $methodref->{"$_"}->[0] ."();";
		  eval "$evalstr";
		  if ( $@ ) {
		    &__print_output("(A) Unable to access data  [ using key ($_) ] for XML management. Error returned is << $@ >>!", WARN);
		  }
		} else {
	      $methodref->{"$_"}->[1] = &create_object('c__HP::ArrayObject__');
	      my $evalstr = "\$methodref->{\"$_\"}->[1]->add_elements({'entries' => \$obj->". $methodref->{"$_"}->[0] ."()});";
		  eval "$evalstr";
		  if ( $@ ) {
		    &__print_output("(B) Unable to access data  [ using key ($_) ] for XML management. Error returned is << $@ >>!", WARN);
		  }
		}
	  }
	}
	
	# Remove the entries which SHOULD NOT have an XML output or should have their
	# output placed as an attribute
	$fields                     = &set_difference($fields, $methodref->{'skipped_fields'}->[1]->get_elements($local_true));
	$fields                     = &set_difference($fields, $methodref->{'attribute_fields'}->[1]->get_elements($local_true));
	$methodref->{'data_fields'} = &create_object('c__HP::ArrayObject__');
	$methodref->{'data_fields'}->add_elements({'entries' => $fields});
	
	# Lastly check to see if "unofficial" elements were added...
	if ( exists($obj->{'ADDED_FIELDS'}) ) {
	  $methodref->{'data_fields'}->add_elements({'entries' => $obj->{'ADDED_FIELDS'}->get_elements($local_true)});
	}
	
	# Collect the translation map from the object (if it is an object) to better optimize the
	# final lookup...
	$result->{'xmltranslations'} = ( &function_exists($obj, '__get_xml_translation_map') eq $local_true )
	                                 ? $obj->__get_xml_translation_map()
								     : {};
	return $result;
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
sub __read_xml($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
  
    my $result      = $local_true;
    my $obj         = $_[0];
	my $node        = $_[1];
	my $rootpath    = $_[2] || '';
	
	if ( (not defined($obj)) || (not defined($node)) ) {
	  $result = $local_false;
	  goto FINISH;
	}
	
	$obj->pre_callback_read() if ( &function_exists($obj, 'pre_callback_read') eq $local_true );
	
	my $data_fields = &get_fields($obj);
	
	my $read_results = {
	                    'needs internal_update' => $local_false,
						'different_elements'    => undef,
					   };
					   
	# Use XML Object infrastructure
	my $xmlobj = &create_object('c__HP::XMLObject__');
	$xmlobj->rootnode($node);
	
	my $nodenames  = $xmlobj->get_nodenames();
	#$nodenames     = &set_difference($nodenames, [ '#comment' ]);
	my $attributes = $xmlobj->get_attributes();
	
	my $unmatched_entries = &set_difference($data_fields, &set_union($nodenames, $attributes, $local_true), $local_true);
	if ( defined($unmatched_entries) && scalar($unmatched_entries->get_elements()) > 0 ) {
	  foreach ( @{$unmatched_entries->get_elements()} ) {
	    if ( ( &set_contains( "$_", $data_fields ) eq $local_false ) && 
		     (( &set_contains( "$_", $nodenames) eq $local_true ) || 
			  ( &set_contains( "$_", $attributes) eq $local_true )) ) {
	      $read_results->{"needs_internal_update"} = $local_true;
	      $read_results->{"different_elements"}    = $unmatched_entries->get_elements();
		  $obj->{"mismatch"} = $read_results; # This is likely where the "ADDED_FIELDS" add_data call is important...
		  last;
		}
	  }
	}
	
	my $control_data = &__get_xml_control_data($obj);
	
	if ( defined($nodenames) && scalar(@{$nodenames}) >= 1 ) {
	  foreach ( @{$nodenames} ) {
	    my ($is_simple_array,
		    $is_object_array,
			$is_object,
			$is_hash,
			$entry,
			$use_interior_nodes) = ( $local_false, $local_false, $local_false, $local_false, $local_true, $local_false );
		
		# Generic Version available for straight translation capabilities
		# However, we allow for obj to override and use specific object
		# method if necessary
		my $xml_translation = "$_";
		if ( exists($control_data->{'xmltranslations'}) ) {
		  $xml_translation = &get_xml_translation($control_data, "$_", BACKWARD);
		}
		
		my $result_type  = ref($obj->{"$xml_translation"});
		
		$is_simple_array = $local_true if ( $result_type =~ m/^array/i );
		$is_hash         = $local_true if ( $result_type =~ m/hash/i );
		$is_object_array = $local_true if ( &is_type($obj->{"$xml_translation"}, 'HP::ArrayObject') eq $local_true );
		$is_object       = $local_true if ( &is_blessed_obj($obj->{"$xml_translation"}) eq $local_true );
		
		$entry = $local_false if ( $is_simple_array eq $local_true ||
		                           $is_object_array eq $local_true ||
			                       $is_object eq $local_true ||
						           $is_hash eq $local_true );		

		$is_object = $local_false if ( $is_object_array eq $local_true );
		$is_hash   = $local_false if ( $is_object eq $local_true );
		
		my $subnodes = $xmlobj->get_nodes_by_xpath( {'xpath' => "$_"} );  # Need to use original name from XML
		  
		if ( $is_debug ) {
		  &__print_debug_output("Processing node ::");
		  &__print_debug_output("\t$xml_translation");
		  &__print_debug_output("\t(E) $entry -- (O) $is_object -- (SA) $is_simple_array -- (OA) $is_object_array");
		  &__print_debug_output("\tNumber of subnodes [ $rootpath/$_ ] --> ".scalar(@{$subnodes}));
		}
		
		if ( defined($subnodes) && scalar(@{$subnodes}) > 0 ) {
		  if ( $is_simple_array eq $local_true ) {
		    &__print_debug_output("Processing nodes as simple array") if ( $is_debug );
		    foreach my $sn ( @{$subnodes} ) {
			  my $data = $xmlobj->get_node_content( $sn );
			  if ( length($data) > 0 ) {
			    push ( @{$obj->{"$xml_translation"}}, $data );
			  }
			}
			if ( scalar(@{$obj->{"$xml_translation"}}) < 1 ) { $obj->{"$xml_translation"} = []; }
		  }
		  
		  if ( $is_object_array eq $local_true ) {
		    my $type   = '__SCALAR__';
			if ( defined($obj->{"$xml_translation"}->type()) ) {
		      $type = &convert_to_colon_module($obj->{"$xml_translation"}->type())->[0];
			}
			my $failed = $local_false;
			
			my $template           = $obj->{"$xml_translation"}->template();
			my $use_interior_nodes = $local_true;
			if ( defined($template) ) {
			  $use_interior_nodes = $template->{'use_interior_nodes'} || $local_false;
			}
			
		    &__print_debug_output("Processing nodes as object array << $type >> [ INTERIOR -> $use_interior_nodes ]") if ( $is_debug );
			
			foreach my $sn ( @{$subnodes} ) {
			  my @interior_nodes = ( $sn );
			  if ( $use_interior_nodes eq $local_true ) {
			    @interior_nodes = $sn->nonBlankChildNodes();
			  }
			  
			  foreach my $intnd ( @interior_nodes ) {
			    if ( $type ne '__SCALAR__' ) {
			      my $subobj = &get_template_obj($obj->{"$xml_translation"});
				  if ( not defined($subobj) ) {
			        &__print_output("Problem attempting to instantiate << $type >> to process node(s)! << $@ >>", WARN);
			        $failed = $local_true;
				    $result = $local_false;
				    last;
				  }
				  $subobj = $subobj->clone();
			      if ( $subobj->read_xml( $intnd, "$_" ) eq $local_true ) {
				    $obj->{"$xml_translation"}->push_item($subobj);
			      } else {
			        &__print_output("Unable to parse node for << $type >> object from ". ref($subobj), WARN);
				    $result = $local_false;
			      }
				} else {
				  $obj->{"$xml_translation"}->push_item($xmlobj->get_node_content( $intnd ))
				}
			  }
			}
			
			if ( $obj->{"$xml_translation"}->number_elements() < 1 ) {
			  next if ($failed eq $local_true );
			}
		  }
			
		  if ( $is_object eq $local_true ) {
			if ( $obj->{"$xml_translation"}->read_xml( $subnodes->[0], "$_" ) eq $local_false ) {
			  &__print_output("Unable to parse node for << $result_type >> object", WARN);
			  $result = $local_false;
			}
		  }

		  if ( $is_hash eq $local_true ) {
		    &__print_debug_output("Processing node as hash") if ( $is_debug );
			foreach my $sn ( @{$subnodes} ) {
			  &__read_xml($obj->{"$xml_translation"}, $sn, $sn->nodeName());
			}
		  }
		  
		  if ( $entry eq $local_true ) {
		    &__print_debug_output("Processing node as scalar") if ( $is_debug );
			my $data = $xmlobj->get_node_content( $subnodes->[0] );
			if ( &valid_string($data) eq $local_true ) {
	          $obj->{"$xml_translation"} = $data;
			}
		  }
		} else {
		  if ( defined($node) ) {
		    my $data = $xmlobj->get_node_content( $node );
			if ( &valid_string($data) eq $local_true ) {
	          $obj->add_data('value', $data);
			}
		  }
		}
	  }
	}
	
	if ( defined($attributes) && scalar(@{$attributes}) >= 1 ) {
	  foreach ( @{$attributes} ) {
		my $xml_translation = "$_";
		if ( exists($control_data->{'xmltranslations'}) ) {
		  $xml_translation = &get_xml_translation($control_data, "$_", BACKWARD);
		}
		my $data = $xmlobj->get_attribute_content($node, "$_");
		if ( &is_blessed_obj($obj->{"$xml_translation"}) eq $local_false ) {
	      $obj->{"$xml_translation"} = $data;
		} else {
		  $obj->{"$xml_translation"}->{"$xml_translation"} = $data;
		}
      }
	}

	$obj->post_callback_read() if ( &function_exists($obj, 'post_callback_read') eq $local_true );
	
  FINISH:
    return $result;	
  }

#=============================================================================
sub __write_xml($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $xmlobj    = $_[0];
	my $obj       = $_[1];
	my $root_name = $_[2];
	
	if ( not defined($root_name) ) {
	  if ( &function_exists($obj,'rootnode_name') eq $local_true ) {
	    $root_name = $obj->rootnode_name();
	  } else {
	    $root_name = 'rootElement';
		&__print_output("Unable to ascertain XML node name.  Using generic!", WARN);
	  }
	}
	
	my $root = undef;
	return $root if ( (not defined($xmlobj)) || (not defined($obj)) );
	return $root if ( &is_type($xmlobj, 'HP::XMLObject') eq $local_false );
	
	$xmlobj->make_document() if ( not defined($xmlobj->doctree()) );
	$obj->pre_callback_write() if ( &function_exists($obj, 'pre_callback_write') eq $local_true );
	
	# Figure out what should be displayed and how...
	my $control_data = &__get_xml_control_data($obj);

	return $root if ( ($control_data->{'method'}->{'attribute_fields'}->[1]->is_empty() eq $local_true) &&
	                  ($control_data->{'method'}->{'data_fields'}->is_empty() eq $local_true) );
					  
	$root = $xmlobj->doctree()->createElement($root_name);
	
	# Remove skipped fields from the attributes and the data fields
	if ( &is_type($control_data->{'method'}->{'skipped_fields'}->[1], 'HP::ArrayObject') eq $local_true ) {
	  $control_data->{'method'}->{'attribute_fields'}->[1] = &set_difference($control_data->{'method'}->{'attribute_fields'}->[1],
	                                                                         $control_data->{'method'}->{'skipped_fields'}->[1]);
	  $control_data->{'method'}->{'data_fields'} = &set_difference($control_data->{'method'}->{'data_fields'},
	                                                               $control_data->{'method'}->{'skipped_fields'}->[1]);
    }
	
	# Loop over all attribute data fields
	foreach ( @{$control_data->{'method'}->{'attribute_fields'}->[1]->get_elements()} ) {
	  # Generic Version available for straight translation capabilities
	  # However, we allow for obj to override and use specific object
	  # method if necessary
	  my $xml_translation = undef;
	  if ( &function_exists($obj, '__get_xml_translation') eq $local_true ) {
		$xml_translation = &get_xml_translation($obj->__get_xml_translation(), "$_", FORWARD);
	  } else {
		$xml_translation = &get_xml_translation($control_data, "$_", FORWARD);
      }

  	  if ( defined($obj->{"$_"}) ) {  
		my $data = &__convert_xml_data($obj, "$_", $control_data->{'convert_fields'});
	    $root->setAttribute("$xml_translation" => $data);
	  }
	}
	
	# Loop over all node data fields
	foreach ( @{$control_data->{'method'}->{'data_fields'}->get_elements()} ) {
	
	  # Generic Version available for straight translation capabilities
	  # However, we allow for obj to override and use specific object
	  # method if necessary
	  my $xml_translation = "$_";
	  if ( &function_exists($obj, '__get_xml_translation') eq $local_true ) {
		$xml_translation = &get_xml_translation($obj->__get_xml_translation(), "$_", FORWARD);
	  } else {
		$xml_translation = &get_xml_translation($control_data, "$_", FORWARD);
      }
	
	  # If defined or is EXPECTED to be output, continue...
	  if ( defined($obj->{"$_"}) ||
	       &set_contains("$_", $control_data->{'method'}->{'forced_output_fields'}->[1]->get_elements($local_true)) eq $local_true ) {
	  
	    my $ref_type = ref($obj->{"$_"});
		
		# Handle HASHES and Blessed objects, then ARRAYs, and finally scalar data
	    if ( &is_blessed_obj($obj->{"$_"}) eq $local_true || $ref_type =~ m/hash/i ) {
		  if ( &is_type($obj->{"$_"}, 'HP::ArrayObject') eq $local_true ) {
		    my $container = undef;
		    if ( defined($obj->{"$_"}->{'force_nodename'}) && 
			     $obj->{"$_"}->force_nodename() eq $local_true ) {
			  $container = $xmlobj->make_container_node("$xml_translation");
			}
			my $cnt = 0;
		    foreach my $element ( @{$obj->{"$_"}->get_elements()} ) {
		      my $rn_name = $xml_translation;
			  if ( ( &is_blessed_obj($element) eq $local_true ) ) {
				if ( &function_exists($element, 'rootnode_name') eq $local_true ) {
				  $rn_name = $element->rootnode_name();
				} else {
				  $rn_name = 'rootElement_'. $cnt;
				  ++$cnt;
				}
			  }
			  if ( not defined($container) ) {
			    if ( ref($element) eq '' ) {
			      $root->appendChild( $xmlobj->make_node({'__element' => $element}, "$rn_name") );
				} else {
				  $root->appendChild( $xmlobj->make_node($element, "$rn_name") );
				}
			  } else {
			    $container->appendChild( $xmlobj->make_node($element, "$rn_name") );
			  }
			}
			
			$root->appendChild($container) if ( defined($container) );
			
			if ( &function_exists($obj->{"$_"}, 'should_add_count_marker') eq $local_true &&
			     $obj->{"$_"}->should_add_count_marker() eq $local_true ) {
			  $root->setAttribute('count', $obj->{"$_"}->number_elements());
			}
		  } elsif ( $ref_type =~ m/hash/i ) {
	        $root->appendChild( $xmlobj->make_node($obj->{"$_"}, "$xml_translation") );
		  } else {
		    my $rn_name = $xml_translation;
			$rn_name = $obj->{"$_"}->rootnode_name() if ( &function_exists($obj->{"$_"}, 'rootnode_name') eq $local_true );
		    $root->appendChild( $xmlobj->make_node($obj->{"$_"}, $rn_name) ); # ADDED
		  }
		} elsif ( $ref_type =~ m/^array/i ) {
		  foreach my $sub ( @{$obj->{"$_"}} ) {
		    $root->appendChild( $xmlobj->make_node($sub, "$xml_translation") );
		  }
		} else {
		  my $node = $xmlobj->doctree()->createElement("$xml_translation");
		  if ( defined($obj->{"$_"}) ) {
		    my $data = &__convert_xml_data($obj, "$_", $control_data->{'method'}->{'convert_fields'}->[1]);
			$node->appendTextNode($data);
		  }
		  $root->appendChild($node);
		}
      }
	}

	$obj->post_callback_write($root) if ( &function_exists($obj, 'post_callback_write') eq $local_true );
	
	return $root;
  }
  
#=============================================================================
sub get_xml_translation($$;$)
  {
    my $result = undef;
	
	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    $inputdata = &convert_input_to_hash([ 'control_data', undef,
	                                      'field_name',   undef,
									      'direction',    undef, ], @_);
	
	# No input, return FALSE exit status
    goto __END_OF_SUB if ( scalar(keys(%{$inputdata})) == 0 );
	
    my $control_data = $inputdata->{'control_data'};
	my $field_name   = $inputdata->{'field_name'};
	my $direction    = $inputdata->{'direction'} || BACKWARD;
	
	goto __END_OF_SUB if ( not defined($control_data) );
	
	my $ref_type = ref($control_data);
	my $blessed  = &is_blessed_obj($control_data);
	
	if ( ( $ref_type !~ m/hash/i ) &&
	     ( &is_blessed_obj($control_data) eq $local_false ) ) {
	  $field_name   = $control_data;
	  $control_data = undef;
    } else {	
	  if ( &is_type($control_data, 'HP::XML::ControlStructure') eq $local_false ) {
	    if ( defined($control_data) && ref($control_data) =~ m/hash/i ) {
	      my $obj = &create_object('c__HP::XML::ControlStructure__');
		  &transfer_data($control_data, $obj);
		  $control_data = $obj;
	    } else {
	      $field_name   = $control_data;
	      $control_data = undef;
	    }
	  }
	}
	
	goto __END_OF_SUB if ( not defined($field_name) );

	if ( defined($control_data) ) {
      if ( defined($control_data->{'xmltranslations'}->{"$direction"}->{"$field_name"}) ) {
	    $result = $control_data->{'xmltranslations'}->{"$direction"}->{"$field_name"};
      } else {
	    $result = $field_name;	
	  }
	} else {
	  $result = $field_name;
	}
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub remove_xml_header($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $xmloutput = $_[0];
	goto __END_OF_SUB if ( &valid_string($xmloutput) eq $local_false );

	my $remove_header = $_[1];
	
	$remove_header = $local_true if ( not defined($remove_header) );
	if ( $remove_header eq $local_true ) {
	  $xmloutput =~ s/\<\?(.*)\>\s*//;
    }
	
  __END_OF_SUB:
	return $xmloutput;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;