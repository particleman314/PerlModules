package HP::Support::Object;

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
    use lib "$FindBin::Bin/../..";

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

    $VERSION    = 1.00;

	@ISA    = qw(Exporter);
    @EXPORT = qw(
				 &get_array_fields
				 &get_fields
				 &get_object_fields
				 &get_template_obj
				 &transfer_data
				);

    $module_require_list = {
							'HP::Constants'                  => undef,
							'HP::Support::Base'              => undef,
							'HP::Support::Base::Constants'   => undef,
							'HP::Support::Module'            => undef,
							'HP::Support::Object::Constants' => undef,
							'HP::Support::Object::Tools'     => undef,
							
							'HP::CheckLib'                   => undef,
							
							'HP::Array::Tools'               => undef,
						   };
    $module_request_list = {
	                       };

    $module_callback     = {};

    $is_init  = 0;
    $is_debug = (
			$ENV{'debug_support_object_pm'} ||
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
my $local_true    = TRUE;
my $local_false   = FALSE;

my $local_pass    = PASS;
my $local_fail    = FAIL;

#=============================================================================
sub __cleanup_internals($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $obj = $_[0];
    goto __END_OF_SUB2 if ( not defined($obj) );
	
	&__print_debug_output("Using object type --> ". ref($obj), __PACKAGE__) if ( $is_debug );
	
	my $internal_fields   = $_[1];
	my $additional_method = $_[2];
	
	if ( (not defined($internal_fields)) &&
	     ( (&is_blessed_obj($obj) eq $local_true) && &function_exists($obj, 'skip_fields') eq $local_true ) ) {
	  $internal_fields = $obj->skip_fields();
	}
	
	my $fields        = &get_fields($obj, $local_false);
	my $fixed_fields  = 0;
		
	$fields = &set_difference($fields, $internal_fields);  # Could be objects or standard PERL arrays
	my $number_fields = scalar(@{$fields});
	my $control_data  = {};
	
	foreach ( @{$fields} ) {
	
	  &__print_debug_output("Analyzing field :: $_", __PACKAGE__) if ( $is_debug );
	  
	  if ( defined($additional_method) && exists($additional_method->{$_}) ) {
		my $method_locale = OBJECT;
		my $method_name   = $additional_method->{$_};
		
	    if ( ref($additional_method->{"$_"}) =~ m/^array/i ) {
		  $method_locale = $additional_method->{$_}->[0];
		  my $method_module = $additional_method->{$_}->[1];
		  if ( &has($method_module) eq $local_false ) {
		    my $evalstr = "use $method_module;";
			eval "$evalstr";
			if ( $@ ) {
			  &__print_output("Unable to load << $method_module >>!", WARN);
			  next;
			}
		  }
		  $method_name   = "$method_module".'::'.$additional_method->{$_}->[2];
		}
		
	    my $method_result = $local_false;
		my $evalstr = undef;
		if ( $method_locale eq OBJECT ) {
	      $evalstr = "\$method_result = \$obj->$method_name(\$obj->{$_});";
		} else {
	      $evalstr = "\$method_result = &$method_name(\$obj, \"$_\");";
		}
		eval "$evalstr";
		if ( $@ ) {
		  &__print_output("Unable to call method [ $method_name ].  Attempted to call << $evalstr >>\nError condition --> $@", WARN);
		}
		if ( $method_result eq $local_true ) {
		  delete($obj->{$_});
		  ++$fixed_fields;
		  &__print_debug_output("Special method called and resulted in cleansing [ $_ | $fixed_fields | $number_fields ]", __PACKAGE__) if ( $is_debug );
		}
      } elsif ( &is_blessed_obj($obj->{$_}) eq $local_true ) {
	    if ( &function_exists($obj->{$_}, 'cleanup_internals') eq $local_true ) {
		  if ( $obj->{$_}->cleanup_internals($internal_fields, $additional_method) eq $local_fail ) {
            delete($obj->{$_});
		    ++$fixed_fields;
		    &__print_debug_output("Object method called and resulted in cleansing [ $_ | $fixed_fields | $number_fields ]", __PACKAGE__) if ( $is_debug );
		  }
		} else {
		  if ( &__cleanup_internals($obj->{$_}, $internal_fields, $additional_method) eq $local_fail ) {
            delete($obj->{$_});
		    ++$fixed_fields;
		    &__print_debug_output("Object method called and resulted in cleansing [ $_ | $fixed_fields | $number_fields ]", __PACKAGE__) if ( $is_debug );		  
		  }
		}
	  } elsif ( defined($obj->{$_}) && defined(&is_class_rep($obj->{$_})->{'class'}) ) {
	    delete($obj->{$_});
		++$fixed_fields;
		&__print_debug_output("(S) Unexpanded instantiation found and resulted in cleansing [ $_ | $fixed_fields | $number_fields ]", __PACKAGE__) if ( $is_debug );
	  } else {
	    my $ref_type = ref($obj->{$_});
		if ( $ref_type =~ m/^array/i ) {
		  if ( scalar(@{$obj->{$_}}) < 1 ) {
		    $obj->{$_} = [];
		    ++$fixed_fields;
		    &__print_debug_output("Empty simple array found and resulted in cleansing [ $_ | $fixed_fields | $number_fields ]", __PACKAGE__) if ( $is_debug );
			next;
		  } elsif ( defined(&is_class_rep($obj->{$_})->{'class'}) ) {
		    $obj->{$_} = [];
			++$fixed_fields;
			next;
		    &__print_debug_output("(A) Unexpanded instantiation found and resulted in cleansing [ $_ | $fixed_fields | $number_fields ]", __PACKAGE__) if ( $is_debug );
		  }
		  my $subcount = 0;
		  foreach my $sub (@{$obj->{$_}}) {
		    if ( &__cleanup_internals($sub, $internal_fields, $additional_method) eq $local_fail ) {
			  ++$subcount;
			}
		  }
		  if ( $subcount == scalar(@{$obj->{$_}}) ) {
		    $obj->{$_} = [];
		    ++$fixed_fields;		  
		    &__print_debug_output("Empty simple subarray found and resulted in cleansing [ $_ | $fixed_fields | $number_fields ]", __PACKAGE__) if ( $is_debug );
		  }
		} elsif ( (not defined($obj->{$_})) && ($ref_type eq '') ) {
		  delete($obj->{$_});
		  ++$fixed_fields;
		  &__print_debug_output("Scalar (undef) found and resulted in cleansing [ $_ | $fixed_fields | $number_fields ]", __PACKAGE__) if ( $is_debug );
		}
	  }
	}
	
  __END_OF_SUB:
	return $local_fail if ( ($fixed_fields == $number_fields) && ($number_fields > 0) );
	
  __END_OF_SUB2:
	return $local_pass;
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
sub __set_debug($)
  {
    if ( $_[0] eq $local_true ) {
	  $is_debug = $local_true;
	  eval "use Data::Dumper;";
	  eval "\$Data::Dumper::Sortkeys = 1;";
	}
  }
  
#=============================================================================
sub get_array_fields($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my @result = ();
	my $obj    = $_[0];
	goto FINISH if ( not defined($obj) );
	
	my $ref_type = ref($obj);
	if ( &is_blessed_obj($obj) eq $local_true || $ref_type =~ m/hash/i ) {
	  my $data_fields = &get_fields($obj);
	  foreach ( @{$data_fields} ) {
	    push ( @result, "$_" ) if ( ref($obj->{"$_"}) =~ m/^array/i );
	  }
	}
	
  FINISH:
	return \@result;
  }
  
#=============================================================================
sub get_fields($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my @result = ();
	my $obj    = $_[0];
	
    goto __END_OF_SUB if ( not defined($obj) );
	
	my $ref_type    = ref($obj);
	my $use_base    = $_[1];
	
	$use_base = $local_true if ( not defined($use_base) );
	my $use_method  = $local_false;
	
	if ( &is_blessed_obj($obj) eq $local_true ) {
	  $use_method = $local_true if ( &function_exists($obj, 'data_types') eq $local_true);
	} else {
	  goto __END_OF_SUB if ( $ref_type !~ m/hash/i );
	}
	
	my $access = $use_base && $use_method;
	@result = ( $access eq $local_true ) ? keys( %{$obj->data_types(@_)} ) : keys( %{$obj} );
	
  __END_OF_SUB:
	return \@result;
  }
  
#=============================================================================
sub get_object_fields($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my @result = ();
	my $obj = $_[0];

	goto __END_OF_SUB if ( not defined($obj) );
	
	my $ref_type = ref($obj);
	if ( &is_blessed_obj($obj) eq $local_true || $ref_type =~ m/hash/i ) {
	  my $data_fields = &get_fields($obj);
	  foreach ( @{$data_fields} ) {
	    push ( @result, "$_" ) if ( &is_blessed_obj($obj->{"$_"}) eq $local_true );
	  }
	}
	
  __END_OF_SUB:
	return \@result;
  }

#=============================================================================
sub get_template_obj($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $result = undef;
	
    my $obj = $_[0] || goto __END_OF_SUB;
	$result = $obj->{'template'} if ( &has_template_obj($obj) eq $local_true );
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub transfer_data($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $result  = $local_false;
    my $hashref = $_[0];
	my $object  = $_[1];
	
	goto __END_OF_SUB if ( ref($hashref) !~ m/hash/i );
	
	my $hashfields = &get_fields($hashref);
	if ( ( &is_blessed_obj($object) eq $local_true ) ||
	     ( ref($object) =~ m/hash/i ) ) {
	  my $copied = 0;
	  foreach ( @{$hashfields} ) {
	    if ( exists($object->{"$_"}) ) {
	      $object->{"$_"} = &clone_item($hashref->{"$_"});
		  ++$copied;
	    }
	  }
	  $result = $local_true if ( $copied > 0 );
	}
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;