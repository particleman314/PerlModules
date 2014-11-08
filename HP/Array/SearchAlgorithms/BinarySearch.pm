package HP::Array::SearchAlgorithms::BinarySearch;

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
	
	use parent qw(HP::Array::SearchAlgorithms::GenericSearch);
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

    @EXPORT  = qw (
                   );

    $module_require_list = {
	                        'HP::Constants'                => undef,
	                        'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object::Tools'   => undef,
							
							'HP::CheckLib'                           => undef,
							'HP::Array::Constants'                   => undef,
							'HP::Array::SearchAlgorithms::Constants' => undef,
						   };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_array_searchalgorithms_binarysearch_pm'} ||
                 $ENV{'debug_array_searchalgorithms_module'} ||
                 $ENV{'debug_array_module'} ||
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
my $local_false = FALSE;
my $local_true  = TRUE;

#=============================================================================
sub data_types
  {
    my $self         = shift;
	my $which_fields = shift || COMBINED;

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
	$self->instantiate();

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
sub run
  {
    my $self       = shift;
	my $num_iter   = 0;
	my $result     = NOT_FOUND;
	my $good_setup = $self->SUPER::run();
	
	goto __END_OF_SUB if ( $good_setup ne $local_true );

	my $arrobj    = $self->arrayobject();
	my $item      = $self->item();
	my $item_type = ref($item);

	&__print_debug_output("Searching for item : <$item>", __PACKAGE__) if ( $is_debug );
	
	my $has_sort_method = exists($arrobj->{'sort_method'});
	
	if ( $item_type ne '' || ( not $has_sort_method ) ) {
	  my $ls = &create_object('c__HP::Array::SearchAlgorithms::LinearSearch__');
	  $ls->arrayobject($arrobj);
	  $ls->item($item);
	  $result = $ls->run();
	  goto __END_OF_SUB;
	}

	my @elements     = $arrobj->get_elements();
	my $num_elements = scalar(@elements);
	
	my $lower_limit = 0;
	my $upper_limit = $num_elements;
	
	my $isnumeric = &is_numeric($item);

  SEARCH_AGAIN:
    my $elemrange = $upper_limit - $lower_limit;
	
	&__print_debug_output("Upper|Lower limits : [ $upper_limit | $lower_limit ]", __PACKAGE__) if ( $is_debug );

	# Single entry in section use-case
	if ( $elemrange <= 0 ) {
	  if ( &equal($elements[$lower_limit], $item) eq $local_true ) {
	    $result = $lower_limit;
	  }
	  goto __END_OF_SUB;
	}
	
	++$num_iter;
    my $halfway_pt = int($elemrange / 2) + $lower_limit;
	my $direction  = undef;
	
	if ( $isnumeric eq $local_true ) {
	  $direction = $elements[$halfway_pt] <=> $item;
	} else {
	  $direction = $elements[$halfway_pt] cmp $item;
	}
	
	return $halfway_pt if ( $direction eq ELEMENT_MATCH );
	
	if ( $direction eq LOWER_SECTION ) {
	  $upper_limit = $halfway_pt - 1;
	  goto SEARCH_AGAIN;
	}
	
	if ( $direction eq UPPER_SECTION ) {
	  $lower_limit = $halfway_pt + 1;
	  goto SEARCH_AGAIN;
	}
	
  __END_OF_SUB:
    &__print_debug_output("Number of iterations : $num_iter [ $item | $result ]", __PACKAGE__) if ( $is_debug );
	return $result;	
  }
  
#=============================================================================
1;