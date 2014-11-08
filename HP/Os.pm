package HP::Os;

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
				$os_signals

                %default_os_hash
                %default_hash_os

                @ISA 
				@EXPORT
               );

    $module_require_list = {
                            'Net::Ping'                    => undef,
			                'Config'                       => undef,

							'HP::Constants'                => undef,
			                'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object::Tools'   => undef,
							
			                'HP::Support::Os'              => undef,
							'HP::Support::Os::Constants'   => undef,
			                'HP::String'                   => undef,
							'HP::Os::Constants'            => undef,
			                'HP::Array::Tools'             => undef,
			               };
    $module_request_list = {};

    @ISA    = qw(Exporter);
    @EXPORT = qw(
				 &get_bit_size
                 &get_dir_sep
				 &get_hostname
				 &get_homedir
				 &get_fn_limit
				 &get_known_filename_limits
				 &get_known_oses
				 &get_ostag
				 &get_os_type
                 &get_native_ostag
				 &get_signal_names
				 &get_username
                 &is_machine_offline
                 &is_os_known
				 &modify_signals_by_os
				 &os_is_64bit
				 &translate_os
				 &translate_signal_id
                 &trap_signals
		        );

    $os_signals = {};
    $is_init    = 0;
    $is_debug   = (
		           $ENV{'debug_os_pm'} ||
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

    %default_os_hash = (
	                    'win32' => 'nt',
			            'win64' => 'nt64',
			            'lin32' => 'lin',
			            'lin64' => 'lin64',
                       );
    %default_hash_os = reverse %default_os_hash;

    # Print a messages stating this module has been loaded.
    print STDERR "LOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
END
  {
    print STDERR "UNLOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
my @oses = keys(%default_os_hash);
my $filename_size_limits = {
			                &WINDOWS_SHORTNAME => WINDOWS_PATH_MAX,
			                &LINUX_SHORTNAME   => LINUX_PATH_MAX,
			               };

#=============================================================================
sub __initialize()
  {
    if ( not $is_init ) {
      $is_init = 1;
      &modify_signals_by_os();

      print STDERR "INITALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
sub __name_to_num($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $signal_id = shift;
    return $os_signals->{"$signal_id"};
  }

#=============================================================================
sub __num_to_name($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $signal_id = shift;
    foreach my $sigid (keys(%{$os_signals})) {
      if ( $os_signals->{"$sigid"} eq "$signal_id" ) {
	    return $sigid;
      }
    }
    return 'UNKNOWN';
  }

#=============================================================================
sub __prepare_signal_traps($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    &trap_signals($_[0]) if ( defined($_[0]) );
    my $xml_signal_handling = $_[1] || return;

    return if ( ref($xml_signal_handling) !~ m/hash/i );

    if ( defined($xml_signal_handling) ) {
      my @os_signals = @{&get_signal_names()};
      foreach my $sighdl ( @{$xml_signal_handling} ) {
	    if ( ( exists($sighdl->{'signal'}) ) && ( exists($sighdl->{'handler'}) ) &&
	         ( &set_contains(\@os_signals, $sighdl->{'signal'}) ) &&
	         ( defined($SIG{"$sighdl->{'signal'}"}) ) ) {
	      my $sigeval = "\$SIG{\'$sighdl->{'signal'}\'} = $sighdl->{'handler'}";
	      &__print_debug_output("Handling user defined signal/handler --> ($sighdl->{'signal'}|$sighdl->{'handler'})", __PACKAGE__);
	      eval "$sigeval";
	      if ( $@ ) {
	        &__print_output("Problem with handling signal type << $sighdl >>...", __PACKAGE__);
	      }
	    }
      }
    }
  }

#=============================================================================
sub get_bit_size()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    return 64 if ( &os_is_64bit() );
    return 32;
  }

#=============================================================================
sub get_dir_sep()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    return &os_is_windows_native() ? '\\' : '/';
  }
  
#=============================================================================
sub get_homedir()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    return $ENV{'HOME'} || $ENV{'USERPROFILE'};
  }
  
#=============================================================================
sub get_hostname()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    return $ENV{'HOSTNAME'} || $ENV{'HOST'} || &chomp_r(`hostname`);
  }

#=============================================================================
sub get_fn_limit()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	if ( &os_is_windows_native() ) {
	   return &get_known_filename_limits(WINDOWS_SHORTNAME);
	}
	return &get_known_filename_limits(LINUX_SHORTNAME);
  }
  
#=============================================================================
sub get_known_filename_limits(;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    if ( scalar(@_) ) {
      return $filename_size_limits->{"$_[0]"} if ( exists($filename_size_limits->{"$_[0]"}) );
      return '?';
    }

    return $filename_size_limits;
  }

#=============================================================================
sub get_known_oses()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    return \@oses;
  }

#=============================================================================
sub get_ostag()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    if ( &os_is_windows() ) { 
      return &get_native_ostag();
    } else {
      my $ostype = ( &os_is_64bit() ) ? 'lin64' : 'lin32';
      return $ostype;
    }
  }

#=============================================================================
sub get_os_type()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    if ( &os_is_windows() ) {
      if ( &os_is_windows_native() ) {
	    return WINDOWS_SHORTNAME;
      } else {
	    return 'cygwin';
      }
    } else {
      return LINUX_SHORTNAME;
    }
  }
  
#=============================================================================
sub get_native_ostag()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    if ( &os_is_windows() ) {
      return ( &os_is_64bit() ) ? 'win64' : 'win32';
    } elsif ( &os_is_linux() ) {
      return ( &os_is_64bit() ) ? 'lin64' : 'lin32';
    } else {
      return 'unknown';
    }
  }

#=============================================================================
sub get_signal_names()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    return $os_signals;
  }

#=============================================================================
sub get_username()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    return $ENV{'USER'} || $ENV{'USERNAME'} || &chomp_r(`whoami`);
  }

#=============================================================================
sub is_machine_offline($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $host_to_find = shift || return OFFLINE;
    my $bouncer      = &create_object('c__Net::Ping__');

    if ( defined($bouncer) ) {
      my @result = $bouncer->ping("$host_to_find", 10);

	  if ( $is_debug ) {
        &__print_debug_output("Result from ping for host << $host_to_find >>", __PACKAGE__ );
        &__print_debug_output("Result : $result[0]\n", __PACKAGE__) if ( defined($result[0]) );
	  }
      return ONLINE if ( $result[0] );
    }
    return OFFLINE;
  }

#=============================================================================
sub is_os_known($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    return FALSE if ( not defined($_[0]) );
    return FALSE if ( not &set_contains("$_[0]",\@oses) );
    return TRUE;
  }

#=============================================================================
sub modify_signals_by_os($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    # Need to allow for specific information passed to
    # be appended/changed/removed!

    # Allow PERL to tell us what is supported...
    my @specific_signals    = split(' ',$Config{'sig_name'});
    my @specific_signals_id = split(' ',$Config{'sig_num'});

    for ( my $count = 0; $count < scalar(@specific_signals_id); ++$count ) {
      #&__print_debug_output("Managing signal : $specific_signals[$count] with id $specific_signals_id[$count]\n", __PACKAGE__);
      $os_signals->{"$specific_signals[$count]"} = $specific_signals_id[$count];
    }
  }

#=============================================================================
sub os_is_64bit()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $machtype = undef;

    if ( &os_is_windows() ) {
      $machtype = $ENV{'PROCESSOR_ARCHITECTURE'};
    } else {
      $machtype = &chomp_r(`uname -a`);
    }

    if ( not defined($machtype) ) { $machtype = $Config{'ptrsize'} * 8; }

    if ( ( $machtype =~ m/WOW64/ ) ||
	 ( $machtype =~ m/AMD64/ ) ||
	 ( $machtype =~ m/x86_64/ ) ) {
      return TRUE;
    } else {
      return FALSE;
    }
  }

#=============================================================================
sub reset_known_oses($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $os_hash = shift || return;
    if ( ref($os_hash) !~ m/hash/i ) {
      &__print_output("Must send hash to reset OS types", __PACKAGE__);
      return;
    }

    %default_os_hash = %{&HP::Support::Hash::__hash_merge(\%default_os_hash, $os_hash)};
    %default_hash_os = reverse %default_os_hash;

    @oses = keys(%default_os_hash);
  }

#=============================================================================
sub translate_os(;$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $hashref = shift;

    my $ostype    = undef;
    my $direction = undef;

    if ( ref($hashref) !~ m/hash/i ) {
      $ostype    = $hashref || &get_ostag();
      $direction = shift || 'forward';
    } else {
      $ostype    = exists( $hashref->{'os'} )        ? $hashref->{'os'}        : &get_ostag();
      $direction = exists( $hashref->{'direction'} ) ? $hashref->{'direction'} : 'forward' ;
    }

    &__print_debug_output("OS Declaration -- << $ostype >>  ::  Translation Direction -- << $direction >>", __PACKAGE__);

    if ( $direction =~ m/forward/i ) {
      return $default_os_hash{"$ostype"} if ( exists($default_os_hash{"$ostype"}) );
      return UNKNOWN;
    }

    if ( $direction =~ m/backward/i ) {
      return $default_hash_os{"$ostype"} if ( exists($default_hash_os{"$ostype"}) );
      return UNKNOWN;
    }

    return undef;
  }

#=============================================================================
sub translate_signal_id($;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $signal_id            = shift || return -1;
    my $translation_function = shift || '__num_to_name';

    if ( ( $translation_function ne '__num_to_name' ) &&
	 ( $translation_function ne '__name_to_num' ) ) {
      return $signal_id;
    }

    no strict;
    my $result = &{$translation_function}($signal_id);
    use strict;

    return $result;
  }

#=============================================================================
sub trap_signals($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $function_callback = shift || goto BASIC_TRAPS;

    foreach my $sighdl (keys(%{&get_signal_names()})) {
      &__print_debug_output("Managing signal type << $sighdl >>", __PACKAGE__);
      if ( exists($SIG{"$sighdl"}) ) {
	    $SIG{"$sighdl"} = $function_callback     if ( ref($function_callback) =~ m/code/i );
	    $SIG{"$sighdl"} = \&{$function_callback} if ( ref($function_callback) eq '' );
      }
    }

    # User can override this if needed...

  BASIC_TRAPS:
    my $special_signals = {
	                       'CHLD'  => 'DEFAULT',
			               'WINCH' => 'DEFAULT',
			               'PIPE'  => 'DEFAULT',
                          };

    foreach my $sighdl ( keys(%{$special_signals}) ) {
      if ( exists($os_signals->{"$sighdl"}) ) {
	    $SIG{"$sighdl"} = $special_signals->{"$sighdl"};
      }
    }
  }

#=============================================================================
&__initialize();

#=============================================================================
1;
