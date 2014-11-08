package HP::Stream::IO;

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

	use parent qw(HP::Stream);
	
    use vars qw(
                $VERSION
                $is_debug
                $is_init

                $module_require_list
                $module_request_list

                $broken_install

				@ISA
                @EXPORT
				$comment
               );

    $VERSION = 0.75;

    @EXPORT  = qw (
                  );

    $module_require_list = {
	                        'Tie::File'                    => undef,
							'Fcntl'                        => undef,
	                        'Text::Format'                 => undef,
							'Storable'                     => undef,
							
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Screen'          => undef,
							'HP::Support::Object'          => undef,
							'HP::Support::Object::Tools'   => undef,
	                        'HP::CheckLib'                 => undef,
							
							'HP::Array::Constants'         => undef,
							'HP::Array::Tools'             => undef,
							'HP::Stream::Constants'        => undef,
							'HP::Stream::IOFlags'          => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_stream_io_pm'} ||
				 $ENV{'debug_stream_modules'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );

    $broken_install = 0;
	$comment        = '#';
	
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
sub __output
  {
    my $self   = shift;
    my $data   = shift || return;
	my $marker = shift;
	
	my $glob = $self->fileglob();

	if ( defined($glob) ) {
	  foreach ( @{$data} ) {
	    if ( defined($marker) ) {
	      &print_msg("$_", $marker, $glob) if ( defined($_) );
	    } else {
	      print $glob "$_\n" if ( defined($_) );
	    }
	  }
	}
	
	# Handle rotation logging...
	$self->rotate() if ( ( $self->is_rotating() eq TRUE ) && ( $self->should_rotate() eq TRUE ) );
	return;
  }
  
#=============================================================================
sub __partition_msg
  {
    my $self = shift;
	my $data = shift || return;
	
	my $screen_limit   = $HP::Support::Screen::TermIOCols;
    my $text_formatter = Text::Format->new(
	                                       {
											'columns'  => $screen_limit,
										   }
										  );
	$text_formatter->firstIndent(0);
    my @data = split('\n', $text_formatter->format($data));
	return \@data;
  }
  
#=============================================================================
sub clear
  {
    my $self = shift;
	
	return if ( $self->is_system() eq TRUE );
	
	$self->close();
	
	$self->SUPER::clear();	
	$self->fileglob(undef);
	return;
  }
  
#=============================================================================
sub close
  {
    my $self = shift;

	return CLOSE_DONT_CARE if ( not defined($self->fileglob()) );
	return FALSE if ( ( $self->is_system() eq TRUE ) );
	
	if ( ( $self->is_rotating() eq TRUE ) &&
	     ( $self->should_rotate() eq TRUE ) ) {
	  $self->rotate();
	}
	
	return FALSE if ( $self->is_system() eq TRUE );
	
	$self->fileglob()->close();
	$self->fileglob(undef);
	return TRUE;
  }

#=============================================================================
sub convert_output
  {
    my $self     = shift;
	my $specific = { 'active' => { &FORWARD => [ 'bool2string', __PACKAGE__ ], &BACKWARD => [ 'string2bool', __PACKAGE__ ] } };
	
	$specific = &HP::Support::Hash::__hash_merge($specific, $self->SUPER::convert_output());
	return $specific;
  }
  
#=============================================================================
sub data_types
  {
    my $self = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
					   'fileglob' => undef,
					   'flags'    => 'c__HP::Stream::IOFlags__',
					   'active'   => FALSE,
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
sub get_stream_attribute
  {
    my $self = shift;
	my $attr = shift || return FALSE;
	
	return FALSE if ( ( not defined($self->flags()) ) ||
	                  ( not exists($self->flags()->{"$attr"}) ) );
	
	return $self->flags()->{"$attr"};
  }

#=============================================================================
sub flush
  {	
    my $self = shift;
	if ( ( $self->active() eq TRUE ) &&
	     ( defined($self->fileglob())) ) {
	  $self->fileglob()->flush();
	}
	return;
  }

#=============================================================================
sub force_xml_output
  {
    my $self     = shift;
	my $specific = [ 'fileglob' ];
	
	$specific = &set_union($specific, $self->SUPER::force_xml_output());
	return $specific;
  }
  
#=============================================================================
sub get_comment
  {
    my $self = shift;
    return $HP::Stream::IO::comment;
  }

#=============================================================================
sub hysteresis
  {
    my $self = shift;
	return $self->flags()->{'buffer_limits'};
  }
  
#=============================================================================
sub is_comment(@)
  {
    my $self  = shift;
    my $input = shift || return TRUE;
    return TRUE if ( &valid_string() eq FALSE );

    $input = &chomp_r("$input");
	return TRUE if ( substr($input, 0, 1) eq $self->get_comment() );
    return FALSE;
  }

#=============================================================================
sub is_rotating
  {
    my $self = shift;
	return $self->get_stream_attribute('rotating');
  }
  
#=============================================================================
sub is_system
  {
    my $self = shift;
	return $self->get_stream_attribute('system');
  }

#=============================================================================
sub maximum_size
  {
    my $self = shift;
	return $self->flags()->maximum_size();
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
sub output
  {
    my $self = shift;
	return if ( $self->valid() eq FALSE );
	
	my $content = shift || return;
	
	my ( $data, $marker, $location ) = ($content, INFO, APPEND);
	
	$marker   = shift if ( scalar(@_) > 0 );
    $location = shift if ( scalar(@_) > 0 );
	
	if ( ref($content) =~ m/hash/i ) {
	  $data     = $content->{'msg'} if ( exists($content->{'msg'}) );
	  $marker   = $content->{'prefix'} if ( exists($content->{'prefix'}) );
	  $location = $content->{'location'} if ( exists($content->{'location'}) );
	}
		
	$data = $self->__partition_msg($data);
	$self->__output($data, $marker);
	return;
  }

#=============================================================================
sub print
  {
    my $self = shift;
	
	$self->SUPER::print();
	return;
  }

#=============================================================================
sub raw_output
  {
    my $self = shift;
	return if ( $self->valid() eq FALSE );

	my $content = shift || return;
	my ( $data, $location ) = ($content, APPEND);
	
    $location = shift if ( scalar(@_) > 0 );
	
	if ( ref($content) =~ m/hash/i ) {
	  $data     = $content->{'msg'} if ( exists($content->{'msg'}) );
	  $location = $content->{'location'} if ( exists($content->{'location'}) );
	}

	$data = &convert_to_array($data, TRUE);
	$self->__output($data);
	return;
  }

#=============================================================================
sub rotate
  {	
    my $self = shift;
	my $size = $self->maximum_size();
	  
	if ( ( $size > -1 ) ) {
	  my @lines = ();
	  tie @lines, 'Tie::File', $self->fileglob();
	  if ( scalar(@lines) > $size ) {
		
	    my $difference = scalar(@lines) - $size;
		while ( $difference > 0 ) {
		  shift(@lines);
		  --$difference;
		}
	  }
	  untie @lines;
	}
  }

#=============================================================================
sub set_comment
  {
    my $self    = shift;
	my $comment = shift || return;
	
	$HP::Stream::IO::comment = $comment;
	return;
  }

#=============================================================================
sub set_rotating
  {
    my $self  = shift;
	my $yesno = shift;
	
	$self->set_stream_attribute('rotating', $yesno);

	$self->flags()->{'maximum_size'}  = shift if ( scalar(@_) > 0 );
	$self->flags()->{'buffer_limits'} = shift if ( scalar(@_) > 0 );
	return;
  }

#=============================================================================
sub set_stream_attribute
  {
    my $self  = shift;
	my $attr  = shift || return;
	my $value = shift || TRUE;
	
	return if ( ( not defined($self->flags()) ) ||
	            ( not exists($self->flags()->{"$attr"}) ) );
	
	$self->flags()->{"$attr"} = $value;
    return;
  }
  
#=============================================================================
sub set_system
  {
    my $self = shift;
	$self->set_stream_attribute('system', @_);
	return;
  }
  
#=============================================================================
sub should_rotate
  {	
    my $self = shift;
	my $size = $self->flags()->maximum_size();
	
	my $result = FALSE;
	
	if ( ( $size > -1 ) ) {
	  my @lines = ();
	  tie @lines, 'Tie::File', $self->fileglob();
	  if ( scalar(@lines) > $size + $self->hysteresis() ) {
	    $result = TRUE;
		untie @lines;
	  }
    }
    return $result;
  }
  
#=============================================================================
sub slurp
  {	
    my $self = shift;
	my $data = undef;
	
	if ( $self->valid() eq FALSE ) {
	  if ( defined($self->get_path()) ) {
	    # Need to be coded
	  }
	} else {
	  my @lines = ();
	  my $mode = O_RDWR;
	  $mode = O_RDONLY if ( &is_type($self, 'HP::Stream::IO::Input') eq TRUE );
	  
	  if ( (not defined($self->fileglob())) &&
	       (defined($self->entry()->path())) ) {
		$self->open();   
	  }
	  tie @lines, 'Tie::File', $self->fileglob(), mode => $mode;
	  $data = &clone_item(\@lines);
	  untie @lines;
	  $self->close();
	}
 	return $data;
  }

#=============================================================================
sub write_as_attributes
  {
    my $self     = shift;
	my $specific = [ 'active' ];
	
	$specific = &set_union($specific, $self->SUPER::write_as_attributes());
	return $specific;
  }
  
#=============================================================================
1;