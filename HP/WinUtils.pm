package HP::WinUtils;

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

                @ISA
                @EXPORT
               );
                                                                                              
    $VERSION     = 0.7;
    @ISA         = qw ( Exporter );
    @EXPORT      = qw (
		               &augment_path
		               &make_windows_shortcut
		               &set_registry_environment
		               &set_registry_entry
		      );

    $module_require_list = {
	                        'HP::Constants'     => undef,
                            'HP::Array::Tools'  => undef,
                            'HP::Support::Base' => undef,
			                'HP::Path'          => undef,
                            'HP::StreamManager' => undef,
                            'HP::TextTools'     => undef,
                            'HP::Process'       => undef,
                           };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug  = (
		          $ENV{'debug_winutils_pm'} ||
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
      #my @winutils_exceptions = qw(
      #                             INVALID_REGISTRY_PARAMETER
      #                             PATH_EXPRESSION_INVALID
      #                             UNSUPPORTED_REGISTRY_MODE
      #                            );

      #&add_exception_ids( @winutils_exceptions );
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
sub augment_path($;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $newpath           = shift;
    my $addpath_pathcount = shift;
    my $ispre             = shift || 0;

    my $type = $ispre ? "Prepend" : "Append";

    $newpath = = &HP::Path::__flip_slashes("$newpath", PATH_FORWARD, PATH_BACKWARD);  # Convert slashes to backslashes

    print STDOUT <<EOT

    #
    # $type "$newpath" to the system PATH.
    #
    # Read the PATH from the registry
    ReadRegStr \$R0 HKLM "SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" "PATH"
    StrCmp "\$R0" "" couldnotreadpath_$addpath_pathcount
    # Search for the path to be added
    Push "\$R0"
    Push "$newpath"
    Call StrStr
    pop \$R1
    # If the path already exists, then we're done.
    StrCmp \$R1 "" 0 donepath_$addpath_pathcount
    # ${type}ing the new path
EOT
;

    if ( $ispre ) {
        print STDOUT <<EOT
    StrCpy \$R1 \"$newpath;\$R0\"
EOT
;
    } else {
        print STDOUT <<EOT
    StrCpy \$R1 \"\$R0;$newpath\"
EOT
;
    }

    print STDOUT <<EOT
    WriteRegExpandStr HKLM "SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment" "PATH" "\$R1"
    goto donepath_$addpath_pathcount
couldnotreadpath_$addpath_pathcount:
    MessageBox MB_OK|MB_ICONEXCLAMATION "Failed to read PATH from the registry.  Not updating PATH." /SD IDOK

donepath_$addpath_pathcount:
EOT
;
    ++$addpath_pathcount;
    return $addpath_pathcount;
  }

#=============================================================================
sub set_registry_entry($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $params = shift;
    &raise_exception(
                     'INVALID_REGISTRY_PARAMETER',
		     "Incoming parameters is not defined\n"
                    ) if ( not defined($params) );


    my ($type, $path, $value) = split /\s*,\s*/, $params, 3;
    &raise_exception(
                     'INVALID_REGISTRY_PARAMETER',
		     "Triplet malformed \n"
                    ) if ( not defined($type) ||
			   not defined($path) ||
			   not defined($value) );

    my @known_registry_types = qw(
				  string
				  expandstring
				  int
				  binary
				 );
    # Determine the registry command based on type
    my $regcmd = undef;

    $type = &lowercase_all(&eat_quotations("$type"));
    &raise_exception(
	             'UNSUPPORTED_REGISTRY_MODE',
		     "Unsupported registry write mode: $type\n"
	            ) if ( not &set_contains($type, \@known_registry_types) );
			
    if ($type eq 'string') {
      $regcmd = 'WriteRegStr';
    } elsif ($type eq 'expandstring') {
      $regcmd = 'WriteRegExpandStr';
    } elsif ($type eq 'int') {
      $regcmd = 'WriteRegDWord';
    } elsif ($type eq 'binary') {
      $regcmd = 'WriteRegBin';
    }
    
    &raise_exception(
	             'UNSUPPORTED_REGISTRY_MODE',
		     "Unsupported registry write mode: $type\n",
		    ) if ( not defined($regcmd) );

    # Expand the path
    $path = &external_env_eval("$path");
    $path = &HP::Path::__flip_slashes("$path", PATH_BACKWARD, PATH_FORWARD);

    my $dirsep = &get_dir_sep();

    my @pathparts = split /\//, $path;

    my $root    = shift @pathparts;
    my $key     = pop @pathparts;
    my $regpath = join("$dirsep", @pathparts);

    # Expand the value
    $value = &external_env_eval("$value");
    print STDOUT "\n";
    print STDOUT "    # Setting registry key: $path = $value\n";
    print STDOUT "    $regcmd $root \"$regpath\" \"$key\" \"$value\"\n";
  }

#=============================================================================
sub set_registry_environment($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $params = shift;

    &raise_exception(
	             'INVALID_REGISTRY_PARAMETER',
		     "Incoming parameters is not defined\n"
                    ) if ( not defined($params) );

    my ($var, $val) = split /\s*=\s*/, $params;

    &raise_exception(
                     'INVALID_REGISTRY_PARAMETER',
		     "Key/Value pair malformed \n"
                    ) if ( not defined($var) || not defined($val) );

    $val = &external_env_eval("$val");
    print STDOUT "\n";
    print STDOUT "    # Setting Environment variable $var=$val\n";
    print STDOUT "    WriteRegStr HKLM \"SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment\" \"$var\" \"$val\"\n";
  }

#=============================================================================
sub make_windows_shortcut($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $parameters = shift;

    &raise_exception(
                     'INVALID_REGISTRY_PARAMETER',
		     "Incoming parameters is not defined\n"
	            ) if ( not defined($parameters) || ref($parameters) !~ m/hash/i );

    print STDOUT "\n";
    print STDOUT "    SetShellVarContext $parameters->{'context'}\n";

    # Create the directory, if needed
    print STDOUT "    # Creating shortcut '\$$parameters->{'target'}\\$parameters->{'linkname'}' in context '$parameters->{'context'}\n";

    $parameters->{'linkname'} = &HP::Path::__flip_slashes("$parameters->{'linkname'}", 'forward', 'backword'); # Convert slashes to backslashes
    my $dirsep = &get_dir_sep();

    my @t = split /$dirsep/, $parameters->{'linkname'};
    pop @t;
    my $dir = join("$dirsep", @t);
    if ( defined($dir) and $dir ne '.') {
      print STDOUT "    CreateDirectory \"\$$parameters->{'target'}\\$dir\" \n";
    } else {
      print STDOUT "    CreateDirectory \"\$$parameters->{'target'}\" \n";
    }

    # Construct the command to create the shortcut
    print STDOUT "    CreateShortCut \"\$$parameters->{'target'}\\$parameters->{'linkname'}\" \"$parameters->{'launch'}\" \"$parameters->{'options'}->{'params'}\"";
    if ( exists $parameters->{'options'}->{'icon'} ) {
      $parameters->{'options'}->{'icon'} = &external_env_eval($parameters->{'options'}->{'icon'});
      $parameters->{'options'}->{'icon'} = "$parameters->{'launch'}" if ($parameters->{'options'}->{'icon'} eq 'source');
      print STDOUT " \"$parameters->{'options'}->{'icon'}\"";
      print STDOUT " \"$parameters->{'options'}->{'iconindex'}\"" if ( exists $parameters->{'options'}->{'iconindex'} );
    }
    print STDOUT "\n";
  }

#=============================================================================
&__initialize();

#=============================================================================
1;

