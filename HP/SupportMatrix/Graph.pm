package HP::SupportMatrix::Graph;

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
	                        'File::Basename'               => undef,
							'GD::Graph'                    => undef,
							'GD::Graph::Data'              => undef,
							
	                        'HP::RegexLib'                 => undef,
							'HP::ArrayTools'               => undef,
							'HP::StreamManager'            => undef,
							'HP::FileManager'              => undef,
							'HP::CSLTools::Constants'      => undef,
							'HP::CSLTools::Common'         => undef,
							
							'HP::SupportMatrix::Constants' => undef,
							'HP::SupportMatrix::Tools'     => undef,							
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_supportmatrix_graph_pm'} ||
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
use constant DEFAULT_HSIZE => 800;
use constant DEFAULT_WSIZE => 600;

#=============================================================================
sub add_data_item
  {
    my $self     = shift;
	my $key      = shift || return;
	my $value    = shift;
	my $defvalue = shift;
	my $type     = shift || '';
	
	my @known_types = ( '', 'SCALAR', 'ARRAY', 'HASH' );
	if ( not &set_contains($type, \@known_types) ) {
	  &csl_print_output("Unknown type << $type >> specified.  Skipping data item for graph!", WARNING);
	  return;
	}
	
	if ( not defined($value) ) { $value = $defvalue; }
	
	my $incoming_type = ref($value);
	if ( $incoming_type ne $type ) {
	  &csl_print_output("Inconsistent types found.  Requested << $type >> but sent << $incoming_type >>.  Skipping data item for graph!", WARNING);
	  return;
	}
	
	$self->set_option( $key, $value );
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
sub data_types
  {
    # See if there is a way to read this from file.
    my %data_fields = (
	                   'filename'     => undef,
					   'xdata'        => undef,
					   'ydata'        => undef,
					   'zdata'        => undef,
					   'graph_opts'   => undef,
					   'graph_output' => undef,
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
sub make_graph
  {
    my $self = shift;
	
	my $graphtype       = shift;
	my $graph           = undef;

	$self->set_data($self->graph_opts());
	
	delete($self->graph_opts()->{'xdata'});
	delete($self->graph_opts()->{'ydata'});
	delete($self->graph_opts()->{'zdata'});
	
	my $data = GD::Graph::Data->new([ $self->xdata(), $self->ydata() ]);
	
	my $hsize = $self->graph_opts()->{'hsize'} || DEFAULT_HSIZE;
	my $wsize = $self->graph_opts()->{'wsize'} || DEFAULT_WSIZE;
	
	eval "use GD::Graph::$graphtype; \$graph = GD::Graph::$graphtype->new($hsize, $wsize);";
	if ( $@ ) {
	  &csl_print_output("Unable to make graph of type << $graphtype >> at this time...", WARNING);
	  return $graph;
	}
	
	while ( my ($k, $v) = each(%{$self->graph_opts()}) ) {
	  $graph->set( $k => $v );
	}
	
	my $plot = $graph->plot($data);
	$self->graph_output($plot);
	$self->save_plot( $plot );
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
sub save_plot
  {
    my $self = shift;
	my $plot = shift || return FALSE;
	
	#my $plot_handle = '__IMG__';
	my $filename = $self->filename();
	
	if ( not defined($filename) ) {
	  &csl_print_output('No output graph saved since no filename provided');
	  return FALSE;
	}

	my $parentdir = File::Basename::dirname("$filename");
	if ( not &does_directory_exist("$parentdir") ) { &make_recursive_dirs("$parentdir"); }
	
	open( __IMG__, ">$filename" ) || return FALSE;
	binmode __IMG__;
	print __IMG__ $plot->png();
	close __IMG__;
	
	if ( &does_file_exist("$filename") ) {
	  return TRUE;
	}
	return FALSE;
  }
  
#=============================================================================
sub set_data
  {
    my $self        = shift;
	my $graphparams = shift;
	
    if ( exists($graphparams->{'xdata'}) ) {
	  $self->xdata($graphparams->{'xdata'});
	}
	
	if ( exists($graphparams->{'ydata'}) ) {
	  $self->ydata($graphparams->{'ydata'});
	}

	if ( ( exists($graphparams->{'options'}) ) && ( ref( $graphparams->{'options'} ) =~ m/hash/i ) ) {
	  foreach my $gphopts ( keys %{$graphparams->{'options'}} ) {
	    $self->set_option( $gphopts, $graphparams->{"$gphopts"} );
	  }
	}
    return;
  }
  
#=============================================================================
sub set_option
  {
    my $self  = shift;
	my $grkey = shift;
	my $grval = shift;
	
	if ( not defined($grkey) ) { return; }
	$self->{'graph_opts'} = {} if ( not defined($self->{'graph_opts'}) );
    $self->{'graph_opts'}->{"$grkey"} = $grval;
	return;
  }
  
#=============================================================================
1;