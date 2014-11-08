package HP::XML::XMLEnableObject;

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

    $VERSION = 0.85;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'XML::Dumper'                  => undef,
							
							'HP::Constants'                => undef,
							'HP::Base::Constants'          => undef,

							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
							
	                        'HP::CheckLib'                 => undef,	
							'HP::Path'                     => undef,
							'HP::FileManager'              => undef,
							'HP::XML::Utilities'           => undef,
							'HP::XML::Constants'           => undef,
							
							'HP::Array::Tools'             => undef,
							'HP::Stream::Constants'        => undef,
							'HP::DBContainer'              => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_xml_xmlenableobject_pm'} ||
                 $ENV{'debug_xml_modules'} ||
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

#=============================================================================
sub as_xml
  {
    my $self     = $_[0];
	my $hashdata = $_[1];
	
	my $xmlconvert = &create_object('c__XML::Dumper__');
	
	if ( defined($xmlconvert) ) {
	  if ( not defined($hashdata) ) {
	    return $xmlconvert->pl2xml( $self );
	  } else {
	    return $xmlconvert->pl2xml( $hashdata );
	  }
	}
	return undef;
  }
  
#=============================================================================
sub AUTOLOAD
  {
    our $AUTOLOAD;
    my $self = shift;
    my $type = ref($self) or die "\$self is not an object when calling method << $AUTOLOAD >>\n";
    
    # DESTROY messages should never be propagated.
    return if $AUTOLOAD =~ /::DESTROY$/;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    unless ( defined($name) or exists($self->{$name}) ) {
      if ( defined($name) ) {
	    &__print_output("Can't access '$name' field in class $type.  Returning empty string...\n", 'STDERR');
      } else {
	    &__print_output("Can't access an undefined field in class $type.  Returning empty string...\n", 'STDERR');
      }
      return undef;
    }

    my $num_elements = scalar( @_ );

    if ( $num_elements >= 1) {
      # Set built-on-the-fly function...
      if ( $num_elements == 1 ) {
	    return $self->{$name} = $_[0];
      } else {
	    return $self->{$name} = \@_;
      }
    } else {
      # Get built-on-the-fly function...
      return $self->{$name};
    }
  }

#=============================================================================
sub bool2string
  {
    my $self            = $_[0];
	my $item            = $_[1];
	my $translation_map = $_[2];
	
	return &convert_boolean_to_string($item, $translation_map);
  }
  
#=============================================================================
sub convert_output
  {
	return {};
  }

#=============================================================================
sub data_types
  {
    my $self         = $_[0];
	my $which_fields = $_[1] || COMBINED;
	
    my $data_fields = {
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
sub force_xml_output
  {
    my $self   = $_[0];
	my $result = [];
	
	$result = $self->{'ADDED_FIELDS'}->get_elements() if ( exists($self->{'ADDED_FIELDS'}) );
	
	return $result;
  }

#=============================================================================
sub new
  {
    my $class       = shift;
    my $data_fields = &data_types();

    my $self = {
		        %{$data_fields},
	           };
			   
    bless $self, $class;
	
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
	
	return $self;  
  }

#=============================================================================
sub prepare_xml
  {
    my $self          = $_[0];
	my $rootnode_name = $_[1];

	if ( not defined($rootnode_name) &&
	  &function_exists($self, 'rootnode_name') eq $local_true ) {
	  $rootnode_name = $self->rootnode_name();
	} else {
	  $rootnode_name ||= 'root_node_element';
	}
	
	my $xmlobj  = &create_object('c__HP::XMLObject__');
	my $doctree = $xmlobj->make_document();
	
	my $output = $xmlobj->prepare_xml($self, $rootnode_name);
	return $output;
  }

#=============================================================================
sub parse_xml
  {
	my $result   = $local_false;
    my $self     = $_[0];

	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    if ( ref($_[1]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'node',     undef,
	                                        'rootpath', undef, ], @_[ 1..scalar(@_)-1 ]);
    } else {
	  $inputdata = $_[1];
	}
	
	# No input, return FALSE exit status
    goto __END_OF_SUB if ( scalar(keys(%{$inputdata})) == 0 );
	
	my $node     = $inputdata->{'node'}     || goto __END_OF_SUB;
	my $rootpath = $inputdata->{'rootpath'} || '//';

	$result = &HP::XML::Utilities::__read_xml($self, $node, $rootpath);
	goto __END_OF_SUB if ( $result eq $local_false );
	
	$self->cleanup_internals() if ( &function_exists($self, 'cleanup_internals') eq TRUE );
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub read_xml
  {
	my $result   = $local_false;
    my $self     = $_[0];
	
	if ( ref($self) eq 'HP::BaseObject' ) {
	  $result = $local_true;
	  goto __END_OF_SUB;
	}

	my $xmlobj = $_[1];
	goto __END_OF_SUB if ( &is_type($xmlobj, 'HP::XMLObject') eq $local_false );
    goto __END_OF_SUB if ( not defined($xmlobj->rootnode()) );
	
	$result = $self->parse_xml($xmlobj->rootnode());
	
  __END_OF_SUB:
	return $result;
  }

#=============================================================================
sub readfile
  {
    my $result   = $local_false;
	
    my $self     = $_[0];
	my $filename = $_[1];
	
	goto __END_OF_SUB if ( &valid_string($filename) eq $local_false );
	
	$filename = &convert_path_to_client_machine($filename, 'linux');
	goto __END_OF_SUB if ( &does_file_exist($filename) eq $local_false );
	
	my $xmlobj = &create_object('c__HP::XMLObject__');
	$xmlobj->xmlfile("$filename");
	goto __END_OF_SUB if ( $xmlobj->readfile() eq $local_false );
	
	$result = $self->read_xml($xmlobj);
	if ( $result eq $local_false ) {
	  $self->clear();
	  goto __END_OF_SUB;
	}
	
	$self->validate();

  __END_OF_SUB:
	return $result;
  }

#=============================================================================
sub skip_fields
  {
    my $self = $_[0];
	return $self->{SUPPRESSION_KEY} if ( exists($self->{SUPPRESSION_KEY}) );
	return [];
  }

#=============================================================================
sub string2bool
  {
    my $self            = $_[0];
	my $item            = $_[1];
	my $translation_map = $_[2];
	
	return &convert_string_to_boolean($item, $translation_map);
  }

#=============================================================================
sub update_skip_fields
  {
    my $self        = $_[0];
	my $skip_fields = $_[1];
	
    # Need a means to take all inputs and squeeze into an array by flattening
	
	if ( exists($self->{SUPPRESSION_KEY}) ) {
	  $skip_fields = &set_union( $skip_fields, $self->{SUPPRESSION_KEY} );
	}
	$skip_fields = &set_union( $skip_fields, [ SUPPRESSION_KEY ] );
	
	$self->{'SUPPRESSION_KEY'} = $skip_fields;
	
	return;
  }
  
#=============================================================================
sub validate
  {
	return;
  }

#=============================================================================
sub write_as_attributes
  {
	return [];
  }

#=============================================================================
sub write_xml
  {
    my $result = $local_false;
	
    my $self = $_[0];
	goto __END_OF_SUB if ( ref($self) eq 'HP::BaseObject' );
	
	my $xmloutput = $self->prepare_xml(@_[ 1..scalar(@_)-1 ]);
	goto __END_OF_SUB if ( not defined($xmloutput) );
	
	$result = $local_true;
	
  __END_OF_SUB:
    return ( $xmloutput, $result ) if ( wantarray() );
	return $xmloutput;
  }

#=============================================================================
sub writefile
  {
    my $result   = $local_false;
	
    my $self     = $_[0];
	my $filename = $_[1];
	
	goto __END_OF_SUB if ( &valid_string($filename) eq $local_false );
	
	$filename = &convert_path_to_client_machine($filename, 'linux');
	
	my $xmloutput = $self->write_xml();
	goto __END_OF_SUB if ( &valid_string($xmloutput) eq $local_false );

  WRITE_OUT:
    my $strDB  = &getDB('stream');
	goto __END_OF_SUB if ( not defined($strDB) );
	
	my $stream = $strDB->find_stream_by_path("$filename");
	if ( defined($stream) ) {
	  $stream->output("$xmloutput");
	} else {
	  $stream = $strDB->make_stream("$filename", OUTPUT);
	  if ( defined($stream) ) {
	    $stream->raw_output($xmloutput);
	  } else {
	    &__print_output("Unable to open << $filename >> for writing XML output!", WARN);
	  }
	}
	$strDB->remove_stream($stream->handle()) if ( defined($stream) );
	$result = $local_true;
	
  __END_OF_SUB:
	return $result;
  }

#=============================================================================
1;