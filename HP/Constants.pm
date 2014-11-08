package HP::Constants;

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

    use vars qw(
                $VERSION
                $is_debug
                $is_init
				@ISA
				@EXPORT
			   );

    $VERSION = 1.01;

	@ISA    = qw(Exporter);
	@EXPORT = qw(
	              TRUE
	              FALSE
				  PASS
				  FAIL
				  
				  FORWARD
				  BACKWARD
				  
				  ARRAY
				  HASH
				  
				  LOCAL
				  COMBINED
				);

	$is_init  = 0;
    $is_debug = (
                 $ENV{'debug_constants_pm'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );
  }

#=============================================================================
END
  {
    print STDERR "UNLOADED <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
use constant TRUE  => 1;
use constant FALSE => 0;
use constant PASS  => 0;
use constant FAIL  => 1;

use constant FORWARD  => 1;
use constant BACKWARD => -1;

use constant ARRAY => 'array';
use constant HASH  => 'hash';

use constant LOCAL    => 0;
use constant COMBINED => 1;

#=============================================================================
sub __initialize()
  {
    if ( $is_init eq FALSE ) {
      $is_init = TRUE;
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
1;