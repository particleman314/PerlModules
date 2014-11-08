package HP::Environment::zlib;

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
                           };

    $module_request_list = {
                           };

    $is_init  = 0;
    $is_debug = (
		 $ENV{'debug_zlib_pm'} or
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
sub __initialize()
  {
    if ( not $is_init ) {
      $is_init = 1;
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
# Set up loader for ZLIB (Compression Library).
sub install_package()
  {
    if ( &os_is_windows() ) {
    $HP::Environment::Config::ec_installs{'zlib'} = {
                                                         '*' => {
                                                                 'searchtype'       => 'published',
                                                                 'subpath'          => [ 'zlib' ],
                                                                 'compilerspecific' => 1,
                                                                 'configfunc'       => \&config_environment_zlib,
                                                                 'setversion'       => 'ZLIBVER',
                                                                 'store_mod_name'   => 1,
                                                                }
                                                        };
    } else {
    $HP::Environment::Config::ec_installs{'zlib'} = {
                                                         '*' => {
                                                                 'searchtype'       => 'opt',
                                                                 'subpath'          => [ 'xil_published' ],
                                                                 'usepackagename'   => 'zlib',
                                                                 'compilerspecific' => 1,
                                                                 'configfunc'       => \&config_environment_zlib,
                                                                 'setversion'       => 'ZLIBVER',
                                                                 'store_mod_name'   => 1,
                                                                }
                                                        };
    }
  }

#=============================================================================
sub config_environment_zlib($;$$)
  {
    my ($pkgdir, $version, $package) = @_;

    &eh_setenv('ZLIB_ROOT', "$pkgdir");
    &eh_prepend_path('zlib', 'REGEX_EXCLUDES', {'unique' => 1, separator => ' '});
  }

#=============================================================================
&__initialize();

#=============================================================================
1;

