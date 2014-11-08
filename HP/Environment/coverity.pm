package HP::Environment::coverity;

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
			    'HP::ArrayTools'          => undef,
                           };

    $module_request_list = {
                           };

    $is_init  = 0;
    $is_debug = (
		 $ENV{'debug_coverity_pm'} or 
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
# Set up loader for PureCov.
sub install_package()
  {
    if ( &os_is_linux() ) {
      if ( not &set_contains('/tools/batonroot/coverity', \@HP::Environment::Config::appdist_roots) ) {
	&HP::Environment::Config::ec_add_search_roots( ['/tools/batonroot/coverity'], 'prepend' );
      }
    }

    $HP::Environment::Config::ec_installs{'coverity'} = {
							   '*' => {
								   'searchtype' => 'opt',
								   'subpath'    => [ 'Coverity' ],
								   'configfunc' => \&config_environment_coverity,
								}
							};

    # This is a HACK since the directory structure has a different layout.
    # I will need to add more functionality to allow for this type of
    # directory layout...
    if ( &os_is_linux() ) {
      push (@{$HP::Environment::Config::ec_installs{'coverity'}{'*'}{'subpath'}}, '4.5.0');
      $HP::Environment::Config::ec_installs{'coverity'}{'*'}{'usesearchdir'} = 1;
    }
  }

#=============================================================================
sub config_environment_coverity($;$$)
  {
    my ($pkgdir, $version, $package) = @_;

    if ( &os_is_windows() ) {
      my $COVPREVENT = &join_path("$pkgdir",'Prevent');
      my $COVARCH    = &join_path("$pkgdir",'CAA','cva');

      &eh_setenv('COVERITY_PREVENT', "$COVPREVENT");
      &eh_setenv('COVERITY_ARCHITECT', "$COVARCH") if ( -d "$COVARCH" );
      &eh_prepend_path(&join_path("$COVPREVENT",'bin'));

    } else {
      my $version      = '4.5.0';
      my $is_64bit     = &os_is_64bit();
      my $prevent_name = 'prevent-linux';
      $prevent_name    .= '64' if ( $is_64bit );
      $prevent_name    .= "-4.5.0";

      $pkgdir .= "/$prevent_name";

      &eh_prepend_path(&join_path("$pkgdir",'bin'));
      &eh_setenv('COVERITY_PREVENT', "$pkgdir");

      # Need to use a specific version of GCC location to use Coverity...
      my $ostag = ( $is_64bit ) ? 'lnx64' : 'lnx32' ;
      my $specific_gcc = "/tools/batonroot/rodin/devkits/$ostag/gcc-4.1.1";

      # Environment variables
      &eh_setenv('CC', &join_path("$specific_gcc",'bin','gcc'));
      &eh_setenv('CXX', &join_path("$specific_gcc",'bin','g++'));

      # System path
      &eh_remove_path("gcc-");
      &eh_prepend_path(&join_path("$specific_gcc",'bin'));

      # LD_LIBRARY_PATH
      &eh_remove_path("gcc-", 'LD_LIBRARY_PATH');
      &eh_prepend_path(&join_path("$specific_gcc",'lib'), 'LD_LIBRARY_PATH');

      if ( $is_64bit ) {
	&eh_prepend_path(&join_path("$specific_gcc",'lib64'), 'LD_LIBRARY_PATH');
      }
    }
    &eh_setenv('COVERITY', "$pkgdir");
  }

#=============================================================================
&__initialize();

#=============================================================================
1;
