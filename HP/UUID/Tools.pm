package HP::UUID::Tools;

################################################################################
# Copyright (c) 2013-2014 HP.   All rights reserved
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

use strict;
use warnings;
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

    $VERSION = 0.75;

	@ISA  = qw(Exporter);	
    @EXPORT  = qw (
	               &generate_unique_uuid
				   &get_uuid
				   &is_zero_uuid
				   &valid_uuid
                  );

    $module_require_list = {
	                        'UUID::Tiny'                  => undef,
							
							'HP::Constants'               => undef,
							'HP::Support::Base'           => undef,
							'HP::Support::Hash'           => undef,
							'HP::Support::Object::Tools'  => undef,
							'HP::Support::Configuration'  => undef,
							'HP::Support::Module'         => undef,
							
							'HP::CheckLib'                => undef,
							
							'HP::UUID::Constants'         => undef,
							};
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_uuid_tools_pm'} ||
                 $ENV{'debug_uuid_modules'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );

    $broken_install = 0;

    print STDERR "BEGIN <". __PACKAGE__ .">\n" if ( $is_debug );

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "\t-->Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
        if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod\n" if ( $is_debug ); 
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
sub __initialize()
  {
    if ( not $is_init ) {
      $is_init = 1;
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
sub get_uuid($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $null_uuid = ZERO_UUID;
	
    if ( ( &has('Data::UUID') eq FALSE ) && ( &has('UUID::Tiny') eq FALSE ) ) {
	  return $null_uuid;
	}
	
	if ( &has('UUID::Tiny') ) {
	  my $uuid_type = shift;
	  my $data      = shift || undef;
	  return &UUID::Tiny::uuid_to_string(&UUID::Tiny::create_uuid($uuid_type, $data));	
	}
	
	# Needs to be finished...
	if ( &has('Data::UUID') ) {
    }	
  }

#=============================================================================
sub generate_unique_uuid
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $trials = 0;
	my $uuids  = shift;
	
	if ( &is_type($uuids, 'HP::ArrayObject') eq FALSE ) {
	  my $temp = $uuids;
	  $uuids = &create_object('c__HP::ArrayObject__');
	  $uuids->add_elements({'entries' => $temp});
	}
	
  RECALCULATE_UUID:
    ++$trials;
	
	my $uuidversion = shift || 4;
	$uuidversion = UUID_CONVERT_VERSION->{$uuidversion};
	
	my $possible_UUID = &get_uuid($uuidversion, @_);
	goto RECALCULATE_UUID if ( ( $trials < MAX_UUID_GENERATIONS ) &&
                               ( $uuids->contains($possible_UUID) || $possible_UUID eq ZERO_UUID ) );
							   
	if ( $trials < MAX_UUID_GENERATIONS ) {
	  return $possible_UUID;
	} else {
	  return ZERO_UUID;
	}
  }

#=============================================================================
sub is_zero_uuid
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $id  = shift || return TRUE;
	my $obj = undef;
	
	if ( scalar(@_) > 0 ) {
	  $obj = $id;
	  $id = shift;
	}
	
	if ( &is_blessed_obj($obj) eq TRUE || ref($obj) =~ m/hash/i ) {
	  return TRUE if ( defined($obj->{"$id"}) && ($obj->{"$id"} eq ZERO_UUID) );
	} else {
	  return TRUE if ( $id eq ZERO_UUID );
	}
	return FALSE;
  }

#=============================================================================
sub valid_uuid
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $id  = shift || return FALSE;
	my $obj = undef;
	
	if ( scalar(@_) > 0 ) {
	  $obj = $id;
	  $id = shift;
	}

	my $uuid = undef;
	if ( ref($obj) =~ m/hash/i ) {
	  $uuid = $obj->{'id'};
	} else {
	  $uuid = $id;
	}
	
	if ( $uuid =~ m/^(\w{8})\-(\w{4})\-(\w{4})\-(\w{4})\-(\w{12})$/ ) {
	  my $is_hex = TRUE;
	  
	  $is_hex &= &is_hexadecimal($1);
	  $is_hex &= &is_hexadecimal($2);
	  $is_hex &= &is_hexadecimal($3);
	  $is_hex &= &is_hexadecimal($4);
	  $is_hex &= &is_hexadecimal($5);
	  
	  my $variant_result = &str_matches(lc(substr($4,0,1)), [ '8', '9', 'a', 'b' ]);
	  my @uuidtypes      = keys(%{&UUID_CONVERT_VERSION});
	  my $version_result = &str_matches(lc(substr($3,0,1)), \@uuidtypes);
	  return $variant_result && $version_result && $is_hex;
	}

	return FALSE;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;