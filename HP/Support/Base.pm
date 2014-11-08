package HP::Support::Base;

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

	use HP::Constants;
	use HP::Support::PerlModuleUtils;
	
    use vars qw(
				$VERSION
				$is_init
				$is_debug

				$module_require_list

				@ISA
				@EXPORT
	           );

	@ISA     = qw(Exporter);
    @EXPORT  = qw(
				  &__pause
				  &get_method_name
                  &serialize
		         );

	$module_require_list = {
	                        'Storable'                     => undef,
							'HP::Support::Base::Constants' => undef,
	                       };

    $VERSION  = 0.92;
	
    $is_init  = FALSE();
    $is_debug = (
	             $ENV{'debug_support_base_pm'} ||
	             $ENV{'debug_support_modules'} ||
		         $ENV{'debug_hp_modules'} ||
		         $ENV{'debug_all_modules'} || FALSE()
		        );
  }

#=============================================================================
END
  {
    print STDERR "UNLOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
my $local_true  = TRUE();
my $local_false = FALSE();

#=============================================================================
sub __initialize()
  {     
    if ( $is_init eq $local_false ) {
      $is_init = $local_true; 
	  &load_modules({'package' => __PACKAGE__,
	                 'perl_modules' => $HP::Support::Base::module_require_list});
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }     
  }       

#=============================================================================
sub __pause()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    print STDERR "PAUSE >>";
    getc();
  }

#=============================================================================
sub __set_debug(;$)
  {
    return if ( not defined($_[0]) );
    &HP::Support::PerlModuleUtils::__set_debug_on(__PACKAGE__) if ( $_[0] eq $local_true );
  }
  
#=============================================================================
sub allow_space_as_valid_string($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    my $allowance = $_[0];
	
	if ( not defined($allowance) ) {
	  $HP::Support::Base::allow_space = $local_false;
	  goto __END_OF_SUB;
	}
	$HP::Support::Base::allow_space = $allowance;
	
  __END_OF_SUB:
    return;
  }

#=============================================================================
sub convert_to_regexs($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $result = undef;
    goto __END_OF_SUB if ( not defined($_[0]) );

    my $actual = ref($_[0]) eq '';
    my $sclref = ref($_[0]) =~ m/^scalar/i;
    my $arrref = ref($_[0]) =~ m/^array/i;

	if ( $actual ) {
	  if ( exists(COMPILED_REGEX->{$_[0]}) ) {
	    $result = COMPILED_REGEX->{$_[0]};
		goto __END_OF_SUB;
	  }
	  my $qm = quotemeta("$_[0]");
	  COMPILED_REGEX->{"$_[0]"} = $qm;
	  $result = $qm;
	  goto __END_OF_SUB;
	}
	
	if ( $sclref ) {
	  $result = &convert_to_regexs(${$_[0]});
	  goto __END_OF_SUB;
	}
	
    if ( $arrref ) {
      my @regexs = ();
      for ( my $loop = 0; $loop < scalar(@{$_[0]}); ++$loop ) {
	    push( @regexs, &convert_to_regexs($_[0]->[$loop]) );
      }
      $result = \@regexs;
	  goto __END_OF_SUB;
    }
	
  __END_OF_SUB:
    return $result;
  }

#=============================================================================
sub get_method_name
  {
    my $i = 1;
	my @call_details = (caller($i++));
	my $method_name = $call_details[3];
	
    return "<$method_name>" if ( defined($method_name) );
	return undef;
  }
  
#=============================================================================
sub serialize(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $result = undef;
	
	# Need to generate internal array ref to insert all items...
	foreach ( @_ ) {
	  my $data = $_;
	  next if ( not defined($data) );
	  
	  if ( ref($data) eq '' ) { $data = \$_; }
	  if ( defined($result) ) {
	    $result .= Storable::freeze($data); # Need to add marker to allow for deserialization  TODO
	  } else {
	    $result = Storable::freeze($data);
	  }
	}
	return $result;
  }
  
#=============================================================================
sub valid_string($)
  {
    my $result = $local_false;
    my $data   = shift;
	
	while ( scalar(@_) > 0 ) {
	   my $nextdata = shift;
	   next if ( not defined($nextdata) );
	   $data .= $nextdata;
	}
	
	goto __END_OF_SUB if ( not defined($data) );
	
	my $pkg_var_value = $HP::Support::Base::allow_space;
	
	$data =~ s/ +/ /g; # Compress multiple spaces to single space...
	
	goto __END_OF_SUB if ( length($data) < 1 && $pkg_var_value eq $local_false );
	goto __END_OF_SUB if ( (length($data) == 1) && ($data eq ' ') && $pkg_var_value eq $local_false );
	$result = $local_true;
	
  __END_OF_SUB:
    return $result;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;