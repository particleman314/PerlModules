package HP::CheckLib;

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

	use HP::Constants;
	use HP::Support::PerlModuleUtils;
	
    use vars qw(
				$VERSION
				$is_init
				$is_debug

				$module_require_list
                $module_request_list

                $broken_install

				@ISA
				@EXPORT
	       );

	@ISA = qw(Exporter);
    @EXPORT  = qw(
	              &function_exists
				  &has_template_obj
				  &is_alphabetic
				  &is_alphanumeric
				  &is_basic_perl_obj
				  &is_binary
				  &is_blessed_obj
				  &is_class_rep
				  &is_hexadecimal
				  &is_integer
				  &is_octal
				  &is_numeric
				  &is_octal
				  &is_type
                  &limit
				  &valid_string
				 );

    $module_require_list = {							
							'HP::Constants'                => undef,
							
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
	                       };
    $module_request_list = {
	                       };

    $VERSION  = 0.95;
	
    $is_init  = 0;
    $is_debug = (
	         $ENV{'debug_checklib_pm'} ||
		     $ENV{'debug_hp_modules'} ||
		     $ENV{'debug_all_modules'} || 0
		);

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    $broken_install = 0;

    print STDERR "BEGIN <". __PACKAGE__ .">\n" if ( $is_debug );

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "\t--> Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
        if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug );
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
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUESTED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug );
          eval "use $usemod;";
        }
        if ( $@ ) {
          print STDERR "\t--> Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
        }
      }
    } else {
      my $use_cmd = &load_required_modules( __PACKAGE__, $module_require_list);
      eval "$use_cmd";
    }

    # Print a messages stating this module has been loaded.
    print STDERR "LOADING <".__PACKAGE__."> Module\n" if $is_debug;
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
sub __initialize()
  {     
    if ( not $is_init ) {
      $is_init = $local_false; 
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }     
  }       

#=============================================================================
sub __set_debug(;$)
  {
    return if ( not defined($_[0]) );
    &HP::Support::PerlModuleUtils::__set_debug_on(__PACKAGE__) if ( $_[0] eq $local_true );
  }
  
#=============================================================================
sub dereference($;$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	
	my $data  = $_[0] || goto __END_OF_SUB;
	my $deref = $_[1];

	$deref = $local_true if ( not defined($deref) );
	
	goto __END_OF_SUB if ( $deref eq $local_false );
	goto __END_OF_SUB if ( &is_blessed_obj($data) eq $local_true );
	
	my $ref_type = ref($data);
	
	return ${$data} if ( $ref_type =~ m/scalar/i );
	return @{$data} if ( $ref_type =~ m/^array/i );
	return %{$data} if ( $ref_type =~ m/hash/i );
	
  __END_OF_SUB:
	return $data;
  }
  
#=============================================================================
sub function_exists($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $module  = $_[0];
	my $routine = $_[1];
	
	return $local_false if ( (not defined($module)) && (not defined($routine)) );
	
	if ( $is_debug ) {
	  &__print_debug_output("Routine :: <$routine>", __PACKAGE__) if ( defined($routine) );
	  &__print_debug_output("Module  :: <$module>", __PACKAGE__) if ( defined($module) );
	}
	
	my $result = undef;
	if ( not defined($routine) ) {
	  $result = defined(&{$module});
	} else {
	  $result = UNIVERSAL::can($module, $routine);
	}
	
	( defined($result) ) ? return $local_true : return $local_false;
  }

#=============================================================================
sub has_template_obj($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $obj = $_[0];
    return $local_false if ( not defined($obj) );
	
	return $local_false if ( &is_blessed_obj($obj) eq $local_false );
	return $local_true  if ( exists($obj->{'template'}) );
	return $local_false;
  }
    
#=============================================================================
sub is_alphabetic($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $str = $_[0];

    return $local_false if ( &valid_string($str) eq $local_false );
    return $local_true  if ( $str =~ m/^[A-Za-z]+$/ );
	return $local_false;
  }

#=============================================================================
sub is_alphanumeric($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $str = $_[0];

    return $local_false if ( &valid_string($str) eq $local_false );
    return $local_true  if ( (&is_alphabetic($str) eq $local_true) ||
	                         (&is_numeric($str) eq $local_true) ||
					         ($str =~ m/^[A-Za-z0-9]+/) );
	return $local_false;
  }

#=============================================================================
sub is_basic_perl_obj($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $obj        = shift;
    return $local_false if ( not defined($obj) );
	
	my $type = ref($obj);
	 
    my $basic = $local_false;
	foreach ( [ 'scalar', 'array', 'hash', 'glob', 'code' ] ) {
	  if ( $type eq "$_" ) {
	    $basic = $local_true;
		last;
	  }
	}
	
	return $basic;
  }
  
#=============================================================================
sub is_binary($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	 
	my $str    = shift;
	my $result = $local_false;
	
	return $result if ( &valid_string($str) eq $local_false );
	
	$str = lc($str);
	my $has_binary_marker = ( $str =~ m/^0b/ ) ? $local_true : $local_false;
	$str =~ s/^0b// if ( $has_binary_marker eq $local_true );
	
	goto FINISH if ( $str =~ m/[^01]/ );
	
	$result = $local_true;
  FINISH:
	return $result;
  }

#=============================================================================
sub is_blessed_obj($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	 
    my $obj        = shift;
    return $local_false if ( not defined($obj) );
	
	my $hasfunc    = &function_exists($obj, 'isa');
	my $isbaseperl = ( &is_basic_perl_obj($obj) || ref($obj) eq '' ) ? $local_true : $local_false;
	
	return ( $hasfunc eq $local_true && $isbaseperl eq $local_false ) ? $local_true : $local_false;
  }

#=============================================================================
sub is_class_rep($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $result = {
	              'class'              => undef,
				  'use_interior_nodes' => $local_false,
				  'style'              => undef,
				  'singleton'          => $local_false,
				 };
				 
    my $input = shift || return $result;
	
	if ( $input =~ m/^c__(\w*\:?\:?.*)__\s*(singleton)?/ ) {
	  $result->{'class'} = $1;
	  $result->{'style'} = [ $local_false, undef ];
	  if ( defined($2) ) {
	    $result->{'singleton'} = $local_true;
	  }
	} elsif ( $input =~ m/\[(\w*\:?\:?.*)?\]\s*c__(\w*\:?\:?.*)__\s*(\d)?/ ) {
	  $result->{'class'} = $2;
	  if ( defined($3) ) {
	    $result->{'use_interior_nodes'} = ( $3 ne $local_false ) ? $local_true : $local_false;
      }
	  if ( &valid_string($1) eq $local_true ) {
	    $result->{'style'} = [ $local_true, $1 ];
	  } else {
	    $result->{'style'} = [ $local_true, 'HP::ArrayObject' ];
	  }
    }
	
	return $result;
  }
  
#=============================================================================
sub is_hexadecimal($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	 
	my $str    = shift;
	my $result = $local_false;
	
	goto FINISH if ( &valid_string($str) eq $local_false );
	 
	$str = lc($str);
	my $has_hexi_marker = ( $str =~ m/^0x/ ) ? $local_true : $local_false;
	$str =~ s/^0x// if ( $has_hexi_marker eq $local_true );
	
	goto FINISH if ( $str =~ m/[^\d^a-f]/ );
	
	$result = $local_true;
  FINISH:
	return $result;
  }
  
#=============================================================================
sub is_integer($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $str    = shift;
    my $result = $local_false;
	
    goto FINISH if ( &valid_string($str) eq $local_false );

	$str = lc($str);

	my $binary_match          = &is_binary($str);
	my $octal_match           = &is_octal($str);
	my $hexadecimal_match     = &is_hexadecimal($str);
	my $integerized_str       = ( $str !~ m/[a-z]/ ) ? int($str) : undef;
	
	# Should cover cases where binary and integer would overlap ( i.e. 0, 101, 110010 )
	if ( $binary_match eq $local_true && ( defined($integerized_str) && $str eq $integerized_str ) ) {
	  $result = $local_true;
	  goto FINISH;
	}

	# Should cover cases where octal and integer would overlap ( i.e. 0 )
	if ( $octal_match eq $local_true && ( defined($integerized_str) && $str eq $integerized_str ) ) {
	  $result = $local_true;
	  goto FINISH;
	}

	# Should cover cases where hexadecimal and integer would overlap ( i.e. 0, 5623, 93265823 )
	if ( $hexadecimal_match eq $local_true && ( defined($integerized_str) && $str eq $integerized_str ) ) {
	  $result = $local_true;
	  goto FINISH;
	}

	$result = $local_true if ( defined($integerized_str) && $str eq $integerized_str );
	&__print_debug_output("[B] $binary_match : [O] $octal_match : [H] $hexadecimal_match : [ $result | $str ]", __PACKAGE__);

  FINISH:
	
    return $result;
  }

#=============================================================================
sub is_numeric($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $str    = shift;
	my $result = $local_false;
    return $result if ( &valid_string($str) eq $local_false );

    return $local_true if ($str =~ m/^(\+?|\-?)(\d+)\.(\d+)$/ ||
                    $str =~ m/^(\+?|\-?)(\d+)\.(\d+)([eE](\+|\-)?)(\d+)$/ ||
                    $str =~ m/^(\+?|\-?)(\d+)([eE](\+|\-)?)(\d+)$/);

    return $local_true if ( &is_integer($str) eq $local_true );
    return $result;
  }

#=============================================================================
sub is_octal($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	 
	my $str    = shift;
	my $result = $local_false;
	 
	return $result if ( &valid_string($str) eq $local_false );

	return $local_true if ( $str =~ /^0/ && $str =~ m/^0[0-7]+/ );
	return $result;
  }
  
#=============================================================================
sub is_type($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $obj        = shift;
    return $local_false if ( not defined($obj) );
	if ( &is_blessed_obj($obj) eq $local_false ) { return $local_false; }
	
	foreach my $parent (@_) {
	  if ( $obj->isa($parent) ) { return $local_true; }
	}
	
	return $local_false;
  }
  
#=============================================================================
sub limit($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my ($value, $max, $min) = @_;

    return undef if ( ( not defined($value) ) && ( ( not defined($min) ) || ( not defined($max) ) ) );
    return $value if ( ( ( not defined($min) ) || ( not defined($max) ) ) );

    my $validate_max = &is_numeric($max);
    my $validate_min = &is_numeric($min);

    return $value if ( ( $validate_min eq $local_false ) || ( $validate_max eq $local_false ) );

	# Swap min and max if backwards ordered
    if ( $max < $min ) {
      my $temp = $max;
      $max = $min;
      $min = $temp;
    }

    return $max if ( $value > $max );
    return $min if ( $value < $min );
    return $value;
  }

#=============================================================================
sub valid_string($)
  {
    my $result = $local_$local_false;
    my $data   = $_[0];
	
	my $id = 0;
	while ( scalar(@_) > 1 ) {
	   my $nextdata = $_[++$id];
	   next if ( not defined($nextdata) );
	   $data .= $nextdata;
	}
	
	goto __END_OF_SUB if ( not defined($data) );
	
	my $pkg_var_value = $HP::Support::Base::allow_space;
	
	$data =~ s/ +/ /g; # Compress multiple spaces to single space...
	
	goto __END_OF_SUB if ( length($data) < 1 && $pkg_var_value eq $local_$local_false );
	goto __END_OF_SUB if ( (length($data) == 1) && ($data eq ' ') && $pkg_var_value eq $local_$local_false );
	$result = $local_$local_true;
	
  __END_OF_SUB:
    return $result;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;