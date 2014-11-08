package HP::ArrayObject;

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

	use overload q{""} => 'HP::ArrayObject::print';

	use parent qw(HP::BaseObject);
	
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

    $VERSION = 1.21;

    @EXPORT  = qw (
                  );

    $module_require_list = {
	                        'HP::Constants'              => undef,
							'HP::Support::Hash'          => undef,
                            'HP::Support::Base'          => undef,
							'HP::Support::Module'        => undef,
							'HP::Support::Object'        => undef,
							'HP::Support::Object::Tools' => undef,
							'HP::CheckLib'               => undef,
							'HP::Utilities'              => undef,
							
							'HP::Array::Constants'       => undef,
							'HP::Array::Tools'           => undef,
                          };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_arrayobject_pm'} ||
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
      $cached_object = HP::ArrayObject->new() if ( not defined($cached_object) );
	}
  }
  
#=============================================================================
sub __prepare_object
  {
	my $other_obj = $_[1];
	
	if ( &is_type($other_obj, 'HP::ArrayObject') eq $local_false ) {
	  my $original_data = $_[1];
	  $other_obj = &create_object('c__HP::ArrayObject__');
	  $other_obj->add_elements({'entries' => &convert_to_array($original_data, $local_true)});
	}
	
	return $other_obj;
  }

#=============================================================================
sub __turn_off_cloning
  {
    $skip_cloning = $local_true;
	return undef;
  }

#=============================================================================
sub __turn_on_cloning
  {
    $skip_cloning = $local_false;
	return undef;
  }
  
#=============================================================================
# ---------------------------------------------------------------------
# Description :: Add elements to an array object
# Return      :: TRUE | FALSE
# ---------------------------------------------------------------------
sub add_elements
  {
	my $result = $local_false;
    my $self   = $_[0];
	
	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    if ( ref($_[1]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'entries',     undef,
	                                        'format',      \&is_integer,
											'location',    \&is_integer,
	                                        'skip_checks', undef, ], @_[ 1..scalar(@_)-1 ]);
    } else {
	  $inputdata = $_[1];
	}
	
	# No input, return FALSE exit status
    goto __END_OF_SUB if ( scalar(keys(%{$inputdata})) == 0 );
	
	my $data        = $inputdata->{'entries'};
	my $keep_format = ( not defined($inputdata->{'format'}) ) ? $local_true : $inputdata->{'format'};
	my $location    = $inputdata->{'location'} || APPEND;
	my $skip_checks = $inputdata->{'skip_checks'} || $local_false;
	
	# No data to act upon, return a FALSE exit status
	goto __END_OF_SUB if ( not defined($data) );
	
	my @items = @{$data};
	my $multiple_items = ( scalar(@items) > 0 ) ? $local_true : $local_false;
	
	$result = $local_true;
	
	# Allow nested arrays to be kept if format is "NATIVE" = TRUE
	if ( $keep_format eq $local_true ) {
	  CORE::push( @{$self->{'elements'}}, @items )    if ( $location == APPEND );
	  CORE::unshift( @{$self->{'elements'}}, @items ) if ( $location == PREPEND );
	} else {
	  foreach my $single_item (@items) {
	    my $inserted_items = &convert_to_array($single_item, $local_true);
		$self->add_elements( {'entries'     => $inserted_items,
		                      'format'      => $keep_format,
							  'location'    => $location,
		                      'skip_checks' => $skip_checks } ); # Allow for nested arrays (flattens)
	  }
	}

	# Specialization based on array type
	$self->__post_add() if ( &function_exists($self, '__post_add') eq $local_true &&
	                         $skip_checks eq $local_false );
	
 __END_OF_SUB:
	return $result;
  }

#=============================================================================
sub allocate
  {
    my $result = $local_false;
    my $self   = $_[0];
	my $size   = $_[1];
	
	goto __END_OF_SUB if ( &is_integer($size) eq $local_false );
	goto __END_OF_SUB if ( $size < 1 );
	
	my $array = $self->get_elements();
	my $numelems = scalar(@{$array});
	
	goto __END_OF_SUB if ( $numelems >= $size );
	
	$result = $local_true;
	
	$array->[$size] = undef;
	&__print_debug_output("Allocated more space for array by ". ($size - $numelems) . " elements") if ( $is_debug );
	
  __END_OF_SUB:
	return $result;
  }

#=============================================================================
sub clear_contents
  {
    my $self = $_[0];
	$self->{'elements'} = [];
	return $local_true;
  }
  
#=============================================================================
sub cloning_enabled
  {
    return ( $skip_cloning ) ? $local_false : $local_true;
  }
  
#=============================================================================
# ---------------------------------------------------------------------
# Description :: Determine if object contained in array object
# Return      :: TRUE | FALSE
# ---------------------------------------------------------------------
sub contains
  {
	my $result = $local_false;
	my $self   = $_[0];
	my $item   = $_[1];
	
    goto __END_OF_SUB if ( not defined($item) );
	
	$result = ( $self->find_instance($item) > NOT_FOUND ) ? $local_true : $local_false;
	
  __END_OF_SUB:
    return $result;
  }

#=============================================================================
# ---------------------------------------------------------------------
# Description :: Determine underlying data structure of array object
# Return      :: NONE
# ---------------------------------------------------------------------
sub data_types
  {
    my $self         = $_[0];
	my $which_fields = $_[1] || COMBINED;
	
    my $data_fields = {
		               'elements'     => [],
					   'glue'         => ' ',
					   'type'         => undef,
					   'count_marker' => $local_false,
					   'template'     => undef,
		              };
    
	# Collect all parent related fields if selected
	if ( $which_fields eq COMBINED ) {
      foreach ( @ISA ) {
	    my $parent_types = undef;
	    my $evalstr      = "\$parent_types = $_->data_types()";
	    eval "$evalstr";
		if ( ! $@ ) {
		  &__print_output("Unable to incorporate parent object < $_ > for ". __PACKAGE__, 'STDERR');
		  next;
		}
	    $data_fields     = &HP::Support::Hash::__hash_merge( $data_fields, $parent_types ) if ( defined($parent_types) );
	  }
	}
	
    return $data_fields;
  }

#=============================================================================
# ---------------------------------------------------------------------
# Description :: Delete objects in array by index location
# Return      :: TRUE | FALSE
# ---------------------------------------------------------------------
sub delete_elements_by_index
  {
	my $result = $local_false;
    my $self   = $_[0];
	my $index  = $_[1];
	
	# Nothing to do since indices are undefined
	goto __END_OF_SUB if ( not defined($index) );
	
	my $num_items = $self->number_elements();
	
	# Nothing to do since no indices provided
	goto __END_OF_SUB if ( $num_items < 1 );
	
	$result = $local_true;
	
	$index = [ $index ] if ( ref($index) eq '' );
	
	# Keep only those elements NOT defined by the removal indices
	my @indices   = @{&set_unique($index, ASCENDING_SORT)};  # One or more indices (sorted)
	my @new_array = ();
	
	for ( my $loop = 0; $loop < $num_items; ++$loop ) {
	  next if ( &set_contains($loop, \@indices) eq TRUE );
	  CORE::push( @new_array, $self->get_element($loop) );
	}
	
	$self->{'elements'} = \@new_array;
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
# ---------------------------------------------------------------------
# Description :: Delete objects in array by type
# Return      :: TRUE | FALSE
# ---------------------------------------------------------------------
sub delete_elements
  {
    my $result = $local_false;
	my $self   = shift;
    my $remove = \@_;

    goto __END_OF_SUB if ( not defined($remove) );

    my @tmp_array = &convert_to_array($remove);
	
	my $rollback = $self->get_elements();
	
	# Allow rollback if failure found in the middle of operation
    foreach (@tmp_array) {
	  my $subresult = $self->splice( $_ );
	  if ( $subresult eq $local_false ) {
	    $self->{'elements'} = $rollback;
	    goto __END_OF_SUB;
	  }
	}
	
	$result = $local_true;
  __END_OF_SUB:
	return $result;
  }

#=============================================================================
# ---------------------------------------------------------------------
# Description :: Record frequency of element types in array object
# Return      :: Hash representation of histogram
# ---------------------------------------------------------------------
sub element_frequency
  {
    my $result = 0;
	my $self   = $_[0];
	my $match  = $_[1];
	
	goto __END_OF_SUB if ( &valid_string($match) eq $local_false );
	
	my $match_idx = $self->find_all_instances($match);
	if ( ref($match_idx) eq '' ) {
	  $result = 1 if ( $match_idx != NOT_FOUND );
	  goto __END_OF_SUB;
	}
	
	$result = ( ref($match_idx) =~ m/^array/i ) ? scalar(@{$match_idx}) : 0;
	
  __END_OF_SUB:
	return $result;
  }
 
#=============================================================================
# ---------------------------------------------------------------------
# Description :: Determine if instance of object in array object
# Return      :: index of matching location or NOT_FOUND
# ---------------------------------------------------------------------
sub find_all_instances
  {
    my $self = $_[0];
	return $self->find_instance(@_[ 1..scalar(@_)-1 ], $local_true);
  }

#=============================================================================
# ---------------------------------------------------------------------
# Description :: Determine if instance of object in array object
# Return      :: index of matching location or NOT_FOUND
# ---------------------------------------------------------------------
sub find_instance
  {
    my $result  = NOT_FOUND;
    my $self    = $_[0];

	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    if ( ref($_[1]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'item',    undef,
	                                        'findall', undef, ], @_[ 1..scalar(@_)-1 ]);
    } else {
	  $inputdata = $_[1];
	}
	
	my @result = ();
	
	# No input, return FALSE exit status
    goto __END_OF_SUB if ( scalar(keys(%{$inputdata})) == 0 );
	
	my $item    = $inputdata->{'item'};
	my $findall = $inputdata->{'findall'} || $local_false;
	
	goto __END_OF_SUB if ( not defined($item) );
	
	my $LS = &create_object('c__HP::Array::SearchAlgorithms::LinearSearch__');
	
	$LS->item($item);
	$LS->arrayobject($self);
	$result = $LS->run($findall);
	
  _END_OF_SUB:
	return $result;
  }

#=============================================================================
# ---------------------------------------------------------------------
# Description :: Get element from array object at index requested
# Return      :: object within array object or undefined
# ---------------------------------------------------------------------
sub get_element
  {
	my $result = undef;

    my $self   = $_[0];
	my $idx    = $_[1];
	
	goto __END_OF_SUB if ( not defined($idx) );
	
	my $is_obj = ( &is_integer($idx) eq $local_true ) ? $local_false : $local_true;
	
	if ( $is_obj eq $local_true ) {
	  my $location = $self->find_instance($idx);
	  goto __END_OF_SUB if ( $location eq NOT_FOUND );
	  $result = $self->{'elements'}->[$location];
	} else {
	  goto __END_OF_SUB if ( $self->in_range($idx) eq $local_false );
	  $result = $self->{'elements'}->[$idx];
	}
	
  __END_OF_SUB:
    return $result;
  }
  
#=============================================================================
# ---------------------------------------------------------------------
# Description :: Get all elements from array object
# Return      :: array object elements
# ---------------------------------------------------------------------
sub get_elements
  {
    my $self      = $_[0];
	my $force_ref = $_[1] || $local_false;
	
	my @result = &convert_to_array($self->{'elements'}, $local_false);

	# Manage return types here
	my $requested_answer = wantarray();

	return @result if ( $requested_answer &&
	                    ( $force_ref eq $local_false ) );
	return \@result if ( ( $force_ref eq $local_true ) ||
	                     &valid_string($requested_answer) eq $local_false )
  }

#=============================================================================
sub get_element_at_front
  {
    my $result = undef;
    my $self   = $_[0];
	
	if ( $self->is_empty() eq $local_false ) {
	  $result = $self->get_element(0);
	}
	
	return $result;
  }
  

#=============================================================================
sub get_element_at_back
  {
    my $result = undef;
    my $self   = $_[0];
	
	if ( $self->is_empty() eq $local_false ) {
	  my $numelem = $self->number_elements();
	  $result = $self->get_element($numelem - 1);
	}
	
	return $result;
  }
  
#=============================================================================
sub in_range
  {
    my $result = $local_false;
    my $self   = $_[0];
	my $idx    = $_[1];
	
	goto __END_OF_SUB if ( &valid_string($idx) eq $local_false );
	goto __END_OF_SUB if ( &is_integer($idx) eq $local_false );
	goto __END_OF_SUB if ( $idx < 0 || $idx > $self->number_elements() );
	
	$result = $local_true;
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
# ---------------------------------------------------------------------
# Description :: Determine if array object is empty
# Return      :: TRUE or FALSE
# ---------------------------------------------------------------------
sub is_empty
  {
    my $result = $local_true;
    my $self   = $_[0];
	
	goto __END_OF_SUB if ( $self->number_elements() < 1 );
	$result = $local_false;
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
# ---------------------------------------------------------------------
# Description :: Iterate over all element in array object with method
# Return      :: NONE
# ---------------------------------------------------------------------
sub iterate
  {    
    my $self = $_[0];
	
	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    if ( ref($_[1]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'return_code_only', \&is_integer,
	                                        'transformation',   undef,
											'mutate',           \&is_integer, ], @_[ 1..scalar(@_)-1 ]);
    } else {
	  $inputdata = $_[1];
	}
	
	my @result = ();
	
	# No input, return FALSE exit status
    goto __END_OF_SUB if ( scalar(keys(%{$inputdata})) == 0 );
	
	my $collect_return_codes = $inputdata->{'return_code_only'};
	my $lambda_function      = $inputdata->{'transformation'};  # This is likely a closure
	my $mutate               = $inputdata->{'mutate'};
	$mutate = $local_true if ( not defined($mutate) );
	
	my $rclist               = ( $mutate eq $local_true ) ? $self : $self->clone();

	goto __END_OF_SUB if ( not defined($lambda_function) );
	goto __END_OF_SUB if ( ref($lambda_function) !~ m/^code/i );
	
	$collect_return_codes = $local_false if ( not defined($collect_return_codes) );
	
	# Pre-allocate size for array
	my @input = $self->get_elements();
	$result[scalar(@input) - 1] = undef;
	
	for ( my $loop = 0; $loop < scalar(@input); ++$loop ) {
	  $result[$loop] = $lambda_function->($input[$loop]);
	}
		
  __END_OF_SUB:
	return \@result if ( $collect_return_codes eq $local_true );
	
	$rclist->replace_elements(\@result);
	return $rclist;
  }
  
#=============================================================================
# ---------------------------------------------------------------------
# Description :: Combine two array objects
# Return      :: NONE
# ---------------------------------------------------------------------
sub merge
  {
    my $result   = $local_false;
    my $self     = $_[0];
	my $otherobj = $_[1];
	
	goto __END_OF_SUB if ( &is_type($otherobj, 'HP::ArrayObject') eq $local_false );
	
	my $count = $otherobj->number_elements();
	
	$result = $local_true;
	
	goto __END_OF_SUB if ( $count == 0 );
	
	my $data = $otherobj->get_elements();
	$self->add_elements({'entries' => $data});
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub new
  {
    my $class = shift;
	my $self  = undef;

	if ( ref($_[0]) =~ m/hash/i ) {
	  if ( exists($_[0]->{&ARRAY_SKIP_CLONE_OPTION}) ) {
	    $skip_cloning = $_[0]->{&ARRAY_SKIP_CLONE_OPTION};
		delete($_[0]->{&ARRAY_SKIP_CLONE_OPTION});
		shift (@_) if ( scalar(keys(%{$_[0]})) < 1 );
	  }
	}
	
	# Ask the cached object container to clone a matching object otherwise
	# go through the construction process.
	if ( $skip_cloning eq $local_false ) {
	  if ( defined($HP::ArrayObject::cached_object) ) {
	    $self = $HP::ArrayObject::cached_object->clone();
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
	$HP::ArrayObject::cached_object = $self if ( not defined($HP::ArrayObject::cached_object) );
	
  UPDATE:
	if ( @_ ) {
	  if ( ref($_[0]) =~ m/hash/i ) {
	    foreach my $key (keys{%{$_[0]}}) {
		  $self->{"$key"} = $_[0]->{"$key"} if ( exists($self->{"$key"}) );
		}
	  } else {
	    &__print_output("Please use a hash as input to construct this class < $class >", 'STDERR');
	  }
	}

    return $self;
  }

#=============================================================================
# ---------------------------------------------------------------------
# Description :: Determine number of elements in array object
# Return      :: number of elements
# ---------------------------------------------------------------------
sub number_elements
  {
    my $self = $_[0];
	
	$self->{'elements'} = [] if ( not defined($self->{'elements'}) );
	return scalar(@{$self->{'elements'}});
  }

#=============================================================================
sub print
  {
    my $self        = $_[0];
	my $indentation = $_[1] || '';
	
	my $result   = '';
	my $numelems = $self->number_elements();
	
	$result .= &print_object_header($self, $indentation) ."\n\n";
	$result .= &print_string($numelems, 'Number of Elements', $indentation) ."\n";
	$result .= &print_string($self->glue(), 'Glue', $indentation) ."\n";
	
	if ( $numelems < 1 ) {
	  $result .= $indentation ."Elements           : NONE \n";
	} else {
	  $result .= $indentation ."Elements           :\n";
  	  my $counter = 1;
	  foreach ( @{$self->get_elements()} ) {
	    if ( &is_blessed_obj($_) eq $local_false ) {
	      $result .= &print_string($_, "$counter)", $indentation."\t") ."\n"; 
		} else {
		  if ( &function_exists($_, 'print') eq $local_true ) {
		    my $subitemprint = $_->print($indentation . "\t");
		    $result .= &print_string($subitemprint, "$counter)", $indentation."\t") ."\n";
		  }
		}
	    ++$counter;
	  }
	}
	
	my $uppercontent = $self->SUPER::print($indentation, @_);
	$result .= $uppercontent if ( defined($uppercontent) );
	return $result;
  }

#=============================================================================
# ---------------------------------------------------------------------
# Description :: Add single element to array object
# Return      :: TRUE or FALSE
# ---------------------------------------------------------------------
sub push
  {
    my $self   = $_[0];
	my $result = $local_true;
	
	foreach ( @_[ 1..scalar(@_)-1 ] ) {
	  $result = $result && $self->push_item($_);
	}
	return $result;
  }

#=============================================================================
# ---------------------------------------------------------------------
# Description :: Add single element to array object
# Return      :: TRUE or FALSE
# ---------------------------------------------------------------------
sub push_item
  {
    my $result       = $local_false;
    my $self         = $_[0];

	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    if ( ref($_[1]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'item',     undef,
	                                        'location', undef, ], @_[ 1..scalar(@_)-1 ]);
    } else {
	  $inputdata = $_[1];
	}
	
	my @result = ();
	
	# No input, return FALSE exit status
    goto __END_OF_SUB if ( scalar(keys(%{$inputdata})) == 0 );
	
	my $item     = $inputdata->{'item'};
	my $location = $inputdata->{'location'};

	$location = APPEND if ( &valid_string($location) eq $local_false );
	goto __END_OF_SUB if ( &is_integer($location) eq $local_false );
	
	my $num_elements = $self->number_elements();
	
	if ( $location eq APPEND ) {
	  $location = $num_elements + 1;
	} elsif ( $location eq PREPEND ) {
	  $location = 1;
	} else {
	  if ( $location < 0 ) { $location = abs($location); }
	  if ( $location == 0 ) { $location = 1; }
	}
	
	$result = $local_true;
	
	if ( $location == $num_elements + 1 ) {
	  CORE::push( @{$self->{'elements'}}, $item );
	  goto __END_OF_SUB;
	} elsif ( $location == 1 ) {
	  unshift( @{$self->{'elements'}}, $item );
	  goto __END_OF_SUB;
	}
	
	my $data = $self->{'elements'};
	my @temp_set_1 = splice( @{$data}, $location - 1, $num_elements );

    CORE::push( @{$data}, $item, @temp_set_1 );

	$self->{'elements'} = $data;
	
  __END_OF_SUB:
	return $result;
  }

#=============================================================================
sub replace_elements
  {
    my $self    = $_[0];
	my $newdata = $_[1];
	
	my $elements = $self->get_elements();
	
	$self->clear_contents();
	my $result = $self->add_elements({'entries'     => $newdata,
	                                  'skip_checks' => $local_true});
									  
	# Don't destroy array if addition fails.  Revert back to old
	$self->{'elements'} = $elements if ( $result eq $local_false );
	return $result;
  }
  
#=============================================================================
# ---------------------------------------------------------------------
# Description :: Replace element in array object at specified index
# Return      :: TRUE or FALSE
# ---------------------------------------------------------------------
sub set_element
  {
    my $result = $local_false;
    my $self   = $_[0];

	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    if ( ref($_[1]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'index', \&is_integer,
	                                        'item',  undef, ], @_[ 1..scalar(@_)-1 ]);
    } else {
	  $inputdata = $_[1];
	}
	
	my @result = ();
	
	# No input, return FALSE exit status
    goto __END_OF_SUB if ( scalar(keys(%{$inputdata})) == 0 );
	
	my $idx  = $inputdata->{'index'};
	my $item = $inputdata->{'item'};

	goto __END_OF_SUB if ( not defined($idx) );
	goto __END_OF_SUB if ( &is_integer($idx) eq $local_false );
	goto __END_OF_SUB if ( $self->in_range($idx) eq $local_false );
	
	$result = $local_true;
	$self->{'elements'}->[$idx] = $item;
	
  __END_OF_SUB:
	return $result;
  }

#=============================================================================
sub should_add_count_marker
  {
    my $self = $_[0];
	my $toggled_value = ! $self->count_marker();
    return $toggled_value;
  }
  
#=============================================================================
sub skip_fields
  {
    my $self     = $_[0];
	my $specific = [ 'type', 'template', 'count_marker' ];

	$specific    = &set_union($specific, $self->SUPER::skip_fields());
	return $specific;
  }

#=============================================================================
# ---------------------------------------------------------------------
# Description :: Sort elements in array object
# Return      :: NONE
# ---------------------------------------------------------------------
sub sort
  {
	my $self          = $_[0];
	my $sort_criteria = $_[1] || $self->{'sort_method'};

	my ( $module, $routine ) = &module_routine($sort_criteria) if ( defined($sort_criteria) );
	
	my @data = $self->get_elements();
	if ( ( defined($sort_criteria) ) &&
	     ( &function_exists($module, $routine) eq $local_true ) ) {
	  @data = sort $sort_criteria ( @data );
	} else {
	  @data = sort { $a cmp $b } ( @data );
	}
	$self->{'elements'} = \@data;
	return $local_true;
  }
  
#=============================================================================
# ---------------------------------------------------------------------
# Description :: Excise elements within an array object
# Return      :: NONE
# ---------------------------------------------------------------------
sub splice
  {
    my $result       = $local_false;
    my $self         = $_[0];
	my $removal_item = $_[1];
	
	return $result if ( &valid_string($removal_item) eq $local_false );
	
	my $entry_id = $self->find_instance( $removal_item );
	
	while ( $entry_id ne NOT_FOUND ) {	
	  $result = $local_true;
	  if ( $entry_id == 0 ) {
	    shift (@{$self->{'elements'}});
	    goto CHECK_ENTRY;
	  } elsif ( $entry_id == $self->number_elements() ) {
	    pop ( @{$self->{'elements'}} );
	    goto CHECK_ENTRY;
	  }
	
	  splice( @{$self->{'elements'}}, $entry_id, 1 );
	CHECK_ENTRY:
	  $entry_id = $self->find_instance( $removal_item );
	}
	
	return $result;
  }
  
#=============================================================================
&__initialize();
1;