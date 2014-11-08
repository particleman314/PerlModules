package HP::Drive::MapperDB::Broker;

################################################################################
# Copyright (c) 2013-2014 HP.   All rights reserved
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

use strict;
use warnings;
use diagnostics;

#=============================================================================
BEGIN 
  {
    use Exporter();
	
    use FindBin;
    use lib "$FindBin::Bin/../../..";

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
				$comment
               );

    $VERSION = 0.75;

    @EXPORT  = qw (
                  );

    $module_require_list = {
                            'DBM::Deep'                    => undef,
							'MIME::Base64'                 => undef,
							
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::Support::Os'              => undef,
	                        'HP::CheckLib'                 => undef,
							
							'HP::FileManager'              => undef,
							'HP::UUID::Tools'              => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_drive_mapperdb_broker_pm'} ||
				 $ENV{'debug_drive_mapperdb_modules'} ||
				 $ENV{'debug_drive_modules'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );

    $broken_install = 0;
	$comment        = '#';
	
    print STDERR "BEGIN <". __PACKAGE__ .">\n" if ( $is_debug );

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "\t-->Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
        if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod\n" if ( $is_debug ); 
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
sub __check_for_db
  {
    my $self   = shift;
	my $result = FALSE;
	
	my $db     = $self->db();
	
	return $result if ( not defined($db) );
	return $result if ( &is_type($db, 'DBM::Deep') eq FALSE );
	return TRUE;
  }

#=============================================================================
sub __convert_inputs
  {
    my $self = shift;
	
	my $inputdata = {};
	if ( ref($_[0]) !~ m/hash/i ) {
	  $inputdata = &convert_input_to_hash([ 'fullpath', \&valid_string,
	                                        'drvltr', \&valid_string,
											'pid', undef ], @_);
	} else {
	  $inputdata = $_[0];
	}
	
	return $inputdata;
  }

#=============================================================================
sub associated_pids
  {
    my $self       = shift;
	my $result     = [];
	my $drvmap_key = shift || return $result;
	
	return $result if ( &valid_string($drvmap_key) eq FALSE );
	return $result if ( $self->__check_for_db() eq FALSE );
	
	my $db = $self->db();
	if ( exists($db->{"$drvmap_key"}) ) {
	  my $entry = $self->decode($db->{$drvmap_key});  # This should be a DriveMapping object
	  $result = $entry->get_pids();
	}
	
	return $result;
  }
  
#=============================================================================
sub clear
  {
    my $self = shift;

	# Need to flesh this out some more as to when exactly the conditions are
	# right to allow the DB to be cleared
	my $db = $self->db();
	$db->clear() if ( $self->number_records() > 0 );
	$db->optimize();
  }
  
#=============================================================================
sub connect
  {
    my $self = shift;

	my $filename = $self->dbfile();
    return FAIL if ( &valid_string($filename) eq FALSE );
	
	if ( &does_file_exist("$filename") eq TRUE ) {
	  &__print_output("Connecting to pre-existing file << $filename >>", INFO);
	}
	
    my $db = DBM::Deep->new(
                            file      => "$filename",
                            locking   => TRUE,
                            autoflush => TRUE,
	                       );
	
	$self->db($db) if ( defined($db) );
	return PASS;
  }

#=============================================================================
sub data_types
  {
    my $self = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
					   'dbfile' => undef,
					   'db'     => undef,
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
sub decode
  {
    my $self        = shift;
	my $encoded_str = shift;  # This is an XML string representation encoded into Base64
	
	return undef if ( &valid_string($encoded_str) eq FALSE );
	my $xmlstr = &decode_base64($encoded_str);
	
	my $xmlparser = &create_object('c__XML::LibXML__');
	return undef if ( not defined($xmlparser) );
	
	my $doctree = $xmlparser->load_xml( string => "$xmlstr" );
	return undef if ( not defined($doctree) );
	
	# Convert XML into object, then return object...
	my $entry = &create_object('c__HP::Drive::MapperDB::DriveMapping__');
	return undef if ( not defined($entry) );
	
	my $success = $entry->read_xml($doctree->getDocumentElement());
	return undef if ( $success eq FALSE );
	return $entry;
  }
  
#=============================================================================
sub decrement
  {
    my $self   = shift;
	my $result = FALSE;
	
	return $result if ( $self->__check_for_db() eq FALSE );
	
	my $db = $self->db();
	
	my $inputdata  = $self->__convert_inputs(@_);	
	my $fullpath   = $inputdata->{'fullpath'};
	my $drvltr     = $inputdata->{'drvltr'};
	my $drvmap_key = $self->make_key("$fullpath", "$drvltr");

	return $result if ( &valid_string($drvmap_key) eq FALSE );
	
	my $pid = shift || &get_pid();
	my $record_changed = FALSE;
	
	# Lock out the DB until changes have been propagated...
    $db->lock_exclusive();
	my $entry = $db->{"$drvmap_key"};
	
	if ( defined($entry) ) {
	  $entry = $self->decode($entry);  # This should be a DriveMapping object
	  goto FINISH if ( not defined($entry) );
	  
	  # Use DriveMapping functionality...
	  my $removed = $entry->remove_pid($pid);
	  $record_changed = TRUE if ( $removed eq TRUE );
	} else {
	  &__print_output("Expected to find entry for [ $fullpath | $drvltr ], but didn't", WARN);
	}
	
    if ( $record_changed eq TRUE ) {
	  my $dbentry = $self->encode($entry);
	  goto FINISH if ( not defined($dbentry) );
	
      # This should be atomic by definition of DB designed by connect call
      $result = $db->put("$drvmap_key", "$dbentry");
	}
	
  FINISH:
    $db->unlock();
	return $result;
  }
  
#=============================================================================
sub encode
  {
    my $self       = shift;
	my $drvmap_obj = shift;
	
	return undef if ( &is_type($drvmap_obj, 'HP::Drive::MapperDB::DriveMapping') eq FALSE );
	return undef if ( &valid_string($drvmap_obj->fullpath()) eq FALSE ||
	                  &valid_string($drvmap_obj->reduced_path()) eq FALSE );
					  
	my $xmlstr = $drvmap_obj->prepare_xml('drive_mapping');
	my $encoded_str = &encode_base64("$xmlstr");
	return undef if ( &valid_string($encoded_str) eq FALSE );
	return $encoded_str;
  }
  
#=============================================================================
sub increment
  {
    my $self   = shift;
	my $result = FALSE;
	
	return $result if ( $self->__check_for_db() eq FALSE );
	
	my $db = $self->db();

	my ( $fullpath, $drvltr, $pid ) = ( undef, undef, undef );
	
	if ( &is_type($_[0], 'HP::Drive::MapperDB::DriveMapping') eq FALSE ) {
	  my $inputdata  = $self->__convert_inputs(@_);	
	  $fullpath      = $inputdata->{'fullpath'};
	  $drvltr        = $inputdata->{'drvltr'};
	  $pid           = $inputdata->{'pid'};
	  splice(@_,0,3);
	} else {
	  $fullpath   = $_[0]->fullpath();
	  $drvltr     = $_[0]->reduced_path();
	  $pid        = $_[1];
	  splice(@_,0,2);
	}
	
	my $drvmap_key = $self->make_key("$fullpath", "$drvltr");

	return $result if ( &valid_string($drvmap_key) eq FALSE );
	
	$pid = ( defined($pid) ) ? $pid : &get_pid();
	my $record_changed = FALSE;
	
    $db->lock_exclusive();
	my $entry = $db->{"$drvmap_key"};
	
	if ( defined($entry) ) {
	  $entry = $self->decode($entry);  # This should be a DriveMapping object
	  goto FINISH if ( not defined($entry) );
	  
	  my $added = $entry->add_pid($pid);
	  $record_changed = TRUE if ( $added eq TRUE );
	} else {
	  $entry = &create_object('c__HP::Drive::MapperDB::DriveMapping__');
	  $entry->add_pid($pid);
	  $entry->fullpath("$fullpath");
	  $entry->reduced_path("$drvltr");
      $record_changed = TRUE;
	}
	
    if ( $record_changed eq TRUE ) {
	  my $dbentry = $self->encode($entry);
	  goto FINISH if ( not defined($dbentry) );
	
      # This should be atomic by definition of DB designed by connect call
      $result = $db->put("$drvmap_key", "$dbentry");
	}
	
  FINISH:
    $db->unlock();
	return $result;
  }
  
#=============================================================================
sub make_key
  {
    my $self      = shift;
	#my $container = &create_object('c__HP::ArrayObject__');
	
	#return undef if ( not defined($container) );
	&HP::Support::Base::allow_space_as_valid_string(TRUE);
	
	my $keystr = '';
	foreach (@_) {
	  next if ( &valid_string($_) eq FALSE );
	  $keystr .= "$_";
	}
	
	&HP::Support::Base::allow_space_as_valid_string();
	
	return &generate_unique_uuid(undef, 3, "$keystr");  # UUID version 3 (MD5) key
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
		  $self->{"$key"} = $_[0]->{"$key"} if ( exists($self->{"$key"}) );
		}
	  } else {
	    &__print_output("Please use a hash as input to construct this class < $class >", 'STDERR');
		return undef;
	  }
	}

    bless $self, $class;
	$self->instantiate();
    return $self;
  }

#=============================================================================
sub number_records
  {
    my $self = shift;
	return 0 if ( $self->__check_for_db() eq FALSE );
	
	my $db = $self->db();
	return scalar(keys(%{$db}));
  }

#=============================================================================
sub number_pids
  {
    my $self       = shift;
	my $result     = $self->associated_pids(@_);
	return scalar(@{$result});
  }
  
#=============================================================================
sub scan_db_for_pid
  {
    my $self = shift;
	return undef if ( $self->__check_for_db() eq FALSE );

	my $db  = $self->db();
	my $pid = shift || &get_pid();
	
	my @matches = ();
	
	foreach ( keys(%{$db}) ) {
	  my $entry = $self->decode($db->{"$_"});
	  if ( $entry->has_pid($pid) eq TRUE ) {
	    push (@matches, $entry);
	  }
	}
	
	return \@matches;
  }
  
#=============================================================================
1;