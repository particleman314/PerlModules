package HP::Environment::bldtools;

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
		 $ENV{'debug_bldtools_pm'} ||
		 $ENV{'debug_environment_config_pm'} ||
		 $ENV{'debug_hp_modules'} ||
		 $ENV{'debug_all_modules'} || 0
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
# Set up loader for CSLBLDTOOLS.
sub install_package()
  {
    &__print_debug_output("Installation instructions for bldtools\n", __PACKAGE__);
    $HP::Environment::Config::ec_installs{'bldtools'} = {
							    '*' => {
								    'searchtype' => 'reflective',
                                                                    'remove'     => [ 'bin' ],
								    'configfunc' => \&config_environment_bldtools,
								   }
							   };
  }

#=============================================================================
sub config_environment_bldtools($;$$)
  {
    &__print_debug_output("Inside 'config_environment_bldtools'\n", __PACKAGE__);
    my ($pkgdir, $version) = @_;

    my $envvar = 'CSLBLD';
    if ( exists($ENV{'CSLBLD_LOCAL'}) ) {
      $envvar = 'CSLBLD_LOCAL';
    }

    if (exists($ENV{"$envvar"}) and -e &join_path("$ENV{$envvar}",'.top')) {
      # Development mode, don't change path.
      &setenv('CSLBLD', "$ENV{$envvar}");
      &setenv("$envvar", "$ENV{$envvar}");
    } else {
      &setenv('CSLBLD', "$pkgdir");
      &setenv("$envvar", "$pkgdir");
      &remove_path('BldTools-\d');
      &prepend_path(&join_path("$pkgdir",'bin'));
    }

    &setenv('CSLBLDBIN',&join_path("$ENV{'CSLBLD'}",'bin'));

    # Don't take any chances about where the HP and Bld modules are stored...

    my $bldtools_path = &path_to_mixed("$ENV{$envvar}");
    &prepend_path(&join_path("$bldtools_path",'HP'),'PERL5LIB', { 'unique' => 1 } );
  }

#=============================================================================
&__initialize();

#=============================================================================
1;
