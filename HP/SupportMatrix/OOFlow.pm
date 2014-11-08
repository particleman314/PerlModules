package HP::SupportMatrix::OOFlow;

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
							'HP::CSLTools::Common'         => undef,
							'HP::CSLTools::Constants'      => undef,
							
							'HP::SupportMatrix::Constants' => undef,
							'HP::SupportMatrix::Tools'     => undef,
							'HP::SupportMatrix::Jarfile'   => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_supportmatrix_ooflow_pm'} ||
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
sub add_item
  {
    my $self    = shift;
	my $jarfile = shift || return;
	
	if ( not defined($self->{'support_jarfiles'}) ) {
	  $self->support_jarfiles([]);
	} else {
	  if ( ref($self->{'support_jarfiles'}) !~ m/array/i ) {
	    $self->support_jarfiles([]);
	  }
	}
	
	if ( ref($jarfile) =~ m/jarfile/i ) {
	  &csl_print_debug_output( "Adding jarfile item..." );
	  push ( @{$self->{'support_jarfiles'}}, $jarfile );
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

    if ( $num_elements >= 1 ) {
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
sub clear
  {
    my $self = shift;
	
	$self->main_jarfile(undef);
	$self->tag(undef);
	$self->support_jarfiles(undef);
	$self->valid(FALSE);
	
	return;
  }
  
#=============================================================================
sub data_types
  {
    # See if there is a way to read this from file.
    my %data_fields = (
		               'tag'              => undef,
					   'main_jarfile'     => undef,
					   'support_jarfiles' => undef,
					   'valid'            => FALSE,
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
sub get_number_jarfiles
  {
    my $self = shift;
	if ( not defined($self->support_jarfiles()) ) { return -1; }
	return scalar(@{$self->support_jarfiles()});
  }

#=============================================================================
sub get_OOTB_flows
  {
    my $self   = shift;
	my $result = [];
	
	if ( not defined( $self->support_jarfiles() ) ) { return $result; }
	foreach ( @{$self->support_jarfiles()} ) {
	  push ( @{$result}, $_->name() );
	}
	
	return $result;
  }
  
#=============================================================================
sub mark_duplicates
  {
    my $self = shift;
	my @objs = @{ $self->support_jarfiles() };
	
	for ( my $loop1 = 0; $loop1 < scalar(@objs); ++$loop1 ) {
	  for ( my $loop2 = $loop1 + 1; $loop2 < scalar(@objs); ++$loop2 ) {
	    if ( $objs[$loop2]->duplicate() != TRUE ) {
	      $objs[$loop1]->mark_duplicate( $objs[$loop2] );
	      &csl_print_debug_output( "Testing item #$loop1 against item #$loop2 for duplication --> << ". $objs[$loop1]->duplicate() ." >>" );
		}
		if ( $objs[$loop1]->name() eq $objs[$loop2]->name() ) {
	      &csl_print_debug_output( "Testing item #$loop1 against item #$loop2 for consistency --> << ". $objs[$loop1]->consistent() ." >>" );		
		  $objs[$loop1]->mark_consistent( $objs[$loop2] );
		}
	  }
	}
	return;
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

	my $tagID = $node->getAttribute('tag');
	if ( defined($tagID) ) { $self->tag($tagID); }
	
	my $specific_nodes = &parse_nodes( $node, 'jarfile', { 'count'   => 0,
										                   'compare' => GEQ, } );
	if ( scalar(@{$specific_nodes}) < 1 ) {
	  $self->name($node->textContent);
	} else {
	  $self->support_jarfiles([]) if ( not defined($self->{'support_jarfiles'}) );
	  foreach (@{$specific_nodes}) {
	    my $jarfile = HP::SupportMatrix::Jarfile->new();
        $jarfile->parse( $_ );
	    if ( $jarfile->type() =~ m/delivery/i ) {
	      $self->main_jarfile($jarfile->name());
		  next;
	    }
        $self->add_item( $jarfile );
	  }
	  $self->mark_duplicates();
	}
	
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
	
	if ( not defined($self->main_jarfile()) || not defined($self->tag()) ) {
	  $self->valid(FALSE);
	  return;
	}
	
	$self->valid(TRUE);
	
	return;
  }

1;