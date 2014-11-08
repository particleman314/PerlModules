package HP::UnitConversion;

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

    use vars qw(
		        $VERSION
		        $is_debug
		        $is_init

                $module_require_list
                $module_request_list

                $broken_install

                $aliases
		        $conversion_table

		        @ISA
		        @EXPORT
	           );

    $VERSION   = 0.4;

    @ISA    = qw (Exporter);
    @EXPORT = qw (
		          &unit_convert
		         );

    $module_require_list = {
	                        'HP::Constants'     => undef,
							'HP::Support::Base' => undef,
                           };
    $module_request_list = {};

    $conversion_table = {};
    $aliases          = {};

    $is_init  = 0;
    $is_debug = (
		         $ENV{'debug_unitconversion_pm'} ||
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

    # Print a message stating this module has been loaded.
    print STDERR "LOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
END
  {
    print STDERR "UNLOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
sub __check_4_aliases($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $unit = shift || return;
    if ( exists($aliases->{$unit}) ) { return $aliases->{$unit}; }
    return $unit;
  }

#=============================================================================
sub __define_conversiontable()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    $conversion_table = {
			 'minutes-seconds' => 60,
			 'hours-seconds'   => 60 * 60,
			 'days-seconds'    => 24 * 60 * 60,
			};
    $aliases = {
	            's'    => 'seconds',
		        'secs' => 'seconds',
		        'mins' => 'minutes',
               };
  }

#=============================================================================
sub __initialize()
  {
    if ( not $is_init ) {
      &__define_conversiontable();
      $is_init = 1;
    }
  }

#=============================================================================
sub __unit_conversion($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $value = shift;
    my $cu    = shift;
    my $ru    = shift;

    $cu = &__check_4_aliases("$cu");
    $ru = &__check_4_aliases("$ru");

    &__print_debug_output("Current Unit --> << $cu >> :: Requested Unit --> << $ru >>", __PACKAGE__) if ( $is_debug );

    if ( exists($conversion_table->{"$cu-$ru"}) ) {
      return $value * $conversion_table->{"$cu-$ru"};
    } elsif ( exists($conversion_table->{"$ru-cu"}) ) {
      return $value / $conversion_table->{"$cu-$ru"};
    }

    return $value;
  }

#=============================================================================
sub unit_convert($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $value         = $_[0];
    my $current_units = $_[1];
    my $request_units = $_[2];

    if ( ref($_[0]) =~ m/hash/i ) {
      $value = $_[0]->{"$_[1]"};
      $current_units = $_[0]->{"$_[1]\_unit"};
      $request_units = $_[2];
    }
    return $value if ( ( not defined($current_units) ) || ( scalar(@_) != 3 ) );
    return &__unit_conversion($value, $current_units, $request_units);
  }

#=============================================================================
&__initialize();

#=============================================================================
1;
