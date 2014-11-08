package HP::TestObject;

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

    $VERSION = 1.05;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'HP::Constants'              => undef,
							'HP::Support::Base'          => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'          => undef,
							'HP::Support::Object'        => undef,
							'HP::Support::Object::Tools' => undef,
							'HP::Support::Module'        => undef,
	                        'HP::CheckLib'               => undef,
							'HP::XML::Utilities'         => undef,
							
							'HP::Array::Tools'           => undef,
							'HP::Path'                   => undef,
							'HP::FileManager'            => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_testobject_pm'} ||
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

my $skip_cloning  = $local_false;
my $cached_object = undef;

#=============================================================================
sub __initialize
  {
    if ( $is_init eq $local_false ) {
	  $is_init = $local_true;
      $cached_object = HP::TestObject->new() if ( not defined($cached_object) );
	}
  }
  
#=============================================================================
sub data_types
  {
    my $self         = $_[0];
	my $which_fields = $_[1] || COMBINED;
	
    my $data_fields = {
	                   'major'       => undef,
					   'minor'       => undef,
	                   'revision'    => undef,
					   'subrevision' => undef,
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
sub force_xml_output
  {
    my $self     = $_[0];

	my $specific = &get_fields($self);
	$specific    = &set_union($specific, $self->SUPER::force_xml_output());
	return $specific;
  }

#=============================================================================
sub new
  {
    my $class = shift;
	my $self  = undef;

	if ( ref($_[0]) =~ m/hash/i ) {
	  if ( exists($_[0]->{'skip'}) ) {
	    $skip_cloning = $_[0]->{'skip'};
		delete($_[0]->{'skip'});
		shift (@_) if ( scalar(keys(%{$_[0]})) < 1 );
	  }
	}
	
	# Ask the cached object container to clone a matching object otherwise
	# go through the construction process.
	if ( $skip_cloning eq $local_false ) {
	  if ( defined($HP::TestObject::cached_object) ) {
	    $self = $HP::TestObject::cached_object->clone();
	    &__print_debug_output("Using cloned object to make new one...", __PACKAGE__) if ( $is_debug );
	    goto UPDATE;
	  }
	}
	
    my $data_fields = &data_types();

    $self = {
		     %{$data_fields},
	        };
			   
    bless $self, $class;
	$self->instantiate();
	&__print_debug_output("Using constructed object to seed cloneable storage item...", __PACKAGE__) if ( $is_debug );
	$HP::TestObject::cached_object = $self if ( not defined($HP::TestObject::cached_object) );
	
  UPDATE:
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
	
	return $self;  
  }

#=============================================================================
sub readfile
  {
    my $self = $_[0];
	return $self->SUPER::readfile(@_[ 1..scalar(@_)-1 ]);
  }

#=============================================================================
sub rootnode_name
  {
    return 'version';
  }
  
#=============================================================================
sub skip_fields
  {
    my $self     = $_[0];
	my $specific = [];
	
	$specific = &set_union($specific, $self->{SUPPRESSION_KEY}) if ( exists($self->{SUPPRESSION_KEY}) );
	$specific = &set_union($specific, $self->SUPER::skip_fields());
	return $specific;
  }

#=============================================================================
sub write_as_attributes
  {
    my $self = $_[0];
	
	my $specific = [ 'comparison' ];

	$specific = &set_union($specific, $self->SUPER::write_as_attributes());
	return $specific;
  }

#=============================================================================
sub writefile
  {
    my $result  = $local_false;
    my $self    = $_[0];
    my $xmlfile = $_[1];
  
    goto __END_OF_SUB if ( &valid_string($xmlfile) eq $local_false );

	$result = $self->SUPER::writefile($xmlfile);
	return $result;
  }
  
#=============================================================================
&__initialize();
1;