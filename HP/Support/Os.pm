package HP::Support::Os;

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

				@ISA
 		        @EXPORT
               );

	@ISA = qw(Exporter);
	
    @EXPORT = qw(
	             &determine_os
	             &get_pid
		         &os_is_cygwin
		         &os_is_darwin
		         &os_is_linux
		         &os_is_windows
		         &os_is_windows_native
		        );

    $module_require_list = {
			                'Config'                     => undef,
							
							'HP::Constants'              => undef,
							'HP::Support::Base'          => undef,
							'HP::Support::Os::Constants' => undef,
			               };
    $module_request_list = {};

    $is_init    = 0;
    $is_debug   = (
		           $ENV{'debug_support_os_pm'} ||
		           $ENV{'debug_support_modules'} ||
		           $ENV{'debug_hp_modules'} ||
		           $ENV{'debug_all_modules'} || 0
		          );

    $broken_install = 0;

    print STDERR "BEGIN <". __PACKAGE__ .">\n" if ( $is_debug );

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "\t--> Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

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
          eval "use $usemod $module_request_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUESTED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug );
          eval "use $usemod;";
        }
        if ( $@ ) {
          print STDERR "\t--> Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
        }
     }
    } else {
      my $use_cmd = &load_required_modules( __PACKAGE__, $module_request_list);
      eval "$use_cmd";
    }

    # Print a messages stating this module has been loaded.
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
sub __initialize()
  {
    if ( $is_init eq $local_false ) {
      $is_init = $local_true;
      print STDERR "INITALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
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
sub __windows_style()
  {
	my $found_windows = ( $^O =~ m/MSWin/ ) || $local_false;
    return ( $found_windows ) ? $local_true : $local_false;
  }
  
#=============================================================================
sub determine_os
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $is_windows = &os_is_windows() || &os_is_cygwin() || &os_is_windows_native();
	my $is_linux   = &os_is_linux();
	my $is_mac     = &os_is_darwin();
	
	return WINDOWS_SHORTNAME   if ( $is_windows eq $local_true );
	return LINUX_SHORTNAME     if ( $is_linux eq $local_true );
	return MACINTOSH_SHORTNAME if ( $is_mac eq $local_true );
	
	return UNKNOWN_OS_TYPE;
  }
  
#=============================================================================
sub get_pid(;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $pid    = $_[0] || $$;
	my $result = $pid;

    &__print_debug_output("PID from input/\$\$ = $pid\n", __PACKAGE__);

    if ( &os_is_cygwin() eq $local_true ) {
      if ( length($Config{'myuname'}) > 0 ) {
	    my $cygpid = Cygwin::pid_to_winpid($pid);
	    if ( defined($cygpid) ) { $result = abs($cygpid); }
      }
    }
	
    return $result;
  }

#=============================================================================
sub os_is_cygwin()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $is_perl_cygwin  = $local_false;
    my $is_home_cygwin  = $local_false;
    my $is_shell_cygwin = $local_false;

    $is_perl_cygwin  = $local_true if ( $Config{'myuname'} =~ m/cygwin/i );
    $is_home_cygwin  = ( exists($ENV{'HOME'}) && $ENV{'HOME'} =~ m/cygdrive/ );
    $is_shell_cygwin = exists($ENV{'CYGWIN'});

	my $found_cygwin = ( $^O =~ m/cygwin/i ) ||
	                   ( $is_perl_cygwin eq $local_true ) ||
					   ( $is_home_cygwin eq $local_true ) ||
					   ( $is_shell_cygwin eq $local_true ) ||
					   $local_false;
					   
    return ( $found_cygwin ) ? $local_true : $local_false;
  }

#=============================================================================
sub os_is_darwin()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $found_darwin = ( $^O =~ m/darwin/i ) || $local_false;
    return ( $found_darwin ) ? $local_true : $local_false;
  }

#=============================================================================
sub os_is_linux()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $found_linux = ( $^O =~ m/linux/i ) || $local_false;
    return ( $found_linux ) ? $local_true : $local_false;
  }

#=============================================================================
sub os_is_windows()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $found_windows = &os_is_windows_native() || &os_is_cygwin();
    return ( $found_windows ) ? $local_true : $local_false;
  }

#=============================================================================
sub os_is_windows_native()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
 
	my $found_windows = ( &__windows_style eq $local_true ) || $local_false;
    return ( $found_windows ) ? $local_true : $local_false;
  }

#=============================================================================
&__initialize();

#=============================================================================
1;