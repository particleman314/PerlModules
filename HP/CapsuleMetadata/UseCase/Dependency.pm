package HP::CapsuleMetadata::UseCase::Dependency;

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

	use parent qw(HP::BaseObject HP::XML::XMLEnableObject);
	
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
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::CheckLib'                 => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
	             $ENV{'debug_capsulemetadata_usecase_dependency'} ||
                 $ENV{'debug_capsulemetadata_usecase_modules'} ||
				 $ENV{'debug_capsulemetadata_modules'} ||
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
sub __collect_dependency_nodes
  {
    my $self = shift;
	my $root = shift || '//';
	my $node = shift || return [];
	
	my $xmlobj = &create_object('c__HP::XMLObject__');
	$xmlobj->rootnode($node);
	
	my $nodes = $xmlobj->get_nodes_by_xpath({'xpath' => "$root"});
	return $nodes;
  }
#=============================================================================
sub __determine_dependency_types
  {
    my $self = shift;
	my $template = {};
	
	my $node = shift || return $template;
	
	my $xmlobj = &create_object('c__HP::XMLObject__');
	$xmlobj->rootnode($node);
	my $nodenames = $xmlobj->get_nodenames();
	
	foreach ( @{$nodenames} ) {
	  $template->{"$_"} = 'c__HP::CapsuleMetadata::UseCase::DependencyTypes::'. $_ .'__';
	}

	return $template;
  }
  
#=============================================================================
sub data_types
  {
    my $self = shift;
    my $which_fields = shift || COMBINED;
	
    my $data_fields = {
	                   'deptypes' => 'c__HP::ArrayObject__',
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
sub number_dependencies
  {
    my $self = shift;
	return $self->deptypes()->number_elements();
  }
  
#=============================================================================
sub print
  {
    my $self = shift;
	return;
  }

#=============================================================================
sub read_xml
  {
	my $result   = TRUE;
    my $self     = shift;

	my $node     = shift || return $result;
	my $rootpath = shift || '//';
	
	$self->pre_callback_read() if ( &function_exists($self, 'pre_callback_read') eq TRUE );
	
	my $template = $self->__determine_dependency_types($node);
	
	foreach ( keys(%{$template}) ) {
	  my $nodes = $self->__collect_dependency_nodes($_, $node);
	  foreach my $n ( @{$nodes} ) {
	    my $depobj = &create_object($template->{"$_"});
		if ( not defined($depobj) ) {
		  &__print_output("Unable to generate object << $template->{$_} >> for processing XML node...", WARN);
		  next;
		}
		if ( $depobj->read_xml($n) eq TRUE ) {
		  $self->deptypes()->push_item($depobj);
		} else {
		  $result &= FALSE;
		}
	  }
	}
	
	$self->post_callback_read() if ( &function_exists($self, 'post_callback_read') eq TRUE );
	
	$self->validate();
	$self->cleanup_internals() if ( &function_exists($self, 'cleanup_internals') eq TRUE );
	return $result;
  }

#=============================================================================
sub write_xml
  {
    my $self     = shift;
	my $filename = shift || &join_path(&getcwd(), 'dependencies.xml');
	
	my $result = $self->SUPER::write_xml("$filename", 'dependencies');
	return $result;
  }
  
#=============================================================================
1;