package HP::Environment::Helper;

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
                $is_trace

                $module_require_list
                $module_request_list

                $broken_install

		$pathdelim
		$site

		%newenv

		@newenv_remove
                @addon_package_locations

                @ISA
                @EXPORT
               );

    $VERSION     = 0.99;

    @ISA    = qw ( Exporter );
    @EXPORT = qw (
                  &add_package_location
		  &append_path
                  &clear_package_locations
		  &compare_versions
		  &get_newenv
		  &get_newenv_ref
		  &get_newenv_remove
		  &get_newenv_remove_ref
                  &get_package_locations
		  &prepend_path
		  &remove_path
		  &setenv
		  &install_package_configuration
		  &add_newenv_var

                  @addon_package_locations
                 );    

    $module_require_list = {
			    'File::Basename'          => undef,

			    'HP::RegexLib'            => undef,
			    'HP::BasicTools'          => undef,
			    'HP::ArrayTools'          => undef,
			    'HP::Os'                  => undef,
			    'HP::OsSupport'           => undef,
			    'HP::Path'                => undef,
			    'HP::String'              => undef,
			    'HP::FileManager'         => undef,
			    'HP::TextTools'           => undef,
                           };

    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_environment_helper_pm'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );
    $is_trace  = $ENV{'trace_environment_helper_pm'} || 0;

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

    # Determine this current OS's path delimiter
    $pathdelim = &get_path_delim();

    # Print a message stating this module has been loaded.
    print STDERR "LOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
END
  {
    print STDERR "UNLOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
use constant FAIL => 0;
use constant PASS => 1;

my @addon_package_locations = ();

#=============================================================================
sub __add_skip_vars($)
  {
    my $arrayref = shift;

    foreach my $envpoke (@_) {
      my @skip_vars = ();
      if ( exists($ENV{$_[0]}) ) {
        @skip_vars = split(':',$ENV{$_[0]});
      }
      push (@{$arrayref}, @skip_vars) if ( scalar(@skip_vars) );
    }

    $arrayref = &set_unique($arrayref);
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
sub add_newenv_var($)
  {
    my $var = shift;
    return if ( not defined($var) );

    if ( not exists($newenv{"$var"}) ) {
      $newenv{"$var"} = $ENV{"$var"} if ( exists($ENV{"$var"}) );
    }
  }

#=============================================================================
sub add_package_location($;$)
  {
    my $path = shift;
    return if ( not defined($path) or length($path) < 1 or not &does_directory_exist( "$path" ) );

    my $system_path = shift;

    if ( not defined($system_path) or not $system_path or $system_path !~ m/tru/ ) { 
      $system_path = 'false';
    } else {
      $system_path = 'true';
    }

    $path = &path_to_unix("$path");

    if ( not &set_contains("$path", \@addon_package_locations) ) {
      &prepend_path("$path",'PERL5LIB') if ( $system_path eq 'true' );
      unshift ( @INC, "$path" );
      push ( @addon_package_locations, "$path" );
    }
  }

#=============================================================================
# Append the requested path to the PATH.
sub append_path($;$$)
  {
    &__print_debug_output("Inside 'append_path'", __PACKAGE__) if ( $is_debug );

    my $newpath  = shift;
    my $var      = shift || 'PATH';
    my $director = shift || {};

    my @skip_vars = ();    
    &__add_skip_vars(\@skip_vars,'SKIP_ENV_VARS','EXPUNGE_ENV_VARS');    
    
    if ( &set_contains( $var, \@skip_vars ) ) { return; }

    if ( &os_is_windows_native() ) {
      $newpath = &path_to_mixed("$newpath", { 'convert_path' => 1, });
      $newpath =~ s/\//\\/g;
    } elsif ( &os_is_cygwin() ) {
      $newpath = &path_to_unix("$newpath",  { 'convert_path' => 1, }) if ( not exists($director->{'style'}) or $director->{'style'} =~ m/[unix|linux]/i );
      $newpath = &path_to_mixed("$newpath", { 'convert_path' => 1, }) if ( exists($director->{'style'}) and $director->{'style'} =~ m/mixed/i );
      $newpath = &path_to_win("$newpath",   { 'convert_path' => 1, }) if ( exists($director->{'style'}) and $director->{'style'} =~ m/win/i );
    } else {
      $newpath = &path_to_unix("$newpath",  { 'convert_path' => 1, });
    }

    if ( not exists($director->{'separator'}) ) { 
      if ( not defined($pathdelim)  or length($pathdelim) < 1 ) { $pathdelim = &get_path_delim(); }
      $director->{'separator'} = $pathdelim; 
    }

    if ($ENV{"$var"}) {
      $ENV{"$var"} = "$ENV{$var}"."$director->{'separator'}"."$newpath";
      if ( exists($director->{'unique'}) and $director->{'unique'} ) {;
        my @entry_comps = split("$director->{'separator'}","$ENV{$var}");
        $ENV{"$var"} = join("$director->{'separator'}",@{&set_unique(\@entry_comps)});
      }
    } else {
      $ENV{"$var"} = "$newpath";
    }
    $newenv{"$var"} = $ENV{"$var"};
  }

#=============================================================================
sub clear_package_locations()
  {
    @addon_package_locations = ();
  }

#=============================================================================
sub compare_versions($$)
  {
    &__print_debug_output("Inside 'compare_versions'", __PACKAGE__) if ( $is_debug );

    my $a = shift;
    my $b = shift;
    my ($aver, $arev) = split /_/, $a, 2;
    my ($bver, $brev) = split /_/, $b, 2;
    my @avers = split /\./, $aver;
    my @bvers = split /\./, $bver;
    my $diff = 0;

    # Compare lexiographical dates.
    return $aver cmp $bver if ( $aver =~ m/(\d*)\-(\d*)\-(\d*)/ );

    # Compare each number in the version, separated by dots (.).
    for (my $i = 0; not $diff and $i < scalar(@avers) and $i < scalar(@bvers); ++$i) {
      my $aisnumber = &is_numeric($avers[$i]);
      my $bisnumber = &is_numeric($bvers[$i]);
      if ( $aisnumber and $bisnumber ) {
	$diff = $avers[$i] - $bvers[$i];
      } else {
	$diff = $avers[$i] cmp $bvers[$i];
      }
    }
    # If $diff==0, see if one version is longer than the other.
    $diff ||= scalar(@avers) - scalar(@bvers);
    # If diff is set, we're done, return diff.
    return $diff if ($diff);

    # At this point, the versions are identical, so compare the revisions.
    $arev ||= '';
    $brev ||= '';
    return $arev cmp $brev;
  }

#=============================================================================
sub get_newenv_ref()
  {
    return \%newenv;
  }
#=============================================================================
sub get_newenv()
  {
    return %newenv;
  }
#=============================================================================
sub get_newenv_remove_ref()
  {
    return \@newenv_remove;
  }
#=============================================================================
sub get_newenv_remove()
  {
    return @newenv_remove;
  }

#=============================================================================
sub get_package_locations()
  {
    return \@addon_package_locations; 
  }

#=============================================================================
sub install_package_configuration($$)
  {
    my $modulepath = shift;
    my $module     = shift;

    &__print_debug_output("Module path = << $modulepath >>, Module = << $module >>", __PACKAGE__) if ( $is_debug );

    my $full_module_name = "$modulepath".'::'."$module";
    my $cmd              = "use $full_module_name;";

    my @names            = &convert_from_colon_module( "$full_module_name" );
    my $full_name        = $names[0];

    &__print_debug_output("Cmd to run --> << $cmd >>, Full name --> << $full_name >>",__PACKAGE__) if ( $is_debug );

    eval "$cmd";

    if ( $@ or not exists($INC{"$full_name"}) ) {
      &__print_output("Problem loading basic environment module << $full_module_name >>\n$@\n", __PACKAGE__);
      return FAIL;
    }

    my $has_API_access = 0;
    $cmd = "\$has_API_access = $full_module_name->can('install_package');";

    eval "$cmd";
    if ( $@ ) {
      &__print_output("No API interface for environment module << $full_module_name >>\n$@\n", __PACKAGE__);
      return FAIL;
    }

    if ( $has_API_access ) {
      $cmd = "\&$full_module_name"."::install_package();";
      eval "$cmd";
      if ( $@ ) {
	&__print_output("Could not properly call API interface << $module >>!\n$@\n", __PACKAGE__);
	return FAIL;
      }
    }
    return PASS;
  }

#=============================================================================
sub prepend_path($;$$)
  {
    &__print_debug_output("Inside 'prepend_path'", __PACKAGE__) if ( $is_debug );

    my $newpath  = shift;
    my $var      = shift || 'PATH';
    my $director = shift || {};

    my @skip_vars = ();    
    &__add_skip_vars(\@skip_vars,'SKIP_ENV_VARS','EXPUNGE_ENV_VARS');    
    
    if ( &set_contains( $var, \@skip_vars ) ) { return; }    
    
    if ( &os_is_windows_native() ) {
      $newpath = &path_to_mixed("$newpath", { 'convert_path' => 1, });
      $newpath =~ s/\//\\/g;
    } elsif ( &os_is_cygwin() ) {
      $newpath = &path_to_unix("$newpath",  { 'convert_path' => 1, }) if ( not exists($director->{'style'}) or $director->{'style'} =~ m/[unix|linux]/i );
      $newpath = &path_to_mixed("$newpath", { 'convert_path' => 1, }) if ( exists($director->{'style'}) and $director->{'style'} =~ m/mixed/i );
      $newpath = &path_to_win("$newpath",   { 'convert_path' => 1, }) if ( exists($director->{'style'}) and $director->{'style'} =~ m/win/i );
    } else {
      $newpath = &path_to_unix("$newpath",  { 'convert_path' => 1, });
    }

    if ( not exists($director->{'separator'}) ) {
      if ( not defined($pathdelim)  or length($pathdelim) < 1 ) { $pathdelim = &get_path_delim(); }
      $director->{'separator'} = $pathdelim;
    }

    &__print_debug_output("Path delimiter --> $director->{'separator'}\n", __PACKAGE__);
    if ($ENV{"$var"}) {
      $ENV{"$var"} = "$newpath"."$director->{'separator'}"."$ENV{$var}";
      if ( exists($director->{'unique'}) and $director->{'unique'} ) {;
        my @entry_comps = split("$director->{'separator'}","$ENV{$var}");
        $ENV{"$var"} = join("$director->{'separator'}",@{&set_unique(\@entry_comps)});
      }
    } else {
      $ENV{"$var"} = "$newpath";
    }
    $newenv{"$var"} = $ENV{"$var"};
  }

#=============================================================================
sub remove_path($;$)
  {
    &__print_debug_output("Inside 'remove_path'", __PACKAGE__) if ( $is_debug );

    my $pattern   = shift;
    my $var       = shift || 'PATH';

    if ( $is_debug ) {
      &__print_debug_output("Input 1 -->\n".Dumper($pattern),__PACKAGE__);
      &__print_debug_output("Input 2 -->\n".Dumper($var),__PACKAGE__);
      &__print_debug_output("Path Delimiter --> $pathdelim\n", __PACKAGE__);
    }

    return if ( not defined($ENV{$var}) );

    my @pathparts = split /$pathdelim/, $ENV{$var};

    &__print_debug_output("Path components -->\n".Dumper(\@pathparts),__PACKAGE__) if ( $is_debug );

    $pattern      = quotemeta("$pattern") if ( ref($pattern) =~ m/regex/i );
    my $stmt      = "\@pathparts = grep !/\\b$pattern/i, \@pathparts;";
    eval "$stmt";
    my $newpath   = join "$pathdelim", @pathparts;

    $ENV{"$var"}    = "$newpath";
    $newenv{"$var"} = "$newpath";
  }

#=============================================================================
sub setenv($$)
  {
    my @skip_vars = ();
    &__add_skip_vars(\@skip_vars,'SKIP_ENV_VARS','EXPUNGE_ENV_VARS');

    my ($var, $val) = @_;
    if ( &set_contains( $var, \@skip_vars ) ) { return; }

    if ( defined($val) ) {
      $ENV{"$var"}    = "$val";
      $newenv{"$var"} = "$val";
    } else {
      delete $ENV{"$var"};
      delete $newenv{"$var"};
      push @newenv_remove, "$var";
    }
  }

#=============================================================================
&__initialize();

#=============================================================================
1;

