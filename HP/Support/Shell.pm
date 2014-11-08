package HP::Support::Shell;

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

				%ERROR_CONSTANTS
				
				@ISA
				@EXPORT
               );

    $VERSION    = 0.85;

	@ISA    = qw(Exporter);
    @EXPORT = qw(
                 &add_error_constant
				 &decode_exit_status
				 &env_setmethod
				 &env_unsetmethod
				 &external_env_eval
				 &generate_exception
				 &get_error_constant
				 &get_script_name

				 %ERROR_CONSTANTS
				 
				 NO_CHANGE
                );

    $module_require_list = {
	                        'File::Basename'      => undef,
							
							'HP::Constants'       => undef,
							'HP::Support::Base'   => undef,
							'HP::CheckLib'        => undef,
							'HP::Support::Os'     => undef,
							'HP::Support::Screen' => undef,
						   };
    $module_request_list = {
	                       };

    %ERROR_CONSTANTS     = ();

    $is_init  = 0;
    $is_debug = (
			$ENV{'debug_support_shell_pm'} ||
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
use constant NO_CHANGE => 1;

#=============================================================================
sub __initialize()
  {
    if ( not $is_init ) {
      $is_init = 1;

      &__make_error_constants();

      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
sub __make_error_constants()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    &add_error_constant('help',1);
    &add_error_constant('info',2);
    &add_error_constant('fail',255);
  }

#=============================================================================
sub add_error_constant($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $error_name_type = shift || 'fail';
    my $error_name_code = shift || 255;

    &__print_debug_output("Inputs --> $error_name_type | $error_name_code\n", __PACKAGE__) if ( $is_debug );

    my $badinput = &is_integer($error_name_code);
    my $badrange = ( $error_name_code < 0 ) || FALSE;

	if ( $is_debug ) {
      &__print_debug_output("BadInput marker --> $badinput\n", __PACKAGE__);
      &__print_debug_output("BadRange marker --> $badrange\n", __PACKAGE__);
	}
	
    if ( ( $badinput eq FALSE ) || $badrange eq TRUE ) {
      &__print_output("Cannot use error constant value of << $error_name_code >> for type << $error_name_type >>", __PACKAGE__ );
      return TRUE;
    }
    if ( not exists($ERROR_CONSTANTS{"$error_name_type"}) ) {
      $ERROR_CONSTANTS{"$error_name_type"} = $error_name_code;
      return FALSE;
    }
    return NO_CHANGE;
  }

#=============================================================================
sub decode_exit_status($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    if ( &is_numeric($_[0]) eq FALSE ) { return ( $_[0], -1, -1 ); }

    my $error_signal = $_[0] & 127;
    my $has_coredump = $_[0] & 128;

    return ( $_[0], $error_signal, $has_coredump );
  }

#=============================================================================
sub env_setmethod($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $key       = shift;
    my $value     = shift;

    my $shellenv  = ( &os_is_windows_native() eq TRUE ) ? 'SHELL_TYPE' : 'SHELL';

    my $shelltype = shift || $ENV{"$shellenv"};

    my $envsetmethod;

    if ( defined($shelltype) ) {
      if ( $shelltype =~ m/win/i || $shelltype =~ m/cmd/i ) {
	    $value =~ s/\//\\/g;
	    $envsetmethod = "set $key=\'$value\'";
      } else {
	    $value =~ s/\\/\//g;
	    if ( $shelltype =~ m/csh/i ) {
	      $envsetmethod = "setenv $key \'$value\'";
	    } else {
	      $envsetmethod = "export $key=\'$value\'";
	    }
      }
    } else {
      $envsetmethod = "export $key=\'$value\'";
    }

    return $envsetmethod;
  }

#=============================================================================
sub env_unsetmethod($;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $key       = shift;
    my $shellenv  = ( &os_is_windows_native() eq TRUE ) ? 'SHELL_TYPE' : 'SHELL';

    my $shelltype = shift || $ENV{"$shellenv"};

    my $envunsetmethod;

    if ( defined($shelltype) ) {
      if ( $shelltype =~ m/win/i || $shelltype =~ m/cmd/i ) {
	    $envunsetmethod = "set $key=";
      } else {
	    if ( $shelltype =~ m/csh/i ) {
	      $envunsetmethod = "setenv $key";
	    } else {
	      $envunsetmethod = "unset $key";
	    }
      }
    } else {
      $envunsetmethod = "unset $key";
    }

    return $envunsetmethod;
  }

#=============================================================================
sub external_env_eval($;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $val    = shift;
    my $nosub  = shift;

    return undef if ( ( not defined($val) ) || ( not $val ) );

    &__print_debug_output("Value -- << $val >> :: Allow substitution -- << $nosub >>", __PACKAGE__) if ( $is_debug );

    if ( ( defined($nosub) ) && $nosub ) {
    RETRY:
      my $new_val = "$val";
      if ( $new_val =~ m/\$(\w*)/ ) {
	    my $env_subst = $ENV{"$1"};
	    $new_val =~ s/\$(\w*)/$env_subst/;
      }
      &__print_debug_output("New Value -- << $new_val >> :: Old Value -- << $val >>", __PACKAGE__) if ( $is_debug );
      $val = "$new_val";
      goto RETRY if ( "$new_val" ne "$val" );
    }

    return "$val";
  }

#=============================================================================
sub generate_exception(;$)
{
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $err = shift;
	if ( &is_numeric("$err") eq FALSE ) { exit 1; }
    exit ($err ? $err : &get_error_constant('fail'));
}

#=============================================================================
sub get_error_constant(;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    return 0 if ( scalar(@_) < 1 );
    return 0 if ( not exists($ERROR_CONSTANTS{"$_[0]"}) );
    return $ERROR_CONSTANTS{"$_[0]"};
  }

#=============================================================================
sub get_script_name()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my ($filename, $dirname, $extension) = fileparse("$0",qr/\.[^.]*/);
    return $filename;
  }

#=============================================================================
&__initialize();

#=============================================================================
1;