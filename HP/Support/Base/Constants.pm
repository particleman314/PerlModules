package HP::Support::Base::Constants;

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

	use HP::Constants;
	
    use vars qw(
				$VERSION
				$is_init
				$is_debug
				@ISA
				@EXPORT
	           );

	@ISA    = qw(Exporter);
    @EXPORT = qw(
				 UNKNOWN				  
				 COMPILED_REGEX
		        );

    $VERSION  = 0.65;
	
    $is_init  = FALSE();
    $is_debug = (
	             $ENV{'debug_support_base_constants_pm'} ||
	             $ENV{'debug_support_base_modules'} ||
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
use constant UNKNOWN        => 'UNKNOWN';
use constant COMPILED_REGEX => {};

#=============================================================================
my $local_true  = TRUE();
my $local_false = FALSE();

#=============================================================================
sub __initialize()
  {     
    if ( $is_init eq $local_false ) {
      $is_init = $local_true; 
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }     
  }       

#=============================================================================
&__initialize();

#=============================================================================
1;