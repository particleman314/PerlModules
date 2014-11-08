package HP::Environment::Config;

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
		$host
		$is_debug
                $is_init

                $module_require_list
                $module_request_list

                $broken_install

		%ec_aliases
		%ec_default_versions
		%ec_installs
		%ec_paths
		%ec_type
		%ec_already_configured
		%newenv
                %hash_module_env

		@appdist_roots
		@newenv_remove

                @ISA
                @EXPORT
               );

    $VERSION     = 0.99;

    @ISA         = qw ( Exporter );
    @EXPORT      = qw (
		       @appdist_roots

		       &add_search_roots
		       &get_search_roots
                       &remove_search_roots

		       &config_environment
		       &config_package
		       &extract_package_version
                       &get_hash_envvar
                       &is_configured
		       &package_locate
		       &package_locate_all
		       &find_env_vars
                      );


    $module_require_list = {
	                    'File::Copy::Recursive'      => undef,
			    'File::Path'                 => undef,
			    'File::Basename'             => undef,

			    'HP::RegexLib'            => undef,
			    'HP::BasicTools'          => undef,
			    'HP::ConfigFile'          => undef,
			    'HP::StreamManager'       => undef,
			    'HP::FileManager'         => undef,
			    'HP::ArrayTools'          => undef,
			    'HP::Os'                  => undef,
			    'HP::OsSupport'           => undef,
			    'HP::Path'                => undef,
			    'HP::String'              => undef,
			    'HP::TextTools'           => undef,
			    'HP::Drive::Mapper'       => undef,
			    'HP::Parsers::xmlloader'  => undef,
			    'HP::Process'             => undef,
			    'HP::VersionTools'        => undef,
			    'HP::IOTools'             => undef,
                            'HP::Environment::Helper' => undef,
			    'HP::CSLBuildTools'       => undef,
                           };

    $module_request_list = {
                            'Tie::Persistent'            => undef,
                           };

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_environment_config_pm'} ||
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
sub __augment_cache_envs($)
  {
    if ( not exists($ENV{'CSLBLDCACHE_ENVS'}) ) {
      $ENV{'CSLBLDCACHE_ENVS'} = "$_[0] ";
    } else {
      $ENV{'CSLBLDCACHE_ENVS'} .= " $_[0] ";
    }
  }

#=============================================================================
sub __augment_module_env($;$)
  {
    my $package       = shift;
    my $force_loading = shift || 0;

    if ( not exists($ENV{'CSLBLDTLS_MODULES'}) ) {
      $ENV{'CSLBLDTLS_MODULES'} = "$package";
    } else {
      $ENV{'CSLBLDTLS_MODULES'} .= " $package";
    }

    if ( $force_loading ) {
      if ( not exists($ENV{'USED_MODULES'}) ) {
	$ENV{'USED_MODULES'} = "$package";
      } else {
	$ENV{'USED_MODULES'} .= " $package";
      }
    }
  }

#=============================================================================
sub __convert_os_type($)
  {
    my $path = shift || undef;

    return '' if ( not defined($path) );

    if ( -l "$path" ) { $path = readlink "$path"; }

    my $current_os   = &get_native_ostag();
    my $expected_os  = &get_ostag();

    if ( $current_os ne $expected_os ) {
      $path =~ s/$current_os/$expected_os/;
    }

    return $path;
  }

#=============================================================================
sub __determine_gcc_version()
  {
    my $dottedver = '0.0.0';
    if ( not $ENV{'GCCVER'} ) {
      my $cxx = $ENV{'CXX'} || &which('g++');

      &__print_debug_output("CXX compiler is << $cxx >>", __PACKAGE__);

      my ($rval , $output) = &runcmd(
                                     {
				      'command'   => "$cxx",
				      'arguments' => '-v',
				      'verbose'   => $is_debug,
				     }
	                            );
      my @output = grep /^gcc version/, @{$output};
      $output[0] =~ /gcc\s+version\s+(\d+\.\d+\.\d+)\s*/;
      $dottedver = $1;
    } else {
      $dottedver = $ENV{'GCCVER'};
    }

    my $ver = $dottedver;
    &__print_debug_output("Version of CXX compiler is << $ver >>", __PACKAGE__);

    $ver =~ s/\.//g;
    &setenv('GCCVER', $ver);

    my $major_version = &get_version_type($dottedver,'major');
    my $minor_version = &get_version_type($dottedver,'minor');

    &__print_debug_output("Major|Minor version for compiler is << $major_version|$minor_version >>", __PACKAGE__);
    return "gcc$major_version$minor_version";
  }

#=============================================================================
sub __changed_env_settings($$)
  {
    my $before_env = shift;
    my $after_env  = shift;

    my $diff_env = {};

    foreach my $key (sort(keys(%{$after_env}))) {
      if ( exists($before_env->{"$key"}) ) {
	&__print_debug_output("Before key :: << $before_env->{$key} >> -- After key :: << $after_env->{$key} >>", __PACKAGE__);
	next if ( "$before_env->{$key}" eq "$after_env->{$key}" );
	my $difference = $after_env->{"$key"};
	$difference =~ s/$before_env->{"$key"}//g;
	$diff_env->{"$key"} = [ 'U', "$difference" ];
      } else {
	$diff_env->{"$key"} = [ 'N', "$after_env->{$key}" ];
      }
    }
    return $diff_env;
  }

#=============================================================================
sub __handle_xml_actions($$)
  {
    my @actions = @{$_[0]};
    my $root    = $_[1];

    foreach my $action (@actions) {
      &__print_debug_output("Action :: << $action >>", __PACKAGE__);
      my $procname = "HP::String::$action";

      no strict;
      $root = &{"$procname"}("$root");
      use strict;
      next;
    }
    return "$root";
  }

#=============================================================================
sub __parse_software_roots($)
  {
    my @possible_roots = ();
    my $ossection = shift || return @possible_roots;

    &__print_debug_output("Inside '__parse_software_roots'", __PACKAGE__);
    &__print_debug_output("Site location information::", __PACKAGE__);
    &__print_debug_output( Dumper($ossection), __PACKAGE__ ) if ( $is_debug );

    my $roots = $ossection->{'roots'}->{'location'};
    my $has_glb_drvmap_status = ( exists($ossection->{'roots'}->{'use_drivemapping'}) and lc($ossection->{'roots'}->{'use_drivemapping'}) eq 'true' ) ? 1 : 0;

    &__print_debug_output("Uses DriveMapping :: << $has_glb_drvmap_status >>", __PACKAGE__);

    $roots = [ $roots ] if ( ref($roots) =~ m/hash/i );
    foreach my $rt (@${roots}) {

      if ( $is_debug ) {
	&__print_debug_output("Root Definition:", __PACKAGE__);
	&__print_debug_output( Dumper($rt), __PACKAGE__ );
      }

      if ( exists($rt->{'directory'}) ) { 
        my $matchsite = ( exists($rt->{'site'}) ) ? $rt->{'site'} : undef;

        #$matchsite = $xlnxsite if ( not defined($matchsite) );

        &__print_debug_output("MatchSite == $matchsite", __PACKAGE__);
        #if ( lc($matchsite) eq 'any' or $matchsite eq "$xlnxsite" ) {
        #  my $locroot  = &allow_substitution('{{{',
        #                                     '}}}',
        #                                     $rt->{'directory'});
        #  next if ( not defined($locroot) );
        #  my $has_lcl_drvmap_status = ( exists($rt->{'use_drivemapping'}) and lc($rt->{'use_drivemapping'}) eq 'true' ) ? 1 : 0;

        #  if ( $has_lcl_drvmap_status or $has_glb_drvmap_status ) {
        #    if ( &os_is_windows() ) {
        #      my $known_drive_map = &dmap_check("$locroot");
        #      if ( defined($known_drive_map) and
        #           $known_drive_map =~ m/^\w:/ ) {
        #        $locroot = $known_drive_map;
        #      } else {
        #        my $loc_mapped = &dmap_get_win_drive("$locroot", 1);
        #        $locroot = $loc_mapped if ( defined($loc_mapped) and
        #                                $loc_mapped =~ m/^\w:/ );
        #      }
        #    }
        #  }

	#  &__print_debug_output("Location root :: << $locroot >>\n", __PACKAGE__);

        #  if ( exists($rt->{'modify'}) ) {
        #    my @actions =  ( exists($rt->{'modify'}) ) ? &convert_2_array($rt->{'modify'}) : ();
        #    $locroot = &__ec_handle_xml_actions(\@actions, "$locroot");
        #  }

        #  if ( exists($rt->{'default'}) and uc($rt->{'default'}) eq 'TRUE' ) {
        #    unshift( @possible_roots, "$locroot" );
        #  } else {
	#    if ( exists($rt->{'position'}) ) {
	#      if ( $rt->{'position'} <= 0 ) {
#		&__print_debug_output("Adding << $locroot >> to beginning of root list", __PACKAGE__);
#		unshift( @possible_roots, "$locroot" );
#	      } elsif ( $rt->{'position'} >= scalar(@possible_roots) ) {
#		&__print_debug_output("Adding << $locroot >> to end of root list", __PACKAGE__);
#		push( @possible_roots, "$locroot" );
#	      } else {
#		&__print_debug_output("Adding << $locroot >> to position $rt->{'position'} in root list", __PACKAGE__);
#		&push_location( "$locroot", $rt->{'position'}, \@possible_roots );
#	      }
#	    } else {
#	      push( @possible_roots, "$locroot" );
#	    }
#          }
#        }
      }
    }


    &__print_debug_output( Dumper(\@possible_roots), __PACKAGE__ ) if ( $is_debug );
    return @possible_roots;
  }

#=============================================================================
sub __extract_matching_packages($$$$$$)
  {
    my $package           = shift;
    my $searchdir         = shift;
    my $requested_version = shift;
    my $match_criteria    = shift;
    my $package_hash      = shift;
    my $optionsref        = shift;

    &__print_debug_output("Inside '__extract_matching_packages'", __PACKAGE__);

    my $found     = 0;
    return undef if (not &does_directory_exist( "$searchdir" ));

    &__print_debug_output("Testing search directory << $searchdir >>", __PACKAGE__);
    &__print_debug_output("Testing for requested version << $requested_version >>", __PACKAGE__) if ( defined($requested_version) );

    my $result = &read_dirs_with_pattern("$searchdir");
    my @dirs   = ();
    if ( defined($result) ) {
      @dirs = @{$result} 
    } else {
      &__print_output("Failed to read directory '$searchdir': $!", __PACKAGE__);
      return undef;
    }

    if ( defined($requested_version) ) {
      @dirs = grep /$requested_version/i, @dirs;
    }

    if ( defined($optionsref->{'has_specialized_match_criteria'}) ) {
      @dirs = grep /^$match_criteria->[0]/, @dirs;
    }

    &__print_debug_output("Short list of directories --> @dirs\n", __PACKAGE__);

    my $info_hash = {
		     'package'      => "$package",
		     'dirs2search'  => \@dirs,
		     'package_hash' => $package_hash,
		     'version'      => $requested_version,
		     'searchdir'    => "$searchdir",
		     'options'      => $optionsref,
		    };

    if ( $match_criteria->[1] =~ m/version/ ) {
      return ($found, $package_hash) = &__handle_match_version($info_hash);
    }

    if ( $match_criteria->[1] =~ m/package/ ) {
      return ($found, $package_hash) = &__handle_match_package($info_hash);
    }

    if ( $match_criteria->[1] =~ m/custom/ ) {
      @dirs = grep /^$match_criteria->[0]/, @dirs;
      return ($found, $package_hash) = &__handle_match_custom($info_hash);
    }
  }

#=============================================================================
sub __handle_match_package($)
  {
    my $info_hash = shift;

    &__print_debug_output("Input --> ".Dumper($info_hash), __PACKAGE__);

    my $package      = $info_hash->{'package'};
    my $searchdir    = $info_hash->{'searchdir'};
    my @dirs         = &convert_2_array($info_hash->{'dirs2search'});
    my $package_hash = $info_hash->{'package_hash'};
    my $version      = $info_hash->{'version'};
    my $optionsref   = $info_hash->{'options'};

    &__print_debug_output("Inside '__handle_match_package'", __PACKAGE__);

    my $found = 0;

    my @sorted_dirs = @dirs;

    if ( exists($optionsref->{'sort_function'}) and ref($optionsref->{'sort_function'}) =~ m/code/i ) {
      @sorted_dirs = &{$optionsref->{'sort_function'}}(@dirs);
    } else {
      @sorted_dirs = sort(@dirs);
    }

    foreach my $pkgdir (@sorted_dirs) {
      &__print_debug_output("Testing search directory << $searchdir >> for << $pkgdir >> using package matching", __PACKAGE__);
      my $shortpkg = File::Basename::basename("$pkgdir");

      &__print_debug_output("Basename ---> $shortpkg\n", __PACKAGE__);
      my ($ignored, $version) = split /-/, "$shortpkg", 2;
      if ( not defined($version) ) {
	if ( not exists($optionsref->{'use_unversioned'}) ) {
	  next;
	} else {
	  $version = '0.0';
	}
      }
      if ( $shortpkg =~ m/^$package/i ) {
	if ( not exists($package_hash->{$version}) ) {
	  ++$found;
	  $package_hash->{$version} = &join_path("$searchdir","$pkgdir");
	  # Now add the version with no revision attached.
	  if ($version =~ s/_.*//) {
	    $package_hash->{$version} = &join_path("$searchdir","$pkgdir");
	  }
	}
      }
    }

    return ($found, $package_hash);
  }

#=============================================================================
sub __handle_match_custom($)
  {
    my $info_hash = shift;

    my $searchdir      = $info_hash->{'searchdir'};
    my $package_hash   = $info_hash->{'package_hash'};
    my $version        = $info_hash->{'options'}->{'version'};
    my @dirs           = &convert_2_array($info_hash->{'dirs2search'});
    my $setup_function = undef;

    &__print_debug_output("Inside '__handle_match_custom'", __PACKAGE__);

    if ( exists($info_hash->{'options'}->{'setupfunc'}) ) {
      $setup_function = $info_hash->{'options'}->{'setupfunc'};
    }

    my $found   = 0;
    my $subpath = undef;

    $version = 'latest' if ( not defined($version) );
    &__print_debug_output("Testing search directory << $searchdir >> for << $version >> using custom matching", __PACKAGE__);
    if ( defined($setup_function) ) {
      ( $found,$subpath ) = &{$setup_function}( "$searchdir","$version" );
      if ( not exists($package_hash->{$version}) ) {
	if ( not defined($subpath) ) {
	  if ( $version !~ m/latest/ ) {
	    $package_hash->{$version} = &join_path( "$searchdir","$version" );
	  } else {
	    $package_hash->{$version} = "$searchdir";
	  }
	} else {
	  $package_hash->{$version} = &join_path( "$searchdir","$subpath" );
	}
      }
    }
    return ($found, $package_hash);
  }

#=============================================================================
sub __handle_match_version($)
  {
    my $info_hash = shift;

    my $searchdir    = $info_hash->{'searchdir'};
    my @dirs         = &convert_2_array($info_hash->{'dirs2search'});
    my $package_hash = $info_hash->{'package_hash'};
    my $version      = $info_hash->{'version'};

    &__print_debug_output("Inside '__handle_match_version'", __PACKAGE__);

    my $found = 0;

    foreach my $pkgdir (sort @dirs) {
      &__print_debug_output("Testing search directory << $searchdir >> for << $pkgdir >> using version matching", __PACKAGE__);
      if ( -d &join_path("$searchdir","$pkgdir") ) {
	if ( not exists($package_hash->{$version}) ) {
	  ++$found;
	  $package_hash->{$version} = &join_path("$searchdir","$pkgdir");
	  if ($version =~ s/_.*//) {
	    $package_hash->{$version} = &join_path("$searchdir","$pkgdir");
	  }
	}
      }
    }
    return ($found, $package_hash);
  }

#=============================================================================
sub __initialize()
  {
    if ( not $is_init ) {
      # Determine the host name.
      $host = &get_hostname();

      # Build a list of possible root locations for Developer Tool
      # installed packages.  Check for discrepancy.  Use current
      # proxy branch in discrepancy found.

      my $current_proxy_branch = &get_proxy_branch_from_path("$FindBin::Bin",
							     {'use_svn' => 0});
      my $stored_proxy_branch = undef;

      &__print_debug_output("Current proxy branch --> $current_proxy_branch\n", __PACKAGE__);
      if ( exists($ENV{'DEVTOOLS_ROOT'}) ) {
        my $main_apdroot = $ENV{'DEVTOOLS_ROOT'};
	$stored_proxy_branch = &get_proxy_branch_from_path("$main_apdroot",
							   {'use_svn' => 0});
	&__print_debug_output("Stored proxy branch --> $stored_proxy_branch\n", __PACKAGE__);
        $main_apdroot    = &__convert_os_type("$main_apdroot");
	push (@appdist_roots, "$main_apdroot");
      }

      if ( exists($ENV{'DEVTOOLS_USER'}) ) {
        my $fallbk_apdroot = $ENV{'DEVTOOLS_USER'};
        $fallbk_apdroot = &__convert_os_type("$fallbk_apdroot");         
	push (@appdist_roots, "$fallbk_apdroot");
      }

      if ( lc(substr($current_proxy_branch,0,1)) le lc(substr($stored_proxy_branch,0,1)) ) {
	  my $proper_proxy_branch = "$stored_proxy_branch";
	  $proper_proxy_branch =~ s/$current_proxy_branch/$stored_proxy_branch/;
          $ENV{'CSLBLD'} = &join_path("$proper_proxy_branch",'bldtools');
      }

      &read_programmatic_xml_file();
      &load_default_config();
      @appdist_roots = @{&set_unique(\@appdist_roots)};

      print STDERR "INIITALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
      $is_init = 1;
    }
  }

#=============================================================================
sub add_search_roots($$)
  {
    &__print_debug_output("Inside 'add_search_roots'", __PACKAGE__);

    my $added_roots           = shift;
    my $position_in_root_list = shift;

    my @added_roots = &convert_2_array($added_roots);
    foreach my $adr (@added_roots) {
      push    ( @appdist_roots, "$adr" ) if ( $position_in_root_list =~ m/append/i );
      unshift ( @appdist_roots, "$adr" ) if ( $position_in_root_list =~ m/prepend/i );
    }
    @appdist_roots = @{&set_unique(\@appdist_roots)};
  }

#=============================================================================
sub config_environment($;$)
  {
    &__print_debug_output("Inside 'config_environment'", __PACKAGE__);

    my $versionsref = shift;
    my $optionsref  = shift || {};

    # Reset the configured module list to avoid duplicate configuration when
    # dependencies are hit.

    my $failures = 0;
    my @packages = keys(%{$versionsref});

    &__print_debug_output("Packages to configure --> ". join(' ',@packages), __PACKAGE__);
    &__print_debug_output("Version ref --> ".Dumper($versionsref), __PACKAGE__) if ( $is_debug );

    foreach my $pkg (@packages) {
      my %base_optionsref = %{$optionsref};  # This should make a deep copy of the hash to allow for reset
      my $failed_load += &config_package($pkg, $versionsref, \%base_optionsref) ? 0 : 1;
      if ( $failed_load ) {
         &__print_output("Failed to load package << $pkg >> requesting version << $versionsref->{$pkg}->[0] >>!", __PACKAGE__);
         $failures += $failed_load;
      }
      &__print_debug_output("Current failure count --> $failures\n", __PACKAGE__);
    }

    # Uniquify the cache environment versions
    if ( exists($ENV{'CSLBLDCACHE_ENVS'}) ) {
      my @entries = split(" ","$ENV{'CSLBLDCACHE_ENVS'}");
      @entries = @{&set_unique(\@entries)};
      $ENV{'CSLBLDCACHE_ENVS'} = join(' ',@entries);
    }

    # Uniquify the modules installed...
    if ( ( exists($ENV{'CSLBLDTLS_MODULES'}) ) && length($ENV{'CSLBLDTLS_MODULES'}) > 0 ) {
      my @entries = split(" ","$ENV{'CSLBLDTLS_MODULES'}");
      @entries    = @{&set_unique(\@entries)};
      &setenv('CSLBLDTLS_MODULES',join(' ',@entries));
    }

    # Lastly remove any blacklisted environment variables
    if ( exists($ENV{'EXPUNGE_ENV_VARS'}) ) {
      my @removed_env_vars = split(':',$ENV{'EXPUNGE_ENV_VARS'});
      foreach my $envvar (@removed_env_vars) {
        delete($ENV{$envvar});
      }
    }

    return $failures ? undef : 1;
  }

#=============================================================================
sub config_package($$;$)
  {
    &__print_debug_output("Inside 'config_package'", __PACKAGE__);

    my $package = shift;
    $package    = lc($package);
    $package    = &expand_alias($package);

    my $versionsref = shift;
    my $optionsref  = shift || {};

    return $ec_already_configured{$package} if ($ec_already_configured{$package});

    if ( not &load_package_module($package) ) {
      &__print_output("Failed to load package module for $package", __PACKAGE__);
      return undef;
    }

    my $pkgref = $ec_installs{$package};
    if ( not $pkgref ) {
      &__print_output("Did not find configuration information for package, $package", __PACKAGE__);
      return undef;
    }

    $pkgref = $pkgref->{'*'};
    if ( not $pkgref ) {
      &__print_output("Did not find global configuration section for package, $package", __PACKAGE__);
      return undef;
    }

    # Determine if this package is platform specific.
    if ( exists($pkgref->{'platforms'}) ) {

      &__print_debug_output( "Module << $package >> has platform specifications\n", __PACKAGE__ );
      # Determine if this package will be configured on this platform.
      my $configure = 0; # true if this platform is supported

      my @platforms = (ref($pkgref->{'platforms'}) =~ m/array/i ) ? @{$pkgref->{'platforms'}} : ( $pkgref->{'platforms'} );

      foreach my $platform (@platforms) {
	$platform = lc($platform);
	# This supported platform list will grow as we add more platforms.
	if ($platform =~ m/lin/i ) {
	  if ( &os_is_linux() ) {
	    $configure = 1;
	    last;
	  }
	} elsif ($platform =~ m/win/i) {
	  if ( &os_is_windows() ) {
	    $configure = 1;
	    last;
	  }
	}
      }
      return (1, 1) if ( not $configure );  # Failed both Linux and Windows
    }

    # Determine if this package has dependents...
    # Load dependents, if any.
    if ( exists($pkgref->{'depends'}) ) {
      &__print_debug_output("Module << $package >> has dependencies\n", __PACKAGE__ );

      my @subpkgs = &convert_2_array($pkgref->{'depends'});
      foreach my $subpkg (@subpkgs) {
	&__print_debug_output("Handling << $package >> dependency of << $subpkg >>", __PACKAGE__);

	if ( not &config_package($subpkg, $versionsref, $optionsref) ) {
	  &__print_output("Failed to configure dependent package --> $subpkg", __PACKAGE__);
	  return undef;
	}
      }
    }

    # Find the package directory.
    my ($pkgdir, $version) = &package_locate("$package", $versionsref, $optionsref);

    # At this point, $pkgdir should be defined, or we've failed.
    if ( not $pkgdir ) {
      &__print_output("Failed to find package directory for $package", __PACKAGE__);
      return undef;
    }

    # If the version is defined as local, we want to extract the version ID by
    # definition of the module itself -- it should tell us a coderef to do this
    if (( defined($version) ) && ( &lowercase_all($version) eq 'local' ) ) {
      my $exvername = $pkgref->{'extractversion'};
      if ( defined($exvername) && ( ref($exvername) =~ m/code/i ) ) {
	no strict;
	$version = &{$exvername}("$pkgdir");
	use strict;
      }
    }

    # Run the package configuration function.
    my $cfgfunc = $pkgref->{'configfunc'};
    if ( not $cfgfunc ) {
      $cfgfunc = \&set_default_variable;
      &__print_debug_output("There is no configuration function for package, $package.  Using default method...", __PACKAGE__);
    }

    no strict;
    &{$cfgfunc}($pkgdir, $version, "$package") if ( ref($cfgfunc) =~ m/code/i );
    use strict;

    &__print_debug_output("Completed running configuration function...\n", __PACKAGE__);

    # Define the version ID name to push into the environment
    my $setvername = $pkgref->{'setversion'};
    if ( defined($setvername) and length($setvername) > 0 ) {
      &setenv("$setvername",$version);
      &__augment_cache_envs("$package:$setvername");
    }

    # Mark this package as loaded.
    my @pkgarray = ($pkgdir, $version);
    $ec_already_configured{"$package"} = @pkgarray;

    # Determine if the name of the module needed to be saved away...
    if ( defined($pkgref->{'store_mod_name'}) and $pkgref->{'store_mod_name'} ) {
      &__augment_module_env("$package");
    }

    # Return success.
    &__print_debug_output("Completed finding package << $package >> with version << $version >>", __PACKAGE__);
    return ($pkgdir, $version);
  }

#=============================================================================
sub expand_alias($)
  {
    &__print_debug_output("Inside 'expand_alias'", __PACKAGE__);

    my $alias = shift;
    return $ec_aliases{$alias} ? $ec_aliases{$alias} : $alias;
  }

#=============================================================================
sub extract_package_version($)
  {
    &__print_debug_output("Inside 'extract_package_version'", __PACKAGE__);

    # This is the basic representation (which may not fit all packages.
    # If the package doesn't fit this condition, then it should write its
    # specific code ref that will "do the right thing"
    my $pkgdir = shift;

    my $pkg    = File::Basename::basename("$pkgdir");
    my ($shortpkg, $version) = split /[;-]/, $pkg, 2;
    return $version;
  }

#=============================================================================
sub find_env_vars($;$)
  {
    &__print_debug_output("Inside 'find_env_vars'", __PACKAGE__);

    my $envname = shift;
    my $style   = shift || 'exact';

    my @results  = ();
    my $comparer = 'eq $envname';

    $comparer = '=~ m/$envname/'  if ( $style =~ /match/ );
    $comparer = '=~ m/^$envname/' if ( $style =~ /match/ and $style =~ m/begin/ );
    $comparer = '=~ m/$envname$/' if ( $style =~ /match/ and $style =~ m/end/ );

    &__print_debug_output("\n$envname\t$style\t$comparer\n", __PACKAGE__);

    foreach my $key (sort(keys(%ENV))) {
      my $result = 0;
      eval "\$result = ( '$key' $comparer ) ? 1 : 0;";
      if ( $@ ) { next; }
      if ( $result == 1 && $style eq 'exact' ) {
	&__print_debug_output("\n$key --- $@ --- '$key' $comparer | $result\n", __PACKAGE__);
	return "$ENV{$key}";
      }
      push(@results, "$ENV{$key}") if ( $result == 1 );
    }

    return \@results;
  }

#=============================================================================
sub get_compiler_string($;$)
  {
    &__print_debug_output("Inside 'get_compiler_string'", __PACKAGE__);

    my $versionsref = shift;
    my $optionsref  = shift || {};

    # Make sure the compiler is configured before trying to continue.
    &config_package('compiler', $versionsref, $optionsref);

    my $cxxvendorver = $ENV{'CXX_VENDOR_VER'};
    if ( (not defined($cxxvendorver)) || (not $cxxvendorver) ) {
      if ( &os_is_windows() ) {
        $cxxvendorver = &__determine_vcstudio_version();
      } else {
        $cxxvendorver = &__determine_gcc_version();
      }
    }

    &setenv('CXX_VENDOR_VER', $cxxvendorver) if ( defined($cxxvendorver) );
    return $cxxvendorver;
  }

#=============================================================================
sub get_hash_envvar()
  {
    &__print_debug_output("Inside 'get_hash_envvar'", __PACKAGE__);

    my @temp = values(%hash_module_env);
    return \@temp;
  }

#=============================================================================
sub get_search_roots()
  {
    &__print_debug_output("Inside 'get_search_roots'", __PACKAGE__);

    return ( wantarray() ) ? @appdist_roots : \@appdist_roots;
  }

#=============================================================================
sub is_configured($)
  {
    &__print_debug_output("Inside 'is_configured'", __PACKAGE__);

    my $input = shift || return 0;
    ( exists($ec_already_configured{"$input"}) and $ec_already_configured{"$input"} > 0 )? 1 : 0;
  }

#=============================================================================
sub load_default_config()
  {
    &__print_debug_output("Inside 'load_default_config'", __PACKAGE__);

    # Initialize configuration hashes.
    %ec_aliases          = ();
    %ec_default_versions = ();
    %ec_installs         = ();
    %ec_paths            = ();

    # Make sure CSLBLD is defined.
    if ( exists($ENV{'CSLBLD_LOCAL'}) ) {
      # Load the defaults perl module for programmatically set items.
      eval "use lib '$ENV{'CSLBLD_LOCAL'}'; use HP::Environment::defaults;";
      warn "$@\n" if ($@);
    } else {
      if ( exists($ENV{'CSLBLD'}) ) {
        # Load the defaults perl module for programmatically set items.
        eval "use lib '$ENV{'CSLBLD'}'; use HP::Environment::defaults;";
        warn "$@\n" if ($@);
      } else {
        warn "No CSLBLD environment setting found.\n";
        &generate_exception('NO_ENVIRONMENT_SETTING');
      }
    }

    # Load the defaults configuration file.
    my $cfgfile = undef;
    foreach my $root (@appdist_roots) {
      $cfgfile = &join_path("$root",'defaultenv.conf');
      &__print_debug_output("Testing for configuration file --> $cfgfile\n", __PACKAGE__);
      my $found_file = &does_file_exist( "$cfgfile" );
      last if ( $found_file );
      $cfgfile = undef if ( not $found_file );
    }
    
    if ( defined($cfgfile) ) {
      my %cfg;
      &load_conf(\%cfg, "$cfgfile");
      foreach my $key (keys %cfg) {
	# Take only the first version listed on the line.
	my ($version) = split /\s+/, $cfg{"$key"};
	$ec_default_versions{"$key"} = $version;
      }
    }
  }

#=============================================================================
sub load_package_module($)
  {
    &__print_debug_output("Inside 'load_package_module'\n", __PACKAGE__);

    my $package = shift;
    $package    = lc($package);

    my $module  = &convert_from_colon_module("$package");

    &__print_debug_output("Attempting to find module --> $module\n", __PACKAGE__);

    if ( not $ec_installs{$package}{'nomodule'}) {
      &__print_debug_output("Need to install this module...\n", __PACKAGE__);
      my $modulepath = '';
      foreach my $dir (@INC) {
	if ( &does_file_exist( &join_path("$dir",'HP','Environment',"$module") ) ) {
	  $modulepath = 'HP::Environment';
	  last;
	} elsif ( &does_file_exist( &join_path("$dir",'Environment',"$module") ) ) {
	  $modulepath = 'Environment';
	  last;
	}
      }

      &__print_debug_output("Module path to use --> << $modulepath >>\n", __PACKAGE__);
      if ($modulepath) {
	if ( not &install_package_configuration($modulepath,"$package") ) {
	  &__print_output("FAILED: Attempted to load Environment Configuration module '$module', but got errors:", __PACKAGE__);
	  return undef;
	}
      } elsif ( not exists($ec_installs{$package}) ) {
	&__print_output("ERROR: No configuration module found for package << $package >>", __PACKAGE__);
	return undef;
      }
    }

    return 1;
  }

#=============================================================================
sub package_locate($$;$)
  {
    &__print_debug_output("Inside 'package_locate'", __PACKAGE__);

    my $package = shift;
    $package    = lc($package);

    my $versionsref = shift;
    my $optionsref  = shift || {};

    my $path    = undef;
    my $version = undef;

    my $pkgref = $ec_installs{"$package"} || return ();
    $pkgref = $pkgref->{'*'} || return ();

    if ( $is_debug ) {
      &__print_debug_output("Using package detail information --> ".Dumper($pkgref), __PACKAGE__ );
      &__print_debug_output("Version Reference --> ".Dumper($versionsref), __PACKAGE__ );
      &__print_debug_output("Options Reference --> ".Dumper($optionsref), __PACKAGE__ );
    }

    my $varname     = $pkgref->{'variable'} || uc($package);
    my $overridevar = uc("${varname}_LOCAL");
    my $requestver  = uc("${varname}_REQUESTED_VERSION");

    if ( exists($ENV{$overridevar}) ) {
      &__print_debug_output("Override variable in effect << $overridevar >>\n", __PACKAGE__);
      if ( not &does_directory_exist( "$ENV{$overridevar}" ) ) {
         &__print_output("Requested override location for package << $package >> could NOT be found.  Path checked :: $ENV{$overridevar}", __PACKAGE__);
         &generate_exception('BAD_PACKAGE'); 
      } else {
         return ($ENV{$overridevar}, 'local');
      }
    }

    my $ref = $versionsref->{"$package"};

    if (ref($ref) =~ m/array/i ) {
      $ref = $ref->[0];
    }

    my $reqver = $ref;
    if (ref($reqver) =~ m/array/i ) { $reqver = $reqver->[0]; }

    if ( exists($ENV{$requestver}) ) {
      &__print_debug_output("Requested version variable in effect << $requestver >>\n", __PACKAGE__);
       $reqver = "$ENV{$requestver}";
    }

    if ($pkgref->{'searchfunc'}) {
      &__print_debug_output("Using search function option to find module...\n", __PACKAGE__);
      my $func = $pkgref->{'searchfunc'};
      if (ref($func) =~ m/code/i ) {
	&__print_debug_output("Code reference encountered...\n", __PACKAGE__);
	($path, $version) = &{$func}($package, $reqver);
	&__print_debug_output("Returns are -->".Dumper($path).Dumper($version), __PACKAGE__) if ( $is_debug );
      } else {
	&__print_output("$package has a search function that is not a CODE reference.", __PACKAGE__);
	exit 1;
      }
    } else {
      my %packages = &package_locate_all("$package", $versionsref, $optionsref);
      # XXX Only the first version listed for the package is supported
      # right now.  At some point, the fallback versions should also be
      # checked.
      if ( not $reqver ) {
	$reqver = $ec_default_versions{$package} || 'latest';
      }
      &__print_debug_output("Packages found --> ".Dumper(\%packages), __PACKAGE__ ) if ( $is_debug );
      if (lc($reqver) eq 'latest') {
	if ( scalar(keys(%packages)) ) {
	  my @allvers = sort { &compare_versions($a,$b) } keys %packages;
	  my $latestver = $allvers[-1];
	  $path    = $packages{$latestver};
	  $version = $latestver;
	} else {
	  &__print_output("No versions found matching requested package << $package >>!", __PACKAGE__);
	  exit 1;
	}
      } else {
	# The $orlater flag lets us choose a newer package if the requested
	# version is not available.
	my $orlater = $reqver =~ s/\+$//;
	# Try exact version match first.
	if ($packages{$reqver}) {
	  $path    = $packages{$reqver};
	  $version = $reqver;
	} elsif ($orlater) {
	  my @vers = sort { &compare_versions($a,$b) } keys %packages;
	  foreach my $tryver (@vers) {
	    if (&compare_versions($tryver, $reqver) > 0) {
	      $path    = $packages{$tryver};
	      $version = $tryver;
	      last;
	    }
	  }
	}
      }
    }

    if ( not defined($path) or $path eq '' ) {
      return ('', $version);
    }

    return ($path, $version);
  }

#=============================================================================
sub package_locate_all($$;$)
  {
    &__print_debug_output("Inside 'package_locate_all'", __PACKAGE__);

    my $package = shift;
    $package    = lc($package);

    my $versionsref = shift;
    my $optionsref  = shift || {};

    my $packages = {};
    my $pkgref   = $ec_installs{$package} || return %{$packages};
    $pkgref      = $pkgref->{'*'} || return %{$packages};

    if ($pkgref and $pkgref->{'listfunc'}) {
      &__print_output("There is currently no support for 'listfunc' list functions.", __PACKAGE__);
    } else {
      if ( exists($pkgref->{'path'}) ) {
	&__print_debug_output("Checking to see if pre-existing path specified\n", __PACKAGE__);
	  ;
	$packages->{$versionsref->{"$package"}->[0]} = $pkgref->{'path'};
      } else {
        if ( defined($pkgref->{'primary_root'}) && (ref($pkgref->{'primary_root'}) =~ m/code/i) ) {
          my $addon_roots = &{$pkgref->{'primary_root'}}(\@appdist_roots, $package, $versionsref, $optionsref);
          if ( scalar(@${addon_roots}) ) {
	    &__print_debug_output("Adding primary root to search roots...\n", __PACKAGE__);
            &add_search_roots($addon_roots, 'prepend');
          }
        }

	$pkgref->{'searchtype'} ||= 'std';

        my @roots = ();
	my $requested_version = 'latest';

	if ( $pkgref->{'searchtype'} eq 'std') {
	  &__print_debug_output("Search Type --> << $pkgref->{'searchtype'} >>", __PACKAGE__);

	  # Assume package searchtype is "std" or something else similar.
	  @roots = @appdist_roots;

	  &__print_debug_output("Search Roots --> << @roots >>", __PACKAGE__);

	  # Determine list of sub-directories to search.
	  my @subdirs = ();
	  if ($pkgref->{'subpath'}) {
	    &__print_debug_output("Managing subpath options...\n", __PACKAGE__);
	    if (ref($pkgref->{'subpath'}) =~ m/array/i ) {
	      @subdirs = @{$pkgref->{'subpath'}};
	    } else {
	      @subdirs = ( $pkgref->{'subpath'} );
	    }
	  }

	  if ( $is_debug ) {
	    &__print_debug_output("Installed packages ::\n".Dumper(\%ec_installs), __PACKAGE__);
	    &__print_debug_output("Options Reference ::\n".Dumper($optionsref), __PACKAGE__);
	    &__print_debug_output("$package", __PACKAGE__);
	  }

	  # Scan @roots for requested package and build %packages hash.
	  my $found = 0;
	  $requested_version = $versionsref->{"$package"}->[0];
	  $requested_version = $optionsref->{'version'} if ( exists($optionsref->{'version'}) );

	  if ( exists($optionsref->{'subpath'}) ) {
	    foreach my $root (@roots) {
	      my @known_subdirs = &convert_2_array($optionsref->{'subpath'});

	      # Loop over all known subdirs
	      if ( scalar(@known_subdirs) ) {
		foreach my $subdir (@known_subdirs) {
		  my $searchdir = &join_path("$root", "$subdir");

		  &__print_debug_output("Testing path << $searchdir >>", __PACKAGE__);
		  my $match_criteria = quotemeta($package);
		  my $matching_mech = [ "$match_criteria", 'version' ];
		  if ( $pkgref->{'searchtype'} =~ m/custom/ and exists($pkgref->{'setupfunc'}) ) {
		    $matching_mech->[1] = 'custom';
		    $optionsref->{'setupfunc'} = $pkgref->{'setupfunc'};
		    $optionsref->{'version'}   = $versionsref->{"$package"}->[0];
		  }
		  &__print_debug_output("ZZZZZZZZ -- Matching critera << $match_criteria >>", __PACKAGE__);
		  my ( $temp, $packages ) = &__extract_matching_packages("$package","$searchdir",
									 $requested_version,
									 $matching_mech,
									 $packages,
									 $optionsref);
		  next if ( not defined($temp) ) ;
		  if ( $is_debug ) {
		    &__print_debug_output("First code path... ( known subdirs --> << @known_subdirs >> to find match)", __PACKAGE__);
		    &__print_debug_output(Dumper($packages), __PACKAGE__);
		  }
		  $found += $temp;
		}
	      } else {
		  my $match_criteria = quotemeta($package);
		  my $matching_mech = [ "$match_criteria", 'version' ];
		  if ( $pkgref->{'searchtype'} =~ m/custom/ and exists($pkgref->{'setupfunc'}) ) {
		    $matching_mech->[1] = 'custom';
		    $optionsref->{'setupfunc'} = $pkgref->{'setupfunc'};
		    $optionsref->{'version'}   = $versionsref->{"$package"}->[0];
		  }
		  my ( $temp, $packages ) = &__extract_matching_packages("$package","$root",
									 $requested_version,
									 $matching_mech,
									 $packages,
									 $optionsref);
		  next if ( not defined($temp) ) ;
		  if ( $is_debug ) {
		    &__print_debug_output("Second code path... ( using root << $root >> to find match )", __PACKAGE__);
		    &__print_debug_output( Dumper($packages), __PACKAGE__ );
		  }
		  $found += $temp;
	      }
	      last if ( $found );
	    }
	  } else {
	    foreach my $root (@roots) {
	      if ( scalar(@subdirs) ) {
		&__print_debug_output("Looping over subdirs << @subdirs >>", __PACKAGE__);
		foreach my $subdir (@subdirs) {
		  my $searchdir = undef;
		  $searchdir = &join_path("$root", "$subdir");
		  if ($pkgref->{'compilerspecific'}) {
		    $searchdir = &join_path("$searchdir", &get_compiler_string($versionsref, $optionsref));
		  }

		  &__print_debug_output("(A) Testing searchpath << $searchdir >>", __PACKAGE__);
		  if ( $pkgref->{'usesearchdir'} ) {
		    if ( &does_directory_exist("$searchdir") ) {
		      $packages->{'0.0'} = "$searchdir";
		      goto FINISH_LINE;
		    }
		  }

		  my $match_criteria = quotemeta($package);
		  my $matching_mech = [ "$match_criteria", 'package' ];
		  if ( exists($pkgref->{'match_criteria'}) ) {
		    &__print_debug_output("Using specialized matching criteria\n", __PACKAGE__);
		    $matching_mech->[0] = $pkgref->{'match_criteria'};
		    $optionsref->{'has_specialized_match_criteria'} = 1;
		  }

		  if ( $pkgref->{'searchtype'} =~ m/custom/ and exists($pkgref->{'setupfunc'}) ) {
		    $matching_mech->[1] = 'custom';
		    $optionsref->{'setupfunc'} = $pkgref->{'setupfunc'};
		    $optionsref->{'version'}   = $versionsref->{"$package"}->[0];
		  }
		  if ( exists($pkgref->{'sortfunc'}) and ref($pkgref->{'sortfunc'}) =~ m/code/i ) {
		    $optionsref->{'sort_function'} = $pkgref->{'sortfunc'};
		  }

		  my ( $temp, $packages ) = &__extract_matching_packages("$package","$searchdir",
									 $requested_version,
									 $matching_mech,
									 $packages,
									 $optionsref);
		  next if ( not defined($temp) ) ;
		  if ( $is_debug ) {
		    &__print_debug_output("Searching through multiple roots with a search directory...", __PACKAGE__);
		    &__print_debug_output(Dumper($packages), __PACKAGE__);
		  }
		  $found += $temp;
		}
	      } else {
		my $match_criteria = ( exists($pkgref->{'usepackagename'}) ) ? quotemeta($pkgref->{'usepackagename'}) : quotemeta($package);
		my $matching_mech = [ "$match_criteria", 'package' ];

		if ( $pkgref->{'searchtype'} =~ m/custom/ and exists($pkgref->{'setupfunc'}) ) {
		  $matching_mech->[1] = 'custom';
		  $optionsref->{'setupfunc'} = $pkgref->{'setupfunc'};
		  $optionsref->{'version'}   = $versionsref->{"$package"}->[0];
		}

		&__print_debug_output(Dumper($optionsref), __PACKAGE__) if ( $is_debug );

		my ( $temp, $packages ) = &__extract_matching_packages("$package","$root",
								       $requested_version,
								       $matching_mech,
								       $packages,
								       $optionsref);
		next if ( not defined($temp) ) ;
		if ( $is_debug ) {
		  &__print_debug_output("Using match criteria against several roots...", __PACKAGE__);
		  &__print_debug_output(Dumper($packages), __PACKAGE__);
		}
		$found += $temp;
	      }

	      last if ($found);
	    }
	  }
	} elsif ( $pkgref->{'searchtype'} eq 'builtin' ) {
	  &__print_debug_output("Using builtin rules...\n", __PACKAGE__);
	  goto FINISH_LINE if ( not exists($pkgref->{'executable'}) );

	  my $executable_full_path = &which("$pkgref->{'executable'}");
	  goto FINISH_LINE if ( not defined($executable_full_path) );

	  my $pkg_ver = $requested_version || $versionsref->{"$package"}->[0] || '0.0';
          my $exedir = File::Basename::dirname("$executable_full_path");

	  # Need to extract this out as a separate subroutine...
          if ( exists($pkgref->{'remove'}) ) {
            foreach my $rm (@{$pkgref->{'remove'}}) {
              $exedir =~ s/$rm$//;
              $exedir = &HP::Path::__remove_trailing_slash("$exedir");
            }
          }
	  $packages->{"$pkg_ver"} = "$exedir";
        } elsif ( $pkgref->{'searchtype'} eq 'reflective' ) {
	  &__print_debug_output("Using reflective rules...\n", __PACKAGE__);
          my $pkg_ver = $requested_version || $versionsref->{"$package"}->[0] || '0.0';
          my $exedir = File::Basename::dirname(&get_full_path("$0"));

          if ( exists($pkgref->{'remove'}) ) {
            foreach my $rm (@{$pkgref->{'remove'}}) {
              $exedir =~ s/$rm$//;
              $exedir = &HP::Path::__remove_trailing_slash("$exedir");
            }
          }
          $packages->{"$pkg_ver"} = "$exedir";
	} else {
	  goto FINISH_LINE;
	}
      }
    }

  FINISH_LINE:
    return %{$packages};
  }

#=============================================================================
sub remove_search_roots($)
  {
    &__print_debug_output("Inside :: << remove_search_roots >>", __PACKAGE__);

    my $removed_roots = shift || [];
    my @removed_roots = &convert_2_array($removed_roots);
    &__print_debug_output("Removed roots --> ".Dumper($removed_roots), __PACKAGE__) if ( $is_debug );

    @appdist_roots = @{&delete_elements(\@appdist_roots,\@removed_roots)} if ( scalar(@removed_roots) );
  }

#=============================================================================
sub set_default_variable($$$)
  {
    &__print_debug_output("Inside 'set_default_variable'", __PACKAGE__);

    my ($pkgdir, $version, $package) = @_;

    if ( exists($ec_installs{"$package"}) && exists($ec_installs{"$package"}{'*'}) ) {
      my $pkgref  = $ec_installs{"$package"}{'*'};
      my $varname = $pkgref->{'variable'} || uc($package);

      &setenv("$varname", "$pkgdir");
    } else {
      &__print_debug_output("Unable to handle inputs for setting an environment variables\n", __PACKAGE__);
    }
  }

#=============================================================================
&__initialize();

#=============================================================================
1;
