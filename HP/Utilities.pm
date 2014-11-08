package HP::Utilities;

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

    $VERSION  = 0.85;

	@ISA    = qw(Exporter);
    @EXPORT = qw(
				 &configuration_handler
				 &convert_boolean_to_string
				 &convert_string_to_boolean
				 &convert_status_to_string
				 &convert_string_to_status
				 &delete_empty_array
				 &delete_field
				 &get_md5
				 &get_memory_address
				 &print_boolean
				 &print_object_header
				 &print_status
				 &print_string
				 &swap
               );

    $module_require_list = {
	                        'Scalar::Util'                 => undef,
							
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::CheckLib'                 => undef,
							'HP::Support::Module'          => undef,
							'HP::String'                   => undef,
						   };
    $module_request_list = {
							'Digest::MD5' => undef,
	                       };

    $is_init  = 0;
    $is_debug = (
			$ENV{'debug_utilities_pm'} ||
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
sub __initialize()
  {
    if ( not $is_init ) {
      $is_init = 1;
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }
  
#=============================================================================
sub as_hash
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $self    = shift;
	my $hashref = {};
	
	my $subname = 'as_hash';
	
	my $data_fields = &get_fields($self);

	foreach my $k ( keys(%{$data_fields}) ) {
	  my $item      = $self->{"$k"};
	  my $item_type = ref( $item );
	  my $result    = undef;
	  
	  if ( &is_blessed_obj($item) ) {
		if ( &function_exists($item, $subname) eq TRUE ) {
		  my $evalstr = "\$result = \$item->$subname();";
		  eval "$evalstr";
		  $hashref->{"$k"} = $result;
		} else {
	      $hashref->{"$k"}->{ &CLASS_TAG } = $item_type;
		}
      } else {
	    # Need to check to see if it is an array of objects or hash of objects
		if ( $item_type eq '' ) {
		  $hashref->{"$k"} = $item;
		} elsif ( $item_type =~ m/^scalar/i ) {
		  $hashref->{"$k"} = $$item;
        } elsif ( $item_type =~ m/^array/i ) {
	      $hashref->{"$k"} = [];
		  foreach my $element ( @{$item} ) {
		    if ( &is_blessed_obj($element) ) {
			  if ( &function_exists($element, $subname) eq TRUE ) {
			    my $evalstr = "\$result = \$element->$subname();";
				eval "$evalstr";
			    push ( @{$hashref->{"$k"}}, $result );
			  } else {
			    push ( @{$hashref->{"$k"}}, ref($element) );
			  }
			} else {
			  push ( @{$hashref->{"$k"}}, $element );
			}
		  }
		} elsif ( $item_type =~ m/hash/i ) {
	      $hashref->{"$k"} = {};
		  foreach my $subk ( keys( %{$item} ) ) {
			if ( &is_blessed_obj($item->{"$subk"}) ) {
			  if ( &function_exists($item->{"$subk"}, $subname) eq TRUE ) {
			    my $evalstr = "\$result = \$item->{'$subk'}->$subname();";
				eval "$evalstr";
  			    $hashref->{"$k"}->{"$subk"} = $result;
			  } else {
			    $hashref->{"$k"}->{"$subk"} = ref($item->{"$subk"});
			  }
			} else {
  			  $hashref->{"$k"}->{"$subk"} = $item->{"$subk"};
			}
		  }
		} elsif ( $item_type =~ m/^code/i ) {
		  $hashref->{"$k"} = {};
		  $hashref->{"$k"}->{ &CODE_REFERENCE_TAG } = $item_type;
		  $hashref->{"$k"}->{'subname'} = $self->sub_name($item);
		} elsif ( $item_type =~ m/^glob/i ) {
		  $hashref->{"$k"} = {};
		  $hashref->{"$k"}->{ &GLOB_TAG } = $item_type;
		  $hashref->{"$k"}->{'obj'} = ref(*$item{IO});
		}
	  }
	}

	$hashref->{ &CLASS_TAG } = ref($self);
    return $hashref;	
  }
  
#=============================================================================
sub configuration_handler($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $data = shift || return;
  }
  
#=============================================================================
sub convert_boolean_to_string($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $boolean         = shift || FALSE;
	my $conversion_data = shift || { &TRUE => 'true', &FALSE => 'false' };
	
	return 'false' if ( not exists($conversion_data->{"$boolean"}) );
	return $conversion_data->{"$boolean"};
  }

#=============================================================================
sub convert_status_to_string($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $status          = shift || FAIL;
	my $conversion_data = shift || { &FAIL => 'fail', &PASS => 'pass' };
	
	return 'fail' if ( not exists($conversion_data->{"$status"}) );
	return $conversion_data->{"$status"};
  }

#=============================================================================
sub convert_string_to_boolean($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $str             = shift || return FALSE;
	my $conversion_data = shift || { 'true' => &TRUE, 'false' => &FALSE };
	my $ignorecase      = shift || TRUE;
	
	$str = &lowercase_all($str) if ( $ignorecase eq TRUE );
	return FALSE if ( not exists($conversion_data->{"$str"}) );
	return $conversion_data->{"$str"};
  }

#=============================================================================
sub convert_string_to_status($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $str             = shift || return FAIL;
	my $conversion_data = shift || { 'fail' => &FAIL, 'pass' => &PASS };
	my $ignorecase      = shift || TRUE;
	
	$str = &lowercase_all($str) if ( $ignorecase eq TRUE );
	return FALSE if ( not exists($conversion_data->{"$str"}) );
	return $conversion_data->{"$str"};
  }

#=============================================================================
sub delete_empty_array
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $obj   = shift;
	my $field = shift || return;
		
	delete($obj->{"$field"}) if ( (exists($obj->{"$field"})) &&
	                              (scalar(@{$obj->{"$field"}}) < 1) );
	return TRUE;
  }
  
#=============================================================================
sub delete_field
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $obj   = shift;
	my $field = shift || return;
		
	delete($obj->{"$field"}) if ( exists($obj->{"$field"}) );
	return TRUE;
  }
  
#=============================================================================
sub get_md5($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    if ( ( not &has('Data::UUID') ) && ( not &has('UUID::Tiny') ) ) {
	  return '0' x 32;
	}

    my $options = shift;
    my $hexcode = undef;

    if ( ref($options) !~ m/hash/i ) {
      if ( defined($options) ) {
	    $options = {
		            'data' => "$options",
		           };
      } else {
	    goto CODE_RETURN;
      }
    }

    my $md5digester = Digest::MD5->new();
    if ( exists($options->{'data'}) ) {
      $md5digester->add($options->{'data'});
      $hexcode = $md5digester->hexdigest();
      goto CODE_RETURN;
    }

    my $needs_closing = 0;
    my $handle        = undef;

    if ( defined($options->{'file'}) ) {
      if ( ( ref($options->{'file'}) !~ m/^glob/i ) &&
	       ( ref($options->{'file'}) !~ m/^filehandle/i )
	     ) {
	    &__print_debug_output("Filename --> $options->{'file'}\n", __PACKAGE__) if ( defined($options->{'file'}) );

	    if ( index( $options->{'file'}, '"' ) > -1 ) { $options->{'file'} =~ s/\"//g }
	    if ( open(TEMP_HANDLE, "<", "$options->{'file'}" ) ) {
	      $handle = *TEMP_HANDLE;
	      &__print_debug_output("Handle value -- << $handle >>", __PACKAGE__);
	      ++$needs_closing;
	    } else {
	      &__print_debug_output("Opening filename failed! $!", __PACKAGE__);
	      goto CODE_RETURN;
	    }
      } else {
	    &__print_debug_output("Input is already a filehandle!", __PACKAGE__);
	    $handle = $options->{'file'};
      }
    } else {
      &__print_debug_output("Cannot determine what should be filename/filehandle!", __PACKAGE__);
      goto CODE_RETURN;
    }

    $md5digester->addfile($handle);
    $hexcode = $md5digester->hexdigest();
    close($handle) if ( $needs_closing );

  CODE_RETURN:
    return $hexcode;
  }

#=============================================================================
sub get_memory_address($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $null = sprintf('0x%#.7x', 0);
	my $obj  = shift || return $null;
	return Scalar::Util::refaddr($obj);
  }

#=============================================================================
sub print_boolean(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'boolean',     \&valid_string,
	                                        'name',        \&valid_string,
											'map',         undef,
											'indentation', \&valid_string ], @_);
    } else {
      $inputdata = $_[0];
    }

    my $boolean      = $inputdata->{'boolean'};
	my $boolean_name = $inputdata->{'name'};
	my $boolean_map  = $inputdata->{'map'};
	my $indentation  = $inputdata->{'indentation'} || '';
	
	my $statement    = '';
	
	return $statement if ( &valid_string($boolean) eq FALSE );
	return $statement if ( &valid_string($boolean_name) eq FALSE );
	
	$statement .= $indentation . "$boolean_name    : " .&convert_boolean_to_string($boolean, $boolean_map);
	
	return $statement;
  }

#=============================================================================
sub print_object_header(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
 
    my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'object', undef,
											'indentation', \&valid_string ], @_);
    } else {
      $inputdata = $_[0];
    }

    my $object       = $inputdata->{'object'};
	my $indentation  = $inputdata->{'indentation'} || '';

	my $statement    = '';
	my $reftype      = ref($object);
	
	return $statement if ( &valid_string($reftype) eq FALSE );
	
	$statement .= $indentation . "Object Type    : $reftype";
	
	return $statement;
  }
  
#=============================================================================
sub print_status(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'status', \&valid_string,
	                                        'name', \&valid_string,
											'indentation', \&valid_string ], @_);
    } else {
      $inputdata = $_[0];
    }

    my $status       = $inputdata->{'status'};
	my $status_name  = $inputdata->{'name'};
	my $indentation  = $inputdata->{'indentation'} || '';
	
	my $statement    = '';
	
	return $statement if ( &valid_string($status) eq FALSE );
	return $statement if ( &valid_string($status_name) eq FALSE );
	
	$statement .= $indentation . "$status_name    : " .&convert_status_to_string($status);
	
	return $statement;
  }

#=============================================================================
sub print_string(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'string', \&valid_string,
	                                        'name', \&valid_string,
											'indentation', \&valid_string ], @_);
    } else {
      $inputdata = $_[0];
    }

    my $string       = $inputdata->{'string'};
	my $string_name  = $inputdata->{'name'};
	my $indentation  = $inputdata->{'indentation'} || '';
	
	my $statement    = '';
	
	return $statement if ( &valid_string($string_name) eq FALSE );
	
	if ( &valid_string($string) eq FALSE ) {
	  $statement .= $indentation . "$string_name    : NONE";	
	} else {
	  $statement .= $indentation . "$string_name    : $string";
	}
	
	return $statement;
  }

#=============================================================================
sub swap($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'array', undef,
	                                        'oldidx', \&valid_string,
											'newidx', \&valid_string ], @_);
    } else {
      $inputdata = $_[0];
    }

    my $array   = $inputdata->{'array'}  || return FALSE;
	my $oldidx  = $inputdata->{'oldidx'};
	my $newidx  = $inputdata->{'newidx'};
  
	return FALSE if ( &valid_string("$oldidx") eq FALSE );
	return FALSE if ( &valid_string("$newidx") eq FALSE );
	
	return FALSE if ( $oldidx == $newidx );
	my $tmp = $array->[$oldidx];
	$array->[$oldidx] = $array->[$newidx];
	$array->[$newidx] = $tmp;
	
	return TRUE;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;
