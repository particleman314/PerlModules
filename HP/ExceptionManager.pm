package HP::ExceptionManager;

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

                $module_callback
		
				@ISA
				@EXPORT
               );

    $VERSION  = 0.85;

	@ISA    = qw(Exporter);
    @EXPORT = qw(
	             &get_exceptions
				 &mark_exception
				 &register_exception
				 &store_exception_data
				 &unregister_exception
				);

    $module_require_list = {
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,							
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							
							'HP::Exception::Constants'     => undef,
						   };
    $module_request_list = {
	                       };

    $module_callback     = {};

    $is_init  = 0;
    $is_debug = (
			$ENV{'debug_exceptionmanager_pm'} ||
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
our $registered_exception_classes = {};

#=============================================================================
sub __initialize()
  {
    if ( not $is_init ) {
      $is_init = 1;
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
sub get_exceptions(;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $request_unregistered = ( scalar(@_) > 0 ) ? TRUE : FALSE;
	
	my $new_edata = {};
	foreach my $subsection ( keys(%{$registered_exception_classes}) ) {
	  $new_edata->{$subsection} = {};
	  foreach my $edata ( keys(%{$registered_exception_classes->{$subsection}}) ) {
		$new_edata->{$subsection}->{$edata} = $registered_exception_classes->{$subsection}->{$edata};
	    if ( $request_unregistered eq TRUE ) {
	      if ( ( defined($registered_exception_classes->{$subsection}->{$edata}->[2]) &&
		       $registered_exception_classes->{$subsection}->{$edata}->[2] eq EXCEPTION_REGISTERED ) ) {
		    delete( $new_edata->{$subsection}->{$edata} );
		  }
		}
	  }
	}
	
	return $new_edata;
  }

#=============================================================================
sub mark_exception($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    return if ( scalar(@_) < 1 );
	return if ( &valid_string($_[0]) eq FALSE );
	
	$_[1] = EXCEPTION_REGISTERED if ( scalar(@_) < 2 );

	if ( $_[1] ne EXCEPTION_REGISTERED && $_[1] ne EXCEPTION_UNREGISTERED ) {
	  &__print_output("Cannot use $_[1] as delineation for exception", WARN);
	  return;
	}
	
	foreach my $subsection ( keys(%{$registered_exception_classes}) ) {
	  foreach my $edata ( keys(%{$registered_exception_classes->{$subsection}}) ) {
	    if ( $edata eq $_[0] ) {
	      $registered_exception_classes->{$subsection}->{$edata}->[2] = $_[1];
		}
	  }
	}
	return;
  }
  
#=============================================================================
sub register_exception($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	&mark_exception($_[0], EXCEPTION_REGISTERED);
	return;
  }
  
#=============================================================================
sub store_exception_data($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    return if ( scalar(@_) < 2 );
    return if ( ref($_[1]) !~ m/hash/i );
	
	if ( not defined($_[2]) ) {
	  $registered_exception_classes->{$_[0]} = $_[1];
	} else {
	  $registered_exception_classes->{$_[0]} = &HP::Support::Hash::__hash_merge( $registered_exception_classes->{$_[0]}, $_[1] );
	}
	
	return;
  }

#=============================================================================
sub unregister_exception($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	&mark_exception($_[0], EXCEPTION_UNREGISTERED);
	return;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;