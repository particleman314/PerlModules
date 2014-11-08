package HP::SupportMatrix::Requirements;

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
	#use Autoloader;
	
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

    $VERSION = 0.75;

    @EXPORT      = qw (
                      );

    $module_require_list = {
	                        'XML::LibXML'                   => undef,
							
	                        'HP::RegexLib'                  => undef,
							'HP::ArrayTools'                => undef,
							'HP::BasicTools'                => undef,
							'HP::CSLTools::Common'          => undef,
							'HP::CSLTools::Constants'       => undef,
							
							'HP::SupportMatrix::Constants'     => undef,
							'HP::SupportMatrix::Tools'         => undef,
							'HP::SupportMatrix::SoftwareGroup' => undef,
							'HP::SupportMatrix::Binaries'      => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_supportmatrix_requirements_pm'} ||
				 $ENV{'debug_supportmatrix_modules'} ||
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
sub __parse_binaries
  {
    my $self = shift;
    my $node = shift || return;

    &HP::SupportMatrix::Tools::__parse($self, $node, 'binaries', { 'type'           => 'multilayer',
										                           'count'          => 0,
										                           'compare'        => GEQ,
										                           'class'          => 'HP::SupportMatrix::Binaries',
										                           'container_name' => 'binaries' } );
    return;
  }
  
#=============================================================================
sub __parse_theme
  {
    my $self = shift;
    my $node = shift || return;
	 
	&HP::SupportMatrix::Tools::__parse($self, $node, 'theme', { 'type' => 'attr' } );
	return;
  }

#=============================================================================
sub __parse_versioninfo
  {
    my $self = shift;
    my $node = shift || return;

    &HP::SupportMatrix::Tools::__parse($self, $node, 'versionInformation', { 'type'           => 'multilayer',
										                                     'count'          => 0,
										                                     'compare'        => GEQ,
										                                     'class'          => 'HP::SupportMatrix::SoftwareGroup',
										                                     'container_name' => 'software' } );
	#$self->consolidate('software', 'software');
	return;
  }

#=============================================================================
sub add_item
  {
    my $self       = shift;
	my $entry_name = shift || return;
	my $obj        = shift || return;

	my @data_entries = keys( %{$self->data_types()} );
	
	&csl_print_debug_output( "Checking data entries for match of requested entry << $entry_name >>" );
    if ( &set_contains( $entry_name, \@data_entries ) ) {
	  &csl_print_debug_output( "Found match, adding to list of items..." );
	  push ( @{$self->{"$entry_name"}}, $obj );  # Direct access to internals...
	}
	return;
  }
  
#=============================================================================
sub AUTOLOAD
  {
    our $AUTOLOAD;
    my $self = shift;
    my $type = ref($self) or die "$self is not an object";
    
    # DESTROY messages should never be propagated.
    return if $AUTOLOAD =~ /::DESTROY$/;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    unless ( defined($name) or exists($self->{$name}) ) {
      if ( defined($name) ) {
	    &__print_output("Can't access '$name' field in class $type.  Returning empty string...\n", 'STDERR');
      } else {
	    &__print_output("Can't access an undefined field in class $type.  Returning empty string...\n", 'STDERR');
      }
      return '';
    }

    my $num_elements = scalar( @_ );

    if ( $num_elements >= 1) {
      # Set built-on-the-fly function...
      if ( $num_elements == 1 ) {
	    return $self->{$name} = $_[0];
      } else {
	    return $self->{$name} = \@_;
      }
    } else {
      # Get built-on-the-fly function...
      return $self->{$name};
    }
  }
 
#=============================================================================
sub consolidate
  {
    my $self = shift;
	my $top_level_item = shift || return;
	my $sub_level_item = shift || return;
	
	&csl_print_debug_output( "Attempting to consolidate multiple entries into a single entry for << $top_level_item >>" );
	
	my @multiple_entries = ();
	eval "\@multiple_entries = \@{ \$self->$top_level_item() };";
	if ( ! $@ ) {
	  if ( scalar( @multiple_entries ) > 1 ) {
	    for ( my $loop = 1; $loop < scalar(@multiple_entries); ++$loop ) {
	      my @objs = ();
		  eval "\@objs = \@{ \$multiple_entries[$loop]->$sub_level_item() };";
		  if ( $@ ) {
		    &csl_print_output( "Unable to access items of entry #$loop regarding << $sub_level_item >>", WARNING );
			next;
		  }
		  if ( $multiple_entries[0]->can('add_item') ) {
		    foreach ( @objs ) {
		      &csl_print_debug_output( "Adding << $sub_level_item >> items from entry #$loop..." );
		      $multiple_entries[0]->add_item( $_ );
		    }
	      }
		}
	    if ( $multiple_entries[0]->can('mark_duplicates') ) {
	      $multiple_entries[0]->mark_duplicates();
	    }
	    eval "\$self->$top_level_item( [ \$multiple_entries[0] ] );";
		if ( $@ ) {
		  &csl_print_output( "Unable to reset single (first) item in $top_level_item field", WARNING );
		  return;
		}
	  } elsif ( scalar( @multiple_entries ) > 0 ) {
	    &csl_print_output( "Only one entry, so no consolidation needed..." );
      }
	} else {
	  &csl_print_output( "Unable to access << $top_level_item >>.  Skipping!", WARNING );
	}
	return;
  }

#=============================================================================
sub data_types
  {
    # See if there is a way to read this from file.
    my %data_fields = (
		               'theme'    => undef,
					   'software' => undef,
					   'binaries' => undef,
					   'valid'    => FALSE,
		              );
    
    return \%data_fields;
  }

#=============================================================================
sub DESTROY
  {
    my $self = shift;

    &__print_debug_output("Calling destructor for object ".ref($self)."\n");
	return;
  }

#=============================================================================
sub get_software_groups
  {
    my $self   = shift;
	my $result = {};
	
	my $software = $self->software();
	if ( not defined($software) ) { return $result; }

	foreach ( @{$software} ) {
	  my $groupobj = $_->software_group();
	  if ( not defined($groupobj) ) { next; }
	  foreach ( keys( %{$groupobj} ) ) {
	    $result->{"$_"} = $groupobj->{"$_"};
	  }
	}
	
	return $result;
  }
  
#=============================================================================
sub get_software_group_names
  {
    my $self   = shift;
    my $result = $self->get_software_groups();
	
	my @group_ids = keys( %{$result} );
	return \@group_ids;
  }

#=============================================================================
sub get_software_products
  {
    my $self   = shift;
    my $result = {};
	
	my $uc_group = shift || return $result;
	
	my $software = $self->software();
	
	if ( not defined($software) ) { return $result; }
	foreach ( @{$software} ) {
	  my $groupobj = $_->software_group();
	  if ( not defined($groupobj) ) { next; }
      if ( not defined($groupobj->{"$uc_group"}) ) { next; }
      my $grpprods = $groupobj->{"$uc_group"};
	  
	  foreach my $prod ( keys (%{$grpprods}) ) {
	    if ( not defined($result->{"$prod"}) ) {
		  $result->{"$prod"} = [];
		  
		  foreach my $v2 ( @{$grpprods->{"$prod"}} ) {
		    if ( not defined($v2) ) { next; }
		    if ( ( not $v2->valid() ) || ( $v2->duplicate() ) || ( not $v2->consistent() ) ) { next; }
			else {
		      push( @{$result->{"$prod"}}, $v2 );
			}
		  }
		} else {
		  my $matched = FALSE;
		  foreach my $v2 ( $grpprods->{"$prod"} ) {
		    if ( not defined($v2) ) { next; }
		    if ( ( not $v2->valid() ) || ( $v2->duplicate() ) || ( not $v2->consistent() ) ) { next; }
		    foreach my $v1 ( $result->{"$prod"} ) { 
			  if ( $v1->equals( $v2 ) ) { $matched = TRUE; }
			  if ( $matched == TRUE ) { last; }
			}
			
			if ( $matched == FALSE ) { push ( @{$result->{"$prod"}}, $v2 ); }
			$matched = FALSE;
		  }
		}
	  }
    }
	
    return $result;	
  }

#=============================================================================
sub get_software_product_names
  {
    my $self   = shift;
    my $result = [];
	
	my $uc_group = shift || return $result;
	my $products = $self->get_software_products( "$uc_group" );
	
	my @results = keys( %{$products} );
    return \@results;	
  }

#=============================================================================
sub get_software_products_with_versions
  {
    my $self   = shift;
    my $result = [];
	
	my $uc_group = shift || return $result;
    my $products = $self->get_software_products( "$uc_group" );
	
	return $products;
  }
  
#=============================================================================
sub get_versions_of_software_product
  {
    my $self   = shift;
    my $result = [];
	
	my $uc_group   = shift || return $result;
	my $product_id = shift || return $result;
	
	my $products = $self->get_software_products( "$uc_group" );
	
	foreach my $prod ( @{$products} ) {
	  if ( $product_id ne $prod ) { next; }
      foreach my $v ( @{$products->{"$prod"}} ) {
	    if ( $v->valid() && ( not $v->duplicate() ) && $v->consistent() ) {
	      push( @{$result}, $v->get_version() );
		}
	  }
	}
	
	return $result;
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
    return $self;  
  }
  
#=============================================================================
sub parse
  {
    my $self = shift;
    my $node = shift || return;

	$self->__parse_theme($node);
	$self->__parse_versioninfo($node);
	$self->__parse_binaries($node);
	
	$self->verify_data();
	return;
  }

#=============================================================================
sub print
  {
    my $self        = shift;
    my $directive   = shift;
    my $data_fields = $self->data_types();

    my $skip_keys   = [];
    my @show_keys   = keys(%{$data_fields});
	
	if ( defined($directive) ) {
      if ( not defined($directive->{'streams'}) ) { $directive->{'streams'} = [ 'STDERR' ]; }
      if ( not defined($directive->{'indent'}) )  { $directive->{'indent'} = ''; }
      if ( not defined($directive->{'package'}) ) { $directive->{'package'} = __PACKAGE__; }
	} else {
	  $directive = {
	                'streams' => [ 'STDERR' ],
					'indent'  => '',
					'package' => __PACKAGE__,
				   };
	}
	
    foreach my $key (sort(@show_keys)) {
      if ( defined($self->{$key}) ) {
	    my $sub_str = $self->{$key};
	    my $outstr = sprintf("$directive->{'indent'}$directive->{'package'}::%-32s --> []",$key);
	    if ( length($sub_str) > 0 ) {
	      $outstr = sprintf("$directive->{'indent'}$directive->{'package'}::%-32s --> [$sub_str]",$key);
	    }
	    &__print_output("$outstr\n",$directive->{'package'});
      }
    }
	return;
  }

#=============================================================================
sub verify_data
  {
    my $self = shift;
	
	if ( not defined($self->theme()) ) {
	  $self->theme('__ALL__');
	}
	
	if ( defined($self->software_group()) && ref($self->software_group()) !~ m/softwaregroup/i ) {
	  $self->valid(FALSE);
	  return;
	}
	
	if ( defined($self->binaries()) && ref($self->binaries()) !~ m/array/i ) {
	  $self->valid(FALSE);
	  return;
	}

	$self->valid(TRUE);
	return;
  }

#=============================================================================

##############################################################################
sub test_get_software_groups
  {
    my $self = shift;
	use Data::Dumper;
	my $result = $self->get_software_groups();
	print STDERR Dumper($result);
	return;
  }
  
1;