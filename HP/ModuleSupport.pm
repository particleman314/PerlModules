package HP::ModuleSupport;

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
   
                $module_data

                @ISA
                @EXPORT
               );
    
    $VERSION = 0.99;
 
    @ISA    = qw(Exporter);
    @EXPORT = qw(
                 load_support_modules
                );

    $module_require_list = {
                            'HP::RegexLib'   => undef,
                            'HP::ArrayTools' => undef,
                            'HP::Os'         => undef,
                           };

    $module_request_list = {};

    $is_init     = 0;
    $is_debug    = (
		    $ENV{'debug_module_support_pm'} ||
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

    $module_data = {
                    '__PERLAddonModules__'    => [],
		    '__PERLAddonSites__'      => [],
                   };

    # Print a message stating this module has been loaded.
    print STDERR "LOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
END
  {
    print STDERR "UNLOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
use constant PERLMOD      => '__PerlAddonModules__';
use constant PERLSITE     => '__PerlAddonSites__';

#=============================================================================
sub __addmodule($$)
  {
    my ($modname, $modtype) = @_;

    return if ( not defined($modname) );

    $modtype = PERLMOD if ( not defined($modtype) );
    push( @{$module_data->{"$modtype"}}, "$modname" );
    &set_unique($module_data->{"$modtype"});
  }

#=============================================================================
sub __addsite($$)
  {
    my ($sitename, $modsite) = @_;

    return if ( not defined($sitename) );

    $modsite = PERLSITE if ( not defined($modsite) );
    push( @{$module_data->{"$modsite"}}, "$sitename" );
    &set_unique($module_data->{"$modsite"});
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
sub load_support_modules()
  {
    &__print_debug_output("Inside 'load_support_modules'", __PACKAGE__);

    # Required modules to include for script.
    my @__AddonModules__ = ();
    my @__AddonSites__   = ();

    push( @__AddonModules__, @{$module_data->{PERLMOD}} ) if ( defined($module_data->{PERLMOD}) );
    push( @__AddonSites__, @{$module_data->{PERLSITE}} ) if ( defined($module_data->{PERLSITE}) );

    my $import_stream = '';

  LOADER:
    print STDERR "\n\n" if ( $is_debug );
    while (scalar(@__AddonModules__)) {
      my $mod = shift(@__AddonModules__);

      next if ( ( not defined($mod) ) || ( length($mod) < 1 ) );

      # print STDERR "Attempting to locate module <$mod>...\n";
      eval "use $mod;";
      if ( $@ ) {
	print STDERR "\tfailed!\n\nError encountered --> \"$@\"\n" if ( ( $is_debug ) || ( ( $@ !~ m/Can't locate(.*)in/ ) && ( length($@) > 0 ) ) );
	if ( scalar(@__AddonSites__) ) {
	  my $newlocation = shift(@__AddonSites__);
	  print STDERR "\nTrying to find modules by adding new location :\t<$newlocation>!\n\n" if ( $is_debug );
	  
	  if ( defined($newlocation) && length($newlocation) > 1 ) {
	    &__print_debug_output("New location to add --> << '$newlocation' >>\n", __PACKAGE__);
	    if ( $newlocation !~ m/\$/) {
	      eval "use lib '$newlocation';";
	      $import_stream .= "use lib '$newlocation';";
	    }
	    if ( $newlocation =~ m/\$/) {
	      eval "use lib \"$newlocation\";";
	      $import_stream .= "use lib \"$newlocation\";";
	    }
	  }

	  # Try to load it again with the new library path installed...
	  unshift(@__AddonModules__, $mod);
	  goto LOADER;
	  
	} else {
	  print STDERR "\nUnable to launch <$0> since cannot find\nnecessary source ($mod)!\n\n";
	  print STDERR "Locations searched :\n\n".join("\t\n", @INC)."\n";
	  exit 127;
	}
      } else {
	#print STDERR "\tsucceeded!\n" if ( $is_debug );
      }

      $import_stream .= "use $mod;";
    }
    #if ( $is_debug ) {
    #  print STDERR "Paths searched for modules : \n\n".join("\n", @INC)."\n\n";
    #  print STDERR "Modules included : \n\n".join("\n",sort(keys(%INC)))."\n\n";
    #}

    return $import_stream;
  }

#=============================================================================
&__initialize();

#=============================================================================
1;
