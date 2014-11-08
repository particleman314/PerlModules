#=============================================================================
use HP::RegexLib;
use HP::BasicTools;
use HP::Os;
use HP::Path;
use HP::StreamManager;
use HP::FileManager;
use HP::Environment::Helper;

my $is_debug = (
                $ENV{'debug_default_pm'} ||
		$ENV{'debug_environment_config_pm'} ||
		$ENV{'debug_hp_modules'} ||
		$ENV{'debug_all_modules'} || 0
	       );

eval "use Data::Dumper;" if ( $is_debug );

my $default_env_pkg = 'HP::Environment::defaults';

#=============================================================================
my @basic_modules = qw (
			bldtools
			svn
		       );
my @preinstall_modules = qw (
                             bldtools
			     svn
			    );

$HP::Environment::Config::ec_default_versions{'bldtools'} = 'latest';
$HP::Environment::Config::ec_default_versions{'svn'}      = 'latest';

#=============================================================================
my $key = 'CSLBLD';
if ( defined($ENV{'CSLBLD_LOCAL'}) ) { $key = 'CLSBLD_LOCAL'; }

my $envdir    = &join_path( $ENV{"$key"}, 'HP', 'Environment');
&add_package_location( "$envdir" , 'false' ) if ( &does_directory_exist( "$envdir" ) );

&__print_debug_output("Adding environment directory for searching --> << $envdir >>\n", $default_env_pkg );
if ( exists($ENV{'CSLBLD_USER_BASIC_MODULES_PATH'}) ) {
  &add_package_location( $ENV{'CSLBLD_USER_BASIC_MODULES_PATH'}, 'true' );
  &__print_debug_output("Adding personal environment directory for searching --> << $ENV{'CSLBLD_USER_BASIC_MODULES_PATH'} >>\n", $default_env_pkg );
}

# Allow users to add there OWN modules to the list as part of additional
# development/functionality which may be germane to their situation but
# not the group of users/developers at large
if ( exists($ENV{'CSLBLD_USER_BASIC_MODULES'}) ) {
  &__print_debug_output("Queueing user requested modules...\n", $default_env_pkg);
  my @user_specific_basic_modules = split(" ", $ENV{'CSLBLD_USER_BASIC_MODULES'});
  foreach my $usbm (@user_specific_basic_modules) {
    my @components = split(':', "$usbm");
    if ( length($components[0]) > 0 ) {
      push (@basic_modules, $components[0]);
      $HP::Environment::Config::ec_default_versions{"$components[0]"} = "$components[1]" || 'latest';
    }
  }
}

if ( exists($ENV{'CSLBLD_USER_PREINSTALL_MODULES_PATH'}) ) {
  &add_package_location( $ENV{'CSLBLD_USER_PREINSTALL_MODULES_PATH'}, 'true' );
  &__print_debug_output("Adding preinstall environment directory for searching --> << $ENV{'CSLBLD_USER_PREINSTALL_MODULES_PATH'} >>\n", __PACKAGE__ );
}

if ( exists($ENV{'CSLBLD_USER_PREINSTALL_MODULES'}) ) {
  &__print_debug_output("Queueing user preinstall modules...\n", $default_env_pkg);
  my @user_specific_preinstall_modules = split(' ', $ENV{'CSLBLD_USER_PREINSTALL_MODULES'});
  foreach my $usbm (@user_specific_preinstall_modules) {
    my @components = split(':', "$usbm");
    if ( length($components[0]) > 0 ) {
      push (@preinstall_modules, $components[0]);
      $HP::Environment::Config::ec_default_versions{"$components[0]"} = "$components[1]" || 'latest';
    }
  }
}

# Set the "compiler" alias based on OS.
if ( &os_is_windows()) {
  $ec_aliases{'compiler'} = 'msvc';
  if ( not &os_is_windows_native() && not &os_is_linux() ) {
    unshift (@preinstall_modules, 'cygwin');
    $HP::Environment::Config::ec_default_versions{'cygwin'} = 'latest';
  }
} else {
  $HP::Environment::Config::ec_aliases{'compiler'} = 'gcc';
}

&__print_debug_output("Default versions of tools -->".Dumper(\%HP::Environment::Config::ec_default_versions), $default_env_pkg ) if ( $is_debug );

goto FINISH if ( exists($ENV{'LOW_LEVEL_TESTING'}) );

#=============================================================================
foreach my $module (@basic_modules) {
  my $modulepath = undef;
  my $all_extraneous_pkg_locations = &get_package_locations();

  &__print_debug_output("Attempting to load module --> << $module >>", $default_env_pkg);

  foreach my $dir (@INC, @{$all_extraneous_pkg_locations}) {
    &__print_debug_output("Checking directory --> $dir", $default_env_pkg);

    my $path = &join_path( "$dir", "$module\.pm" );
    &__print_debug_output("Full path --> << $path >>", $default_env_pkg);

    if ( &does_file_exist("$path") ) {
      &__print_debug_output("Generating modulepath now...", $default_env_pkg);
      $modulepath = &get_package_path("$path","$module");
      next if ( not defined($modulepath) );
      last if ( &__readjust_module_path("$dir", "$modulepath") ); 
    }
  }

  if ( defined($modulepath) ) {
    &__print_debug_output("Installing '$module' now...\n", $default_env_pkg);
    &install_package_configuration( "$modulepath","$module" );
  } else {
    &__print_output("Skipping module << $module >>.  Cannot find in expected path locations...", $default_env_pkg);
  }
}

FINISH:
&setup_machine_specifications();
&determine_variant();

#=============================================================================
&__print_debug_output("Preinstall modules --> ".Dumper(\@preinstall_modules), $default_env_pkg ) if ( $is_debug );
foreach my $preinstall (@preinstall_modules) {
  &__print_debug_output("Configuring module '$preinstall'\n", $default_env_pkg);
  &config_package($preinstall);
}

#=============================================================================
sub __initialize_defaults()
  {
    if ( not $is_init ) {
      $is_init = 1;
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
sub __readjust_module_path($$)
  {
    my $fullpath = shift;
    my $modpath  = shift;

    $modpath = &convert_from_colon_module("$modpath");
    $fullpath =~ s/$modpath$//;

    my $newpaths = &get_package_locations();
 
   if ( not &set_contains("$fullpath", $newpaths) ) {
      $fullpath = &HP::Path::__remove_trailing_slash("$fullpath");
      &add_package_location("$fullpath", 'true');
      return 1;
    }

    return 0;
  }

#=============================================================================
sub determine_variant()
  {
    foreach (@ARGV) {
      if ( $_ eq '-d' or $_ eq '--debug' ) {
	&setenv('VARIANT','debug');
	return;
      }
      if ( $_ eq '-o' or $_ eq '--opt_debug' ) {
	&setenv('VARIANT','opt_debug');
	return;
      }
    }
    &setenv('VARIANT','release') if ( not exists($ENV{'VARIANT'}) );
  }

#=============================================================================
sub get_package_path($;$)
  {
    my ($path,$modname) = @_;
    my @contents = &slurp("$path");
    foreach my $line (@contents) {
      &__print_debug_output("Checking line information for $modname --> << $line >>", $default_env_pkg);
      if ( $line =~ m/package\s*(\S*)\:\:$modname\s*\;$/ ) {
	&__print_debug_output("Found fullpath module name as $1", $default_env_pkg);
	return "$1";
      }
    }
  }

#=============================================================================
sub setup_machine_specifications()
  {
    my $processors_on_machine = 1;
    if ( &os_is_linux() and not exists($ENV{'NUMBER_OF_PROCESSORS'}) ) {
      if ( not defined($ENV{'NUMBER_OF_PROCESSORS'}) ) {
	my @contents = &slurp('/proc/cpuinfo');
	while ( scalar(@contents) ) {
	  my $line = shift(@contents);
	  next if ( $line !~ m/^processor/ );
	  ++$processors_on_machine;
	}
	--$processors_on_machine;
	&setenv('NUMBER_OF_PROCESSORS',$processors_on_machine);
      }
    }
    &add_newenv_var('NUMBER_OF_PROCESSORS');
  }

#=============================================================================
&__initialize_defaults();

#=============================================================================
1;
