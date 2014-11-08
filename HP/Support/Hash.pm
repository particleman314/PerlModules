package HP::Support::Hash;

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

                $broken_install

				@ISA
				@EXPORT
	       );

	@ISA     = qw(Exporter);
    @EXPORT  = qw(
	              &convert_data_to_kv
				  &convert_input_to_hash
				  &manage_inputs
		         );

    $module_require_list = {
	                        'HP::Constants'                => undef,			
							'HP::Support::Base'            => undef,
							'HP::Support::Hash::Constants' => undef,
							'HP::Support::Object'          => undef,
	                       };
    $module_request_list = {};

    $VERSION  = 0.65;
	
    $is_init  = 0;
    $is_debug = (
	         $ENV{'debug_support_hash_pm'} ||
			 $ENV{'debug_support_modules'} ||
		     $ENV{'debug_hp_modules'} ||
		     $ENV{'debug_all_modules'} || 0
		);

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

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
my $local_true    = TRUE;
my $local_false   = FALSE;
my $skip_undefs   = $local_true;

#=============================================================================
sub __hash_merge(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my %temp = ();

    foreach ( @_ ) {
      if ( ( defined($_) ) && ( ref($_) =~ m/hash/i ) ) {
        foreach my $key (keys(%{$_})) {
	      $temp{"$key"} = $_->{"$key"};
        }
	  }
    }
	
    return \%temp;
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
sub allow_undef_settings()
  {
    $skip_undefs = $local_false;
  }
  
#=============================================================================
sub convert_data_to_kv($;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my ( $key, $value ) = undef;
    my $data            = $_[0] || goto __END_OF_SUB;
	
	my $ref_data = ref($data);
	if ( ($ref_data =~ m/^scalar/i) || ($ref_data eq '') ) {
	  $key   = DUMMY_KEY;
	  $value = $data;
	} elsif ( $ref_data =~ m/^array/i ) {
	  my $number_elements = scalar(@{$data});
	  if ($number_elements > 0 ) {
	    $key = $data->[0];
		if ( $number_elements > 1 ) {
		  shift(@{$data});
		  $value = $data;
        }
	  }
	} elsif ( $ref_data =~ m/^hash/i ) {
	  $key = $data->{'key'};
	  $value = $data->{'value'};
	}
	
  __END_OF_SUB:
	return ($key, $value);
  }

#=============================================================================
sub convert_input_to_hash(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $output        = {};
	my $control_data  = shift || goto __END_OF_SUB;
	
	for ( my $loop = 0; $loop < scalar(@{$control_data}); $loop += 2 ) {
	  my $varname  = $control_data->[$loop];
	  my $testfunc = $control_data->[$loop + 1];
	  my $input    = shift;
	  
	  if ( $skip_undefs eq $local_true && (not defined($input)) ) {
	    &__print_debug_output("Skipping varname : $varname", __PACKAGE__) if ( $is_debug );
		next;
	  }
	  
	  &__print_debug_output("Managing varname : $varname", __PACKAGE__) if ( $is_debug );
	  $output->{"$varname"} = $input;
	  
	  if ( ref($testfunc) =~ m/code/i ) {
	    my $result = &{$testfunc}($input);
	    $output->{"$varname"} = undef if ( (not defined($result)) || $result eq $local_false );
	  }
	}
	
	if ( scalar(@_) > 0 ) {
	  $output->{&NON_NAMED_PARAM_SECTION} = \@_;
	}
	
  __END_OF_SUB:
	return $output;
  }

#=============================================================================
sub disallow_undef_settings()
  {
    $skip_undefs = $local_true;
  }
  
# TODO : This needs some work to avoid recursion ( unnecessary nesting )
#=============================================================================
sub manage_inputs(@)
  {
	my $inputdata = {};
	
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash(@_);
    } else {
	  $inputdata = $_[0];
	}
	
	return $inputdata;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;