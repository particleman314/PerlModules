package HP::Path;

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

				%win_path_cache
				%mixed_path_cache
				%unix_path_cache
				%file_stat_attr

                $user_tempdir
                $cygpath_exe

                @ISA 
				@EXPORT
               );

    $VERSION  = 0.95;

    @ISA    = qw(Exporter);
    @EXPORT = qw(
	             &convert_path_to_client_machine
				 &convert_java_path
                 &escapify_path
				 &find_relative_path
				 &get_attribute
				 &get_file_size
				 &get_file_time
				 &get_full_path
				 &get_resolved_path
				 &get_path_delim
				 &get_temp_dir
				 &join_path
				 &minimize_pathnames
				 &normalize_path
				 &path_find_common_root
				 &path_is_rel
				 &path_is_same
				 &path_to_mixed
				 &path_to_unix
				 &path_to_win
                 &set_temp_dir
				 &which
		        );

    $module_require_list = {
			                'File::Basename'               => undef,
			                'File::Path'                   => undef,

							'HP::Constants'                => undef,
			                'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Os'              => undef,
							'HP::Support::Os::Constants'   => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::Support::Screen'          => undef,
							
							'HP::Path::Constants'          => undef,
							'HP::CheckLib'                 => undef,
			                'HP::String'                   => undef,
			                'HP::Os'                       => undef,
			               };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
		         $ENV{'debug_path_pm'} ||
		         $ENV{'debug_hp_modules'} ||
				 $ENV{'debug_all_modules'} || 0
		);

    $cygpath_exe  = undef;
    $user_tempdir = undef;

    # These cache hashes should speed up duplicate calls to the path conversion
    # functions.
    %file_stat_attr = (
		       'device_num'    => 0,
		       'inode_num'     => 1,
		       'file_mode'     => 2,
		       'hard_link_cnt' => 3,
		       'user_id'       => 4,
		       'group_id'      => 5,
		       'device_id'     => 6,
		       'file_size'     => 7,
		       'access_time'   => 8,
		       'modify_time'   => 9,
		       'creation_time' => 10,
		       'blk_size'      => 11,
		       'blk_allocated' => 12,
		      );

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

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
sub __add_trailing_slash($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $path               = shift || return undef;
    my $has_trailing_slash = &__has_trailing_slash("$path");

    if ( $has_trailing_slash eq FALSE ) {
      if ( &os_is_linux() eq FALSE ) {
	    $path .= '\\';
      } else {
	    $path .= '/';
      }
    }
    return "$path";
  }

#=============================================================================
sub __convert_path($$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $hashref         = shift;

    my $cmd             = $hashref->{'cmd'}             || return undef;
    my $use_system_call = $hashref->{'use_system_call'} || FALSE;
    my $path            = $hashref->{'path'}            || './';

    my $output = undef;

    if ( $use_system_call eq TRUE ) {
      my $syscmd = "$cmd $hashref->{'arguments'}";
      my $sysout = `$syscmd`;
      $output    = &chomp_r($sysout);
    } else {
      my $hashcmd = {
	                 'command'   => &escapify_path("$cmd"),
		             'arguments' => $hashref->{'arguments'},
		             'verbose'   => $is_debug,
                    };
      &__print_debug_output("Beginning hash ref --> ".Dumper($hashcmd), __PACKAGE__) if ( $is_debug );
      my ($rval, $output2) = &runcmd($hashcmd);
      &raise_exception(
		               'BAD_COMMAND',
		               "Could not convert using cygpath : << $path >>".join("\n",@{$output}),
		               'STDERR'
		              ) if ( $rval > 1 );
      my @output2 = &chomp_r(@{$output2});
      $output = $output2[0];
    }
    return $output;
  }

#=============================================================================
sub __flip_slashes($$$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'path', \&valid_string,
	                                        'old_style', \&valid_string,
 											'new_style', \&valid_string,
											'result_style', \&is_integer ], @_);
    } else {
	  $inputdata = $_[0];
	}
	
    return undef if ( scalar(keys(%{$inputdata})) == 0 );

	my $path           = $inputdata->{'path'} || return undef;
	my $old_style      = $inputdata->{'old_style'};
	my $new_style      = $inputdata->{'new_style'};
	my $resultant_size = $inputdata->{'result_style'} || 1;

    &__print_debug_output("Old/New styles --> $old_style|$new_style\n", __PACKAGE__);
    &__print_debug_output("Number of replacements --> $resultant_size\n", __PACKAGE__);

    return "$path" if ( $old_style eq $new_style );
    if ( $old_style eq PATH_BACKWARD ) {
      $path =~ s/\\/\//g;
    } else {
      my $replacement = '\\' x $resultant_size;
      $path =~ s/\//$replacement/g;
    }
    return "$path";
  }

#=============================================================================
sub __has_trailing_slash($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
  
    my $has_trailing_slash = FALSE;
    my $path               = shift || return $has_trailing_slash;

    $has_trailing_slash    = ( substr($path,-1,1) eq '/' || substr($path,-1,1) eq '\\' );
	return ( $has_trailing_slash ) ? TRUE : FALSE;
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
sub __is_only_letter_drive($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $path = shift || return FALSE;
	if ( &__is_letter_drive("$path") eq TRUE ) {
	  my $result = ( $path =~ m/^\w:\Z/ ) ? TRUE : FALSE;
	  &__print_debug_output("<$path> --> Result = $result", __PACKAGE__);
	  return $result;
	}
	return FALSE;
  }
  
#=============================================================================
sub __is_letter_drive($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $path = shift || return FALSE;
    my $result = ($path =~ m/^\w:/) ? TRUE : FALSE;
	&__print_debug_output("<$path> --> Result = $result", __PACKAGE__);
	return $result;
  }

#=============================================================================
sub __is_unc_style($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $path = shift || return FALSE;
    return ($path =~ m/^\/\//) ? TRUE : FALSE;
  }

#=============================================================================
sub __remove_quotes($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    my $input = shift;
    $input =~ s/\"//g;
    return "$input";
  }

#=============================================================================
sub __remove_trailing_slash($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $path = shift;
    return $path if ( &valid_string($path) eq FALSE );

    $path = &__flip_slashes("$path", PATH_BACKWARD, PATH_FORWARD );
    my $has_trailing_slash = &__has_trailing_slash("$path");

    $path = &__flip_slashes("$path", PATH_FORWARD, PATH_BACKWARD ) if ( &os_is_windows_native() eq TRUE );
    $path =~ s/\/$//;
    $path =~ s/\\$// if ( &os_is_windows() eq TRUE );

    return ("$path", $has_trailing_slash ) if ( wantarray() );
    return "$path";
  }

#=============================================================================
sub convert_path_to_client_machine($;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $path2convert = shift;
    my $client_os    = shift || &determine_os();

    return undef if ( ( &valid_string("$path2convert") eq FALSE ) ||
	                  ( &valid_string("$client_os") eq FALSE ) );

	my $winshtname = WINDOWS_SHORTNAME;
    return &path_to_win( &normalize_path("$path2convert") )  if ( $client_os =~ m/$winshtname/i );
    return &path_to_unix( &normalize_path("$path2convert") ) if ( $client_os !~ m/$winshtname/i );
	return "$path2convert";
  }

#=============================================================================
sub convert_java_path($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

	my $javapath = shift || return;
	
	$javapath =~ s/\./ /g;
	my @components = split(" ",$javapath);
	return &join_path(@components);
  }
  
#=============================================================================
sub escapify_path($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
    my $input = shift;

	return $input if ( &valid_string($input) eq FALSE );

    my $curr_spc_idx = index("$input", ' ');
    return "$input"if ( $curr_spc_idx < 0 );

    &__print_debug_output("Found space in < $input > at index < $curr_spc_idx >\n", __PACKAGE__);

    my $total_length  = length("$input");
    my $rebuilt_input = '';
    my $is_windows_native = &os_is_windows_native();

    while ( $curr_spc_idx <= $total_length ) {
      my $part_a    = substr("$input",0,$curr_spc_idx);
      my $part_b    = substr("$input",$curr_spc_idx + 1, $total_length);

      $total_length = length("$part_b");

      my $from_direction = PATH_BACKWARD;
      my $to_direction   = PATH_FORWARD;
      my $addon          = "\\ ";

      if ( $is_windows_native eq TRUE ) {
	    $from_direction = PATH_FORWARD;
	    $to_direction   = PATH_BACKWARD;
	    $addon          = ' ';
      }

      my $rebuilt_part = '';
      if ( length($part_a) > 0 ) {
	    $rebuilt_part = &__flip_slashes("$part_a", $from_direction, $to_direction)."$addon";
      }
      $rebuilt_input .= "$rebuilt_part";

      &__print_debug_output("First part -- < $part_a >\nSecond part -- < $part_b >\nRebuilt string -- < $rebuilt_input >\nRemaining length -- $total_length\n", __PACKAGE__ );
      if ( $total_length < 1 ) { $rebuilt_input .= "$part_b"; last; }

      $input = "$part_b";
      $curr_spc_idx = index("$input", ' ');
      &__print_debug_output("Next space index is --> $curr_spc_idx\n",__PACKAGE__);
      if ( $curr_spc_idx < 0 ) { $rebuilt_input .= "$input"; last; }
    }

    &__print_debug_output("Returning rebuilt path as :: $rebuilt_input\n", __PACKAGE__);
    return "$rebuilt_input";
  }

#=============================================================================
sub find_relative_path($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $source = shift;
    my $dest   = shift;

    return undef if ( &valid_string($source) eq FALSE ||
		              &valid_string($dest) eq FALSE );

    my $handle_no_common_root = shift || FALSE;
    my $dest_orig = $dest;

    $source = &__remove_quotes("$source");
    $dest   = &__remove_quotes("$dest");

    &__print_debug_output("Source  -- $source\n",__PACKAGE__);
    $source = &get_full_path("$source");
    &__print_debug_output("Destination  -- $dest\n",__PACKAGE__);
    $dest   = &get_full_path("$dest");

    &__print_debug_output("Full path src   --> $source\n", __PACKAGE__);
    &__print_debug_output("Full path dest  --> $dest\n", __PACKAGE__);

    my $parent = &__remove_trailing_slash(&path_find_common_root("$source", "$dest"));
    my $regex  = &convert_to_regexs("$parent").'\\\\?';
    $regex     = &convert_to_regexs("$parent").'\/?' if ( &os_is_windows_native() eq FALSE );

    &__print_debug_output("Regex to strip off parent --> $regex\n", __PACKAGE__);
    #my $parlen    = length("$parent");
    #my $sourcelen = length("$source");
    #my $destlen   = length("$dest");

    $source =~ s/$regex//;
    $dest   =~ s/$regex//;

    #$source = ($parlen >= $sourcelen) ? '' : substr("$source", $parlen);
    #$dest   = ($parlen >= $destlen) ? '' : substr("$dest", $parlen);

    &__print_debug_output("Reduced path src   --> $source\n", __PACKAGE__);
    &__print_debug_output("Reduced path dest  --> $dest\n", __PACKAGE__);

    return '.' if ("$source" eq "$dest");

    $source = &__flip_slashes("$source", PATH_BACKWARD, PATH_FORWARD) if ( length($source) > 0 );

    my @parts = split /\//, "$source";
    return $dest_orig if ( ( $handle_no_common_root ) && ( ( substr("$dest", 0, 1) eq ':' ) ) );

    my $dots = '';
    foreach (@parts) {
      $dots = &join_path($dots, '..');
    }
    &__print_debug_output("Final built destination --> $dest || $dots\n", __PACKAGE__);
	if ( length($dest) > 0 ) {
      return &join_path($dots, "$dest");
	} else {
	  return "$dots";
	}
  }

#=============================================================================
sub get_attribute($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $fn   = shift;
    my $attr = shift;

    return undef if ( (&valid_string($fn) eq FALSE) || ( not -e "$fn" ) );
    return undef if ( (&valid_string($attr) eq FALSE) || (not defined($file_stat_attr{$attr})) );

    my @st = stat("$fn");
    return $st[$file_stat_attr{$attr}];
  }

#=============================================================================
sub get_file_size($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    return &get_attribute("$_[0]",'file_size');
  }

#=============================================================================
sub get_file_time($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    return &get_attribute("$_[0]",'modify_time');
  }

#=============================================================================
sub get_full_path($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $path = shift;
    return $path if ( &valid_string($path) eq FALSE );

    &__print_debug_output("Path to alter --> $path\n", __PACKAGE__);
    my $result = undef;

    if ( &path_is_rel("$path") eq FALSE ) {
	  $result = &normalize_path(&path_to_mixed("$path"));
    } else {
	  $result = &normalize_path(&join_path(&path_to_mixed(File::Spec->rel2abs(File::Spec->curdir())), "$path"));
    }
    $result = &lowercase_first("$result") if ( &__is_letter_drive("$result") eq TRUE );
    &__print_debug_output("Full Path result --> $result\n", __PACKAGE__);
    return "$result";
  }

#=============================================================================
sub get_path_delim()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $os_result = &os_is_windows_native();
    &__print_debug_output("Is Windows Native ??? $os_result\n", __PACKAGE__);

    if ( $os_result eq TRUE ) { return ';'; }
    return ':';
  }

#=============================================================================
sub get_resolved_path($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $path = shift;

    return $path if ( ( not defined($path) ) || ( length("$path") < 1 ) );

    &__print_debug_output("Continuing forward with decoding...\n", __PACKAGE__ ) if ( $is_debug );
	
  DECODE_SYMLINK:
    $path = readlink "$path" if ( -l "$path" );
    if ( -l "$path" ) { goto DECODE_SYMLINK; }

    $path = &get_full_path("$path");
    if ( &__is_letter_drive("$path") eq TRUE ) {
	  $path = &lowercase_first("$path");
	  $path = &__flip_slashes("$path", PATH_FORWARD, PATH_BACKWARD) if ( &os_is_windows() eq TRUE );
    }

    &__print_debug_output("Returned resolved path --> $path\n", __PACKAGE__);
    return "$path";
  }

#=============================================================================
sub get_temp_dir(;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $use_standard_temp = shift;

    my $tmp = $user_tempdir;
    if ( defined($use_standard_temp) ) {
       $tmp ||= $ENV{'TMP'} || $ENV{'TEMP'};
    } else {
       $tmp ||= $ENV{'TEMPORARYDIR'} || $ENV{'TMP'} || $ENV{'TEMP'};
    }

    if ( not defined($tmp) ) {
      if ( &os_is_windows() eq TRUE ) {
	    if ( -d 'c:/temp' ) { $tmp = 'c:/temp'; }
	    else {
	      &__print_output("No c:/temp found on this machine, trying c:/tmp (non-standard)...", WARN);
	      if ( -d 'c:/tmp' ) { $tmp = 'c:/tmp' }
	    }
        if ( not defined($tmp) ) {
	      &__print_output("Unable to find ANY temporary directory.  Using c:/", WARN);
          $tmp = 'c:/';
        }
      } else {
	    $tmp = '/tmp';
      }
    } else {
      if ( &os_is_linux() eq TRUE ) {
        $tmp ||= '/tmp';
      }
    }

    if ( &os_is_windows_native() eq TRUE ) {
      $tmp = &path_to_win("$tmp");
    } else {
      $tmp = &path_to_unix("$tmp");
    }
    &__print_debug_output("Temporary directory --> $tmp\n", __PACKAGE__);

    mkpath("$tmp", 0, 0777) if ( not -d "$tmp" );
    return "$tmp";
  }

#=============================================================================
sub join_path($;@)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $parent = shift || '';
    $parent = &__remove_quotes("$parent");
    $parent = &__flip_slashes("$parent", PATH_BACKWARD, PATH_FORWARD);

	&__print_debug_output("Parent value : <$parent>", __PACKAGE__) if ( defined($parent) );
	
    my $dirsep = &get_dir_sep();

    while (@_) {
      my $child = shift;
      &__print_debug_output("Checking child ($child) to parent <$parent>\n", __PACKAGE__) if ( $is_debug && defined($parent) );
      if ( not defined($child) ) {
	    &__print_debug_output("Found end of children\n", __PACKAGE__) if ( $is_debug );
	    return "$parent";
      } elsif ( ( defined($parent) ) && ( &path_is_rel("$child") eq TRUE ) ) {
	    $parent = &__remove_trailing_slash("$parent");
	    $parent = "$parent$dirsep$child";
	    &__print_debug_output("Replace last slash -- $parent\n", __PACKAGE__) if ( $is_debug );
      } else {
	    &__print_debug_output("Parent is child\n", __PACKAGE__) if ( $is_debug );
	    $parent = "$child";
      }
    }

    if ( &os_is_windows_native() eq TRUE ) {
      $parent = &__flip_slashes("$parent", PATH_FORWARD, PATH_BACKWARD);
    }
    &__print_debug_output("Final parentage --> $parent\n", __PACKAGE__) if ( $is_debug );
    return "$parent";
  }

#=============================================================================
sub minimize_pathnames($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	 
    my $text = shift;
    my $path = shift;
	 
	if ( &valid_string($path) eq TRUE ) {
	  my $converted = FALSE;
	  if ( &__is_letter_drive("$path") eq TRUE ) {
	    $path = &__flip_slashes("$path", PATH_BACKWARD, PATH_FORWARD);
		$converted = TRUE;
	  }
		
	  my $pathlgt = length($path);
      my $textlgt = length($text);
	  my $remaining_space = int($HP::Support::Screen::TermIOCols*0.8) - $textlgt;
	  
	  if ( $is_debug ) {
	    &__print_debug_output("Length of text  : $textlgt", __PACKAGE__);
	    &__print_debug_output("Length of path  : $pathlgt", __PACKAGE__);
	    &__print_debug_output("Remaining Space : $remaining_space", __PACKAGE__);
      }
	  
	  if ( $pathlgt >= $remaining_space ) {
		
	    #======================================================================
	    # Need an algorithm to suppress directories...
	    #======================================================================
		my $replacement_path = "$path";
		my $amt_chopped_path = 0;
		my $flipped = 0;
		
		while ( $amt_chopped_path <= $remaining_space - 3 ) {
		  my $last_slash = rindex("$replacement_path",'/');
		  if ( $last_slash > -1 ) {
			$amt_chopped_path += length($replacement_path) - $last_slash;
		    $replacement_path = substr("$replacement_path",0, $last_slash);
			if ( $replacement_path eq '.' ) { goto FINALE; }
		    $replacement_path = reverse "$replacement_path";
		    $flipped = ( $flipped += 1 ) % 2;
		  } else {
			last;
		  }
		  goto FINALE if ( $replacement_path eq '.' );
		  &__print_debug_output("Amount chopped away now --> $amt_chopped_path -- $flipped -- <$replacement_path>", __PACKAGE__) if ( $is_debug );
		}
		
	  FINALE:
		$replacement_path = reverse "$replacement_path" if ( $flipped );
		if ( $converted ) {
		  $replacement_path = &convert_to_regexs(&__flip_slashes("$replacement_path", PATH_FORWARD, PATH_BACKWARD));
		  $path = &__flip_slashes("$path", PATH_FORWARD, PATH_BACKWARD);
		}
		
		if ( $is_debug ) {
		  &__print_debug_output("Amount of text to remove from 'middle' : $amt_chopped_path", __PACKAGE__);
		  &__print_debug_output("Path : $path", __PACKAGE__);
		  &__print_debug_output("Removal Path : $replacement_path", __PACKAGE__);
		}
		$path =~ s/$replacement_path/\.\.\./;
	  } else {
		$path = &__flip_slashes("$path", PATH_FORWARD, PATH_BACKWARD) if ( $converted );
	  }
	}
	 
	return "$text $path";
  }
  
#=============================================================================
sub normalize_path($;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $p = shift || return;
    my $leave_trailing_slash = shift;

    $leave_trailing_slash = TRUE if ( not defined($leave_trailing_slash) );

    $p = &__flip_slashes("$p", PATH_BACKWARD, PATH_FORWARD);
    my $lastchar_is_slash = ( rindex($p, '/') == (length($p)-1) ) ? TRUE : FALSE;
    chop($p) if ( ( $lastchar_is_slash ) && ( $leave_trailing_slash eq TRUE ) );

  SPLITAGAIN:
    my @parts = split '/', $p;
    my $i = 1;

    while ( ( $i >= 0 ) && ( $i < scalar(@parts) ) ) {
      # only ignore double '/' if not the first two characters in the path
      if ($parts[$i] eq '.') {
	    splice @parts, $i, 1;
      } elsif ( ($parts[$i] eq '') && ( ( $i != 1 ) || ( not &os_is_windows() ) )) {
	    splice @parts, $i, 1;
      } elsif ( ($parts[$i] eq '') && ( ( $i == 1 ) && ( $parts[0] =~ "^[a-zA-Z]:" ) ) ) {
	    splice @parts, $i, 1;
      } elsif ($parts[$i] eq '..') {
	    if ($i > 1) {
	      splice @parts, $i-1, 2;
	      --$i;
	    } else {
	      splice @parts, $i, 1;
	    }
      } else {
	    ++$i;
      }
    }

    $p = join('/', @parts);
    $p .= '/' if ( ( $lastchar_is_slash ) && ( $leave_trailing_slash ) );
    $p = &__flip_slashes("$p", PATH_FORWARD, PATH_BACKWARD) if ( &os_is_windows_native() eq TRUE );
    $p = &lowercase_first("$p") if ( &__is_letter_drive("$p") eq TRUE );
	
    &__print_debug_output("Result from normalization --> $p\n", __PACKAGE__) if ( $is_debug );
    return "$p";
  }

#=============================================================================
sub path_find_common_root($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $path1        = shift;
    my $path2        = shift;
    my $hashref      = shift || undef;

    return undef if ( &valid_string($path1) eq FALSE || &valid_string($path2) eq FALSE );

    # Force into UNIX style to do simpler handling, then revert
    # back when ready to return result...
    my $normalpath1 = &path_to_unix("$path1", $hashref);
    my $normalpath2 = &path_to_unix("$path2", $hashref);

	if ( $is_debug ) {
      &__print_debug_output("Mixed path 1 --> $normalpath1\n", __PACKAGE__);
      &__print_debug_output("Mixed path 2 --> $normalpath2\n", __PACKAGE__);
    }
	
    my @p1 = split /\//, "$normalpath1";
    my @p2 = split /\//, "$normalpath2";

    my @newparts = ();
    while ( scalar(@p1) && scalar(@p2) && ( $p1[0] eq $p2[0] ) ) {
      push @newparts, shift @p1;
      shift @p2;
    }

    my $dirseparator   = &get_dir_sep();
    my $regexseparator = &convert_to_regexs($dirseparator);

    my $root = join($dirseparator, @newparts);
    $root .= $dirseparator if ( $root !~ /$regexseparator$/ );
    if ( ( &os_is_windows() eq TRUE ) || ( &os_is_cygwin() eq TRUE ) ) {
	  $hashref->{'cygpath_options'} = '-m';
	  $root = &path_to_mixed("$root", $hashref);
	  $root = &lowercase_first("$root") if ( &__is_letter_drive("$root") );
    }
    if ( &os_is_windows_native() eq TRUE ) {
	  $hashref->{'cygpath_options'} = '-w';
      $root = &path_to_win("$root", $hashref);
	  $root = &lowercase_first("$root") if ( &__is_letter_drive("$root") );
    }
	
    &__print_debug_output("Matched root --> $root\n", __PACKAGE__) if ( $is_debug );
	return ( $root, \@p2 ) if ( wantarray() );
    return $root;
  }

#=============================================================================
sub path_is_rel($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $path = shift;
    return FALSE if ( &valid_string($path) eq FALSE );

    return FALSE if ( ( $path =~ m/^\// ) || ( ( &os_is_windows() eq TRUE ) &&
	                                           ( &__is_unc_style("$path") eq TRUE ) ) );
    return FALSE if ( ( &os_is_windows() eq TRUE ) &&
	                  ( &__is_letter_drive("$path") eq TRUE ) );
    return TRUE;
  }

#=============================================================================
sub path_is_same($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $path1 = shift;
    my $path2 = shift;

    return FALSE if ( (&valid_string($path1) eq FALSE) || (&valid_string($path2) eq FALSE) );

    $path1 = &get_resolved_path("$path1");
    $path2 = &get_resolved_path("$path2");
	return &equal("$path1", "$path2");
  }

#=============================================================================
sub path_to_mixed($;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $path = shift;
    return $path if ( &valid_string($path) eq FALSE );
	$path =~ s/\n/ /g if ( $path =~ m/\n/ );

    my $hashref = shift || undef;

    my $use_system_call = FALSE;
    if ( ( defined($hashref) ) && ( ref($hashref) =~ m/hash/i ) ) {
      $use_system_call = $hashref->{'use_system'} if ( defined($hashref->{'use_system'}) );
    }

    if ( &os_is_cygwin() eq TRUE ) {
      my $handle_multipath = FALSE;
      my $cygpath_options  = '';

      if ( ( defined($hashref) ) && ( ref($hashref) =~ m/hash/i ) ) {
	    $cygpath_options  = $hashref->{'cygpath_options'} if ( defined($hashref->{'cygpath_options'}) );
	    $handle_multipath = $hashref->{'convert_path'}    if ( defined($hashref->{'convert_path'}) );
	    if ( ( $handle_multipath eq TRUE ) && ( $cygpath_options !~ m/\-\-path/ ) ) { $cygpath_options .= ' --path '; }
      }

      # Assume path is already in mixed form.
      return "$path" if ( ( &__is_letter_drive("$path") eq TRUE ||
			                &__is_unc_style("$path") eq TRUE ) &&
			              ( "$path" !~ m/\\/ ) );

      $path = &__flip_slashes("$path", PATH_BACKWARD, PATH_FORWARD);

      if ( not defined($cygpath_exe) ) {
	    $cygpath_exe = 'cygpath';
	    $cygpath_exe = &join_path("$ENV{'CYGWIN_ROOT'}",'bin','cygpath') if ( exists($ENV{'CYGWIN_ROOT'}) );
      }

      if ( $handle_multipath eq TRUE ) {
	    $path = "\"$path\"" if ( index($path, ' ') > -1 );  # Handle spaces with proper quoting
	    my $result = "$path";
	    $result    = &__convert_path(
                                     {
                                      'cmd'             => "$cygpath_exe",
				                      'arguments'       => "$cygpath_options -m $path",
				                      'use_system_call' => $use_system_call,
				                      'path'            => "$path"
                                     }
                                    );
		$result =~ s/\n/ /g;
	    return "$result";
      }

      if ( not exists($mixed_path_cache{"$path"}) ) {
	    my ($fn, $dir) = fileparse("$path");
	    $dir = &__remove_trailing_slash("$dir");

	    if ( -f "$path" && -d "$dir" ) {
	      $mixed_path_cache{"$path"} = &path_to_mixed("$dir", $hashref) . '/' . "$fn";
	    } else {
	      &__print_debug_output("System call request --> $use_system_call\n", __PACKAGE__) if ( $is_debug );
	      $path = "\"$path\"" if ( index($path, ' ') > -1 );
	      my $result2 = &__convert_path(
                                        {
                                         'cmd'             => "$cygpath_exe",
                                         'arguments'       => "$cygpath_options -m \"$path\"",
					                     'use_system_call' => $use_system_call,
                                         'path'            => "$path"
                                        }
                                       );
		  $result2 =~ s/\n/ /g;
	      $mixed_path_cache{"$path"} = "$result2" if ( defined($result2) );
	    }
      }
      return "$mixed_path_cache{$path}" if ( defined($mixed_path_cache{"$path"}) );
	  return "$path";
    } elsif ( &os_is_windows_native() eq TRUE ) {
      my $result = &path_to_win("$path");
      &__print_debug_output("Result = $result\n", __PACKAGE__) if ( $is_debug );
      return "$result";
    } else {
      my $result = &escapify_path(&path_to_unix("$path"));
      &__print_debug_output("Result = $result\n", __PACKAGE__) if ( $is_debug );
      return "$result";
    }
  }

#=============================================================================
sub path_to_win($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $path = shift;
    return $path if ( &valid_string($path) eq FALSE );
	$path =~ s/\n/ /g if ( $path =~ m/\n/ );

    my $winpath = "$path";
    my $hashref = shift || undef;

    my $use_system_call = FALSE;

    if ( ( defined($hashref) ) && ( ref($hashref) =~ m/hash/i ) ) {
      $use_system_call  = $hashref->{'use_system'} if ( defined($hashref->{'use_system'}) );
    }

    &__print_debug_output("Use system call --> $use_system_call\n", __PACKAGE__) if ( $is_debug );

    if ( &os_is_cygwin() eq TRUE ) {
      my $handle_multipath = FALSE;
      my $cygpath_options  = '';

      if ( ( defined($hashref) ) && ( ref($hashref) =~ m/hash/i ) ) {
	    $cygpath_options  = $hashref->{'cygpath_options'} if ( defined($hashref->{'cygpath_options'}) );
	    $handle_multipath = $hashref->{'convert_path'}    if ( defined($hashref->{'convert_path'}) );
	    if ( ( $handle_multipath eq TRUE ) && ( $cygpath_options !~ m/\-\-path/ ) ) { $cygpath_options .= ' --path '; }
      }

      $path =~ &__flip_slashes("$path", PATH_BACKWARD, PATH_FORWARD);

      if ( not defined($cygpath_exe) ) {
	    $cygpath_exe = 'cygpath';
	    $cygpath_exe = &join_path("$ENV{'CYGWIN_ROOT'}",'bin','cygpath') if ( exists($ENV{'CYGWIN_ROOT'}) );
      }

      if ( $handle_multipath eq TRUE ) {
	    my $result = &__convert_path(
	                                 {
				                      'cmd'             => "$cygpath_exe",
				                      'arguments'       => "$cygpath_options -m $path",
				                      'use_system_call' => $use_system_call,
				                      'path'            => "$path"
				                     }
				                    );
	    $result = &__flip_slashes("$result", PATH_FORWARD, PATH_BACKWARD);
		$result =~ s/\n/ /g;
	    return $result;
      }

      # If not already stored in the cache...
      if ( not exists($win_path_cache{"$path"}) ) {
	    my ($fn, $dir) = fileparse("$path");
	    $dir =~ s/[\\?\/?]$//g;

	    if ( -f "$path" && -d "$dir" ) {
	      $win_path_cache{"$path"} = &path_to_win("$dir", $hashref) . "\\" . "$fn";
	    } else {
	      my $result2 = &__convert_path(
	                                    {
					                     'cmd'             => "$cygpath_exe",
					                     'arguments'       => "$cygpath_options -m $path",
					                     'use_system_call' => $use_system_call,
					                     'path'            => "$path"
                                        }
				                       );
	      $result2 = &__flip_slashes("$result2", PATH_FORWARD, PATH_BACKWARD, 2);
		  $result2 =~ s/\n/ /g;
	      $win_path_cache{"$path"} = "$result2" if ( defined($result2) );
	    }
      }
      $winpath = $win_path_cache{"$path"};
    } elsif ( &os_is_windows_native() eq TRUE ) {
      &__print_debug_output("Inside windows native handling...\n", __PACKAGE__) if ( $is_debug );
      $path = &__flip_slashes("$path", PATH_FORWARD, PATH_BACKWARD);
      $winpath = "$path";
    } else {
      return "$path";
    }
    return &uppercase_first("$winpath");
  }

#=============================================================================
sub path_to_unix($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $path = shift;
    return $path if ( &valid_string($path) eq FALSE );
	$path =~ s/\n/ /g if ( $path =~ m/\n/ );

    my $hashref = shift || undef;

    my $use_system_call = FALSE;

    if ( ( defined($hashref) ) && ( ref($hashref) =~ m/hash/i ) ) {
      $use_system_call = $hashref->{'use_system'} if ( defined($hashref->{'use_system'}) );
    }

    if ( &os_is_cygwin() eq TRUE ) {
      my $handle_multipath = FALSE;
      my $cygpath_options  = '';

      if ( ( defined($hashref) ) && ( ref($hashref) =~ m/hash/i ) ) {
	    $cygpath_options  = $hashref->{'cygpath_options'} if ( defined($hashref->{'cygpath_options'}) );
	    $handle_multipath = $hashref->{'convert_path'}    if ( defined($hashref->{'convert_path'}) );
	    if ( ( $handle_multipath eq TRUE ) && ( $cygpath_options !~ m/\-\-path/ ) ) { $cygpath_options .= ' --path '; }
      }

      $path = &__flip_slashes("$path", PATH_BACKWARD, PATH_FORWARD);

      if ( not defined($cygpath_exe) ) {
	    $cygpath_exe = 'cygpath';
	    $cygpath_exe = &join_path("$ENV{'CYGWIN_ROOT'}",'bin','cygpath') if ( exists($ENV{'CYGWIN_ROOT'}) );
      }

      if ( $handle_multipath eq TRUE ) {
	    &__print_debug_output("Handling multipath case\n", __PACKAGE__);
	    my $result = &__convert_path(
				                     {
				                      'cmd'             => "$cygpath_exe",
				                      'arguments'       => "$cygpath_options -u \"$path\"",
				                      'use_system_call' => $use_system_call,
				                      'path'            => "$path",
				                     }
	                                );
		$result =~ s/\n/ /g if ( defined($result) );
	    return "$result";
      }

      if ( not exists($unix_path_cache{"$path"})) {
	    my ($fn, $dir) = fileparse("$path");
	    $dir = &__remove_trailing_slash("$dir");

	    if (-f "$path" && -d "$dir") {
	      $unix_path_cache{"$path"} = &path_to_unix("$dir",$hashref) . '/' . "$fn";
	    } else {
	      &__print_debug_output("Calling convert_path...\n", __PACKAGE__) if ( $is_debug );
	      $path = "\"$path\"" if ( index($path, ' ') > -1 );
	      my $result2 = &__convert_path(
					                    {
					                     'cmd'             => "$cygpath_exe",
					                     'arguments'       => "$cygpath_options -u \"$path\"",
					                     'use_system_call' => $use_system_call,
					                     'path'            => "$path",
					                    },
				                       );
		  if ( defined($result2) ) {
            $result2 =~ s/\n/ /g;		  
	        $unix_path_cache{"$path"} = "$result2";
		  }
	    }
      }
      return "$unix_path_cache{$path}" if ( defined($unix_path_cache{"$path"}) );
	  return "$path";
    } elsif ( &os_is_windows_native() eq TRUE ) {
      $path = &__flip_slashes("$path", PATH_BACKWARD, PATH_FORWARD);
      return "$path";
    } else {
      $path =~ s/^(\w):/\/$1/;
      return "$path";
    }
  }

#=============================================================================
sub set_temp_dir($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $proposed_temp_dir = shift || return;
    &__print_debug_output("Checking viability of directory -- << $proposed_temp_dir >>\n", __PACKAGE__ ) if ( $is_debug );
    if ( -f "$proposed_temp_dir" ) { return; }

    mkpath(&escapify_path("$proposed_temp_dir"), 0, 0777);
    $user_tempdir = "$proposed_temp_dir";
  }

#=============================================================================
sub which($;$$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $file          = shift;
    my $hinted_path   = shift;
    my $no_conversion = shift || FALSE;

    return undef if ( &valid_string($file) eq FALSE );

    if ( &valid_string($hinted_path) eq FALSE ) { $hinted_path = undef; }
	if ( defined($hinted_path) ) {
	  $hinted_path =~ s/\n/ /g;
	  #&__print_output("Hinted path = $hinted_path");
	}
	
    my $sep = &get_path_delim();
    $sep = ';' if ( &os_is_cygwin() eq TRUE );
	
    my @paths = split(/$sep/, "$ENV{'PATH'}");
    if ( defined($hinted_path) ) { @paths = ( "$hinted_path" ); }
    my $iswin = &os_is_windows();

    foreach my $path (@paths) {
      next if ( &valid_string($path) eq FALSE );
      $path = &path_to_unix("$path") if ( $no_conversion eq FALSE );
	  &__print_debug_output("Path to test --> $path", __PACKAGE__) if ( $is_debug );
      my $trypath = undef;
      if ( defined($path) ) {
	    $path    = &__remove_trailing_slash("$path");
	    $trypath = &join_path("$path", "$file");
      } else { 
	    $trypath = &join_path('.',"$file");
      }

      # On Windows, try additional paths
      if ( $iswin eq TRUE ) {
        $trypath = &path_to_mixed("$trypath");
	    if ( not defined($trypath) ) { return undef; }
	    my @winext = qw(
			            exe
			            com
			            bat
			            cmd
		               );
		if ( &os_is_windows_native() eq FALSE ) { @winext = &delete_elements('bat', \@winext); }
	    foreach my $ext (@winext) {
	      my $trypath_with_ext = "$trypath.$ext";
          my $existence  = ( -e "$trypath_with_ext" );
          my $executable = ( -x "$trypath_with_ext" );
	      if ( $existence && $executable ) {
	        $trypath = "$trypath_with_ext";
            last;
	      } else {
            if ( $existence && ( not $executable ) ) {
              &__print_output ("Found file << $trypath_with_ext >>, but it is NOT executable by user << ". &get_username()." >>", __PACKAGE__);
            }
          }
	    }
      }
	  return "$trypath" if ( -e "$trypath" && -x "$trypath");
    }
    return undef;
  }

#=============================================================================
&__initialize();

#=============================================================================
1;