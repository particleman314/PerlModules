package HP::Timestamp;

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

                @ISA
                @EXPORT
               );
    
    $VERSION = 0.7;

    @ISA    = qw(Exporter);
    @EXPORT = qw(
		         &get_time_array
		         &get_formatted_datetime
		         &get_formatted_date
		         &get_formatted_elapsed_time
		         &get_formatted_elapsed_time_hires
		         &get_formatted_time
		         &get_formatted_time_hires
		         &get_raw_datetime
		         &get_raw_datetime_hires
		         &get_date_difference
		        );

    $module_require_list = {
                            'Time::HiRes'              => undef,
							'POSIX'                    => undef,
	                        'HP::Constants'            => undef,
			                'HP::Support::Base'        => undef,
							'HP::Support::Module'      => undef,
							
							'HP::Timestamp::Constants' => undef,
                           };
    $module_request_list = {
                            'Date::Pcalc' => undef,
                           };

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_timestamp_pm'} ||
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
sub __delta_dhms($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my ( $date1, $date2 ) = @_;
    return undef if ( ( ref($date1) !~ m/hash/i ) ||
		      ( ref($date2) !~ m/hash/i ) );

    my ($dd, $dh, $dm, $ds) = Date::Pcalc::Delta_DHMS($date1->{'year'},  $date1->{'month'},   $date1->{'day'},
						      $date1->{'hours'}, $date1->{'minutes'}, $date1->{'seconds'},
						      $date2->{'year'},  $date2->{'month'},   $date2->{'day'},
						      $date2->{'hours'}, $date2->{'minutes'}, $date2->{'seconds'});

    if ( ( $dh > 0 ) || ( $dm > 0 ) || ( $ds > 0 ) ) {
      return $dd + 1;
    } else {
      return $dd;
    }
  }

#=============================================================================
sub __initialize()
  {
    if ( not $is_init ) {
      $is_init = 1;
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }
                                
#=============================================================================
sub get_date_difference($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $answer = &has("Date::Pcalc");
    if ( $answer eq TRUE ) {
      my $date1 = shift;
      my $date2 = shift;
      my $type  = shift || 'delta_dhms';

      return undef if ( ( not defined($date1) ) || ( not defined($date2) ) );

      if ( $type eq 'delta_dhms' ) {
	    my $dd = 0;
	    my $stmt = "\$dd = \&__${type}(\$date1,\$date2);";
	    disable diagnostics;
	    eval ("$stmt" );
	    enable diagnostics;
	    return $dd;
      }
      return undef;
    } else {
      return undef;
    }
  }

#=============================================================================
sub get_elapsed_time_array($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    my $starttime = shift;

    my $elapsed   = time() - $starttime;
    my $days      = int($elapsed/( HOURS_IN_DAY * MINS_IN_HOUR * SECS_IN_MIN ));
    $elapsed-= $days * HOURS_IN_DAY * MINS_IN_HOUR * SECS_IN_MIN;
    my $hours     = int($elapsed/( MINS_IN_HOUR * SECS_IN_MIN ));
    $elapsed-= $hours * MINS_IN_HOUR * SECS_IN_MIN;
    my $minutes   = int($elapsed/( SECS_IN_MIN ));
    $elapsed-= $minutes * SECS_IN_MIN;
    my $seconds   = int($elapsed);
    my $msec      = int(($elapsed-$seconds)*100);
    return ($days, $hours, $minutes, $minutes, $seconds, $msec);
  }

#=============================================================================
sub get_formatted_date(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my @t = &get_time_array(@_);
    return sprintf("%04u-%02u-%02u", $t[5]+1900, $t[4]+1, $t[3]);
  }

#=============================================================================
sub get_formatted_datetime(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my @t = ();
    if ( ref($_[1]) =~ m/hash/i ) {
      &__print_debug_output("Handling offset date/time hash...",__PACKAGE__) if ( $is_debug );
      @t = &get_time_array(shift, shift);
    } else {
      @t = &get_time_array(shift);
    }
    my $connector   = $_[0] || ' ';
    my $time_concat = $_[1] || ':';
    return sprintf("%04u-%02u-%02u${connector}%02u${time_concat}%02u${time_concat}%02u", $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0]);
  }

#=============================================================================
sub get_formatted_elapsed_time(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $starttime = shift;
    my ($days, $hours, $minutes, $seconds, $msec) = &get_elapsed_time_array($starttime);
    my $csec = int($msec/10);
    if ($days) {
      return sprintf("%u:%02u:%02u:%02u", $days, $hours, $minutes, $seconds);
    }
    elsif ($hours) {
      return sprintf("%u:%02u:%02u", $hours, $minutes, $seconds);
    }
    elsif ($minutes) {
      return sprintf("%u:%02u", $minutes, $seconds);
    }
    return sprintf("%u sec", $seconds);
  }

#=============================================================================
sub get_formatted_elapsed_time_hires(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $starttime = shift;
    my ($days, $hours, $minutes, $seconds, $msec) = &get_elapsed_time_array($starttime);
    my $csec = int($msec/10);
    if ($days) {
      return sprintf("%u:%02u:%02u:%02u.%02u", $days, $hours, $minutes, $seconds, $csec);
    }
    elsif ($hours) {
      return sprintf("%u:%02u:%02u.%02u", $hours, $minutes, $seconds, $csec);
    }
    elsif ($minutes) {
      return sprintf("%u:%02u.%02u", $minutes, $seconds, $csec);
    }
    return sprintf("%u.%02u sec", $seconds, $csec);
  }

#=============================================================================
sub get_formatted_time(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my @t = &get_time_array(@_);
    my $time_concat = $_[1] || ':';
    return sprintf("%02u${time_concat}%02u${time_concat}%02u", $t[2], $t[1], $t[0]);
  }

#=============================================================================
sub get_formatted_time_hires(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my @t   = &get_time_array(@_);
    my @tod = &Time::HiRes::gettimeofday();
    return sprintf("%02u:%02u:%02u.%02u", $t[2], $t[1], $t[0], int($tod[1]/10000));
  }

#=============================================================================
sub get_raw_datetime(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my @t = &get_time_array(@_);
    return sprintf("%04u%02u%02u%02u%02u%02u", $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0]);
  }

#=============================================================================
sub get_raw_datetime_hires(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    my @t   = &get_time_array(@_);
    my @tod = &Time::HiRes::gettimeofday();
    return sprintf("%04u%02u%02u%02u%02u%02u%03u", $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0], int($tod[1]/1000));
  }

#=============================================================================
sub get_time_array($;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    my $islocal  = shift;
    my $date_adj = shift;

    my @current_time = ();

    if (defined($islocal) && $islocal) {
      @current_time = localtime;
    } else {
      @current_time = gmtime();
    }

	if ( $is_debug ) {
      &__print_debug_output("Checking for offset matrix...",__PACKAGE__);
      &__print_debug_output("Date Offset matrix\n".Dumper($date_adj),__PACKAGE__);
      &__print_debug_output("Unmodified Current Date/Time\n".Dumper(\@current_time),__PACKAGE__);
	}
	
    if ( defined($date_adj) && ref($date_adj) =~ m/hash/i ) {
      if ( exists($date_adj->{'year_offset'}) )   { $current_time[5] += $date_adj->{'year_offset'}; }
      if ( exists($date_adj->{'month_offset'}) )  { $current_time[4] += $date_adj->{'month_offset'}; }
      if ( exists($date_adj->{'day_offset'}) )    { $current_time[3] += $date_adj->{'day_offset'}; }
      if ( exists($date_adj->{'hour_offset'}) )   { $current_time[2] += $date_adj->{'hour_offset'}; }
      if ( exists($date_adj->{'minute_offset'}) ) { $current_time[1] += $date_adj->{'minute_offset'}; }
      if ( exists($date_adj->{'second_offset'}) ) { $current_time[0] += $date_adj->{'second_offset'}; }
   }
    &__print_debug_output("Update Date/Time\n".Dumper(\@current_time),__PACKAGE__) if ( $is_debug );
    return @current_time;
  }

#=============================================================================
&__initialize();

#=============================================================================
1;