package HP::CSL::Constants;

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
				$is_init
				$is_debug

				$module_require_list
                $module_request_list

                $prefix
                $broken_install

				@ISA
				@EXPORT
	       );

	@ISA  = qw(Exporter);
    @EXPORT  = qw(
	              DEFAULT_BUILD_LOG
	              MAX_HISTORY_FILELINES
				  HYBRID_VERSIONS
				  
				  DEFAULT_SVN_REVISION
				  DEFAULT_BUILD_NUMBER
				  DEFAULT_VERSION_NUMBER
				  
				  CSL_ERRORS
				  
				  JENKINS_ENVIRONMENT_QUERY
				  JENKINS_XML_QUERY
				  JENKINS_QUERY_MAP
		         );

	$module_require_list = {
	                        'HP::Timestamp' => undef,
	                       };
    $module_request_list = {};

    $VERSION  = 0.65;
	
    $is_init  = 0;
    $is_debug = (
	         $ENV{'debug_csl_constants_pm'} ||
	         $ENV{'debug_csl_modules'} ||
		     $ENV{'debug_hp_modules'} ||
		     $ENV{'debug_all_modules'} || 0
		);

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    $prefix = '';

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
use constant MAX_HISTORY_FILELINES  => 10;
use constant HYBRID_VERSIONS        => [1,2,3];
use constant DEFAULT_BUILD_LOG      => 'build.log';
use constant DEFAULT_SVN_REVISION   => -1;
use constant DEFAULT_BUILD_NUMBER   => 1;

use constant DEFAULT_VERSION_NUMBER => '1.0.0';

use constant JENKINS_ENVIRONMENT_QUERY => 1;
use constant JENKINS_XML_QUERY         => 0;

use constant JENKINS_QUERY_MAP         => {
                                   &JENKINS_ENVIRONMENT_QUERY => {
								                          'revision'  => [ 'SVN_REVISION', DEFAULT_SVN_REVISION ],
														  'buildid'   => [ 'BUILD_NUMBER', DEFAULT_BUILD_NUMBER ],
														  'builddate' => [ 'BUILD_ID', &get_formatted_datetime() ],
														  'home'      => [ 'JENKINS_HOME', undef ],
								                         },
								   &JENKINS_XML_QUERY => {
								                 },
                                  };
#=============================================================================
sub __initialize()
  {     
    if ( not $is_init ) {
      $is_init = 1; 
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }     
  }       

#=============================================================================
&__initialize();

#=============================================================================
1;