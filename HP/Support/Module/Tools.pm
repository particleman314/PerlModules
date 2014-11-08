package HP::Support::Module::Tools;

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

    $VERSION    = 0.85;

	@ISA = qw(Exporter);
    @EXPORT = qw(
	             &import_packages
				 &load_packages
	             &require_packages
				 &use_packages
				);

    $module_require_list = {
							'HP::Constants'                => undef,
							
							'HP::Support::Base'            => undef,							
							'HP::Support::Base::Constants' => undef,
						   };
    $module_request_list = {
	                       };

    $module_callback     = {};

    $is_init  = 0;
    $is_debug = (
			$ENV{'debug_support_module_tools_pm'} ||
			$ENV{'debug_support_module_modules'} ||
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

#=============================================================================
sub __add_packages($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my @result = ();
	my @errmsg = ();
	
	my $command = $_[0];
	
	$result[scalar(@{$_[1]}) - 1] = undef;
	$errmsg[scalar(@{$_[1]}) - 1] = undef;
	my $success = TRUE;
	
	for (my $loop = 0; $loop < scalar(@{$_[1]}); ++$loop ) {
	  my $evalstr = "$_[0] $_[1]->[$loop];";
	  eval "$evalstr";
	  if ( $@ ) {
	    &__print_output( "Unable to load << $_[$loop] >> for use.  Error condition : $@", FAILURE );
		$result[$loop] = FALSE;
		$errmsg[$loop] = $@;
		$success = FALSE;
	  } else {
	    $result[$loop] = TRUE;
	  }
	}
	
	return ( \@result, \@errmsg, $success );
  
  }

#=============================================================================
sub __initialize()
  {
    if ( $is_init eq $local_false) {
      $is_init = $local_true;
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
sub load_packages($)
  {
    eval "use Module::Load::Conditional;";
	return if ( scalar(@_) < 1 );
	
	if ( ref($_[0]) =~ m/^array/i ) {
	  return can_load($_[0]);
	}
	return FALSE;
  }
  
#=============================================================================
sub import_packages($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	return &__add_packages('import', @_);
  }
  
#=============================================================================
sub require_packages($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	return &__add_packages('require', @_);
  }
  
#=============================================================================
sub use_packages(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	return &__add_packages('use', @_);
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;