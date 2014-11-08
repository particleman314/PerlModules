package HP::VersionObject;

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
				$default_version_delimiter
				
				@ISA
                @EXPORT
               );

    $VERSION = 1.05;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'HP::Constants'              => undef,
							'HP::Support::Base'          => undef,
							'HP::Support::Hash'          => undef,
							'HP::Support::Object'        => undef,
							'HP::Support::Object::Tools' => undef,
							'HP::Support::Module'        => undef,
	                        'HP::CheckLib'               => undef,
							'HP::XML::Utilities'         => undef,
							
							'HP::Version::Constants'     => undef,
							
							'HP::Array::Tools'           => undef,
							'HP::Path'                   => undef,
							'HP::FileManager'            => undef,
	                       };
    $module_request_list = {};

	$default_version_delimiter = '.';
	
    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_versionobject_pm'} ||
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
sub __build_version
  {
    my $self = $_[0];
	my $d    = $self->get_version_delimiter();

    my $field_names = $self->get_version_fields();
	
	my $fields = &create_object('c__HP::ArrayObject__');
	$fields->add_elements({'entries' => $field_names});
	
	my $version = [];
	my $suppressed_fields = &create_object('c__HP::ArrayObject__');
	$suppressed_fields->add_elements({'entries' => VERSIONMAPPING->{$self->output_representation()}});
	
	foreach ( @{$fields->get_elements()} ) {
	  if ( $suppressed_fields->contains($_) eq $local_false ) {
	    if ( defined($self->{$_}) ) {
		  if ( &is_alphabetic($self->{$_}) eq $local_false && $_ ne 'major' ) {
		    if ( defined($self->get_field_size($_)) ) {
	          push ( @{$version}, sprintf('%0'. $self->get_field_size($_) .'d', $self->{$_}) );
			} else {
	          push ( @{$version}, $self->{$_} );
			}
		  } else {
	        push ( @{$version}, $self->{$_} );
		  }
		}
	  }
	}
	
	if ( scalar(@{$version}) > 0 ) {
	  $version = join($d, @{$version});
	} else {
	  $version = undef;
	}
	$self->version($version);
	
	return;
  }

#=============================================================================
sub __convert_version
  {
    my $self = $_[0];

	my $v = $_[1] || $self->version();
	my $d = $self->get_version_delimiter();
	
	return if ( not defined($v) );
	
	if ( $d eq '_' ) {
	  $v =~ s/_/./g;
	  $d = '.';
	}
	
	if ( defined($self->{'pattern'}) ) {
	  my $pattern = &convert_to_regexs($self->pattern());
	} else {
	  my @components = $self->__separate_version($v, $d);
	  my ($major, $minor, $revision, $subrevision) = @components;
	  if ( defined($major) && ( not defined($minor) ) ) {
	    if ( defined($self->get_field_size('minor')) ) {
		  $minor = sprintf('%0'. $self->get_field_size('minor') .'d', 0);
		} else {
		  $minor = '00';
		}
		$self->only_major_value_defined($local_true);
	  }
	  $self->major($major);
	  $self->minor($minor);
	  $self->revision($revision);
	  $self->subrevision($subrevision);
	  
	  my $field_size = {};
	  
	  $field_size->{'major'}       = $self->__update_field($major);
	  $field_size->{'minor'}       = $self->__update_field($minor);
	  $field_size->{'revision'}    = $self->__update_field($revision);
	  $field_size->{'subrevision'} = $self->__update_field($subrevision);
	  
	  $self->set_field_size($field_size);
	  
	  foreach ( keys(%{$self->{'field_size'}}) ) {
	    delete($self->{'field_size'}->{$_}) if ( not defined($self->{'field_size'}->{$_}) );
	  }
	}

	return;
  }

#=============================================================================
sub __increment
  {
    my $result  = $local_false;
    my $self    = $_[0];
	
	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    if ( ref($_[1]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'key',     undef,
	                                        'mapping', undef,
											'amount',  \&is_integer, ], @_[ 1..scalar(@_)-1 ]);
    } else {
	  $inputdata = $_[1];
	}
	
	# No input, return FALSE exit status
    goto __END_OF_SUB if ( scalar(keys(%{$inputdata})) == 0 );
	
	my $key     = $inputdata->{'key'};
	my $mapping = $inputdata->{'mapping'};
	my $amt     = $inputdata->{'amount'};
	
	if ( defined($self->{$key}) && is_alphabetic($self->{$key}) eq $local_false ) {
	  $result = $local_true;
	  if ( $key ne 'major' ) {
	    if ( defined($self->get_field_size($key)) ) {
	      $self->{$key} = sprintf('%0'. $self->get_field_size($key) .'d', int($self->{$key}) + $amt);
		} else {
	      $self->{$key} = int($self->{$key}) + $amt;
		}
	  } else {
	    $self->{$key} = int($self->{$key}) + $amt;
	  }
	  my $remaining_fields = VERSIONMAPPING->{$mapping};
	  foreach ( @{$remaining_fields} ) {
	    if ( defined($self->field_size()) ) {
	      $self->{$_} = sprintf('%0'. $self->get_field_size($_) .'d', 0) if ( defined($self->{$_}) );
		} else {
		  $self->{$_} = '00' if ( defined($self->{$_}) );
		}
	  }
	}
	
  __END_OF_SUB:
	$self->___build_version();
	return $result;
  }
  
#=============================================================================
sub __initialize
  {
    if ( $is_init eq $local_false ) {
	  $is_init = $local_true;
      $cached_object = HP::VersionObject->new() if ( not defined($cached_object) );
	}
  }
  
#=============================================================================
sub __modify_output
  {
    my $self = $_[0];
	goto __END_OF_SUB if ( not defined($self->output_representation()) );
		
	$self->version(undef);
	$self->__build_version();
	$self->cleanup_internals();
	
  __END_OF_SUB:
	return;
  }
  
#=============================================================================
sub __separate_version
  {
    my @result = ();
	
    my $self  = $_[0];
	my $input = $_[1] || $self->version() || goto __END_OF_SUB;
	my $delim = $_[2] || $self->get_version_delimiter() || '.';
	
	my $regex  = &convert_to_regexs($delim);
	@result = split /$regex/, $input;
	
  __END_OF_SUB:
	return @result;
  }
  
#=============================================================================
sub __update_field
  {
    my $self  = $_[0];
	my $value = $_[1];
	
	my $temp = $value;
	$temp =~ s/^[0*]// if ( defined($temp) );

	my $isint = &is_integer($temp);
	my $islet = &is_alphabetic($value);
	
	return length($value) if ( $isint eq $local_true && $islet eq $local_false );
	return undef;
  }
  
#=============================================================================
sub as_node
  {
    my $self = $_[0];
	$self->set_style(XMLNODES);
	return;
  }
  
#=============================================================================
sub as_attribute
  {
    my $self = $_[0];
	$self->set_style(XMLATTR);
	return;
  }
  
#=============================================================================
sub compare
  {
    my $self  = $_[0];
	my $other = $_[1] || return $local_false;
	
	my $equalize = $_[2] || $local_false;
	my $comparer = $_[3] || COMPARATORS->{$self->comparison()}->{'representation'};
	
	my $comparison_objects = KNOWN_COMPARATORS;
	my $found = $local_false;
	foreach ( @{$comparison_objects} ) {
	  $found = &equal($_->{'operator'},$comparer);
	  last if ( $found eq $local_true );
	}
	
	my $result = $local_false;
	return $result if ( $found eq $local_false );
	
	my $version_components = $self->get_version_fields();
	
	foreach ( @{$version_components} ) {
	  return $result if ( ( (not defined($self->{"$_"})) && defined($other->{"$_"}) ) ||
	                      ( (not defined($other->{"$_"})) && defined($self->{"$_"}) ) );
	  last if ( (not defined($self->{"$_"})) &&
	            (not defined($other->{"$_"})) );

	  my $self_data  = $self->{"$_"};
	  my $other_data = $other->{"$_"};
	  
	  if ( $equalize eq $local_true ) {
	    my $length_diff = length($self_data) - length($other_data);
		goto SKIP if ( $length_diff == 0 );
		
		&__print_debug_output("Before Equalization :: <$self_data> -- <$other_data>") if ( $is_debug );
		if ( $length_diff > 0 ) {
		  $other_data .= '0' x $length_diff;
		} elsif ( $length_diff < 0 ) {
		  $self_data .= '0' x (-$length_diff);
		}
		&__print_debug_output("After Equalization :: <$self_data> -- <$other_data>") if ( $is_debug );
	  }
	  
	SKIP:
	  my $evalstr = "\$result = (\$self_data $comparer \$other_data);";
	  eval("$evalstr");
	  return $local_false if ( $result eq $local_false || $result eq '' );
	}
	
	return $local_true;
  }
  
#=============================================================================
sub data_types
  {
    my $self         = $_[0];
	my $which_fields = $_[1] || COMBINED;
	
    my $data_fields = {
	                   'version'     => undef,
	                   'major'       => undef,
					   'minor'       => undef,
	                   'revision'    => undef,
					   'subrevision' => undef,
					   'comparison'  => EQUALS->{'representation'},
					   'style'       => XMLNODES,
					   
					   'only_major_value_defined' => $local_false,
					   'output_representation'    => ALL_FIELDS,
					   'version_delimiter'        => $default_version_delimiter,
					   'pattern'                  => undef,
					   'field_size'               => {},
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
sub decode
  {
    my $self = $_[0];

	$self->__convert_version($_[1]) if ( defined($_[1]) );
	if ( defined($self->major()) ) {
	  $self->version($self->get_version());
	}
	$self->cleanup_internals();
	return;
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
sub get_field_size
  {
    my $result = undef;
    my $self   = $_[0];
	my $field  = $_[1];
	
	if ( not defined($field) && exists($self->{'field_size'}->{'major'}) ) {
	  $result = $self->{'field_size'}->{'major'};
	  goto __END_OF_SUB;
	}
	goto __END_OF_SUB if ( not defined($field) );
	
	if ( exists($self->{'field_size'}->{$field}) ) {
	  $result = $self->{'field_size'}->{$field};
	  goto __END_OF_SUB;
	}

  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub get_version
  {
    my $self = $_[0];
	$self->__build_version();
	return $self->version();
  }
  
#=============================================================================
sub get_version_delimiter
  {
    my $self = $_[0];
	return $self->version_delimiter();
  }

#=============================================================================
sub get_version_fields
  {
    return [ 'major', 'minor', 'revision', 'subrevision' ];
  }

#=============================================================================
sub increment
  {
    my $self = $_[0];
	my $type = $_[1] || 'major';
	my $amt  = $_[2] || 1;
	
	my $mapping = undef;
	
	$type = 'major' if ( &set_contains($type, $self->get_version_fields()) eq $local_false );
	
	$mapping = MAJOR_ONLY           if ( $type eq 'major' );
	$mapping = MAJOR_MINOR          if ( $type eq 'minor' );
	$mapping = MAJOR_MINOR_REVISION if ( $type eq 'revision' );
	$mapping = ALL_FIELDS           if ( $type eq 'subrevision' );
	
	$self->__increment($type, $mapping, $amt);
	$self->__build_version();
	
	return $local_true;
  }

#=============================================================================
sub make_node
  {
    my $result = undef;
    my $self   = $_[0];
	
	my $nodename = $_[1] || 'version';

	# Version style --> XMLNODES or XMLATTR
	# XMLNODES will produce a collection of nodes for the Version Object
	# XMLATTR  will produce the string representation of the Version Object as an attribute (just a number)

	my $xmlobj  = &create_object('c__HP::XMLObject__');
	my $doctree = $xmlobj->make_document();
	
	if ( &equal($self->style(), XMLNODES) ) {
	  $result =&HP::XML::Utilities::__write_xml($xmlobj, $self, "$nodename");
	} else {
	  my $node = $doctree->createElement('version');
	  
	  my $suppressed_fields = $self->{SUPPRESSION_KEY};
	  
	  $node->setAttribute('comparison', $self->comparison()) if ( &set_contains('comparison', $suppressed_fields) eq $local_false );
	  $node->setAttribute('value', $self->get_version());
	  $result = $node;
	}
	
	return $result;
  }

#=============================================================================
sub modify_output_representation_all_fields
  {
    my $self = $_[0];
	$self->modify_output_representation(ALL_FIELDS);
	return $local_true;
  }
  
#=============================================================================
sub modify_output_representation
  {
    my $self = $_[0];
	my $rep  = $_[1] || return;
	
	my @known_representations = keys(%{&VERSIONMAPPING});
	if ( &set_contains($rep, \@known_representations) eq $local_true ) {
	  $self->output_representation($rep);
	  $self->__modify_output();
	}
	
	return $local_true;
  }
  
#=============================================================================
sub new
  {
    my $class = shift;
	my $self  = undef;

	if ( ref($_[0]) =~ m/hash/i ) {
	  if ( exists($_[0]->{&VERSION_SKIP_CLONE_OPTION}) ) {
	    $skip_cloning = $_[0]->{&VERSION_SKIP_CLONE_OPTION};
		delete($_[0]->{&VERSION_SKIP_CLONE_OPTION});
		shift (@_) if ( scalar(keys(%{$_[0]})) < 1 );
	  }
	}
	
	# Ask the cached object container to clone a matching object otherwise
	# go through the construction process.
	if ( $skip_cloning eq $local_false ) {
	  if ( defined($HP::VersionObject::cached_object) ) {
	    $self = $HP::VersionObject::cached_object->clone();
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
	$HP::VersionObject::cached_object = $self if ( not defined($HP::VersionObject::cached_object) );
	
  UPDATE:
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
	
	$self->update();
	$self->set_field_size(2, $self->get_version_fields(), $local_false);
	return $self;  
  }

#=============================================================================
sub post_callback_read
  {
    my $self = $_[0];
	
	if ( exists($self->{'value'}) ) {
	  $self->move('value', 'version');
	  $self->update();
	}
	
	return;
  }

#=============================================================================
sub prepare_xml
  {
    my $self   = $_[0];
	my $output = undef;
	
	my $version_style = $_[1] || $self->style() || XMLNODES;
	$self->style($version_style);
	
	my $node = $self->make_node();
    goto __END_OF_SUB if ( not defined($node) );
	
	my $xmlobj = &create_object('c__HP::XMLObject__');
	if ( defined($xmlobj) ) {
	  $xmlobj->rootnode($node);
	  $xmlobj->make_document() if ( not defined($xmlobj->doctree()) );
	  $xmlobj->doctree()->setDocumentElement($xmlobj->{'rootnode'});
	
	  $output = $xmlobj->rootnode()->toString();
    }
	
  __END_OF_SUB:
	return $output;
  }
  
#=============================================================================
sub readfile
  {
    my $result = $local_false;
	my $self   = $_[0];
	
	$result = $self->SUPER::readfile(@_[ 1..scalar(@_)-1 ]);

	$self->version($self->get_version()) if ( $result eq $local_true );
	return $result;
  }

#=============================================================================
sub set_field_size
  {
    my $self       = $_[0];
	
	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    if ( defined($_[1]) && ref($_[1]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'field_size',  \&is_integer,
	                                        'fields',      undef,
											'overwrite',   undef, ], @_[ 1..scalar(@_)-1 ]);
    } else {
	  $inputdata = $_[1];
	}
	
	# No input, return FALSE exit status
    goto __END_OF_SUB if ( scalar(keys(%{$inputdata})) == 0 );
	
	my ( $field_size, $fields, $overwrite ) = ( undef, undef, undef );
	
	my $all_fields = $self->get_version_fields();
	
	$field_size = $inputdata->{'field_size'};
	$fields     = $inputdata->{'fields'};
	$overwrite  = $inputdata->{'overwrite'};
	
	$overwrite = $local_true if ( not defined($overwrite) );

	if ( ( not defined($field_size) ) && ( not defined($fields) ) ) {
	  my @specific_fields = keys(%{$inputdata});
	  $fields = \@specific_fields;
	} else {
	  goto __END_OF_SUB if ( &valid_string($field_size) eq $local_false ||
	                         &is_integer($field_size) eq $local_false );
	  goto __END_OF_SUB if ( $field_size < 0 );
	  $fields = $all_fields if ( not defined($fields) );
	}
	
	foreach ( @{$fields} ) {
	  next if ( &set_contains($_, $all_fields) eq $local_false );
	  if ( $overwrite eq $local_true || ( not defined($self->{'field_size'}->{$_}) ) ) {
	    if ( defined($field_size) ) {
	      $self->{'field_size'}->{$_} = $field_size;
	    } else {
	      $self->{'field_size'}->{$_} = $inputdata->{$_};
		}
	  }
	}
	
  __END_OF_SUB:
	return;
  }
  
#=============================================================================
sub set_style
  {
    my $self  = $_[0];
	my $style = $_[1];
	
	my $allowed_styles = KNOWN_STYLES;
	
	$style = XMLNODES if ( not defined($style) );
	$style = XMLNODES if ( &set_contains($style,$allowed_styles) eq $local_false );
	
	$self->style($style);
	
  __END_OF_SUB:
	return;
  }
  
#=============================================================================
sub set_version
  {
    my $self    = $_[0];
	my $version = $_[1] || return $local_false;
	
	$self->version($version);
	$self->update();
	return;
  }
  
#=============================================================================
sub set_version_delimiter
  {
    my $self      = $_[0];
	my $delimiter = $_[1] || return $local_false;
	
	return $local_false if ( &valid_string($delimiter) eq $local_false );
	
	$self->version_delimiter($delimiter);
	
	return $local_true;
  }

#=============================================================================
sub skip_fields
  {
    my $self     = $_[0];

	my $specific = [ 'version', 'version_delimiter', 'style',
	                 'only_major_value_defined', 'output_representation', 'pattern', 'field_size' ];
	$specific = &set_union($specific, $self->{SUPPRESSION_KEY}) if ( exists($self->{SUPPRESSION_KEY}) );
	$specific = &set_union($specific, $self->SUPER::skip_fields());
	return $specific;
  }

#=============================================================================
sub to_string
  {
    my $self = $_[0];
	if ( defined($self->output_representation()) &&
	     $self->output_representation() > ALL_FIELDS ) {
	  $self->__modify_output();	 
	}
	return $self->get_version();
  }
  
#=============================================================================
sub update
  {
    my $self = $_[0];

    $self->__convert_version() if ( defined($self->version()) );
    return $local_true;
  }

#=============================================================================
sub write_as_attributes
  {
    my $self = $_[0];
	
	my $specific = [ 'comparison' ];

	$specific = &set_union($specific, $self->SUPER::write_as_attributes());
	return $specific;
  }

#=============================================================================
&__initialize();
1;