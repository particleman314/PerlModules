package HP::Array::Tools;

################################################################################
# Copyright (c) 2014 HP.   All rights reserved
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

	@ISA  = qw(Exporter);
    @EXPORT      = qw (
	                   &convert_to_array
					   &flatten
					   &is_array_type
					   &is_disjoint
					   &is_proper_subset
					   &is_subset
					   &set_contains
					   &set_difference
					   &set_intersect
					   &set_symmetric_difference
					   &set_unique
					   &set_union
					   
					   &sum_array
					  );

    $module_require_list = {
	                        'HP::Constants'                   => undef,
							
							'HP::Support::Base'               => undef,
							'HP::Support::Base::Constants'    => undef,
							'HP::Support::Object'             => undef,
							'HP::Support::Object::Tools'      => undef,
							
							'HP::CheckLib'                    => undef,
							
							'HP::Array::Constants'            => undef,
							'HP::ExceptionManager'            => undef,
							
                          };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_array_tools_pm'} ||
				 $ENV{'debug_arrays_modules'} ||
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
sub __ascending_numerical_sort($$)
  {
    return $_[0] <=> $_[1];
  }
  
#=============================================================================
sub __descending_numerical_sort($$)
  {
    return $_[1] <=> $_[0];
  }

#=============================================================================
sub __initialize()
  {
    if ( not $is_init ) {
      $is_init = 1;
	  
	  if ( &__load_exceptions_into_DB(&__predefined_exceptions()) eq FALSE ) {
	    &__print_output("Unable to access exception DB or register array exceptions (partial or full)!", WARN);
	  }
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
sub __load_exceptions_into_DB(;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $result = TRUE;
	my $edata  = $_[0];
	return if ( not defined($edata) );
	
	#&__print_output("Registering array exceptions...", INFO);
	&store_exception_data('array', $edata);
	return $result;
	
	#foreach ( keys(%{$edata}) ) {
	#  my $data = $edata->{$_};
	#  &__print_debug_output("Registering exception :: Name = $_, EID = ". $data->[0] .", Classification = ". $data->[1],__PACKAGE__) if ( $is_debug );

	#  my $insertion = &add_exception_mapping({ 'name' => $_, 'number' => $data->[0], 'class' => $data->[1] });
	#  if ( $insertion eq FALSE ) {
	#    &__print_output("Unable to install << ".$data->[1]." >> exception type!", WARN);
	#	$result = FALSE;
	#  }
	#}
	
	#return $result;
  }
  
#=============================================================================
sub __load_exceptions_into_DB_from_xml($)
  {
    # TO DO : Read xml to generate exception data for incorporation
	# &__load_exceptions_into_DB($xmlconvert_data);
  }
  
#=============================================================================
sub __lexiographical_sort($$)
  {
    return $_[0] cmp $_[1];
  }
  
#=============================================================================
sub __object_sort($$)
  {
    return ref($_[1]) cmp ref($_[0]);
  }
  
#=============================================================================
sub __predefined_exceptions()
  {
    return {
	        'array_storage'         => [ undef, 'HP::Array::Exceptions::ArrayStorageException' ],
	        'index_outofbounds'     => [ undef, 'HP::Array::Exceptions::IndexOutOfBoundsException' ],
	        'negative_array_size'   => [ undef, 'HP::Array::Exceptions::NegativeArraySizeException' ],
	        'no_array_object'       => [ undef, 'HP::Array::Exceptions::NoArrayObjectException' ],
	        'no_such_element'       => [ undef, 'HP::Array::Exceptions::NoSuchElementException' ],
	        'set_operation_failure' => [ undef, 'HP::Array::Exceptions::SetOperationFailureException' ],
	       };
  }
  
#=============================================================================
sub __prepare_sets($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $dataA = $_[0];
	my $dataB = $_[1];
	
	my $as_obj = $_[2] ||
	             ( (&is_array_type($dataA) eq TRUE) && (&is_array_type($dataB) eq TRUE) ) ||
				 FALSE;

	my $sort_type = $_[3];
	
	my $setA   = &__set_conversion($dataA, $sort_type);
	my $setB   = &__set_conversion($dataB, $sort_type);
				 
	return ($setA, $setB, $as_obj);
  }
  
#=============================================================================
sub __set_conversion($;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $set = $_[0];
	return &create_object('c__HP::Array::Set__') if ( not defined($set) );

	if ( &is_type($set, 'HP::Array::Set') eq FALSE ) {
	  my $setdata = &convert_to_array($set, TRUE);
	  $set = &create_object('c__HP::Array::Set__');
	  $set->sort_method($_[1]) if ( defined($_[1]) );
	  $set->add_elements({'entries' => $setdata});
	}

	return $set;
  }
  
#=============================================================================
sub __set_debug($)
  {
    if ( $_[0] eq TRUE ) {
	  $is_debug = TRUE;
	  eval "use Data::Dumper;";
	  eval "\$Data::Dumper::Sortkeys = 1;";
	}
  }
  
#=============================================================================
sub __unique
  {
    my @result = ();
    return \@result if ( not defined($_[0]) || ref($_[0]) !~ m/^array/i );
	
    my @a = @{$_[0]};
	return $_[0] if ( scalar(@a) <= 1 );
	
    my %temp   = ();

    foreach ( @a ) {
	  if ( &is_blessed_obj($_) eq TRUE ) {
	    my $found_ref = FALSE;
	    foreach my $k (keys(%temp)) {
		  if ( &equal($k, ref($_)) eq TRUE ) {
		    my $found = FALSE;
		    foreach my $item ( @{$temp{$k}} ) {
			  if ( &equal($item, $_) eq TRUE ) {
			    $found = TRUE;
				last;
			  }
			}
			push( @{$temp{$k}}, $_ ) if ( $found eq FALSE );
			$found_ref = TRUE;
			last;
		  }
		}
		
		if ( $found_ref eq FALSE ) {
		  $temp{ref($_)} = [];
		  push( @{$temp{ref($_)}}, $_ );
		  push( @result, $temp{ref($_)} );
		}
	  } else {
	    next if ( not defined($_) );
        ++$temp{$_};
        push( @result, $_ ) if ( $temp{$_} < 2 );
	  }
    }

	@result = &flatten(\@result);
	return \@result;
  }

#=============================================================================
sub convert_to_array($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    my $listref      = $_[0];

    my $as_ref       = FALSE;
    my $hashordering = 'kvpair';

    if ( scalar(@_) > 1 ) { $as_ref = $_[1]; }
    if ( scalar(@_) > 2 ) { $hashordering = lc($_[2]); }

    &__print_debug_output("Using hashordering method --> << $hashordering >>", __PACKAGE__) if ( $is_debug );

    my @tmpArray = ();

    if ( not defined($listref) ) {
      if ( not $as_ref ) { 
        return @tmpArray;
      } else {
        return \@tmpArray;
      }
    }

    if ( ref($listref) eq '' ) {
      push( @tmpArray, $listref );
    } elsif ( ref($listref) =~ m/^scalar/i ) {
      push( @tmpArray, ${$listref} );
    } elsif ( ref($listref) =~ m/^array/i ) {
      @tmpArray = @{$listref};
    } elsif ( ref($listref) =~ m/hash/i ) {
      my @keys   = keys(%{$listref});
      my @values = values(%{$listref});
      if ( $hashordering =~ m/kvpair/i ) {
	    for (my $loop = 0; $loop < scalar(@keys); ++$loop ) {
	      push( @tmpArray, $keys[$loop], $values[$loop] );
	    }
      } else {
	    push( @tmpArray, @keys, @values );
      }
	} elsif ( &is_type($listref, 'HP::ArrayObject') eq TRUE ) {
	  @tmpArray = @{$listref->get_elements()};
    }

    if ( $as_ref eq FALSE ) {
      return @tmpArray;
    } else {
      return \@tmpArray;
    }  
  }

#=============================================================================
sub flatten($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $listref = $_[0];
    my $as_ref  = FALSE;

    if ( scalar(@_) > 1 ) { $as_ref = $_[1]; }

    my @tmpArray = ();
    if ( not defined($listref) ) {
      if ( not $as_ref ) { 
        return @tmpArray;
      } else {
        return \@tmpArray;
      }
    }

    if ( ref($listref) eq '' || &is_blessed_obj($listref) eq TRUE ) {
      push( @tmpArray, $listref );
    } elsif ( ref($listref) =~ m/^scalar/i ) {
      push( @tmpArray, ${$listref} );
    } elsif ( ref($listref) =~ m/^array/i ) {
	  foreach ( @{$listref} ) {
	    push (@tmpArray, &flatten($_, FALSE));
	  }
	} elsif ( ref($listref) =~ m/hash/i ) {
	  foreach ( keys(%{$listref}) ) {
	    push (@tmpArray, &flatten($listref->{"$_"}, FALSE));
	  }
	}
	
    if ( $as_ref eq FALSE ) {
      return @tmpArray;
    } else {
      return \@tmpArray;
    }  
  }
  
#=============================================================================
sub is_array_type($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $result = FALSE;
    return $result if ( not defined($_[0]) );
	
	$result = &is_type($_[0], 'HP::ArrayObject' );
	return $result;
  }

#=============================================================================
sub is_disjoint($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	return FALSE if ( scalar(@_) < 2 );
	
	my ($setA, $setB, $as_obj) = &__prepare_sets(@_);
	
	# Is set A disjoint from set B -- no elements in common whatsoever...
	return TRUE if ( $setA->number_elements() == 0 );
	
	return FALSE if ( $setA->equals($setB) eq TRUE );
	
	my $setR1 = &set_difference($setA, $setB, TRUE);
	my $setR2 = &set_difference($setB, $setA, TRUE);
	
	return TRUE if ( $setR1->equals($setA) && $setR2->equals($setB) );
	return FALSE;
  }
  
#=============================================================================
sub is_proper_subset($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	return FALSE if ( scalar(@_) < 2 );
	
	my ($setA, $setB, $as_obj) = &__prepare_sets(@_);
	
	my $subset_result = &is_subset($setA, $setB);
	if ( $subset_result eq TRUE ) {
	  my $setR = &set_difference($setA, $setB, TRUE);  # A - B
	
 	  return FALSE if ( $setA->number_elements() == $setB->number_elements() );
	}
	
	return $subset_result;
  }
  
#=============================================================================
sub is_subset($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	return FALSE if ( scalar(@_) < 2 );
	
	my ($setA, $setB, $as_obj) = &__prepare_sets(@_);
	
	# Is set A a subset of set B -- proper subset rules apply with addition A = B
	my $setR = &set_difference($setA, $setB, TRUE);  # A - B
	
	return FALSE if ( $setR->number_elements() > 0 );
	return TRUE;
  }
  
#=============================================================================
sub set_contains($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	return FALSE if ( scalar(@_) < 2 );
  
	my $item    = shift;
	my $set     = &__set_conversion(shift);
	
	return $set->contains($item);
  }

#=============================================================================
sub set_difference($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
 
	my $setR = &create_object('c__HP::Array::Set__');
	if ( scalar(@_) < 2 ) { return $setR; }
	
	my ($setA, $setB, $as_obj) = &__prepare_sets(@_);
	
	if ( $setA->sort_method() eq $setB->sort_method() ) {
	  $setR->sort_method($setA->sort_method());
	}
	
    my @A_elems = $setA->get_elements();
	my @B_elems = $setB->get_elements();

	goto FINISH if ( scalar(@A_elems) == 0 );

	$setR->add_elements({'entries' => \@A_elems});

	my $remove_indices = [];
    foreach ( @B_elems ) {
	  my $result = $setA->find_instance($_);
	  push( @{$remove_indices}, $result ) if ( $result ne NOT_FOUND );
	}
	
	$setR->delete_elements_by_index($remove_indices) if ( scalar(@{$remove_indices}) > 0 );
		
  FINISH:
	return $setR if ( $as_obj eq TRUE );
	return $setR->get_elements();
  }
  
#=============================================================================
sub set_intersect($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $setR = &create_object('c__HP::Array::Set__');
	if ( scalar(@_) < 2 ) { return $setR; }

	my ($setA, $setB, $as_obj) = &__prepare_sets(@_);
	
    my @A_elems = $setA->get_elements();
	my @B_elems = $setB->get_elements();

    goto FINISH if ( scalar(@A_elems) == 0 || scalar(@B_elems) == 0 );

    my %hash  = ();

	my @tmpArray = ();
	push( @tmpArray, @A_elems, @B_elems );

    foreach ( @tmpArray ) { ++$hash{$_}; }

    my @result = ();

    foreach ( keys %hash ) {
      push( @result, $_ ) if ( $hash{$_} > 1 );
    }
	
	$setR->{'elements'} = \@result;
	
  FINISH:
	return $setR if ( $as_obj eq TRUE );
	return $setR->get_elements();
  }

#=============================================================================
sub set_symmetric_difference($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $setR = &create_object('c__HP::Array::Set__');
	if ( scalar(@_) < 2 ) { return $setR; }

	my ($setA, $setB, $as_obj) = &__prepare_sets(@_);
	my $AdiffB = &set_difference($setA, $setB, TRUE);
	my $BdiffA = &set_difference($setB, $setA, TRUE);
	
	$setR = &set_union($AdiffB, $BdiffA, TRUE);
	
  FINISH:
	return $setR if ( $as_obj eq TRUE );
	return $setR->get_elements();
  }

#=============================================================================
sub set_unique($;$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $setR = &create_object('c__HP::Array::Set__');
	if ( scalar(@_) < 1 ) { return $setR; }
	
	$setR->sort_method($_[1]) if ( defined($_[1]) );
	$setR->add_elements({'entries' => $_[0]});
	
  FINISH:
	return $setR->get_elements();
  }
  
#=============================================================================
sub set_union($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $setR = &create_object('c__HP::Array::Set__');
	if ( scalar(@_) < 2 ) { return $setR; }

	my ($setA, $setB, $as_obj) = &__prepare_sets(@_);
	
    my @A_elems = $setA->get_elements();
	my @B_elems = $setB->get_elements();

    goto FINISH if ( scalar(@A_elems) == 0 && scalar(@B_elems) == 0 );

	my @tmpArray = ();
	push( @tmpArray, @A_elems, @B_elems );

    my %union;
	
    foreach ( @tmpArray ) { ++$union{$_}; }

    my @results = keys(%union);
	
	$setR->add_elements( {'entries' => \@results} );
	
  FINISH:
	return $setR if ( $as_obj eq TRUE );
	return $setR->get_elements();
  }

#=============================================================================
sub sum_array(@)
  {
    my $total = 0;
    foreach ( @_ ) {
	  my $array = &convert_to_array($_, TRUE);
	  foreach my $element (@{$array}) {
	    $total += $element if ( &is_numeric($element) eq TRUE );
	  }
	}
	
	return $total;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;