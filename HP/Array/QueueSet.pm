package HP::Array::QueueSet;

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
    use lib "$FindBin::Bin/../..";

	#use overload q{""} => 'HP::Array::QueueSet::print';
	
	use parent qw(HP::Array::Queue HP::Array::Set);  # Diamond Inheritance Graph ( Array -> [ Queue, Set ] -> QueueSet )
	use mro "c3";
	
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

    $VERSION = 1.00;

    @EXPORT  = qw ();

    $module_require_list = {
	                        'HP::Constants'              => undef,
							'HP::Support::Base'          => undef,
							'HP::Support::Hash'          => undef,
							'HP::Support::Module'        => undef,
							'HP::Support::Object'        => undef,
							'HP::Support::Object::Tools' => undef,
							
							'HP::Array::Constants'       => undef,
							'HP::Array::Tools'           => undef,

							'HP::CheckLib'               => undef,
                          };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_array_queueset_pm'} ||
				 $ENV{'debug_array_modules'} ||
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
my $local_true  = TRUE;
my $local_false = FALSE;

#=============================================================================
sub __post_add
  {
    my $self = $_[0];
	my $uniq_elems = &HP::Array::Tools::__unique($self->get_elements($local_true)); # preserve order
	my $result = $self->replace_elements($uniq_elems);
	return $result;
  }
  
#=============================================================================
sub data_types
  {
    my $self         = $_[0];
	my $which_fields = $_[1] || COMBINED;
	
    # See if there is a way to read this from file.
    my $data_fields = {
	                  };
    
	if ( $which_fields eq COMBINED ) {
      foreach ( @ISA ) {
	    my $parent_types = undef;
	    my $evalstr      = "\$parent_types = $_->data_types()";
	    eval "$evalstr";
	    $data_fields     = &HP::Support::Hash::__hash_merge( $data_fields, $parent_types ) if ( defined($parent_types) );
	  }
	}
	
	delete($data_fields->{'sort_method'});
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
	
    bless $self, $class;
	$self->__unique();

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

    return $self;
  }

#=============================================================================
# sub print
  # {
    # my $self        = $_[0];
	# my $indentation = $_[1] || '';
	
	# my $result = $self->SUPER::print($indentation, @_);
	# return $result;
  # }

#=============================================================================
sub push_item
  {
    my $result = $local_false;
    my $self   = $_[0];
	
	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    if ( ref($_[1]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'data',       undef,
	                                        'location',   \&is_integer,
											'multi-item', \&is_integer, ], @_[ 1..scalar(@_)-1 ]);
    } else {
	  $inputdata = $_[1];
	}
	
	# No input, return FALSE exit status
    goto __END_OF_SUB if ( scalar(keys(%{$inputdata})) == 0 );
	
	my $data       = $inputdata->{'data'};
	my $location   = $inputdata->{'location'} || APPEND;
	my $multi_item = $inputdata->{'multi-item'} || $local_false;
	
	$result = $self->SUPER::push_item($data, $location, $multi_item);
	$result &= $self->__post_add() if ( $multi_item eq $local_false );
	
	return $result;
  }
  
#=============================================================================
1;