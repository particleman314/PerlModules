package HP::Support::PerlModuleUtils;

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
	use Module::Load 'all';
	use Error;
	
    use vars qw(
				$VERSION
				$is_init
				$is_debug
				@ISA
				@EXPORT
	       );

	@ISA    = qw(Exporter);
    @EXPORT = qw(
	             &load_required_modules
				 &load_requested_modules
				 &load_modules
				);

    $VERSION  = 0.95;
	
    $is_init  = FALSE;
    $is_debug = (
	             $ENV{'debug_support_perlmoduleutils_pm'} ||
	             $ENV{'debug_support_modules'} ||
		         $ENV{'debug_hp_modules'} ||
		         $ENV{'debug_all_modules'} || FALSE()
		        );
  }

#=============================================================================
END
  {
    print STDERR "UNLOADED <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
my $local_true  = TRUE();
my $local_false = FALSE();

#=============================================================================
sub __begin(;$)
  {
    my $pkg = $_[0] || __PACKAGE__;
    print STDERR "BEGIN LOADING <$pkg>\n" if ( $is_debug );  
  }

#=============================================================================
sub __end()
  {
    my $pkg = $_[0] || __PACKAGE__;
    print STDERR "END LOADING <$pkg> Module\n" if ( $is_debug );   
  }
  
#=============================================================================
sub __initialize()
  {     
    if ( not $is_init ) {
      $is_init = $local_true; 
      print STDERR "INITIALIZING <".__PACKAGE__."> Module\n" if ( $is_debug );
    }     
  }       

#=============================================================================
sub __set_debug_on(;$)
  {
    my $package = __PACKAGE__;
    if ( not defined($_[0]) ) {
	  $HP::Support::PerlModuleUtils::is_debug = $local_true;
	} else {
	  $package = $_[0];
	  eval "\$$package"."::is_debug = $local_true";
	  if ( $@ ) {
	    print STDERR "Unable to set local debug flag for $package\n";
		return;
	  }
	}
	return &load_required_modules({'package'      => $package,
	                               'perl_modules' => [ 'Data::Dumper' ],
								   'eval_block'   => '$Data::Dumper::Sortkeys = 1'});
  }
  
#=============================================================================
sub __verify_input($)
  {
    return undef if ( ref($_[0]) !~ m/^[hash|array]/i );
	
	my %tmphash = ();
	if ( ref($_[0]) =~ m/^array/i ) {
	  %tmphash = map { $_ => undef } @{$_[0]};
	} else {
	  %tmphash = %{$_[0]};
	}
	
	if ( $is_debug ) {
	  $tmphash{'Data::Dumper'} = undef if ( not exists($tmphash{'Data::Dumper'}) );
	}
    return \%tmphash;
  }
  
#=============================================================================
sub load_required_modules($)
  {
    return if ( ref($_[0]) !~ m/hash/i );
	
    my $result = &__verify_input($_[0]->{'perl_modules'});
    return $local_false if ( not defined($result) );
	
	my $package = $_[0]->{'package'} || 'main';
	
    foreach my $usemod (keys(%{$result})) {
      if ( defined($result->{$usemod}) ) {
        print STDERR "\t--> [$package]  REQUIRED(V)  :: use $usemod $result->{$usemod};\n" if ( $is_debug );
        &autoload_remote( $package, $usemod );
		# Handle versioning here
      } else {
        print STDERR "\t--> [$package]  REQUIRED(NV) :: use $usemod;\n" if ( $is_debug );
        &autoload_remote( $package, $usemod );
      }
      if ( $@ ) {
        print STDERR "\t--> Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
        die "Exiting!\n$@";
      }
    }
	
	return $local_true;
  }
  
#=============================================================================
sub load_requested_modules($)
  {
    return if ( ref($_[0]) !~ m/hash/i );
	
    my $result = &__verify_input($_[0]);
    return $local_false if ( not defined($result) );

	my $package = $_[0]->{'package'} || 'main';
	
    foreach my $usemod (keys(%{$result})) {
      if ( defined($result->{$usemod}) ) {
        print STDERR "\t--> [". __PACKAGE__ ."] REQUESTED(V)  :: use $usemod $result->{$usemod};\n" if ( $is_debug );
        &autoload_remote( $package, $usemod );
		# Handle versioning here
      } else {
        print STDERR "\t--> [". __PACKAGE__ ."] REQUESTED(NV) :: use $usemod;\n" if ( $is_debug );
        &autoload_remote( $package, $usemod );
      }
      if ( $@ ) {
        print STDERR "\t--> Cannot find PERL Module << $usemod >>! Please have this installed or accessible for future functionality!\n";
      }
    }
	
	return $local_true;
  }

#=============================================================================
sub load_modules($;$)
  {
    my $result = $local_true;
    &__begin($_[0]->{'package'}) if ( scalar(@_) > 0 );
    $result = &load_required_modules($_[0]) if ( defined($_[0]) );
	&load_requested_modules($_[1]) if ( defined($_[1]) );
    &__end($_[0]->{'package'})   if ( scalar(@_) > 0 && $result eq $local_true );
	return $result;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;