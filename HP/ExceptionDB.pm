package HP::ExceptionDB;

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
    use lib "$FindBin::Bin/..";

	use parent qw(HP::DB);
	
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

    $VERSION = 0.75;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'File::Basename'               => undef,
							
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
	                        'HP::CheckLib'                 => undef,
							
							'HP::Exception::Constants'     => undef,
							'HP::ExceptionDB::Constants'   => undef,
							'HP::Array::Constants'         => undef,
							'HP::Array::Tools'             => undef,
							
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_exceptiondb_pm'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );

    $broken_install = 0;

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
sub _new_instance
  {
    return &new(@_);
  }
  
#=============================================================================
sub add_exception_type
  {
    my $self   = shift;
	
	my ( $exname, $exdata ) = ( undef, undef );
	if ( ref($_[0]) =~ m/hash/i ) {
	  my $inputdata = shift;
	  ($exname, $exdata) = each (%{$inputdata});
	} else {
	  $exname = shift;
	  $exdata = shift;
	}
	
	my $result = FALSE;
	
	return $result if ( &valid_string($exname) eq FALSE );
	return $result if ( ref($exdata) !~ m/^array/i );
	return $result if ( scalar(@{$exdata}) < 2 );
	
	my $exnum  = $exdata->[0];
	my $extype = $exdata->[1];
	  
	return $result if ( &is_integer($exnum) eq FALSE );
	return $result if ( &valid_string($extype) eq FALSE );
	return $result if ( $self->has_exception('id', $exnum) eq TRUE || $self->has_exception('name', $exname) eq TRUE );
	
	my $extype_obj = &create_object('c__HP::ExceptionDB::ExceptionType__');
	return $result if ( not defined($extype_obj) );
	
	$extype_obj->name($exname);
	$extype_obj->id(abs($exnum));
	$extype_obj->method($extype);
	  
	return $self->known_exceptions()->push_item($extype_obj);
  }

#=============================================================================
sub clear
  {
    my $self = shift;
	
	$self->known_exceptions()->clear() if ( &is_type($self->{'known_exceptions'}, 'HP::ArrayObject') eq TRUE );
	$self->valid(FALSE);
	return;
  }

#=============================================================================
sub data_types
  {
    my $data_fields = {
					   'known_exceptions' => '[] c__HP::ExceptionDB::ExceptionType__',
					   'valid'            => FALSE,
		              };
    
    foreach ( @ISA ) {
	  my $parent_types = undef;
	  if ( &function_exists($_, 'data_types') eq TRUE ) {
	    my $evalstr      = "\$parent_types = $_->data_types()";
	    eval "$evalstr";
	    $data_fields     = &HP::Support::Hash::__hash_merge( $data_fields, $parent_types ) if ( defined($parent_types) );
	  }
	}
	
    return $data_fields;
  }

#=============================================================================
sub DESTROY
  {
    my $self = shift;

    &__print_debug_output("Calling destructor for object ".ref($self)."\n") if ( $is_debug );
	return;
  }

#=============================================================================
sub find_exception_idx_by_id
  {
    my $self = shift;
	my $id   = shift;
	
	my $idx  = NOT_FOUND;
	
	return $idx if ( &valid_string($id) eq FALSE );
	$id = abs($id) if ( $id < 0 );
	
	return $idx if ( $id < MINIMUM_ERROR_CODE || $id > MAXIMUM_ERROR_CODE );
	
	my $elements = $self->known_exceptions()->get_elements();
	for ( my $loop = 0; $loop < scalar(@{$elements}); ++$loop ) {
	  if ( $elements->[$loop]->get_exception_id() eq $id ) {
		$idx = $loop;
		last;
	  }
	}
	
	return $idx;
  }
  
#=============================================================================
sub find_exception_idx_by_name
  {
    my $self = shift;
	my $name = shift;
	
	my $idx  = NOT_FOUND;
	
	return $idx if ( &valid_string($name) eq FALSE );
	
	my $elements = $self->known_exceptions()->get_elements();
	for ( my $loop = 0; $loop < scalar(@{$elements}); ++$loop ) {
	  if ( $elements->[$loop]->get_exception_name() eq $name ) {
		$idx = $loop;
		last;
	  }
	}
	
	return $idx;
  }

#=============================================================================
sub find_exception_idx_by_method
  {
    my $self = shift;
	my $type = shift;
	
	my $idx  = NOT_FOUND;
	
	return $idx if ( &valid_string($type) eq FALSE );
	
	my $elements = $self->known_exceptions()->get_elements();
	for ( my $loop = 0; $loop < scalar(@{$elements}); ++$loop ) {
	  if ( $elements->[$loop]->get_exception_class() eq $type ) {
		$idx = $loop;
		last;
	  }
	}
	
	return $idx;
  }

#=============================================================================
sub find_exception_index
  {
    my $self   = shift;
	my $marker = shift;
	my $value  = shift;
	
	my $idx    = NOT_FOUND;
	
	return $idx if ( &valid_string($marker) eq FALSE );
	return $idx if ( &valid_string($value) eq FALSE );
	
	my $search_params = $self->known_exceptions()->get_template_obj()->searchable_fields();
	$search_params = &set_intersect($marker, $search_params);

	foreach my $sp ( @{$search_params} ) {
	  my $evalstr = "\$idx = \$self->find_exception_idx_by_$sp('$value');";
	  eval "$evalstr";
	  last if ( $idx ne NOT_FOUND );
	}
	
	return $idx;
  }

#=============================================================================
sub get_known_exceptions
  {
    my $self = shift;
	return $self->known_exceptions();
  }
  
#=============================================================================
sub has_exception
  {
    my $self   = shift;
	my $marker = shift;  # This could be name/number/classification
	my $value  = shift;
	
	my $idx = $self->find_exception_index($marker, $value);
	return ( $idx ne NOT_FOUND ) ? TRUE : FALSE;
  }

#=============================================================================
sub install_exception_types
  {
    my $self = shift;
	my $data = shift;
	
	return if ( &valid_string($data) eq FALSE );
	return if ( ref($data) !~ m/hash/i );
	
	my $result = [];

	foreach my $exname ( keys(%{$data}) ) {	  
	  next if ( ref($data->{$exname}) !~ m/^array/i );
	  CORE::push( @{$result}, [ "$exname", $self->add_exception_type($exname, $data->{"$exname"}) ] );
    }
	
	return $result;
  }
  
#=============================================================================
sub make_exception
  {
    my $self   = shift;
	my $marker = shift;
	my $value  = shift;
	
	my $idx = $self->find_exception_index($marker, $value);
	return undef if ( $idx eq NOT_FOUND );
	
	return $self->known_exceptions()->get_element($idx)->make_exception();
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
	$self->validate();
    return $self;
  }

#=============================================================================
sub number_exceptions
  {
    my $self = shift;
	return $self->known_exceptions()->number_elements();
  }
  
#=============================================================================
sub remove_exception
  {
    my $self   = shift;
	my $marker = shift;
	my $value  = shift;
	
	return FALSE if ( &valid_string($marker) eq FALSE );
	
	my $idx = $self->find_exception_index($marker, $value);
	return FALSE if ( $idx eq NOT_FOUND );
	
	return $self->known_exceptions()->delete_elements_by_index($idx);
  }

#=============================================================================
sub validate
  {
    my $self = shift;
	
	$self->SUPER::validate();
	$self->valid(TRUE);
	return;
  }

#=============================================================================
1;