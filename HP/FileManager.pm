package HP::FileManager;

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
                                                                                                                     
    $VERSION     = 1.00;

    # Setup the exported variables and functions available
    @ISA       = qw ( Exporter );
    @EXPORT    = qw (
                     &change_permissions
					 &collect_all_files
					 &collect_directory_contents
					 &delete
					 &does_file_exist
					 &does_directory_exist
					 &get_extension
					 &has_proper_os_extension
					 &ignore_hidden
					 &is_jar_file
					 &is_matching_file_extension
					 &is_xml_file
					 &is_zip_file
					 &make_recursive_dirs
					 &read_dirs_with_pattern
					 &remove_extension
					 &strip_directories
					 &work_in_directory
		            );

    $module_require_list = {
                            'Cwd'                          => undef,
                            'File::Spec'                   => undef,
                            'File::Path'                   => undef,
                            'File::Find'                   => undef,
                            'File::Copy::Recursive'        => undef,
                            'File::Basename'               => undef,

							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							
							'HP::Support::Os'              => undef,
							'HP::Os'                       => undef,
							'HP::String'                   => undef,
							'HP::CheckLib'                 => undef,
							'HP::NumberSystems'            => undef,
							'HP::Path'                     => undef,
                           };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_filemanager_pm'} ||
				 $ENV{'debug_hp_modules'} ||
				$ ENV{'debug_all_modules'} || 0
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
my @dirs_to_delete   = ();
my $pattern_to_strip = '';

my $ignore_hidden_files       = FALSE;
my $ignore_hidden_directories = FALSE;

#=============================================================================
sub __check_for_valid_directory_entry(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $directory = shift;
	
	if ( &does_directory_exist("$directory") eq FALSE ) {
	  return &make_exception('HP::FileManager::Exception::DirectoryNotFound');
	}
	
	my $current_directory = &getcwd();
	
	my $error = chdir("$directory");
	if ( $error == 0 ) {  # FAILURE
	  return &make_exception('HP::FileManager::Exception::DirectoryAccessDenied');
	}
	
	# Now changed into requested directory
	return $current_directory;
  }
  
#=============================================================================
sub __check_for_valid_directory_exit(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $directory = shift;
	
	if ( defined($directory) ) {
	  if ( &does_directory_exist("$directory") eq FALSE ) {
	    return &make_exception('HP::FileManager::Exception::DirectoryNotFound');
	  }

	  my $error = chdir("$directory");
	  if ( $error == 0 ) {  # FAILURE
	    return &make_exception('HP::FileManager::Exception::DirectoryAccessDenied');
	  }
	}
	
	return TRUE;
  }
  
#=============================================================================
sub __get_directory_contents($)
  {
    my $directory = shift || return [];
	 
	my $success = opendir(__DIRHANDLE__, "$directory");
	if ( not $success ) { return []; }
	 
	my @dircontents = grep !/^\.\.?\z/, readdir (__DIRHANDLE__);
	closedir(__DIRHANDLE__);
    
	chomp(@dircontents);
	return \@dircontents;
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
sub __internal_pattern_dir($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    my $relative_path = "$_";

    &__print_debug_output("Testing input --> $relative_path\n", __PACKAGE__) if ( $is_debug );
    &__print_debug_output("Pattern to strip away --> $pattern_to_strip\n", __PACKAGE__) if ( $is_debug );

    my $dirName = File::Spec->catfile("$File::Find::dir", "$relative_path");
    &__print_debug_output("File::Find::dir = $File::Find::dir :: Dirname = $dirName\n", __PACKAGE__) if ( $is_debug );

    if ( ( &does_directory_exist("$dirName") eq TRUE ) &&
	     ( "$relative_path" =~ m/$pattern_to_strip/ ) ) {
      &__print_debug_output("MATCHED $File::Find::file TO: $pattern_to_strip", __PACKAGE__) if ( $is_debug );
      push @dirs_to_delete, "$dirName";
    }
  }

#=============================================================================
sub change_permissions($;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $directory   = shift;
    my $permissions = shift || 0777;

	if ( not &is_octal($permissions) ) { $permissions = &make_octal($permissions); }
	
    if ( &does_directory_exist( "$directory" ) eq TRUE ) {
	  my $num_changed = chmod $permissions, "$directory";

      &__print_output("Ensuring << $directory >> has proper permissions as specified!\n", INFO);
	  if ( $num_changed < 1 ) {
	    &raise_exception(
	                     {
					      'type'    => 'c__HP::FileManager::ChangePermissionsException__',
					      'msg'     => "Could not change permissions for directory << $directory >>",
					      'streams' => [ 'STDERR' ],
				         }
					    );
	  }
			 
      &__print_output("Made directory ($permissions permissions) --> << $directory >>\n", INFO);
    } else {
      &__print_output("No directory to update << $directory >>!!!", WARN);
    }
  }

#=============================================================================
sub collect_all_files($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    my $result = [];
	
    my $dir  = shift;
	my $test = shift;
	return $result if ( ( &valid_string($dir) eq FALSE ) ||
	                    ( &does_directory_exist("$dir") eq FALSE ) );

	$dir = &normalize_path("$dir");
	my $dircontents = &__get_directory_contents("$dir");

	foreach my $entry (@{$dircontents}) {
	  next if ( ($entry eq '.') || ($entry eq '..') );		
	  my $path_entry = &join_path("$dir","$entry");

	  #&__print_output("Testing entry : $path_entry", INFO);
	  my $is_file    = &does_file_exist("$path_entry");
	  my $is_folder  = &does_directory_exist("$path_entry");
	  
      if ( $is_folder eq TRUE ) {
		if ( defined($HP::FileManager::ignore_hidden_directories) &&
		     $HP::FileManager::ignore_hidden_directories eq TRUE ) {
		  next if ( &str_starts_with($entry, [ '.' ]) eq TRUE );
		}
		my $sublevel = &collect_all_files("$path_entry", $test);
		push ( @{$result}, @{$sublevel} ) if ( scalar(@{$sublevel}) > 0 );
      }
	  
	  if ( $is_file eq TRUE ) {
		if ( defined($HP::FileManager::ignore_hidden_files) &&
		     $HP::FileManager::ignore_hidden_files eq TRUE ) {
		  next if ( &str_starts_with($entry, [ '.' ]) eq TRUE );
		}
		  
	    my $test_result = TRUE;
	    if ( ref($test) =~ m/hash/i ) {
		  if ( exists($test->{'function'}) ) {
		    if ( ref($test->{'function'}) =~ m/code/i ) {
		      $test_result = &{$test->{'function'}}("$path_entry");
		    }
		    if ( ref($test->{'function'}) =~ m/regexp/i ) {
			  $test_result = ( $path_entry =~ m/$test->{'function'}/ );
	        }
		  }
	    }
		
	    if ( ref($test) =~ m/code/i ) {
		  $test_result = &{$test}("$path_entry");
	    }
		  
		push( @{$result}, "$path_entry" ) if ( $test_result eq TRUE );
	  }
	}
	
	return $result;
  }
  
#=============================================================================
sub collect_directory_contents($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    my $result = {
	              'directories' => [],
			      'files'       => [],
				 };
				  
    my $dir = shift;
	my $test = shift;

	return $result if ( ( &valid_string("$dir") eq FALSE ) ||
	                    ( &does_directory_exist("$dir") eq FALSE ) );
	&__print_debug_output("Directory to list << $dir >>", __PACKAGE__) if ( $is_debug );

	$dir = &normalize_path("$dir");
	my $dircontents = &__get_directory_contents("$dir");
	 
	foreach my $entry (@{$dircontents}) {
	  next if ( ($entry eq '.') || ($entry eq '..') );		
	  my $path_entry = &join_path("$dir","$entry");
		
	  my $test_result = TRUE;
	  if ( ref($test) =~ m/hash/i ) {
		if ( exists($test->{'function'}) ) {
		  if ( ref($test->{'function'}) =~ m/code/i ) {
		    $test_result = &{$test->{'function'}}("$path_entry");
		  }
		  if ( ref($test->{'function'}) =~ m/regexp/i ) {
			$test_result = ( $path_entry =~ m/$test->{'function'}/ );
	      }
		}
	  }
		
	  if ( ref($test) =~ m/code/i ) {
		$test_result = &{$test}("$path_entry");
	  }
		
		
	  if ( $test_result eq TRUE ) {
	    my $is_file   = &does_file_exist("$path_entry");
	    my $is_folder = &does_directory_exist("$path_entry");
		if ( $is_folder eq TRUE ) {
		  if ( defined($HP::FileManager::ignore_hidden_directories) && $HP::FileManager::ignore_hidden_directories eq TRUE ) {
		    next if ( &str_starts_with($entry, [ '.' ]) eq TRUE );
		  }
		  push( @{$result->{'directories'}}, "$entry" );
		}
		if ( $is_file eq TRUE ) {
		  if ( defined($HP::FileManager::ignore_hidden_files) && $HP::FileManager::ignore_hidden_files eq TRUE ) {
		    next if ( &str_starts_with($entry, [ '.' ]) eq TRUE );
		  }
		  push( @{$result->{'files'}}, "$entry" );
		}
	  }
    }
	 
	return $result;
  }

#=============================================================================
sub delete(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
  
    my $num_removed = 0;
	
    foreach (@_) {
	  my $is_file   = &does_file_exist("$_");
	  my $is_folder = &does_directory_exist("$_");
	  next if ( ( $is_file eq FALSE ) &&
	            ( $is_folder eq FALSE ) );
	  if ( $is_file ) {
	    &__print_debug_output("Deleting file << $_ >>", __PACKAGE__) if ( $is_debug );
	    $num_removed += &delete_file("$_");
	  }
	  if ( $is_folder ) {
	    &__print_debug_output("Deleting folder << $_ >>", __PACKAGE__) if ( $is_debug );
	    $num_removed += &delete_directory("$_");
	  }
	}
	return $num_removed;
  }
  
#=============================================================================
sub delete_directory(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $num_removed = 0;
	foreach (@_) {
	  if ( &does_directory_exist( "$_" ) eq FALSE ) {
	    &__print_output("<< $_ >> directory does not exist\n", WARN);
	    next;
	  }
	  if ( &os_is_windows_native() eq TRUE ) {
	    my $robocopy_exe = &convert_path_to_client_machine('C:/Windows/system32/robocopy.exe');
		if ( &does_file_exist("$robocopy_exe") eq TRUE ) {
		  my $tmpdir    = &get_temp_dir();
		  my $pid       = &get_pid();
		  my $empty_dir = &make_recursive_dirs(&join_path("$tmpdir",'empty_dir'. $pid));
		  my @output    = `$robocopy_exe $empty_dir "$_" /purge 2>NUL`;
		  rmtree("$empty_dir");
		}
	    rmtree( "$_" );
	  } else {
	    rmtree( "$_" );
	  }
	  ++$num_removed;
	}
    return $num_removed;
  }
   
#=============================================================================
sub delete_file(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    # "unlink" can take a list of files...  The return value is the number
    # of files deleted.
    my $numfiles_removed = 0;
    foreach (@_) {
      if ( &does_file_exist( "$_" ) eq FALSE ) {
	    &__print_output("<< $_ >> file does not exist\n", WARN);
	    next;
      }
      my $removed = unlink( "$_" );
	  &__print_debug_output("Number of removed items --> $removed",__PACKAGE__) if ( $is_debug );
      $numfiles_removed += $removed if ( &does_file_exist( "$_" ) eq FALSE );
    }
    return $numfiles_removed;
  }

#=============================================================================
sub does_file_exist($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $inputname = shift;
	
    my $found = ( not -f "$inputname" ) ? 'No ' : '';
    &__print_debug_output( "${found}File found at: << $inputname >>", __PACKAGE__ ) if ( $is_debug );
    return TRUE if ( $found eq '' );
    return FALSE;
  }

#=============================================================================
sub does_directory_exist($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $inputname = shift;
	
    my $found = ( not -d "$inputname" ) ? 'No ' : '';
    &__print_debug_output( "${found}Directory found at: << $inputname >>", __PACKAGE__ ) if ( $is_debug );
    return TRUE if ( $found eq '' );
    return FALSE;
  }

#=============================================================================
sub get_extension($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	my $inputname = shift || return;
	
	my $suffix = substr("$inputname", rindex("$inputname", '.') + 1);
	#my ($name,$path,$suffix) = fileparse("$inputname",qr"\..[^.]*$");
	if ( substr($suffix, 0, 1) eq '.' ) { $suffix = substr("$suffix", 1, length($suffix)); }
	return $suffix;
  }

#=============================================================================
sub has_proper_os_extension($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    my $inputname = shift;
	my $extension = shift;
	
    return FALSE if ( ( &valid_string("$inputname") eq FALSE ) ||
	                  ( &valid_string("$extension") eq FALSE ) );
	return ( lc(&get_extension("$inputname")) eq "$extension" ? TRUE : FALSE );
  }

#=============================================================================
sub ignore_hidden($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    my $type  = shift || return;
	my $value = shift || FALSE;
	
	my $varaccess = "\$HP::FileManager::ignore_hidden_$type";
	$value = TRUE if ( $value ne FALSE );
	
	eval "$varaccess = $value;";
	return;
  }
  
#=============================================================================
sub is_jar_file($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    return &is_matching_file_extension("$_[0]", 'jar');
  }
  
#=============================================================================
sub is_matching_file_extension($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    return &has_proper_os_extension(@_);
  }

#=============================================================================
sub is_xml_file($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    return &is_matching_file_extension("$_[0]", 'xml');
  }

#=============================================================================
sub is_zip_file($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    return &is_matching_file_extension("$_[0]", 'zip');
  }

#=============================================================================
sub make_recursive_dirs($;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $inputdirname = shift;

    &__print_debug_output("Input directory name to design --> ".Dumper($inputdirname), __PACKAGE__) if ( $is_debug );
    return undef if ( ( not defined($inputdirname) ) || ( ref($inputdirname) ne '' ) );

    my $possibledir  = File::Spec->rel2abs("$inputdirname");
    my $permissions  = shift || 0777;

	$permissions = &make_octal($permissions) if ( &is_octal($permissions) eq FALSE );
	
    if ( &does_directory_exist( "$possibledir" ) eq FALSE ) {

      my $native_cmd = "mkpath (\"\$possibledir\", \$is_debug, $permissions);";
      eval "$native_cmd";

      if ( $@ ) {
		&__print_debug_output("Failed to make directory structure << $possibledir >> using File::Path, trying second method...", __PACKAGE__) if ( $is_debug );
		my $base_exist  = 0;
		my $lowestlevel = $possibledir;
		while ( not $base_exist ) {
			my $dummydir = dirname( $lowestlevel );
			$base_exist  = TRUE if ( &does_directory_exist( "$dummydir" ) eq TRUE );
			$lowestlevel = $dummydir;
		}
		my $dirsep = &convert_to_regexs(&get_dir_sep());
		my @missingdirs = split( $dirsep, File::Spec->abs2rel( $possibledir, $lowestlevel ));
		foreach my $subdir (@missingdirs) {
			my $propersubdir = File::Spec->catfile( $lowestlevel, $subdir );
			my $success = mkdir "$propersubdir";
			if ( not defined($success) || $success == FALSE ) {
			  &raise_exception(
                               {
								'type'    => 'c__HP::FileManager::MakeDirectoryException__',
								'msg'     => "Unable to make directory << $propersubdir >>",
								'streams' => [ 'STDERR' ],
							   }
							  );
			}
			$lowestlevel = "$propersubdir";
		}
      }
    } else {
      return "$inputdirname";
    }
    return $possibledir;
  }

#=============================================================================
sub read_dirs_with_pattern($;$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my ($dir, $pattern, $mapping) = @_;
    $pattern = undef if (scalar(@_) < 2);
    $mapping = undef if (scalar(@_) < 3);

    if ( &does_directory_exist($dir) eq TRUE ) {
      my @dir_list = ();
      opendir DIRLOC, $dir;
      if ( not defined($pattern)) {
	    @dir_list = grep { $_ !~ /^\.\.?\w*$/ } readdir DIRLOC;
      } else {
	    if ( not defined($mapping)) {
	      @dir_list = grep { $_ =~ /$pattern/ } readdir DIRLOC;
	    } else {
	      @dir_list = grep { $_ =~ /$pattern/ } map (File::Spec->catdir($mapping, $_), readdir DIRLOC);
	    }
      }
      closedir DIRLOC;

      &__print_debug_output("List of files found::\n".join("\n",@dir_list), __PACKAGE__) if ( $is_debug );
      return \@dir_list;
    }
    &__print_debug_output('No files found', __PACKAGE__) if ( $is_debug );
    return undef;
  }

#=============================================================================
sub remove_extension($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	my $inputname = shift || return;
	$inputname =~ s/(.+)\.[^.]+$/$1/;
	return "$inputname";  
  }
  
#=============================================================================
sub strip_directories(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $topdir        = shift;
    my $strip_pattern = pop(@_);
    my @patterns      = @_;
    
    &__print_debug_output("Top Dir = $topdir\n", __PACKAGE__) if ( $is_debug );

    if ( ref($strip_pattern) !~ m/code/i ) {
      push (@patterns, $strip_pattern);
      $strip_pattern = \&__internal_pattern_dir;
    }

	if ( $is_debug ) {
      &__print_debug_output("Pattern to match --> $strip_pattern\n", __PACKAGE__);
      &__print_debug_output("Patterns to use -->\n".Dumper(\@patterns),__PACKAGE__);
      &__print_debug_output("Dirs to delete --> @dirs_to_delete\n", __PACKAGE__);
    }
	
    foreach (@patterns) {
      $pattern_to_strip = $_;

      &__print_debug_output("Pattern to find --> $pattern_to_strip\n", __PACKAGE__) if ( $is_debug );
      find( {
	     wanted   => $strip_pattern,
	     no_chdir => 0
	    },
	    $topdir );
    
      foreach my $dir (@dirs_to_delete) {
	    &__print_debug_output("Removing << $pattern_to_strip >> $dir...", __PACKAGE__) if ( $is_debug );
	    &delete_directory("$dir");
      }

      undef @dirs_to_delete;
      undef $pattern_to_strip;
    }
  }

#=============================================================================
sub work_in_directory(@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $directory = shift;
	my $function  = shift;
	my @funcargs  = @_;
		
	if ( &valid_string($directory) eq FALSE ) {
	  &raise_exception(
	                   {
					    'type'    => 'c__HP::FileManager::DirectoryNotFoundException__',
					    'msg'     => "Could not change to directory << $directory >>",
					    'streams' => [ 'STDERR' ],
				       }
					  );
	}
	
	my $original_dir = &__check_for_valid_directory_entry("$directory");
	
	if ( $is_debug ) {
	  &__print_debug_output("Original directory --> << $original_dir >>");
	  &__print_debug_output("New directory      --> << $directory >>");
	  &__print_debug_output("Verification of current_directory << ". &getcwd() ." >>");
	}
	
	&raise_exception( $original_dir ) if ( &is_type($original_dir, 'HP::Exception') eq TRUE );  # This is an exception class not a string

	my $func_result = undef;
	no strict;
	if ( scalar(@funcargs) > 0 ) {
	  $func_result = &{$function}(@funcargs);
	} else {
	  $func_result = &{$function}();
	}
	use strict;
	
	my $chgdir_success = &__check_for_valid_directory_exit("$original_dir");
	&raise_exception( $chgdir_success ) if ( &is_type($chgdir_success, 'HP::Exception') eq TRUE );  # This is an exception class not a string
	
	return $func_result;				 
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;
