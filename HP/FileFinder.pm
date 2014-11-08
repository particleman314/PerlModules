package HP::FileFinder;

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

    $VERSION = 1.00;

    @EXPORT  = qw (
                  );

    $module_require_list = {
	                        'Cwd'           => undef,
	                        'File::Find'    => undef,
							
							'HP::Constants'     => undef,
							'HP::Support::Base' => undef,
							'HP::Support::Os'   => undef,
							'HP::Support::Hash' => undef,
							'HP::CheckLib'      => undef,
							
							'HP::Path'          => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_filefinder_pm'} ||
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
my $bootstrap_obj = undef;

#=============================================================================
sub __internal_search
  {
    if ( not defined($bootstrap_obj) ) { return; }
	my $self = $bootstrap_obj;
	
    my $relative_path = &HP::Path::__flip_slashes("$File::Find::dir", 'backward', 'forward');
	my $regex         = &convert_to_regexs($self->rootpath());
	$relative_path    =~ s/$regex// if ( defined($self->rootpath) );
	
    my $depth = ($relative_path =~ tr/\///);
	&__print_debug_output("Current depth [ $File::Find::dir ] = $depth") if ( $is_debug );
	
	if ( $depth < $self->min_traversal_depth() ||
	     $depth > $self->max_traversal_depth() ) { return; }
	
	my $applicable_test = TRUE;
	foreach my $tc ( @{$self->test_conditions()->get_elements()} ) {
	  my $result = 0;
	  my $evalstr = "\$result = ( $tc ) ? TRUE : FALSE";
	  eval "$evalstr";
      $applicable_test &= $result;
	  
	  last if ( $applicable_test eq FALSE );
	}
	
	if ( $applicable_test ) {
	  $self->{'matches'}->push_item( &HP::Path::__flip_slashes( &join_path("$File::Find::dir", "$_"), 'backward', 'forward') );
	}
	
	return;
  }
  
#=============================================================================
sub add_test_condition
  {
    my $self = shift;
	my $test_condition = shift || return FALSE;
	
	$self->{'test_conditions'}->push_item("$test_condition");
	return TRUE;
  }
  
#=============================================================================
sub clear_matches
  {
    my $self = shift;
	
	$self->matches()->clear();
	return;
  }
  
#=============================================================================
sub data_types
  {
    my $self         = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
	                   'matches'             => 'c__HP::ArrayObject__',
					   'min_traversal_depth' => 0,
					   'max_traversal_depth' => 0,
					   'rootpath'            => undef,
					   'test_conditions'     => 'c__HP::ArrayObject__',
					   'search_routine'      => undef,
					   'valid'               => FALSE,
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
sub find_matches
  {
    my $self = shift;
	
	$self->validate();
	
	if ( $self->valid() eq FALSE ) { return FALSE; }
	
	$self->clear_matches();
	$bootstrap_obj = $self;
	find( $self->search_routine(), ( $self->rootpath() ) );

	return TRUE;
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
sub run
  {
    my $self = shift;
	
	$self->find_matches();
	return;
  }

#=============================================================================
sub set_min_depth
  {
    my $self  = shift;
	my $depth = shift || 0;
	
	if ( &is_integer($depth) eq FALSE ) { return; }
	$self->min_traversal_depth($depth);
	$self->validate_depths();
	return;
  }
  
#=============================================================================
sub set_max_depth
  {
    my $self  = shift;
	my $depth = shift || 0;

	if ( &is_integer($depth) eq FALSE ) { return ; }
 	$self->max_traversal_depth($depth);
	$self->validate_depths();
	return;
  }
  
#=============================================================================
sub set_rootpath
  {
    my $self     = shift;
	my $rootpath = shift || return;
	
	if ( &valid_string($rootpath) eq TRUE ) {
	  $self->rootpath("$rootpath");
      $self->min_traversal_depth( &HP::Path::__flip_slashes("$rootpath", 'backward', 'forward') =~ tr/\/// );
	  $self->max_traversal_depth( $self->min_traversal_depth() + 1 );
      $self->validate_depths();
    }
	
	return;
  }
  
#=============================================================================
sub validate_depths
  {
    my $self = shift;
	
	if ( &valid_string($self->rootpath()) eq TRUE ) {
	  if ( $self->max_traversal_depth() <= $self->min_traversal_depth() ) {
	    $self->valid(FALSE);
	    return;
	  }
	  $self->valid(TRUE);
	  return;
    }
	
	$self->valid(FALSE);
	return;
  }
  
#=============================================================================
sub validate
  {
    my $self = shift;
	
	$self->SUPER::validate();

	if ( not defined($self->search_routine()) ) {
	  $self->search_routine($self->can('__internal_search'));
	}
	
	if ( not defined($self->rootpath()) ) {
	  my $currdir = &getcwd();
	  $currdir = ( &os_is_windows_native() eq TRUE ) ? &HP::Path::__flip_slashes("$currdir", 'forward', 'backward') : "$currdir";
	  $self->set_rootpath("$currdir");
	} else {
	  $self->validate_depths();
	}
	
	if ( $self->max_traversal_depth() <= $self->min_traversal_depth() ) {
	  $self->valid(FALSE);
	  return;
	}
	
	$self->valid(TRUE);
	return;
  }
  
#=============================================================================
1;