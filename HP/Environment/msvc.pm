package HP::Environment::msvc;

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
		 $ENV{'debug_msvc_pm'} or
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
sub __newer_version()
  {
    my @a_prime = split('-',$a);
    my @b_prime = split('-',$b);

    return -1 if ( $a_prime[0] < $b_prime[0] );
    return 0 if ( $a_prime[0] == $b_prime[0] );
    return 1;
  }

#=============================================================================
sub __other_settings()
  {
    &eh_setenv('CXX_ADD_PRAGMA_SUPPRESSIONS',4267) if ( &os_is_windows() and &os_is_64bit() );
  }

#=============================================================================
sub __try_MSVC_version($$)
  {
    my ($version, $dictionary) = @_;
    return undef if ( not defined($dictionary) or ref($dictionary) !~ m/array/i );

    my $regex = quotemeta($dictionary->[1]);

    if ($version eq "$dictionary->[0]" or $version =~ m/^$regex/) {
      my $root = ( exists($ENV{"$dictionary->[2]"}) ) ? "$ENV{$dictionary->[2]}" : undef;
      if ( not defined($root) ) {
        $root = "$dictionary->[3]";
        if ( not -e "$root" ) {
          &__print_output("Cannot find MSVC $dictionary->[1].  Should be in $dictionary->[3].  Set $dictionary->[2] and VCVER.", __PACKAGE__);
          return undef;
        }
      }
      return &path_to_mixed("$root");
    }
    return undef;
  }

#=============================================================================
# Set up loader for MSVC.
sub install_package()
  {
    $HP::Environment::Config::ec_installs{'msvc'} = {
							'*' => {
								'searchtype'     => 'custom',
								'searchfunc'     => \&find_package_msvc,
								'configfunc'     => \&config_environment_msvc,
								'platforms'      => [ 'windows' ],
								'store_mod_name' => 1,
							       }
						       };
  }

#=============================================================================
sub find_package_msvc($;$)
  {
    my $package = shift; # $package is unused in this case
    my $version = shift || $ENV{'VCVER'} || '8.0';

    return undef if ( not &os_is_windows() );

    my $msvc_version_file = &HP::Environment::Config::__decode_vcstudio_file();
    return () if ( not defined($msvc_version_file) );

    my @ordered_list = qw(vc90 vc80 vc71);
    my $msvc_version_hash = {};

    for ( my $loop = 1; $loop <= scalar(@ordered_list); ++$loop ) {
      my $entry = "$ordered_list[$loop - 1]";
      my $recid = "$entry\_record";
      if ( exists($msvc_version_file->{"$recid"}) ) {
	$msvc_version_hash->{"$loop-$entry"} = [ $msvc_version_file->{"$recid"}->{'versions'}->[0],
						 $msvc_version_file->{"$recid"}->{'versions'}->[1],
						 $msvc_version_file->{"$recid"}->{'envvars'}->[0],
						 $msvc_version_file->{"$recid"}->{'root'} ];
      }
    }

    return () if ( scalar(keys(%{$msvc_version_hash})) < 1 );

    foreach my $msvckey (sort __newer_version keys(%{$msvc_version_hash})) {
      my $rootpath = &__try_MSVC_version($version, $msvc_version_hash->{$msvckey});
      next if ( not defined($rootpath) );
      return ("$rootpath", "$msvc_version_hash->{$msvckey}->[1]") if ( defined($rootpath) );
    }

    return ();
  }

#=============================================================================
sub config_environment_msvc($;$$)
  {
    my ($pkgdir, $version) = @_;

    $pkgdir      = &path_to_unix("$pkgdir");
    my $msroot   = File::Basename::dirname("$pkgdir");

    my $shortver = undef;
    if ($version eq '800' or $version eq '8.0') {
      $shortver = '80';
    } elsif ($version eq '900' or $version eq '9.0') {
      $shortver = '90';
    } else {
      $shortver = '71';
    }

    my $toplevel_sdk = &join_path("$msroot",'SDK');

    my $sdkver   = 'v1.1';
    if ($shortver eq '80') {
      $sdkver = 'v2.0';
    } elsif ($shortver eq '90') {
      $sdkver = 'v6.0A';
      $toplevel_sdk = &join_path('/c','Program Files','Microsoft SDKs', 'Windows');
    }

    &eh_setenv("VC${shortver}_ROOT", "$pkgdir");
    &eh_setenv("VCVER", "$version");
    &eh_remove_path('msvsn\d');
    &eh_remove_path('Visual Studio');

    &eh_prepend_path(&join_path("$msroot",'Common7','ide'));
    &eh_prepend_path(&join_path("$msroot",'Common7','tools','bin'));
    &eh_prepend_path(&join_path("$msroot",'Common7','tools'));

    if ($shortver eq '71') {
      &eh_prepend_path(&join_path("$msroot",'Vc7','bin'));
    } elsif ($shortver eq '80' or $shortver eq '90') {
      if ( &os_is_64bit() ) {
	&eh_prepend_path(&join_path("$msroot",'Vc','bin','amd64'));
      } else {
        &eh_prepend_path(&join_path("$msroot",'Vc','bin'));
      }

      if ($shortver eq '90') {
	&eh_prepend_path(&join_path("$msroot",'Vc','VCPackages'));
	&eh_prepend_path(&join_path("$toplevel_sdk","$sdkver",'bin'));
      } else {
	&eh_prepend_path(&join_path("$pkgdir",'PlatformSDK','bin'));
      }
    }

    my @includes = (
		    &join_path("$pkgdir",'atlmfc','include'),
		    &join_path("$pkgdir",'include'),
		   );

    if ( $shortver ne '90' ) {
      unshift(@includes, &join_path("$pkgdir",'PlatformSDK','Include'));
    }

    unshift(@includes, &join_path("$toplevel_sdk","$sdkver",'include'));

    my @libs = ();
    if( &os_is_64bit() ) {
      push(@libs,
	   &join_path("$pkgdir",'lib','amd64'),
	   &join_path("$pkgdir",'atlmfc','lib','amd64'),
	   &join_path('/c','Windows','SysWOW64')
 	  );
      if ( $shortver ne '90' ) {
	unshift(@libs, &join_path("$pkgdir",'PlatformSDK','Lib','AMD64'));
      }

    } else {
      push(@libs,
	   &join_path("$pkgdir",'atlmfc','lib'),
	   &join_path("$pkgdir",'lib'),
	   &join_path('/c','Windows','System')
 	  );
      if ( $shortver ne '90' ) {
	unshift(@libs, &join_path("$pkgdir",'PlatformSDK','Lib'));
      }
    }

    if ( $shortver ne '90' ) {
      if( &os_is_64bit() ) {
	unshift(@libs, &join_path("$toplevel_sdk","$sdkver",'Lib','AMD64'));
      } else {
	unshift(@libs, &join_path("$toplevel_sdk","$sdkver",'Lib'));
      }
    } else {
      push (@libs, &join_path("$toplevel_sdk","$sdkver",'Lib'));
      &eh_setenv(&path_to_mixed(
		                &join_path("$pkgdir",'atlmfc','lib').':'.&join_path("$pkgdir",'lib'),
		                { 'convert_path' => 1, }
		               ), 'LIBPATH' );
    }

    my $style = ( &os_is_windows_native() ) ? 'windows' : 'mixed';

    my $include = join(':', @includes);
    &eh_prepend_path("$include", 'INCLUDE', { 'unique'    => 1,
					      'separator' => ';',
		                              'style'     => "$style", });

    my $lib = join(':',@libs);
    &eh_prepend_path("$lib", 'LIB', { 'unique'    => 1,
				      'separator' => ';',
		                      'style'     => "$style", });

    &HP::Environment::Config::__augment_cache_envs('msvc:VCVER');

    &__other_settings();
  }

#=============================================================================
&__initialize();

#=============================================================================
1;
