package HP::Support::Object::Tools;

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
    use lib "$FindBin::Bin/../../..";

    use vars qw(
				$VERSION
				$is_debug
				$is_init

				$module_require_list
                $module_request_list

				$broken_install

                $module_callback
		
				@ISA
				@EXPORT
               );

    $VERSION  = 1.00;

	@ISA    = qw(Exporter);
    @EXPORT = qw(
				 &clone_item
				 &create_object
				 &create_instance
				 &equal
				);

    $module_require_list = {
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Module'          => undef,
							
							'HP::CheckLib'                 => undef,
						   };
    $module_request_list = {
	                       };

    $module_callback     = {};

    $is_init  = 0;
    $is_debug = (
			$ENV{'debug_support_object_tools_pm'} ||
			$ENV{'debug_support_object_modules'} ||
			$ENV{'debug_support_modules'} ||
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
sub __convert_to_structure($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $input  = $_[0] || return undef;
	my $method = $_[1] || 'new';
	
	if ( ref($input) !~ m/hash/i ) {
	  my $class = $input;
	  $input = {
	            'class' => $class,
			   };
	}
	
	my $class = $input->{'class'};
	return undef if ( not defined($class) );
	
	my $type    = exists( $input->{'use_interior_nodes'} ) ? $input->{'use_interior_nodes'} : FALSE;
	my $array   = exists( $input->{'style'} ) ? $input->{'style'}->[0] : FALSE;
	
	&__print_debug_output("DECODE RESULT :: $class --- $type --- $array", __PACKAGE__) if ( $is_debug );

    my $obj     = undef;
	my $evalstr = "use $class; \$obj = $class->$method();";
	
	&__print_debug_output("EVAL :: $evalstr", __PACKAGE__) if ( $is_debug );
	
	eval "$evalstr";
	if ( $@ ) {
	  &__print_output("Unable to instantiate object of type << $class >>\n$@", WARN);
	  return $obj;
	}
	
	$obj->{"use_interior_nodes"} = $type if ( $type eq TRUE );
	
	if ( $array ) {
	  my $array_obj = &__convert_to_structure(
	                                          { 'class' => $input->{'style'}->[1] },
											  'new'
										     );
	  $array_obj->type(&convert_from_colon_module($class));
	  $array_obj->template($obj);
	  return $array_obj;
	}
	
	return $obj;
  }

#=============================================================================
sub __create
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $input = shift || return undef;
	my ( $obj, $method ) = ( undef, 'new' );
	
	if ( ref($input) !~ m/hash/i ) {
	  $obj    = $input;
	  $method = 'new';
	} else {
	  return undef if ( not defined($input) );
      $obj    = $input->{'data'} || $input;
	  $method = $input->{'type'} || 'new';
	}
	
	my $blessed_obj = &is_blessed_obj($obj);
	
	if ( $blessed_obj eq FALSE ) {
	  my $ref_type = ref($obj);
	  if ( $ref_type =~ m/hash/i ) {
	    my @keys = keys(%{$obj});
	    foreach ( @keys ) {
		  $obj->{"$_"} = &__create($obj->{"$_"}, $method);
		}
	  } elsif ( $ref_type =~ m/^array/i ) {
	    for ( my $loop = 0; $loop < scalar(@{$obj}); ++$loop ) {
		  $obj->[$loop] = &__create($obj->[$loop], $method);
		}
	  } elsif ( $ref_type =~ m/^scalar/i ) {
	    $obj = &__create(${$obj}, $method);
	  } else {
	    my $result = &is_class_rep($obj);
	    if ( defined($result->{'class'}) ) {
		  my $specialized_method = ( $result->{'singleton'} eq TRUE ) ? 'instance' : $method;
	      $obj = &__convert_to_structure($result, $specialized_method);
	    }
	  }
	} else {
	  my $datafields = $obj->data_types();
	  foreach ( keys ( %{$datafields} ) ) {
	    my $result = &is_class_rep($obj->{"$_"});
	    if ( defined($result->{'class'}) ) {
		  my $specialized_method = ( $result->{'singleton'} eq TRUE ) ? 'instance' : $method;
	      $obj->{"$_"} = &__convert_to_structure($result, $specialized_method);
	    } else {
		  $obj->{"$_"} = &__create($obj->{"$_"}, $method);
		}
	  }
    }
	
    return $obj;
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
sub clone_item($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $orig = shift;
	return undef if ( not defined($orig) );
	
	my $copy     = undef;
	my $ref_type = ref($orig);
	my $blessed  = &is_blessed_obj($orig);
	
	&__print_debug_output("Ref type --> <$ref_type> :: Blessed --> $blessed", __PACKAGE__) if ( $is_debug );
	
	if ( $blessed eq TRUE ) {
	  my %data_fields = %{$orig};
	  my @keys = keys( %data_fields );
	  $copy = {};
	  foreach ( @keys ) {
	    if ( ( &is_blessed_obj($orig->{"$_"}) eq TRUE ) && 
		     ( &function_exists($_, 'clone') eq TRUE ) ) {
	      $copy->{"$_"} = $orig->{"$_"}->clone();  # Ask object to clone to allow for special handling
		} else {
		  $copy->{"$_"} = &clone_item($orig->{"$_"});
		}
	  }
	  bless $copy, $ref_type;
	}
	if ( $ref_type eq '' ) { $copy = $orig; }
	if ( $ref_type =~ m/^scalar/i ) {
	  &__print_debug_output("Cloning scalar reference...", __PACKAGE__) if ( $is_debug );
	  my $clone = &clone_item(${$orig});
	  $copy = \$clone;
	}
	if ( $ref_type =~ m/^array/i ) {
	  $copy = [];
	  &__print_debug_output("Cloning array reference...", __PACKAGE__) if ( $is_debug );
	  foreach ( @{$orig} ) {
	    &__print_debug_output("Cloning item --> <$_>", __PACKAGE__) if ( $is_debug );
	    if ( ( &is_blessed_obj($_) eq TRUE ) && 
		     ( &function_exists($_, 'clone') eq TRUE ) ) {
	      push ( @{$copy}, $_->clone() );  # Ask object to clone to allow for special handling
		} else {
		  push ( @{$copy}, &clone_item($_) );
		}
	  }
	}
	if ( $ref_type =~ m/hash/i ) {
	  $copy = {};
	  &__print_debug_output("Cloning hash reference...", __PACKAGE__) if ( $is_debug );
	  my @keys = keys(%{$orig});
	  foreach ( @keys ) {
	    &__print_debug_output("Cloning key --> <$_>, value --> < $orig->{$_}", __PACKAGE__) if ( $is_debug );
	    if ( ( &is_blessed_obj($orig->{"$_"}) eq TRUE ) && 
		     ( &function_exists($orig->{"$_"}, 'clone') eq TRUE ) ) {
	      $copy->{"$_"} = $orig->{"$_"}->clone();  # Ask object to clone to allow for special handling
		} else {
		  $copy->{"$_"} = &clone_item($orig->{"$_"});
		}
	  }
	}

	return $copy;
  }

#=============================================================================
sub create_object($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	return undef if ( not defined($_[0]) );
	return &__create({'data' => $_[0], 'type' => 'new'});
  }
  
#=============================================================================
sub create_instance($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	return undef if ( not defined($_[0]) );
	return &__create({'data' => $_[0], 'type' => 'instance'});
  }

#=============================================================================
sub equal($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $first  = shift;
	my $second = shift;
	
	my $result = FALSE;

	return TRUE if ( ( not defined($first) ) && ( not defined($second) ) );
	return $result if ( (not defined($first)) || (not defined($second)) );
	
	my $ref_type1 = ref($first);
	my $ref_type2 = ref($second);
	
	if ( $ref_type1 ne $ref_type2 ) { return $result; }
	
	&__print_debug_output("Ref(1) --> <$ref_type1>  :: Ref(2) --> <$ref_type2>", __PACKAGE__) if ( $is_debug );
	
	if ( &is_blessed_obj($first) eq TRUE && $ref_type1 ne '' ) {
	  my $has_method = &function_exists($ref_type1, 'equals');
	  &__print_debug_output("(HF) $has_method", __PACKAGE__) if ( $is_debug );
	  if ( $has_method eq TRUE ) {
	    $result = $first->equals($second);
	  } else {
	    $result = &equal( { %$first }, { %$second} );  # Get at contents by "unblessing" object
	  }
	} else {
	  if ( $ref_type1 eq '' ) {
	    $result = TRUE if ( $first eq $second );
	  } elsif ( $ref_type1 =~ m/^scalar/i ) {
	    $result = TRUE if ( ${$first} eq ${$second} );
	  } elsif ( $ref_type1 =~ m/^array/i ) {
	    if ( scalar(@{$first}) == scalar(@{$second}) ) {
		  $result = TRUE if ( scalar(@{$first}) == 0 );
		  for ( my $elemloop = 0; $elemloop < scalar(@{$first}); ++$elemloop ) {
		    my $new_first  = $first->[$elemloop];
		    my $new_second = $second->[$elemloop];
		    if ( $is_debug ) {
		      &__print_debug_output("Item #$elemloop", __PACKAGE__);
			  &__print_debug_output("\t$new_first\t$new_second", __PACKAGE__);
		    }
		    $result = &equal($new_first, $new_second);
			goto FINISH if ( $result eq FALSE );
		  }
		}
	  } elsif ( $ref_type1 =~ m/hash/i ) {
	    my @first_keys  = keys(%{$first});
	    my @second_keys = keys(%{$second});

	    if ( scalar(@first_keys) == scalar(@second_keys) ) {
		  $result = TRUE if ( scalar(@first_keys) == 0 );
		  foreach my $k ( @first_keys ) {
		    my $match = grep { $k } @second_keys;
		    if ( defined($match) ) {
		      my $new_first  = $first->{"$k"};
		      my $new_second = $second->{"$k"};
		      $result = &equal($new_first, $new_second);
			  goto FINISH if ( $result eq FALSE );
			}
		  }
		}
	  }
	}
	
  FINISH:
	&__print_debug_output("Match result [ <$first> | <$second> ]: $result\n") if ( $is_debug );
	return $result;
  }

#=============================================================================
&__initialize();

#=============================================================================
1;