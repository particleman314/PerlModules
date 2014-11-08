package HP::DBContainer;

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
    use lib "$FindBin::Bin/../";

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

    $VERSION = 1.2;

    @ISA     = qw ( Exporter );
    @EXPORT  = qw (
	               &createDBs
				   &getDB
				   &shutdownDBs
                  );


    $module_require_list = {
							'HP::Constants'              => undef,
							'HP::Support::Base'          => undef,
							'HP::Support::Object::Tools' => undef,
	                        'HP::CheckLib'               => undef,
                          };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_dbcontainer_pm'} ||
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
my %known_databases = ();  # Private storage for databases, use interface to
                           # access which database requested via 'getDB'

#=============================================================================
sub __create_db($$)
  {
    my $db_id    = shift,
	my $db_class = shift;
	
	return if ( &valid_string($db_id) eq FALSE );
	return if ( &valid_string($db_class) eq FALSE );
	
	my $db = undef;
	
	if ( not exists($known_databases{$db_id}) ) {
	  $db = &create_instance('c__'. $db_class .'__');
	}
	
	if ( defined($db) ) {
	  $known_databases{$db_id} = $db;
	  &__print_debug_output("Database < $db_class > created with moniker < $db_id >", __PACKAGE__) if ( $is_debug );
	}
	
	return;
  }
  
#=============================================================================
sub createDBs()
  {
    &__create_db('stream',    'HP::StreamDB');
    &__create_db('lock',      'HP::LockDB');
    &__create_db('drive',     'HP::Drive::MapperDB');
    &__create_db('uuid',      'HP::UUID::UUIDManager');
    &__create_db('exception', 'HP::ExceptionDB');
	#&__create_db('module',    'HP::Support::ModuleDB');
	
	&__print_debug_output('All possible databases created.', __PACKAGE__) if ( $is_debug );
	return;
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
sub getDB($)
  {
    my $dbid = shift;
	
	return undef if ( &valid_string($dbid) eq FALSE );
	
	return $known_databases{"$dbid"} if ( exists($known_databases{"$dbid"}) );
	return undef;
  }

#=============================================================================
sub shutdownDBs()
  {
    my $dbtypes = &getDBtypes();
	
	foreach ( @{$dbtypes} ) {
	  my $db = &getDB($_);
	  if ( defined($db) ) {
	    $db->shutdown();
	    &__print_debug_output("Database < $_ > shutdown...", __PACKAGE__) if ( $is_debug );
	  }
	}
	
	&__print_debug_output('All possible databases shutdown.', __PACKAGE__) if ( $is_debug );
	return;
  }
  
#=============================================================================
sub getDBtypes()
  {
    my @types = qw(drive lock stream uuid exception module);
	return \@types;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;