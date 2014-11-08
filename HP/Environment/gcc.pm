package HP::Environment::gcc;

use strict;
use warnings;
use diagnostics;

#=============================================================================
BEGIN
  {
    # Include the exporter and class::struct modules.
    use Exporter();

    use FindBin;            
    use lib "$FindBin::Bin/..";
                            
    use vars qw(           
                $VERSION
                $is_debug
                $is_init
                $temporary_roots

                $module_require_list
                $module_request_list

                $broken_install
   
                @ISA
                @EXPORT
               );

    $VERSION  = 0.7;
 
    @ISA    = qw(Exporter);
    @EXPORT = qw(
                );

    $module_require_list = {
                            'File::Path' => undef,

			    'HP::RegexLib'            => undef,
                            'HP::Path'                => undef,
			    'HP::Os'                  => undef,
                            'HP::Environment::Helper' => undef,
			    'HP::StreamManager'       => undef,
			    'HP::FileManager'         => undef,
                           };

    $module_request_list = {
                           };

    $is_init  = 0;
    $is_debug = (
		 $ENV{'debug_gcc_pm'} or
		 $ENV{'debug_environment_config_pm'} or
		 $ENV{'debug_hp_modules'} or
		 $ENV{'debug_all_modules'}
		);

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
sub __cleanup_roots()
  {
    &HP::Environment::Config::ec_remove_search_roots($temporary_roots);
  }

#=============================================================================
sub __determine_OS_distribution()
  {
    my $distro = undef;

    # RedHat system
    if ( &does_file_exist("/etc/redhat-release") ) {
      $distro = 'RedHat_'.&__parse_redhat_version();
      &eh_setenv('OS_DISTRIBUTION',"$distro");
      &HP::Environment::Config::__augment_module_env('distro', 1);
    }

    # SuSE system

    # Other systems

    return $distro;
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
sub __parse_redhat_version()
  {
    my $rhver = '0u0';
    my $hdl = &open_stream("/etc/redhat-release", 'r'm '__RELEASE__');
    if ( $hdl ) {
      while ( my $line = $hdl->getline() ) {
	$line = &chomp_r("$line");
	if ( $line !~ m/^Red Hat(\S*)/ ) {
	  next;
	} else {
	  $rhver = "$1u$2" if ( $line =~ m/\S*\srelease\s(\d*)\.(\d*)\s/ );
	  $rhver = "$1u$2" if ( $line =~ m/\S*\srelease\s(\d*)\s\(\S*\sUpdate\s(\d)\)/ );
	  last;
	}
      }
      &close_stream('__RELEASE__');
    }
    &__print_debug_output("RedHat version found --> $rhver", __PACKAGE__);
    return "$rhver";
  }

#=============================================================================
# Set up loader for GCC.
sub install_package()
  {
    $HP::Environment::Config::ec_installs{'gcc'} = {
						       '*' => {
							       'searchtype'     => 'opt',
							       'subpath'        => [ 'build', 'build/gcc' ],
							       'configfunc'     => \&config_environment_gcc,
							       'platforms'      => [ 'linux' ],
							       'setversion'     => 'GCCVER',
                                                               'primary_root'   => \&multi_os_gcc_usage,
							       'store_mod_name' => 1,
							      }
						      };
    $temporary_roots = undef;
  }

#=============================================================================
sub multi_os_gcc_usage($;$$$)
  {
    my $known_roots = shift || [];
    my $current_os  = &get_native_ostag();
    my $expected_os = &get_ostag();

    my @newroots = ();

    if ( $current_os ne $expected_os ) {
      for (my $loop = 0 ; $loop < scalar(@{$known_roots}); ++$loop ) {
        if ( $known_roots->[$loop] =~ m/$expected_os/ ) {
          my $newroot = $known_roots->[$loop];
          $newroot =~ s/$expected_os/$current_os/;
          push (@newroots, $newroot);
        }
      }
    }

    $temporary_roots = \@newroots; 
    return $temporary_roots;
  }

#=============================================================================
sub config_environment_gcc($;$$)
  {
    my ($pkgdir, $version) = @_;

    # Environment variables
    &eh_setenv('CC', &join_path("$pkgdir",'bin','gcc'));
    &eh_setenv('CXX', &join_path("$pkgdir",'bin','g++'));

    # System path
    &eh_remove_path("gcc-");
    &eh_prepend_path(&join_path("$pkgdir",'bin'));

    # LD_LIBRARY_PATH
    &eh_remove_path("gcc-", 'LD_LIBRARY_PATH');
    &eh_prepend_path(&join_path("$pkgdir",'lib'), 'LD_LIBRARY_PATH');

    if ( &os_is_64bit() and not $ENV{'OS_32_ON_OS_64'} ) {
      &eh_prepend_path(&join_path("$pkgdir",'lib64'), 'LD_LIBRARY_PATH');
    }

    &__determine_OS_distribution();
    &__cleanup_roots() if ( defined($temporary_roots) );
    &HP::Environment::Config::__augment_cache_envs('distro:OS_DISTRIBUTION');
  }

#=============================================================================
&__initialize();

#=============================================================================
1;
