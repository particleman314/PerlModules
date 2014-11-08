package HP::FindSrcRoot;

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

    @ISA    = qw(Exporter);
    @EXPORT = qw(
		 &find_src_root
		);

    $module_require_list = {
                            'File::Spec'     => undef,
                            'File::Basename' => undef,

			                'HP::RegexLib'           => undef,
			                'HP::Os'                 => undef,
                            'HP::Path'               => undef,
                            'HP::IOTools'            => undef,
			                'HP::Parsers::xmlloader' => undef,
                           };

    $VERSION  = 0.9;

    $is_init  = 0;
    $is_debug = (
		 $ENV{'debug_findsrcroot_pm'} ||
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
      print STDERR "INIITALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
sub find_src_root(;$$)
  {
    &__print_debug_output("Inside 'find_src_root'\n", __PACKAGE__);

    my $topfile  = '.top';
    my $bld_root = shift || &get_full_path(File::Spec->curdir());
    my $streams  = shift || [ '__NOWHERE__' ];

    my @searched_bld_dirs = ();

	&__print_debug_output("Topfile --> $topfile", __PACKAGE__);
	
    if ( defined($HP::Parses::xmlloader::xmlcontent) ) {
      my $fsr_section = &extract_xml_section( 'modules->findsrcroot' );
      if ( defined($fsr_section) ) {
	    @searched_bld_dirs = &extract_contents_as( $fsr_section, 'blddirs' ) if ( exists($fsr_section->{'blddirs'}) );
	    $topfile = $fsr_section->{'topfile'} if ( exists($fsr_section->{'topfile'}) );
      }
    }

    &__print_debug_output("Searchable subdirectories --> ".Dumper(\@searched_bld_dirs), __PACKAGE__) if ( $is_debug );
    goto NO_TOP if ( not defined($bld_root) || ref($bld_root) ne '' );

    &__print_debug_output("Initial bld root directory --> $bld_root\n", __PACKAGE__ );
    my $previous_bld_root = "$bld_root";

    for (;;) {
      last if "$bld_root" eq '.';

      # These are all the conditions for finding the root of a project source
      # tree using BldTools or in the legacy Sysgen build.

      last if ( not defined($bld_root) );
      return &path_to_mixed("$bld_root") if ( ( -e &join_path( "$bld_root", "$topfile" ) ) && ( "$bld_root" !~ m/\/test/ ) );

      foreach my $sbd (@searched_bld_dirs) {
	return &path_to_mixed("$bld_root") if ( -e &join_path( "$bld_root", &path_to_mixed( "$sbd" ) ) );
      }

      $previous_bld_root = "$bld_root";

      # Chop the last directory off the path and try again.
      $bld_root = File::Basename::dirname("$bld_root");
      &__print_debug_output("Current bld_root directory --> $bld_root\n", __PACKAGE__);

      if ( ( "$bld_root" eq '' ) ||
	   ( "$bld_root" eq &get_dir_sep() ) ||
	   ( $bld_root =~ /^\w:$/ ) || ( $previous_bld_root eq $bld_root ) ) {
	# All directories were chopped off, and the algorithm hit the root
	# of the directory structure.
	&raise_exception(
			 'NO_BUILD_TREE_FOUND',
			 "You do not appear to be in a build tree.",
			 \&bypass_error,
			 $streams
			);
	return undef;
      }
    }

  NO_TOP:
    &raise_exception(
	             'NO_BUILD_TREE_FOUND',
	             'Executed last line in FindSrcRoot.pm [ should not have ]',
	            );
  }

#=============================================================================
&__initialize();

#=============================================================================
1;
