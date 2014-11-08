package HP::SupportMatrix::Version;

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
	                        'HP::RegexLib'                 => undef,
							'HP::ArrayTools'               => undef,
							'HP::VersionTools'             => undef,
							'HP::CSLTools::Common'         => undef,
							'HP::CSLTools::Constants'      => undef,
							
							'HP::SupportMatrix::Constants' => undef,
							'HP::SupportMatrix::Tools'     => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_supportmatrix_version_pm'} ||
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
sub add_attribute
  {
    my $self = shift;
	my ( $attrname, $attrval ) = @_;
	
	if ( not defined( $self->attributes() ) ) { $self->attributes( {} ); }
	
	$self->attributes->{$attrname} = "$attrval";
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
sub breakup_version_id
  {
    my $self = shift;
	
	if ( defined( $self->version() ) ) {
	  $self->major( &get_version_type( $self->version(), 'major' ) );
	  $self->minor( &get_version_type( $self->version(), 'minor' ) );
	  #$self->patch( &get_version_type( $self->version(), 'patchlevel', quotemeta(?[\.|u]?(\d+)) ) );
	}
  }
  
#=============================================================================
sub clear
  {
    my $self = shift;
	
	$self->version(undef);
	$self->major(undef);
	$self->minor(undef);
	$self->patch(undef);
	$self->attributes(undef);
	$self->duplicate(FALSE);
	$self->consistent(FALSE);
	$self->valid(FALSE);
  }
  
#=============================================================================
sub data_types
  {
    # See if there is a way to read this from file.
    my %data_fields = (
		               'version'    => undef,
					   'major'      => undef,
					   'minor'      => undef,
					   'patch'      => undef,
					   'attributes' => undef,
					   'duplicate'  => FALSE,
					   'consistent' => TRUE,
					   'valid'      => FALSE,
		              );
    
    return \%data_fields;
  }

#=============================================================================
sub DESTROY
  {
    my $self = shift;

    &__print_debug_output("Calling destructor for object ".ref($self)."\n");
  }

#=============================================================================
sub equals
  {
    my $self = shift;
	my $other_version_obj = shift || return FALSE;
	
	if ( $self->version() ne $other_version_obj->version() ) { return FALSE; }
	my $v1attr = $self->attributes();
	my $v2attr = $other_version_obj->attributes();
	
	if ( ( not defined($v1attr) ) && ( not defined($v2attr) ) ) {
	  return TRUE;
	} elsif ( ( not defined($v1attr) ) || ( not defined($v2attr) ) ) {
	  return FALSE;
	} else {
	  my @v1attrs = keys(%{$v1attr});
	  my @v2attrs = keys(%{$v2attr});
	  
	  my $diff = &set_difference(\@v1attrs, \@v2attrs);
	  if ( scalar(@{$diff}) > 0 ) { return FALSE; }
	  foreach ( @v1attrs ) {
	    if ( $v1attr->{"$_"} ne $v2attr->{"$_"} ) { return FALSE; }
	  }
	}
	
	return TRUE;
  }

#=============================================================================
sub get_version
  {
    my $self          = shift;
	my $allowed_attrs = shift || [];
	
	my $attrs = $self->attributes();
	
	my $result = $self->version();
    if ( not defined($attrs) ) { return $result; }
	
	foreach ( keys(%{$attrs}) ) {
	  if ( &set_contains( "$_", $allowed_attrs ) ) {
	    $result .= "-".$attrs->{"$_"};
	  }
	}
	
	return $result;
  }
  
#=============================================================================
sub mark_consistent
  {
    my $consistent = FALSE;
	
    my $self  = shift;
	my $other = shift || return $consistent;
	
	if ( ref($self) ne ref($other) ) { return $consistent; }
	$consistent = TRUE;
	return $consistent;
  }
  
#=============================================================================
sub mark_duplicate
  {
    my $self  = shift;
	my $other = shift || return;
	
	if ( ref($self) ne ref($other) ) { return; }
	
	if ( $self->equals($other) == TRUE ) {
	  $self->duplicate( TRUE );
	  $other->duplicate( TRUE );
	}
	return $self->duplicate();
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
	
	my @specific_nodes = $node->attributes();
	foreach ( @specific_nodes ) {
	  if ( $_->nodeName() =~ m/id/i ) {
	    $self->version( $_->getValue );
		next;
	  }
	  my $attrname = $_->nodeName();
	  my $attrval  = $_->getValue();
	  
	  $self->add_attribute($attrname, "$attrval");
	}
	
	$self->breakup_version_id();
	$self->verify_data();
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
  }

#=============================================================================
sub verify_data
  {
    my $self = shift;
	
	if ( not defined($self->version()) ) {
	  $self->valid(FALSE);
	  return;
	}
	$self->valid(TRUE);
  }

#=============================================================================
1;