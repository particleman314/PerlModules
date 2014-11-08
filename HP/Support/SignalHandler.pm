package HP::Support::SignalHandler;

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

				%LAST_SIGNALHANDLERS
				
				@ISA
 				@EXPORT
               );

    $VERSION    = 0.85;

	@ISA    = qw(Exporter);
    @EXPORT = qw(
				 &install_signal_handler
				 &restore_signal_handler
                );

    $module_require_list = {
							'HP::Constants'              => undef,
							'HP::Support::Base'          => undef,
							'HP::Support::Os'            => undef,
							'HP::Support::Shell'         => undef,					
							'HP::Support::Object::Tools' => undef,
							
							'HP::CheckLib'               => undef,
							'HP::Array::Tools'           => undef,
						   };
    $module_request_list = {
	                       };

    $is_init  = 0;
    $is_debug = (
			$ENV{'debug_support_signalhandler_pm'} ||
			$ENV{'debug_support_modules'} ||
			$ENV{'debug_hp_modules'} ||
			$ENV{'debug_all_modules'} || 0
		);

	%LAST_SIGNALHANDLERS = ();
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

      # Store away current signal handlers allowing users to "restore"
      %LAST_SIGNALHANDLERS = %SIG;

	  &install_signal_handler('WINCH', \&recheck_screen);
	  &install_signal_handler('INT', \&generate_exception, 1);
	  
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
sub install_signal_handler($;$@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my ($signaltype, $subroutineRef, @arguments) = @_;

    if ( ref($signaltype) =~ m/hash/i ) {
      $subroutineRef = $signaltype->{'subroutine_ref'};
      @arguments     = &convert_to_array($signaltype->{'args'});
      $signaltype    = $signaltype->{'signal'};
    }

    $subroutineRef = \&generate_exception if ( not defined($subroutineRef) ); 
    @arguments     = [ $ERROR_CONSTANTS{'fail'} ] if ( scalar(@arguments) < 1 );
	
	my $signal_array_obj = &create_object('c__HP::Array::Set__');
	$signal_array_obj->add_elements({'entries' => &get_signal_names()});
	
    $signaltype = 'INT' if ( ( not defined($signaltype) ) || ( $signal_array_obj->contains("$signaltype") eq FALSE ) );

    if ( exists($SIG{"$signaltype"}) ) {
      $LAST_SIGNALHANDLERS{"$signaltype"} = $SIG{"$signaltype"};

      # If the reference type is not an actual subroutine, then wrap it
      # in a local subroutine reference and assign; otherwise
      # take subroutine reference as is... 
      (ref($subroutineRef) !~ m/^code/i) ? $SIG{"$signaltype"} =
	    sub { &$subroutineRef(@arguments) } : $SIG{"$signaltype"} = $subroutineRef;
    }
  }

#=============================================================================
sub restore_signal_handler(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $signal_array_obj = &create_objects('c__HP::Array::Set__');
	$signal_array_obj->add_elements({'entries' => \@_});
	
	my @signals = $signal_array_obj->get_elements();
    foreach my $sig (@signals) {
      $SIG{"$sig"} = $LAST_SIGNALHANDLERS{"$sig"} if ( exists($SIG{"$sig"}) );
    }
  }

#=============================================================================
&__initialize();

#=============================================================================
1;