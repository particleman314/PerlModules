package HP::SupportMatrix::Tools;

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

    $VERSION = 0.90;

    @ISA         = qw(Exporter);
    @EXPORT      = qw(
	                  &equal_objs
					  &get_attribute_names
	                  &get_subnode_names
					  &parse_nodes
	                  &validate_number_nodes
                     );
				   
    $module_require_list = {
	                        'XML::LibXML'                  => undef,
							
							'HP::String'                   => undef,
							'HP::RegexLib'                 => undef,
							'HP::ArrayTools'               => undef,
	                        'HP::CSLTools::Common'         => undef,
	                        'HP::CSLTools::Constants'      => undef,
							
							'HP::SupportMatrix::Constants' => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_supportmatrix_tools_pm'} ||
				 $ENV{'debug_supportmatrix_modules'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );

    $broken_install = 0;

    print STDERR "BEGIN <". __PACKAGE__ .">\n" if ( $is_debug );

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "\t--> Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
        if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "\t--> REQUIRED [ ". __PACKAGE__ ." ] use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUIRED [ ". __PACKAGE__ ." ] use $usemod\n" if ( $is_debug ); 
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
sub __initialize()
  {
    if ( not $is_init ) {
      $is_init = 1;
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
sub __make_array($$$)
  {
    my $obj          = shift;
	my $number_nodes = shift;
	my $name         = shift;
	
	if ( $number_nodes == 0 ) { return -1; }

	my $previous_content = undef;
	my $evalstr = "\$previous_content = \$obj->$name()";

	eval "$evalstr";
	if ( $@ ) { return -1; }
	
	if ( not defined($previous_content) ) {
	  $evalstr = "\$obj->$name([])";
      eval "$evalstr";
	  if ( $@ ) { return -1; }
	}
	return 0;
  }
  
#=============================================================================
sub __parse
  {
    my $obj     = shift;
    my $node    = shift || return;
	my $nodetag = shift || return;
	my $info    = shift || { 'type' => 'scalar', 'count' => 1, 'compare' => EQU };
	
	my $returncode = PASS;
	
	&csl_print_debug_output( "Parsing XML node for << $nodetag >> node(s)" );
	&csl_print_debug_output( "Main Object : ". ref( $obj ) ." -- Node tag to search : $nodetag" );
	
	if ( not exists( $info->{'type'} ) )    { $info->{'type'}    = 'scalar'; }
	if ( not exists( $info->{'count'} ) )   { $info->{'count'}   = 1; }
	if ( not exists( $info->{'compare'} ) ) { $info->{'compare'} = EQU; }
	
	my $type = &lowercase_first( $info->{'type'} );
	if ( $type eq 'attr' ) {
	  &csl_print_debug_output( "Attribute Data to store into << $nodetag >> is << ". $node->getAttribute( "$nodetag" ) ." >>" ) if ( defined( $node->getAttribute( "$nodetag" ) ) );
	  my $evalstr = "\$obj->$nodetag( \$node->getAttribute( \'$nodetag\' ) )";
	  eval "$evalstr";
	  if ( $@ ) {
	    &csl_print_output( 'Unable to add attribute data to main obj...', WARNING );
	  }
	  return $obj;
	}

	my $specific_nodes = &parse_nodes( $node, $nodetag, $info );
    if ( not defined( $specific_nodes ) ) { return $obj; }
	
	if ( $type eq 'scalar' ) {
	  &csl_print_debug_output( "Scalar Data to store into << $nodetag >> is << ". $specific_nodes->[0]->textContent ." >>" );
	  my $evalstr = "\$obj->$nodetag( \$specific_nodes->[0]->textContent )";
	  eval "$evalstr";
	  if ( $@ ) {
	    &csl_print_output( 'Unable to add scalar data to main obj...', WARNING );
	  }
	  return $obj;
	}

	if ( $type eq 'multilayer' ) {
	  my $container = undef;
	  if ( not defined( $info->{'class'} ) ) { return $obj; }
	  my $class = $info->{'class'};
	  
	  &csl_print_debug_output( "Array Data to store into << $nodetag >> using a container type << $class >>" );
	  
	  if ( &__make_array( $obj, scalar(@{$specific_nodes}), $info->{'container_name'} ) == -1 ) { return $obj; }
	  
	  foreach ( @{$specific_nodes} ) {
	    eval "\$container = $class->new();";
	    if ( $@ || not defined($container) ) {
		  &csl_print_output( "Unable to instantiate an object of type << $class >>", WARNING );
	      next;
	    } else {
	      $container->parse( $_ );
	      if ( $container->valid() ) {
			my $evalstr = "\$obj->add_item( '".$info->{'container_name'}."', \$container )";
		    eval "$evalstr";
			if ( $@ ) {
			  &csl_print_output( "Unable to include class object << $class >> -- no method called 'add_item'", WARNING );
			}
		  }
        }
	  }
    }
	
	return $obj;
  }
  
#=============================================================================
sub equal_objs($$)
  {
    my $obj1 = shift;
    my $obj2 = shift;
	
	if ( not defined($obj1) || not defined($obj2) ) { return NOT_SAME; }
	
	if ( lc(ref($obj1)) ne lc(ref($obj2)) ) { return NOT_SAME; }
	
	my $data_fields1 = $obj1->data_types();
	my $data_fields2 = $obj2->data_types();
	my $unmatched_fields = &set_difference($data_fields1, $data_fields2);
	
	if ( scalar(@{$unmatched_fields}) > 0 ) { return NOT_SAME; }
	
	my $equality = SAME;
	
    my @keys = keys(%{$data_fields1});
    foreach ( @keys ) {
	  my ( $val1, $val2 ) = ( undef, undef );
      eval "\$val1 = \$obj1->$_();";
      eval "\$val2 = \$obj2->$_();";
	  if ( $val1 ne $val2 ) {
		$equality = NOT_SAME;
		last;
      }
	}
	
	return $equality;
  }

#=============================================================================
sub get_attribute_names($)
  {
    my @attrnames = ();
    my $node = shift || return \@attrnames;
	 
    my @attrnodes = $node->attributes();
	foreach ( @attrnodes ) {
	  if ( $_->nodeType == XML_ATTRIBUTE_NODE ) {
	    push ( @attrnames, $_->nodeName() );
	  }
	}
	return \@attrnames;
  }

#=============================================================================
sub get_subnode_names($)
  {
    my $subnode_names = [];
    my $node = shift || return $subnode_names;
	 
    my @subnodes = $node->nonBlankChildNodes();
	foreach my $subnode ( @subnodes ) {
	  &csl_print_debug_output( "Node type --> " . $subnode->nodeType );
	  
	  next if ( $subnode->nodeType == XML_COMMENT_NODE );
	  push( @{$subnode_names}, $subnode->nodeName );
	}
	
	$subnode_names = &set_unique( $subnode_names );
	return $subnode_names;
  }

#=============================================================================
sub parse_nodes(;$$$)
  {
    my $matched_nodes  = [];
	
    my $node    = shift || return $matched_nodes;
	my $nodetag = shift || return $matched_nodes;
	my $info    = shift || { 'type' => 'scalar', 'count' => 1, 'compare' => EQU };
	
	my $subnode_names  = &get_subnode_names( $node );
	my @specific_nodes = ();
	if ( &set_contains( $nodetag, $subnode_names ) ) {
	  foreach ( $node->nonBlankChildNodes() ) {
	    if ( $_->nodeName() eq $nodetag ) { push( @specific_nodes, $_ ); }
	  }
    }
	
	my $return_code = &validate_number_nodes( $nodetag, \@specific_nodes, $info->{'count'}, $info->{'compare'} );
	if ( $return_code == FAIL || $return_code == UNVERIFIED ) { return $matched_nodes; }
	
	return \@specific_nodes;
  }
  
#=============================================================================
sub validate_number_nodes($$;$$)
  {
 	my $nodetag            = shift;
    my $node_collection    = shift;
	my $expected_num_nodes = shift || 0;
	my $comparison         = shift || EQU;
	
	if ( not &valid_string( $nodetag ) ) {
	  &csl_print_output("No element provided, so return code is UNVERIFIED", WARNING);
	  return UNVERIFIED;
	}
	
	if ( not &is_integer( $expected_num_nodes ) ) {
	  &csl_print_output('Resetting number of expected nodes to 0 since input was not an integer', WARNING);
	  $expected_num_nodes = 0;
	}
	
	my $num_nodes = scalar( @{$node_collection} );
	my $result    = 0;
	eval "\$result = ( $num_nodes $comparison $expected_num_nodes );";
	
	( $result )
	    ? return VERIFIED
        : &csl_print_output( "Found $num_nodes node(s) which is UNEXPECTED ( expecting $expected_num_nodes ) when searching for xpath < $nodetag >.", WARNING );
	return FAIL;
  }

#=============================================================================
&__initialize();

#=============================================================================
1;