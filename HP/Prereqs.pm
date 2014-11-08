package HP::Prereqs;

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

use strict;
use warnings;
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
    
    $VERSION = 0.5;
    @ISA     = qw (Exporter);
    @EXPORT  = qw (
                   &load_env_from_prereqs
                   &find_and_load_prereqs
                   &load_prereqs_file
                  );

    $module_require_list = {
                            'File::Path'            => undef,
                            'File::Basename'        => undef,
                            'File::Copy::Recursive' => undef,

                            'HP::RegexLib'            => undef,
                            'HP::String'              => undef,
                            'HP::ArrayTools'          => undef,
                            'HP::Os'                  => undef,
			    'HP::OsSupport'           => undef,
                            'HP::ConfigFile'          => undef,
                            'HP::Environment::Config' => undef,
                            'HP::StreamManager'       => undef,
			    'HP::FileManager'         => undef,
                            'HP::FindSrcRoot'         => undef,
                            'HP::Path'                => undef,
                            'HP::TextTools'           => undef,
			    'HP::Environment::Helper' => undef,
                           };

    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
		         $ENV{'debug_prereqs_pm'} ||
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
sub __initialize()
  {
    if ( not $is_init ) {
      $is_init = 1; 
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }     
  }

#=============================================================================
sub load_env_from_prereqs(;$$)
  {
    my %prereqs          = ();
    my $prereqsref       = shift || \%prereqs;
    my $addon_prereqsref = shift || {};

    &find_and_load_prereqs($prereqsref);

    # Add implicit configurations if not specified in prereqs.conf.
    $prereqsref->{'cygwin'}     ||= [ 'latest' ] if ( ( not &os_is_windows_native() ) && 
						      ( not &os_is_linux() ) );

    if ( ref($addon_prereqsref) =~ m/hash/i ) {
      foreach my $addon_entry (keys(%{$addon_prereqsref})) {
	$prereqsref->{"$addon_entry"} = $addon_prereqsref->{"$addon_entry"};
      }
    }

    foreach my $key (keys(%{$prereqsref})) {
      if ($key eq 'idfile') {
	delete($prereqsref->{$key});
	next;
      }
      #$prereqsref->{$key}[0] =~ s/[\<\>]//g; # Strip unimplemented min/max characters
    }

    &__print_debug_output("Prereqs --> ".Dumper($prereqsref), __PACKAGE__) if ( $is_debug );

    my $rval = &config_environment($prereqsref, {});
    die "Failure occured during environment configuration.  Cannot continue.\n"
      if ( ( not $rval ) && ( not $ENV{'IGNORECSLBLDPREREQS'} ) );
  }

#=============================================================================
sub find_and_load_prereqs($$;$)
  {
    my $ref                 = shift;
    my $additional_tryfiles = shift;
    my $top                 = shift || undef;

    if ( not defined($ref) ) { die "ERROR: ".caller(0)." expects hash reference\n"; }

    if ( not defined($top) ) {
      $top = &find_src_root() or return undef;
    }

    # These locations are relative to "TOP" of src contributions...
    my @tryfiles = qw(
		      devtools/prereqs.conf
		      devtools/conf/prereqs.conf
		      prereqs.conf
		     );
    if ( defined($additional_tryfiles) ) {
      my @addon_tryfiles = &convert_2_array($additional_tryfiles);
      push(@tryfiles, @addon_tryfiles) if ( scalar(@addon_tryfiles) );
    }

    # Try to find the prereqs file
    my $prereqfn;
    foreach my $tryfile (@tryfiles) {
      my $fn = &normalize_path(&join_path("$top","$tryfile"));
      if ( &does_file_exist( "$fn" ) ) {
	$prereqfn = "$fn";
	&load_prereqs_file("$prereqfn", $ref);
	return 1; # done
      }
    }
    return undef; # no prereqs.conf to be found
  }

#=============================================================================
sub load_prereqs_file($$)
  {
    my $prereqfn = shift;
    my $ref      = shift;

    my $os = &get_ostag();
    &__print_debug_output("OS Tag --> $os",__PACKAGE__);

    my @lines = &slurp("$prereqfn");

    foreach my $line (@lines) {
      &__print_debug_output ("Raw line --> $line", __PACKAGE__);
      $line = &clean_read_line($line);
      next if ( length($line) < 1 );
      &__print_debug_output("Cleaned (Final) Line --> < $line >", __PACKAGE__);

      my ($code, $key, @values) = split /\s+/, $line;
      $key = lc($key) if ( $code ne 'def' );

      # Replace any variable with an environment variable
      foreach (@values) {
    REFILTER:
	s/\$(\w+)/$ENV{$1}/g;
	s/\$\{(\w+)\}/$ENV{$1}/g;
	if ( m/\$/ ) { goto REFILTER; };
      }

      if ( $code eq 'def' ) {
	&setenv("$key",join(' ',@values));
	next;
      }

      &__print_debug_output("Refiltering completed...\n", __PACKAGE__);

      my $allowed = 0;
      if ( scalar(@values) > 1 ) {
        for (my $idx = 1; $idx < scalar(@values); ++$idx) {
          if ( ( length($values[$idx]) > 0 ) &&
	       ( $values[$idx] =~ m/$os/ ) ) {
	    $allowed = 1;
	    splice(@values, $idx, 1);
	    last;
	  }
	}
      } else {
	$allowed = 1;
      }
      $ref->{$key} = \@values if ( $allowed );
    }

    &__print_debug_output("Reference Data Structure --> ".Dumper($ref), __PACKAGE__) if ( $is_debug );
  }

#=============================================================================
&__initialize();

#=============================================================================
1;
