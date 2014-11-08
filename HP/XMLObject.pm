package HP::XMLObject;

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

	#use overload q{""} => 'HP::XMLObject::print';
	
	use parent qw(HP::XML::XMLEnableObject);
	
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

    $VERSION = 1.2;
    @EXPORT  = qw (
                  );

    $module_require_list = {
	                        'XML::LibXML'                           => undef,
							'XML::Tidy'                             => undef,
							'XML::LibXML::PrettyPrint'              => undef,
							
							'HP::Constants'                         => undef,
							'HP::Support::Base'                     => undef,
							'HP::Support::Base::Constants'          => undef,
							'HP::Support::Hash'                     => undef,
							'HP::Support::Object'                   => undef,
							'HP::Support::Object::Tools'            => undef,
							'HP::Support::Configuration::Constants' => undef,
							
	                        'HP::CheckLib'                          => undef,
							'HP::Utilities'                         => undef,
							'HP::XML::Utilities'                    => undef,
							'HP::XML::Constants'                    => undef,
							
							'HP::Array::Tools'                      => undef,
							'HP::Stream::Constants'                 => undef,
							'HP::DBContainer'                       => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_xmlobject_pm'} ||
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

my $skip_cloning  = $local_false;
my $cached_object = undef;

#=============================================================================
sub __initialize
  {
    if ( $is_init eq $local_false ) {
	  $is_init = $local_true;
      $cached_object = HP::XMLObject->new() if ( not defined($cached_object) );
	}
  }
  
#=============================================================================
sub __update_rootname_with_attributes
  {
	my $self     = $_[0];
	my $rootname = $_[1];
	my $node     = $_[2];
			
	my $subparser = &create_object('c__HP::XMLObject__');
	$subparser->rootnode($node);
	my $attrlist = $subparser->get_attributes();
		
	foreach my $attr ( @{$attrlist} ) {
	  my $attrval = $subparser->get_attribute_content($self, $attr);
	  $rootname .= SPLITTER_ARROW."$attrval" if ( defined($rootname) );
	  $rootname = "$attrval" if ( not defined($rootname) );
	}

	&__print_debug_output("Updated rootname --> $rootname", __PACKAGE__) if ( $is_debug && defined($rootname) );
	return $rootname;
  }
		
#=============================================================================
sub clear
  {
    my $self     = $_[0];
	my $streamDB = &getDB('stream');  # This is a singleton...
	
	if ( defined($streamDB) ) {
	  my $xmlfile = $self->xmlfile();
	  if ( defined($xmlfile) ) {
	    my $stream = $streamDB->find_stream_by_path("$xmlfile");
	    $stream->close() if ( defined($stream) );
	  }
	}
	$self->rootnode(undef);
	$self->doctree(undef);
	$self->SUPER::clear();
	return;
  }

#=============================================================================
sub convert_to_properties
  {
    my $result   = &create_object('c__HP::ArrayObject__');
    my $self     = $_[0];
	
	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'rootname', \&valid_string,
	                                        'depth',    \&is_integer,
											'node',     undef, ], @_[ 1..scalar(@_)-1 ]);
    } else {
	  $inputdata = $_[0];
	}
	
    #return undef if ( scalar(keys(%{$inputdata})) == 0 );
	my $rootname = $inputdata->{'rootname'};
	my $depth    = $inputdata->{'depth'}    || 0;
	my $node     = $inputdata->{'node'}     || $self->rootnode();
	
	return $result->get_elements() if ( not defined($node) );
	
	my $nodename = $node->nodeName();
	if ( not defined($rootname) ) {
	  $rootname = $nodename;
	} else {
	  $rootname .= SPLITTER_ARROW.$nodename;
	}
	
	$rootname = $self->__update_rootname_with_attributes($rootname, $node) if ( $depth == 0 );

	my $orig_rootname = $rootname;
	
	++$depth;
	my @childnodes = $node->nonBlankChildNodes();
	
	if ( scalar(@childnodes) == 1 && $childnodes[0]->nodeType() == XML_TEXT_NODE ) {
	  $result->push_item("p:$rootname,v:".$childnodes[0]->textContent());
	} else {
	  foreach ( @childnodes ) {
	    $rootname = $orig_rootname;
	    next if ( $_->nodeType() != XML_ELEMENT_NODE );
		next if ( $_->nodeType() == XML_ATTRIBUTE_NODE );
		$rootname = $self->__update_rootname_with_attributes($rootname, $_);
		my $subresult = $self->convert_to_properties($rootname, $depth, $_);
	    $result->add_elements({'entries' => $subresult});
	  }
	}

	--$depth;
	
	my $list_items = $result->get_elements();
	
	if ( $depth == 0 ) {
	  my $hashresult   = {};
	  my $revisit_list = &create_object('c__HP::Array::Set__');
	  
	  foreach ( @{$list_items} ) {
	    my @comps = split(quotemeta(','), $_, 2);
		my $key = $comps[0];
		my $value = $comps[1];
		
		$key =~ s/^p\://;
		$value =~ s/^v\://;
		if ( not exists($hashresult->{"$key"}) ) {
		  $hashresult->{"$key"} = $value;
		} else {
		  if ( &is_type($hashresult->{"$key"}, 'HP::ArrayObject') eq TRUE ) {
		    $hashresult->{"$key"}->push_item($value);
		  } else {
		    my $temp = $hashresult->{"$key"};
			$hashresult->{"$key"} = &create_object('c__HP::Array::Set__');
			$hashresult->{"$key"}->push_item($temp);
			$hashresult->{"$key"}->push_item($value);
			
			$revisit_list->push_item("$key");
		  }
		}
	  }
	  
	  foreach ( @{$revisit_list->get_elements()} ) {
	    $hashresult->{"$_"} = $hashresult->{"$_"}->get_elements();
	  }
	  
	  return $hashresult;
	}
	return $list_items;
  }
  
#=============================================================================
sub data_types
  {
    my $self         = $_[0];
	my $which_fields = $_[1] || COMBINED;

    my $data_fields = {
	                   'doctree'              => undef,
					   'rootnode'             => undef,
					   'xmlfile'              => undef, # string
					   'last_path_expression' => undef, # string
					   'last_result'          => undef,
					   'options'              => {
					                              'allow_header' => $local_true,
					                              'encoding'     => undef,
					                              'standalone'   => $local_false,
												 },
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
sub get_attributes
  {
    my $self   = $_[0];
	my $node   = $_[1];
	my $result = [];
	
	if ( not defined($node) ) {
	  $self->read() if ( not defined($self->rootnode()) );
	  if ( defined($self->rootnode()) ) {
	    $node = $self->rootnode();
	  } else {
	    my $lr = $self->last_result();
		return $result if ( not defined($lr) );
	    my $ref_type = ref($lr);
	    if ( $ref_type =~ m/^array/i ) {
	      my $results = [];
	      foreach ( @{$lr} ) {
		    push ( @{$results}, $self->get_attributes($_) );
          }
		  $self->last_result($results);
          return $results;
		}
      }
    }
	
	my $attrs = $node->attributes();
	
	my @recorded_attrs = keys( %{$attrs->{'NodeMap'}} );
	$self->last_result(\@recorded_attrs);
	return \@recorded_attrs;
  }

#=============================================================================
sub get_attribute_content
  {
    my $self  = $_[0];
	my $input = $_[1];
	
	my ($node, $attr) = (undef, undef);
	if ( ref($input) =~ m/hash/i ) {
	  $node = $input->{'node'};
	  $attr = $input->{'attribute'};
	} else {
	  $node = $input;
      $attr = $_[2];
	}
	
	my $result = undef;
	goto __END_OF_SUB if ( &valid_string($attr) eq $local_false );
	
	if ( not defined($node) ) {
	  $self->read() if ( not defined($self->{'rootnode'}) );
	  goto __END_OF_SUB if ( not defined($self->{'rootnode'}) );
	  $node = $self->{"rootnode"};
	}
	
	if ( defined($node) ) {
	  $result = $node->getAttribute($attr);
	  $self->last_result($result);
	}
	
  __END_OF_SUB:
	return $result;
  }

#=============================================================================
sub get_document_rootnode
  {
	my $result  = undef;
    my $self    = $_[0];
	my $doctree = $self->doctree();
	
	if ( defined($doctree) &&
	     &is_type($doctree, 'XML::LibXML::Document') eq $local_true ) {
	  $result = $doctree->getDocumentElement();
    }
	return $result;
  }
  
#=============================================================================
sub get_nodes_by_xpath
  {
    my $self   = $_[0];
	my $data   = $_[1];
	
	my @result   = ();
	my $rootnode = undef;
	
    if ( not defined($data) ) {
	  $self->read() if ( not defined($self->{'rootnode'}) );
	  $rootnode = $self->{'rootnode'};
	} else {
	  if ( exists($data->{'root'}) ) {
	    $rootnode = $data->{'root'};
	  } else {
	    $self->read() if ( not defined($self->{'rootnode'}) );
		$rootnode = $self->{'rootnode'};
	  }
	}

	goto __END_OF_SUB if ( not defined($rootnode) );
	
	my $xpath = $data->{'xpath'} || goto __END_OF_SUB;
	@result = $rootnode->findnodes($xpath);
	
	$self->last_result(\@result);
	$self->last_path_expression($xpath);
	
  __END_OF_SUB:
	return \@result;
  }
  
#=============================================================================
sub get_nodenames
  {
    my $self = $_[0];
	my $node = $_[1];
	
	my $nodenames = [];
	if ( not defined($node) ) {
	  $self->read() if ( not defined($self->{'rootnode'}) );
	  goto __END_OF_SUB if ( not defined($self->{'rootnode'}) );
	  $node = $self->{'rootnode'};
	}
	
	if ( defined($node) ) {
	  my @nodes = $node->nonBlankChildNodes();
	  $self->last_result(\@nodes);
	  my $arrobj = &create_object('c__HP::Array::Set__');
	  if ( defined($arrobj) ) {
	    foreach ( @nodes ) {
		  my $nodeName = $_->nodeName();
		  if ( $nodeName ne '#comment' ) {
		    if ( $nodeName eq '#text' ) {
			  $arrobj->push_item( $node->nodeName() );
			} else {
			  $arrobj->push_item( $_->nodeName() );
		    }
		  }
	    }
	    $nodenames = $arrobj->get_elements();
		$self->last_result($nodenames);
	  }
	}
	
  __END_OF_SUB:
	return $nodenames;
  }
  
#=============================================================================
sub get_nodes
  {
    my $self     = $_[0];
	my $data     = $_[1];
	
	my @result   = ();
	my $rootnode = undef;
	
	if ( not defined($data) ) {
	  $self->read() if ( not defined($self->{'rootnode'}) );
	  $rootnode = $self->{'rootnode'};
	} else {
	  $rootnode = $data->{'root'} if ( exists($data->{'root'}) );
	}
	
	goto __END_OF_SUB if ( not defined($rootnode) );
	
	@result = $rootnode->nonBlankChildNodes();
	$self->last_result(\@result);

  __END_OF_SUB:
	return \@result;
  }

#=============================================================================
sub get_node_content
  {
    my $result = undef;
    my $self   = $_[0];
	my $node   = $_[1];
  
	if ( not defined($node) ) {
	  $self->read() if ( not defined($self->{'rootnode'}) );
	  goto __END_OF_SUB if ( not defined($self->{'rootnode'}) );
	  $node = $self->{'rootnode'};
	}
	
	if ( defined($node) ) {
	  $result = $node->textContent();
	  $self->last_result($result);
	}
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub get_pretty_print
  {
    #my $self = shift;
	my $pphash = {
	              'doctree'  => 'Document Tree',
				  'rootnode' => 'Root Node of XML Document',
				  'xmlfile'  => 'XML Filename',
				 };
	return $pphash;
  }
  
#=============================================================================
sub is_comment_node
  {
    my $result = $local_false;
    my $self   = $_[0];
	my $node   = $_[1] || goto __END_OF_SUB;
	
	if ( ref($node) =~ m/XML::LibXML/ ) {
	  $result = $local_true if ( $node->nodeType() eq XML_COMMENT_NODE );
	}
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub make_document
  {
    my $self       = $_[0];
	my $version    = $_[1];
	
	my $options = $self->options();
	
	my $encoding   = $_[2] || $options->{'encoding'};
	my $standalone = $_[3] || $options->{'standalone'} || $local_false;
	
	my $doctree = XML::LibXML::Document->new();
	
	$doctree->setEncoding($encoding) if ( defined($encoding) );
	$doctree->setStandAlone($standalone) if ( $standalone eq $local_true );
	
	$self->doctree($doctree);
	return $doctree;
  }

#=============================================================================
sub make_container_node
  {
	my $node     = undef;
    my $self     = $_[0];
	my $nodename = $_[1] || goto __END_OF_SUB;
	
	if ( defined($self->doctree()) ) {
	  $node = $self->doctree()->createElement("$nodename");
	}

  __END_OF_SUB:
	return $node;
  }
  
#=============================================================================
sub make_node
  {
    my $result = undef;
	
    my $self   = $_[0];
	my $obj    = $_[1];
	
	goto __END_OF_SUB if ( not defined($obj) );
	
	if ( &function_exists($obj, 'make_node') eq $local_true ) {
	  $result = $obj->make_node(@_[ 2..scalar(@_)-1 ]);
	} else {
	  $result = &HP::XML::Utilities::__write_xml($self, $obj, @_[ 2..scalar(@_)-1 ]);
	}
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub make_pretty
  {
    my $self      = $_[0];
	my $xmloutput = $_[1] || goto __END_OF_SUB;
	
    my $tidy_obj = undef;
	my $evalstr  = "\$tidy_obj = XML::Tidy->new(xml => \$xmloutput);";
	eval "$evalstr";
	if ( $@ ) {
	  &__print_output("Unable to clean up XML using tidy/prettyprint object...", WARN);
	  goto __END_OF_SUB;
	}
	
	$tidy_obj->tidy('   ');
	$xmloutput = $tidy_obj->toString();
	
	$xmloutput = &remove_xml_header($xmloutput) if ( $self->options()->{'allow_header'} eq $local_false );
	
  __END_OF_SUB:
	return $xmloutput;
  }
  
#=============================================================================
sub new
  {
    my $class = shift;
	my $self  = undef;

	if ( ref($_[0]) =~ m/hash/i ) {
	  if ( exists($_[0]->{&XMLOBJ_SKIP_CLONE_OPTION}) ) {
	    $skip_cloning = $_[0]->{&XMLOBJ_SKIP_CLONE_OPTION};
		delete($_[0]->{&XMLOBJ_SKIP_CLONE_OPTION});
		shift (@_) if ( scalar(keys(%{$_[0]})) < 1 );
	  }
	}
	
	# Ask the cached object container to clone a matching object otherwise
	# go through the construction process.
	if ( $skip_cloning eq $local_false ) {
	  if ( defined($HP::XMLObject::cached_object) ) {
	    $self = &clone_item($HP::XMLObject::cached_object);
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
	$HP::XMLObject::cached_object = $self if ( not defined($HP::XMLObject::cached_object) );

  UPDATE:
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

    return $self;
  }

#=============================================================================
sub prepare_xml
  {
    my $self    = $_[0];
	my $xmlnode = $self->make_node(@_[ 1..scalar(@_)-1 ]);
	return undef if ( not defined($xmlnode) );
	
	$self->rootnode($xmlnode);
	$self->doctree()->setDocumentElement($self->{'rootnode'});
	
	my $xmloutput = $self->rootnode()->toString();
	goto __END_OF_SUB if ( &valid_string($xmloutput) eq $local_false );
	
	$xmloutput = $self->make_pretty($xmloutput);
	
  __END_OF_SUB:
 	return $xmloutput;
  }

#=============================================================================
sub print
  {
    my $self = $_[0];
	
	my $output = "XMLObject :: \n";

	my @fields = keys(%{$self});
	my $print_mapping = $self->get_pretty_print();
	
	foreach ( @fields ) {
	  my $data = $self->{"$_"};
	  my $moniker = exists($print_mapping->{"$_"})
	                ? "$print_mapping->{$_}"
					: "$_ field";
	  
	  $output .= "\t$moniker --> $data\n" if ( defined($data) );
	}
	
	#my $uppercontent = $self->SUPER::print(@_);
	#$output .= $uppercontent if ( defined($uppercontent) );
	return $output;
  }

#=============================================================================
sub readfile
  {
    my $result = $local_false;
    my $self   = $_[0];
	goto __END_OF_SUB if ( not defined($self->xmlfile()) );
	
	my $xmlfile   = $self->xmlfile();
	my $xmlparser = &create_object('c__XML::LibXML__');
	my $doctree   = undef;
	my $evalstr   = "\$doctree = \$xmlparser->parse_file(\"$xmlfile\");";
	eval "$evalstr";
	if ( $@ ) {
	  &__print_output("Unable to read XML file << ". $self->xmlfile() . " >>\n$@", WARN);
	  goto __END_OF_SUB;
	}

	$self->doctree($doctree);
	$self->rootnode($doctree->getDocumentElement());
	$result = $local_true;
	
  __END_OF_SUB:
	return $result;
  }

#=============================================================================
sub shallow_copy
  {
    #my $self = shift;
	return [ 'doctree', 'rootnode', 'last_result' ];
  }

#=============================================================================
sub skip_fields
  {
    my $self = $_[0];
	my $skip_fields = &set_difference(&get_fields($self), [ 'xmlfile' ]);
	return $skip_fields;
  }
  
#=============================================================================
sub validate
  {
    my $self = $_[0];

	$self->SUPER::validate();	
	return;
  }

#=============================================================================
sub writefile
  {
    my $self      = $_[0];
	my $xmloutput = $_[1];
	
	return FALSE if ( not defined($xmloutput) );
	
	my $xmlfile = $self->xmlfile();
	goto __END_OF_SUB if ( not defined($xmlfile) );
	
	$xmloutput = $self->make_pretty($xmloutput);

  WRITE_OUT:
    my $strDB  = &getDB('stream');
	my $stream = $strDB->find_stream_by_path("$xmlfile");
	if ( defined($stream) ) {
	  $stream->output("$xmloutput");
	} else {
	  $stream = $strDB->make_stream("$xmlfile", OUTPUT);
	  if ( defined($stream) ) {
	    $stream->raw_output($xmloutput);
	  } else {
	    &__print_output("Unable to open << $xmlfile >> for writing XML output!", WARN);
	  }
	}
	$strDB->remove_stream($stream->handle()) if ( defined($stream) );
	
  __END_OF_SUB:
	return $xmloutput;
  }
  
#=============================================================================
&__initialize();
1;