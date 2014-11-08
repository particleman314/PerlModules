package HP::Array::Set;

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

	use overload q{""} => 'HP::Array::Set::print';

	use parent qw(HP::ArrayObject);
	
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

    @EXPORT  = qw ();

    $module_require_list = {
	                        'HP::Constants'              => undef,
							'HP::Support::Base'          => undef,
							'HP::Support::Hash'          => undef,
							'HP::Support::Module'        => undef,
							'HP::Support::Object'        => undef,
							'HP::Support::Object::Tools' => undef,
							
							'HP::Array::Constants'       => undef,
							'HP::Array::Tools'           => undef,

							'HP::CheckLib'               => undef,
							'HP::Utilities'              => undef,
                          };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_array_set_pm'} ||
				 $ENV{'debug_array_modules'} ||
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
sub __post_add
  {
    my $self = $_[0];
	$self->__unique();
	$self->sort();
	return;
  }
  
#=============================================================================
sub __run
  {
    my $self = $_[0];
	
	my $inputdata = {};
    if ( ref($_[1]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'type', \&valid_string,
	                                        'setA', undef,
											'setB', undef ], @_[ 1..scalar(@_)-1 ]);
    } else {
	  $inputdata = $_[1];
	}
	
	my $emptyset = &create_object('c__HP::Array::Set__');
	
    return $emptyset if ( scalar(keys(%{$inputdata})) == 0 );

	my $type = $inputdata->{'type'};
	my $setA = $inputdata->{'setA'};
	my $setB = $inputdata->{'setB'};
	
	return $emptyset if ( not defined($setA) );
	
	my $engine = &create_object('c__HP::Array::ArrayOperators::'.$type.'__');
	return $emptyset if ( not defined($engine) );
	
	my $result = $engine->run($setA, $setB);
	
	return ( defined($result) ) ? $result : $emptyset;
  }

#=============================================================================
sub __unique
  {
    my $self = $_[0];
  	my $uniq_elems = &HP::Array::Tools::__unique($self->get_elements($local_true));
	$self->replace_elements($uniq_elems);
	return;
  }
  
#=============================================================================
sub data_types
  {
    my $self         = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
	                   'sort_method' => LEXIOGRAPH_SORT,
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
# ---------------------------------------------------------------------
# Description :: Delete objects in array by index location
# Return      :: TRUE | FALSE
# ---------------------------------------------------------------------
sub delete_elements_by_index
  {
    my $self        = $_[0];
	my $index       = $_[1];
	my $skip_checks = $_[2] || $local_false;
	
	# Nothing to do since indices are undefined
	return $local_false if ( not defined($index) );
	my $num_items = $self->number_elements();
	
	# Nothing to do since no indices provided
	return $local_false if ( $num_items < 1 );
	
	# Keep only those elements NOT defined by the removal indices
	my @indices  = @{&set_unique($index, DESCENDING_SORT)};  # One or more indices (sorted and reversed in order)!!!
	
	my $reduced_num_items = $num_items;
	while ( scalar(@indices) > 0 ) {
	  my $testidx = shift(@indices);
	  next if ( $testidx < 0 || $testidx > $num_items );
	  &swap($self->{'elements'}, $testidx, $reduced_num_items - 1);
	  --$reduced_num_items;
	}
	
	splice($self->{'elements'}, $reduced_num_items, $num_items - $reduced_num_items);
	$self->__post_add() if ( &function_exists($self, '__post_add') eq $local_true &&
	                         $skip_checks eq $local_false );
	
	return $local_true;
  }
  
#=============================================================================
sub difference
  {
    my $self      = $_[0];
	return $self->__run({ 'type' => 'DifferenceEngine',
	                      'setA' => $self,
						  'setB' => $_[1] });
  }
  
#=============================================================================
sub find_instance
  {
    my $self = $_[0];
	my $item = $_[1];
		
	return NOT_FOUND if ( not defined($item) );
	
	if ( defined($self->{'sort_method'}) ) {
	  if ( $self->sort_method() eq LEXIOGRAPH_SORT ||
	       $self->sort_method() eq OBJECT_SORT ) {
	    return $self->SUPER::find_instance($item);	 
	  }
	}
	
	if ( not exists($self->{'sort_object'}) ) {;
	  my $BS = &create_object('c__HP::Array::SearchAlgorithms::BinarySearch__');
	  $self->{'sort_object'} = $BS;
	}
	$self->{'sort_object'}->item($item);
	$self->{'sort_object'}->arrayobject($self);
	return $self->{'sort_object'}->run();
  }

#=============================================================================
sub intersect
  {
    my $self = $_[0];
	return $self->__run({ 'type' => 'IntersectEngine',
	                      'setA' => $self,
						  'setB' => $_[1] });
  }
  
#=============================================================================
sub new
  {
    my $class = shift;
	my $self  = undef;

    my $data_fields = &data_types();

    $self = {
		     %{$data_fields},
	        };
	
    bless $self, $class;
	$self->instantiate();
	
	if ( @_ ) {
	  if ( ref($_[0]) =~ m/hash/i ) {
	    foreach my $key (keys{%{$_[0]}}) {
		  $self->{"$key"} = $_[0]->{"$key"} if ( exists($self->{"$key"}) );
		}
	  } else {
	    &__print_output("Please use a hash as input to construct this class < $class >", 'STDERR');
	  }
	}

	$self->__unique();
    return $self;
  }

#=============================================================================
sub print
  {
    my $self        = $_[0];
	my $indentation = $_[1] || '';
	
	my $result = $self->SUPER::print($indentation, @_[ 2..scalar(@_)-1 ]);
	$result .= &print_string($self->sort_method, 'Sorting Algorithm', $indentation) ."\n";
	return $result;
  }

#=============================================================================
sub push_item
  {
    my $self = $_[0];
	
	my $data       = $_[1];
	my $location   = $_[2] || APPEND;
	my $multi_item = $_[3] || $local_false;
	
	my $result = $self->SUPER::push_item($data, $location, $multi_item);
	if ( ref($data) ne '' ) {
	  $self->sort_method(OBJECT_SORT) if ( $self->{'sort_method'} ne OBJECT_SORT ) 
	}
	
	$self->__post_add() if ( $multi_item eq $local_false );
	
	return $result;
  }
  
#=============================================================================
sub sort
  {
	my $self = $_[0];
	$self->SUPER::sort(@_[ 1..scalar(@_)-1 ]);
	return;
  }

#=============================================================================
sub symmetric_difference
  {
    my $self = $_[0];
	return $self->__run({ 'type' => 'SymmetricDifferenceEngine',
	                      'setA' => $self,
						  'setB' => @_[ 1..scalar(@_)-1 ] });
  }


#=============================================================================
sub union
  {
    my $self = $_[0];
	return $self->__run({ 'type' => 'UnionEngine',
	                      'setA' => $self,
						  'setB' => @_[ 1..scalar(@_)-1 ] });
  }

#=============================================================================
1;