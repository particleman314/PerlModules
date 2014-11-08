package HP::Zip::ArchiveZip;

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

	use parent qw(HP::BaseObject);
	
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

    @EXPORT = qw(
		        );

    $module_require_list = {
                            'Cwd'                        => undef,
							'File::Basename'             => undef,
 
			                'HP::Constants'              => undef,
							'HP::Support::Base'          => undef,
							'HP::Support::Object::Tools' => undef,
			                'HP::Os'                     => undef,
                            'HP::Path'                   => undef,
							'HP::FileManager'            => undef,
							'HP::Copy'                   => undef,
                          };

    $VERSION  = 0.7;

    $is_init  = 0;
    $is_debug = (
		         $ENV{'debug_zip_archivezip_pm'} ||
		         $ENV{'debug_zip_modules_pm'} ||
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
sub __store
  {
    my $self    = shift;
	my $outname = shift || $self->outputname();
	
	my $outdir  = File::Basename::dirname("$outname");
	my $error   = FALSE;
	
    &delete("$outname") if ( &does_file_exist("$outname") );
  
	my $az = &create_object('c__Archive::Zip__');
	return $error if ( not defined($az) );
	
	foreach ( @{$self->files()->get_elements()} ) {
	  &__print_debug_output("Archiving file : $_") if ( $is_debug );
	  my $bn = File::Basename::basename("$_");
	  $az->addFile("$_", "$bn");
	}
	
	foreach ( @{$self->directories()->get_elements()} ) {
	  &__print_debug_output("Archiving directory : $_") if ( $is_debug );
	  my $bn = File::Basename::basename("$_");
	  $az->addTree("$_", "$bn");
	}
	
	$error = $az->writeToFileNamed( "$outname" );
	return $error;
  }
  
#=============================================================================
sub add
  {
    my $self = shift;
	my $item = shift;
	
	return FALSE if ( not defined($item) );
	
	my $is_file      = &does_file_exist("$item");
	my $is_directory = &does_directory_exist("$item");
	
	$item = &convert_path_to_client_machine("$item", &get_os_type());
	return FALSE if ( $is_file eq FALSE && $is_directory eq FALSE );
	
	$self->files()->push_item("$item") if ( $is_file );
	$self->directories()->push_item("$item") if ( $is_directory );
	
	return TRUE;
  }
  
#=============================================================================
sub add_contents
  {
    my $self      = shift;
	my $directory = shift || return FALSE;
	
	return FALSE if ( &does_directory_exist("$directory") eq FALSE );
	
	my $contents = &collect_directory_contents("$directory");
	
	foreach ( @{$contents->{'directories'}} ) {
	  $self->add(&join_path("$directory", "$_"));  # Use Relative path from search location
	}
	foreach ( @{$contents->{'files'}} ) {
	  $self->add(&join_path("$directory", "$_"));
	}
	return TRUE;
  }
  
#=============================================================================
sub combine_zipfiles
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
 
    my $hashInfo = shift;
	
	my $has_entries         = exists($hashInfo->{'entries'});
	my $has_output_filename = exists($hashInfo->{'output_file'});
	
	&raise_exception(
	                 {
					  'severity'      => 'FAILURE',
					  'addon_msg'     => 'No information provided for zipfile management',
					  'streams'       => [ 'STDERR' ],
					  'exceptionType' => 'NO_ZIP_DATA',
					  'callback'      => \&bypass_error,
					 }
					) if ( (not defined($hashInfo)) || (not $has_entries) || (not $has_output_filename) );
					
	my $zip_streams = {};
	my $status      = 1;
	
    if ( scalar(@{$hashInfo->{'entries'}}) == 1 ) {
	  if ( ref($hashInfo->{'entries'}->[0]) =~ m/glob/i ) {
	    my $hdl = &get_filename_from_stream( $hashInfo->{'entries'}->[0] );
	  } elsif ( ref($hashInfo->{'entries'}->[0]) eq '' ) {
	    return &move_contents("$hashInfo->{'entries'}->[0]", "$hashInfo->{'output_file'}");
	  }
	} else {
	  my $cnt = 0;
	  my $combined_zipfile = undef;
	  
	  foreach my $entry ( @{$hashInfo->{'entries'}} ) {
	    ++$cnt;
	    if ( ref($entry) eq '' ) {
		  if ( $cnt == 1 ) {
		    $combined_zipfile = $entry;
		  }
		  $zip_streams->{"$entry"} = &create_object('c__Archive::Zip__');
		  if ( not defined($zip_streams->{"$entry"}) ) {
		    &__print_output("Unable to associated zipfile stream to file << $entry >>", 'WARNING');
			delete($zip_streams->{"$entry"});
			next;
		  }
		  
		  $status = $zip_streams->{"$entry"}->read("$entry");
		  if ( $status != 0 ) {
		    &__print_output("Unable to read zipfile stream of file << $entry >>", 'WARNING');
			delete($zip_streams->{"$entry"});
			next;
          }

		  ### Merge (Forced overwrite) contents of other zips into the first one...
		  if ( $cnt > 1 ) {
		    my @contents = $zip_streams->{"$entry"}->members();
			foreach my $member (@contents) {
			  $zip_streams->{"$combined_zipfile"}->addMember($member);
			}
		  }
		}
	  }
	  
	  $status = 1; # Assume failure to write
	  
	  if ( defined($combined_zipfile) ) {
	    $status = $zip_streams->{"$combined_zipfile"}->writeToFileNamed("$hashInfo->{'output_file'}");
	  }
	  return $status;
	}
  }
  
#=============================================================================
sub data_types
  {
    my $self         = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
	                   'files'       => 'c__HP::ArrayObject__',
					   'directories' => 'c__HP::ArrayObject__',
					   'outputname'  => undef,
		              };
    
	if ( $which_fields eq COMBINED ) {
      foreach ( @ISA ) {
	    my $parent_types = undef;
	    my $evalstr      = "\$parent_types = $_->data_types()";
	    eval "$evalstr";
	    $data_fields     = &HP::Support::Hash::__hash_merge( $data_fields, $parent_types ) if ( defined($parent_types) );
	  }
	}
	
    return $data_fields;
  }
  
#=============================================================================
sub new
  {
    my $class       = shift;
    my $data_fields = &data_types();

    my $self = {
		        %{$data_fields},
	           };
			   
	if ( @_ ) {
	  if ( ref($_[0]) =~ m/hash/i ) {
	    foreach my $key (keys{%{$_[0]}}) {
		  if ( exists($self->{"$key"}) ) { $self->{"$key"} = $_[0]->{"$key"}; }
		}
	  } else {
	    &__print_output("Please use a hash as input to construct this class << $class >>", 'STDERR');
		return undef;
	  }
	}
	
    bless $self, $class;
	$self->instantiate();
	return $self;  
  }

#=============================================================================
sub store
  {
    my $self    = shift;
	my $outname = shift || $self->outputname();
	
	return FALSE if ( not defined( $outname ) );
	
	my $outdir = File::Basename::dirname("$outname");
	&make_recursive_dirs("$outdir") if ( &does_directory_exist("$outdir") eq FALSE );
	
	$self->outputname("$outname");
	my $error  = &work_in_directory("$outdir", sub { $self->__store() }, $self);
	return $error;
  }
  
#=============================================================================
sub unzip_file
  {
	my $zipfile         = shift || return;
	my $output_location = shift || &join_path(&get_temp_dir(), 'MERGE');

	my $currdir = &getcwd();
	
	if ( not &does_directory_exist("$output_location") ) {
	  &make_recursive_dirs("$output_location");
	}

	if ( not &does_file_exist("$zipfile") ) { return; }

	&__print_debug_output("Zipfile to unpack --> $zipfile", __PACKAGE__);
	&move_contents("$zipfile", "$output_location");
	
	my $original_zipfile = "$zipfile";
	$zipfile = &join_path("$output_location", File::Basename::basename("$zipfile"));
	
	my $az = Archive::Zip->new("$zipfile");
	my $error = 0;
	
	if ( defined($az) ) {
	  $error = chdir "$output_location";
	  return 1 if ( $error == 0 );
	  $error = $az->extractTree();
	  if ( $error != 0 ) {
		$az = undef;
		&move_contents("$zipfile", "$original_zipfile");
	  }
	  &delete("$zipfile");
	  chdir "$currdir";
	  return $error;
	}
	
	return 0;
  }

#=============================================================================
1;