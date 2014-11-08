package HP::BaseObject;

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

    $VERSION = 1.00;

    @EXPORT  = qw (
                  );

    $module_require_list = {
                            'B'                            => undef,
							'Storable'                     => undef,
							
							'HP::Constants'                => undef,
							'HP::Base::Constants'          => undef,
							
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::Support::Configuration'   => undef,
							
	                        'HP::CheckLib'                 => undef,
							
							'HP::Array::Tools'             => undef,
							
							'HP::Path'                     => undef,
							'HP::FileManager'              => undef,
							'HP::Utilities'                => undef,
	                       };
    $module_request_list = {};

    $is_init  = FALSE;
    $is_debug = (
                 $ENV{'debug_baseobject_pm'} ||
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

#=============================================================================
sub __data_types
  {
    my $data_fields = {
	                   &PERMIT_TAG => [],
					  };

    return $data_fields;
  }

#=============================================================================
sub __permitted_data_types
  {
    my $data_types = &__data_types();
	
	if ( not exists($data_types->{&PERMIT_TAG}) ) {
	  my $deep_copy = dclone($data_types);
	  delete($deep_copy->{&PERMIT_TAG});
	  return $deep_copy;
	}
	
	my $allowed_data_types = {};
	foreach ( @{$data_types->{&PERMIT_TAG}} ) {
	  if ( exists($data_types->{"$_"}) ) {
	    $allowed_data_types->{"$_"} = $data_types->{"$_"};
	  }
	}
	
	return $allowed_data_types;
  }

#=============================================================================
sub add_data
  {
    my $self    = $_[0];
	
	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    if ( ref($_[1]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'key',     undef,
	                                        'value',   undef,
											'builtin', undef, ], @_[ 1..scalar(@_)-1 ]);
    } else {
	  $inputdata = $_[1];
	}
	
	# No input, return FALSE exit status
    goto __END_OF_SUB if ( scalar(keys(%{$inputdata})) == 0 );
	
	my $key     = $inputdata->{'key'} || goto __END_OF_SUB;
	my $value   = $inputdata->{'value'};
	my $builtin = $inputdata->{'builtin'};
	
	$builtin = $local_true if ( &valid_string($builtin) eq $local_false );
	
	if ( &is_type($self->{"$key"}, 'HP::ArrayObject') eq $local_true ) {
	  $self->{"$key"}->add_elements({'entries' => $value});
	} else {
	  $self->{"$key"} = $value;
	}
	
	$self->update_fields("$key") if ( $builtin eq $local_false );
	return;
  }
  
#=============================================================================
sub AUTOLOAD
  {
    our $AUTOLOAD;
	
    my $self = shift;
    my $type = ref($self) || die "\$self is not an object when calling method << $AUTOLOAD >>\n";
    
    # DESTROY messages should never be propagated.
    return if $AUTOLOAD =~ /::DESTROY$/;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    unless ( defined($name) || exists($self->{$name}) ) {
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
sub clear
  {
    my $self = $_[0];
	
	$self->SUPER::clear() if ( &is_type($self, 'HP::BaseObject') eq $local_false );
	
    my $data_fields = $self->data_types( LOCAL );
	
	my @expected_fields = keys( %{$data_fields} );
	my @current_fields  = keys( %{$self} );
	
	my $diff = &set_difference(\@current_fields, \@expected_fields);
	
    foreach ( @expected_fields ) {
	  if ( &is_blessed_obj($self->{"$_"}) eq $local_true &&
	       &function_exists($self->{"$_"}, 'clear') eq $local_true ) {
		$self->{"$_"}->clear();
	  }
	  $self->{"$_"} = $data_fields->{"$_"};
	  $self->instantiate();
	}
	
	foreach ( @{$diff} ) {
	  delete($self->{$_});
	}
	
	return undef;
  }

#=============================================================================
sub clone
  {
    my $self     = $_[0];
	my $copy     = {};
	my $ref_type = ref($self);
	
	my @allfields     = keys( %{$self->data_types( LOCAL )} );
	my @allcurrfields = keys( %{$self} );
	
	my $shallowcopy = ( &function_exists($self, 'shallow_copy') ) ? $self->shallow_copy( LOCAL ) : [];
	
	my $deepcopy  = &set_difference(\@allfields, $shallowcopy);
	my $newfields = &set_difference(\@allcurrfields, \@allfields);
	
	# TODO : Need to add section for additional fields which were inserted dynamically???
	
	foreach ( @{$deepcopy} ) {
	  $copy->{"$_"} = &clone_item($self->{"$_"});
	}
	
	foreach ( @{$shallowcopy} ) {
	  $copy->{"$_"} = $self->{"$_"};
	}
	
	foreach ( @{$newfields} ) {
	  $copy->{"$_"} = &clone_item($self->{"$_"});
	}
	
	bless $copy, $ref_type;
	return $copy;
  }
  
#=============================================================================
sub data_types
  {
    my $self = $_[0];
	
	my $internal_defined = &__permitted_data_types();
	my $external_added   = [];
    $external_added      = $self->{'ADDED_FIELDS'}->get_elements() if ( defined($self->{'ADDED_FIELDS'}) );
	
	my $result = {};
	
	foreach ( @{$external_added} ) { $result->{"$_"} = $self->{"$_"}; }
	return &HP::Support::Hash::__hash_merge( $result, $internal_defined );
  }
  
#=============================================================================
sub DESTROY
  {
    my $self = $_[0];

    &__print_debug_output("Calling destructor for object ".ref($self)."\n") if ( $is_debug );
	return;
  }

#=============================================================================
sub equals
  {
    my $result = $local_false;
    my $self   = $_[0];
	my $other  = $_[1];
	
	goto __END_OF_SUB if ( &valid_string($other) eq $local_false );
	
	if ( $is_debug ) {
	  &__print_debug_output("Reference obj1 -> ". ref($self));
	  &__print_debug_output("Reference obj2 -> ". ref($other));
	}
	
	goto __END_OF_SUB if ( ref($self) ne ref($other) );
	
	# Test memory address...
	if ( &get_memory_address($self) eq &get_memory_address($other) ) {
	  $result = $local_true;
	  goto __END_OF_SUB;
	}
	
	# Test contents...
	my @first_keys  = keys( %{$self} );
	my @second_keys = keys( %{$other} );
	
    goto __END_OF_SUB if ( scalar(@first_keys) != scalar(@second_keys) );
	
	my $keydiffs = [];
	if ( scalar(@first_keys) > 0 ) {
      $keydiffs = &set_difference(\@first_keys, \@second_keys, $local_false);
	}
	
	goto __END_OF_SUB if ( scalar(@{$keydiffs}) > 0 );
	
	if ( scalar(@first_keys) == scalar(@second_keys) && scalar(@first_keys) == 0 ) {
	  $result = $local_true;
	  goto __END_OF_SUB;
	}
	
	# Test values of equal keys...
	foreach my $k ( @first_keys ) {
	  my $subresult = &equal($self->{"$k"}, $other->{"$k"});  # Recursive
	  goto __END_OF_SUB if ( $subresult eq $local_false );
    }
	
	$result = $local_true;
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub instantiate
  {
    my $self = $_[0];
	goto __END_OF_SUB if ( ref($self) eq 'HP::BaseObject' );
	
	my $data_fields = $self->data_types();

	foreach ( keys ( %{$data_fields} ) ) {
	  my $result = &is_class_rep($self->{"$_"});
	  if ( defined($result->{'class'}) ) {
		$self->add_data($_, &HP::Support::Object::Tools::__convert_to_structure($result));
	  }
    }

  __END_OF_SUB:
    return undef;	
  }
  
#=============================================================================
sub move
  {
    my $result    = $local_false;
    my $self      = $_[0];
	my $old_field = $_[1] || goto __END_OF_SUB;
	my $new_field = $_[2] || goto __END_OF_SUB;
	
	goto __END_OF_SUB if ( $old_field eq $new_field );
	my @data_fields = keys( %{$self} );
	
	goto __END_OF_SUB if ( ( &set_contains($old_field, \@data_fields) eq $local_false ) );# ||
#	                       ( &set_contains($new_field, \@data_fields) eq $local_true ) );
	
	$self->{"$new_field"} = $self->{"$old_field"};
	delete($self->{"$old_field"});
	
	$result = $local_true;
	
  __END_OF_SUB:
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
	$self->instantiate();

	foreach ( keys( %{$data_fields} ) ) {
	  push ( @{$self->{&PERMIT_TAG}}, "$_" ) if ( "$_" ne &PERMIT_TAG );
	}
	
	if ( @_ ) {
	  if ( ref($_[0]) =~ m/hash/i ) {
	    foreach my $key (keys{%{$_[0]}}) {
		  next if ( $key eq &PERMIT_TAG );
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
sub print
  {
    my $self = shift;
	return '';
  }

#=============================================================================
sub push_to_configuration
  {
    my $self = $_[0];
	my $root = $_[1];
	
	my $subroot = $self->root_property();
	if ( defined($root) ) {
	  $root .= "->$subroot" if ( defined($subroot) );
	} else {
	  $root = $subroot;
	}

	goto __END_OF_SUB if ( not defined($root) );
	
	if ( exists($self->{'get_storables'}) || &function_exists($self, 'get_storables') eq $local_true ) {
	  my $fields_to_store = $self->get_storables();
	  
	  foreach ( @{$fields_to_store} ) {
	    my $data = $self->{"$_"};
	    next if ( not defined($data) );
	    if ( &is_blessed_obj($data) eq $local_false ) {
		  my $npath = "$_";
		  $npath = "$root->$npath" if ( defined($root) );
		  $npath = &normalize_configuration_path("$npath", [ '_' ], '->' );
	      &save_to_configuration({'data' => [ "$npath", $data ]});
		  $self->{"$_"} = &get_from_configuration("$npath");
		} else {
		  if ( &is_type($data, 'HP::ArrayObject') eq $local_true ) {
		    foreach my $item ( @{$data->get_elements()} ) {
		      $item->push_to_configuration($root) if ( &function_exists($item, 'push_to_configuration') eq $local_true );
			}
		  } else {
		    $data->push_to_configuration($root) if ( &function_exists($data, 'push_to_configuration') eq $local_true );
          }		  
		}
	  }
	}
	
  __END_OF_SUB:
	return $root;
  }

#=============================================================================
sub sub_name
  {
    my $name = undef;
	my $r    = $_[0];
	
    goto __END_OF_SUB if ref($r);
    goto __END_OF_SUB unless my $cv = svref_2object( $r );
    goto __END_OF_SUB unless $cv->isa( 'B::CV' ) and my $gv = $cv->GV;
	
    $name = '';
    if ( my $st = $gv->STASH ) { 
      $name = $st->NAME . '::';
    }
	
    my $n = $gv->NAME;
	
    if ( $n ) { 
      $name .= $n;
      if ( $n eq '__ANON__' ) { 
        $name .= ' defined at ' . $gv->FILE . ':' . $gv->LINE;
      }
    }
	
  __END_OF_SUB:
    return $name;
  }

#=============================================================================
sub update
  {
    my $result = undef;
    my $self   = $_[0];
	goto __END_OF_SUB if ( ref($self) eq 'HP::BaseObject' );
	
	my $object_fields = &get_object_fields($self);
	my $array_fields  = &get_array_fields($self);
		    
	foreach ( @{$object_fields} ) {
	  if ( &is_type($self->{"$_"}, 'HP::ArrayObject') eq $local_true ) {
	    foreach my $item ( @{$self->{"$_"}->get_elements()} ) {
	      $item->update() if ( &is_blessed_obj($item) eq $local_true &&
		                       UNIVERSAL::can($item, 'update') );
	    }
		next;
	  }
	  $self->{"$_"}->update() if ( defined($self->{"$_"}) &&
	                               UNIVERSAL::can($self->{"$_"}, 'update') );
	}
	
	foreach ( @{$array_fields} ) {
	  next if ( (not defined($self->{"$_"})) || (scalar(@{$self->{"$_"}}) < 1) );
	  foreach my $item ( @{$self->{"$_"}} ) {
	    $item->update() if ( &is_blessed_obj($item) eq $local_true &&
		                     UNIVERSAL::can($item, 'update') );
	  }
	}
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub update_fields
  {
    my $result = undef;
    my $self   = $_[0];
	my $key    = $_[1] || goto __END_OF_SUB;
	
	if ( not defined($self->{'ADDED_FIELDS'}) ) {
	  $self->{'ADDED_FIELDS'} = &create_object('c__HP::Array::Set__');
	}
	$self->{'ADDED_FIELDS'}->push_item("$key");
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub validate
  {
    my $self = $_[0];
	return;
  }

#=============================================================================
1;