package HP::Environment::cygwin;

use warnings;
use strict;

BEGIN
  {
    # Include the exporter and class::struct modules.
    use Exporter();
    use File::Path;

    use HP::Os;
    use HP::Path;
    use HP::Process;
    use HP::Environment::Helper;

    # Define the contents for exportation.
    use vars qw(
                $VERSION
		$is_debug
		
                @ISA
		@EXPORT
               );
    $VERSION     = 0.5;

    @ISA         = qw ( Exporter );
    @EXPORT      = qw (
		      );

    $is_debug = (
                 $ENV{'debug_cygwin_pm'} or
		 $ENV{'debug_environment_config_pm'} or
		 $ENV{'debug_hp_modules'} or
		 $ENV{'debug_all_modules'}
		);
    # Print a messages stating this module has been loaded.
    print STDERR "LOADING <".__PACKAGE__."> Module\n" if $is_debug;
  }

#=============================================================================
# Set up loader for CYGWIN.
sub install_package()
  {
    if ( &os_is_cygwin() ) {
      $HP::Environment::Config::ec_installs{'cygwin'} = {
							    '*' => {
								    'searchtype' => 'custom',
								    'searchfunc' => \&find_cygwin,
								    'configfunc' => \&config_environment_cygwin,
								    'platforms'  => [ 'windows' ],
								   }
							   };
    }
  }

#=============================================================================
sub find_cygwin($;$)
  {
    my ($package, $version) = @_; # $package and $version is unused in this case

    my @expected_paths = qw(/c/cygwin /c/opt/cygwin);
    foreach my $exppath (@expected_paths) {
      if ( -d "$exppath" ) {
	my $inc_dir = &join_path("/",'usr','include');
	if ( exists($ENV{'INCLUDE'}) ) {
	  $inc_dir = "$ENV{'INCLUDE'};$inc_dir";
	}
	&eh_setenv('INCLUDE',"$inc_dir");

        my @bin_dirs = ( &join_path("/",'usr','bin'), &join_path("/",'usr','local','bin') );
        foreach my $bd (@bin_dirs) {
          &eh_prepend_path("$bd");
        }

	return ("$exppath", 'latest');
      }
    }
    return undef;
  }

#=============================================================================
sub config_environment_cygwin($;$$)
  {
    my ($pkgdir, $version) = @_;

    &eh_setenv('BLDCXXJOBS',1) if ( $HP::Process::vm_machine_defined );
    &eh_setenv('CYGWIN_ROOT',"$pkgdir");
  }

#=============================================================================
1;
