package HP::CSL::DAO::Data;

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

    $VERSION = 1.00;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
	                        'HP::CheckLib'                 => undef,
							'HP::Support::Configuration'   => undef,
							'HP::Support::Os'              => undef,
							'HP::Support::Object::Tools'   => undef,
							'HP::Array::Constants'         => undef,
							'HP::Array::Tools'             => undef,
							'HP::String::Constants'        => undef,
							
							'HP::Path'                     => undef,
							'HP::FileManager'              => undef,
							'HP::Os'                       => undef,
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_csl_dso_data_pm'} ||
                 $ENV{'debug_csl_dso_modules'} ||
				 $ENV{'debug_csl_modules'} ||
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
sub __get_parameter
  {
	my $result     = undef;
    my $self       = shift;
	my $section_id = shift;
	my $param      = shift || return $result;
	my $other_sections = shift || [];

	$section_id .= '_section';
	my $evalstr = "\$result = \&get_from_configuration(\"$param\", FALSE, \$self->$section_id()->configuration());";
	eval "$evalstr";
	return undef if ( $@ );
	return $result if ( $@ || not defined($result) );
	my $copy = $self->expand($result, $other_sections);
	
	return $copy;
  }
  
#=============================================================================
sub __simple_replace_items
  {
    my $self = shift;
	
	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'item', undef, 'begin_marker', undef, 'end_marker', undef ], @_);
    } else {
	  $inputdata = $_[0];
	}
	
    return (undef, FALSE) if ( scalar(keys(%{$inputdata})) == 0 );
	my $item = $inputdata->{'item'};

	return (undef, FALSE) if ( not defined($item) );
	
	my $bm = $inputdata->{'begin_marker'} || TEXT_SUBSTITUTION_BEGIN_MARKER;
	my $em = $inputdata->{'end_marker'}   || TEXT_SUBSTITUTION_END_MARKER;
	
	return &allow_substitution($item, $bm, $em);
  }

#=============================================================================
sub add_parameter
  {
    my $result     = FALSE;
    my $self       = shift;
	my $section_id = shift;
	my $data       = shift;
	
	my $existence = &get_from_configuration("$section_id", $self->get_parameters());
	if ( not defined($existence) ) {
	  &save_to_configuration({'table' => $self->get_parameters(), 'data' => [ "$section_id", $data ]});
	}

	return TRUE;
  }
  
#=============================================================================
sub data_types
  {
    my $self         = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
					   'supportMatrix' => 'c__HP::SupportMatrix__',
					   'build_section' => 'c__HP::CSL::DAO::Section__',
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
sub expand
  {
    my $self = shift;
	my $orig = shift;
	my $other_sections = shift || [];
	
	# Configuration    uses {}
	# OS environment   uses %% (windows) or ${ } (linux)
	# PERL environment uses $ENV{ }
	
	my $copy = &clone_item($orig);
	
	my $needs_repeat = FALSE;
	do {
	  ($copy, $needs_repeat) = $self->replace_configuration_items($copy, $other_sections);
	} while ( defined($needs_repeat) && $needs_repeat eq TRUE );
	
	$needs_repeat = FALSE;
	do {
	  if ( &os_is_windows_native() eq TRUE ) {
	    ($copy, $needs_repeat) = $self->replace_windows_environment_items($copy);
	  } elsif ( &os_is_linux() eq TRUE ) {
	    ($copy, $needs_repeat) = $self->replace_linux_environment_items($copy);
	  }
	} while ( defined($needs_repeat) && $needs_repeat eq TRUE );
	
	$needs_repeat = FALSE;
	do {
	  ($copy, $needs_repeat) = $self->replace_perl_environment_items($copy);
	} while ( defined($needs_repeat) && $needs_repeat eq TRUE );
	
	return $copy;	
  }

#=============================================================================
sub get_build_parameter
  {
    my $self  = shift;
	my $param = shift || return undef;
	my $other_sections = shift || [];

	return $self->__get_parameter('build', $param, $other_sections);
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
	$self->os(&get_os_type());
	return $self;  
  }

#=============================================================================
sub print
  {
    my $self = shift;
	return;
  }

#=============================================================================
sub replace_configuration_items
  {
    my $self = shift;
	my $item = shift;
	my $other_sections = shift || [];
	
	return undef if ( not defined($item) );
	
	my $config_sections = [];
	push(@{$config_sections}, &get_configuration());
	
	my @key_types = keys(%{$self->data_types()});
	foreach ( @key_types ) {
	  push( @{$config_sections}, $self->{"$_"}->configuration() ) if ( &is_type($self->{"$_"}, 'HP::CSL::DAO::Section') eq TRUE );
	}
	foreach ( @{$other_sections} ) {
	  push( @{$config_sections}, $_ );
	}
	
	my $changed = FALSE;
	my $ref_type = ref($item);
	
	if ( $ref_type eq '' ) {
	  &__print_debug_output("(B) $item ++++", __PACKAGE__) if ( $is_debug );
	  my $begin_marker = &convert_to_regexs('{');
	  my $end_marker   = &convert_to_regexs('}');
	  #my $begin_marker = &convert_to_regexs(TEXT_SUBSTITUTION_BEGIN_MARKER);
	  #my $end_marker   = &convert_to_regexs(TEXT_SUBSTITUTION_END_MARKER);
		
      return ($item, $changed) if ( $item !~ m/$begin_marker/ );
      return ($item, $changed) if ( $item !~ m/$end_marker/ );
	  
	  if ( $item =~ m/(\S*)$begin_marker(\S*)$end_marker(\S*)/ ) {
        my $begin = $1;
        my $end   = $3;
        my $replacement = $2;

        my $substitution = undef;
		my $replaced = FALSE;
		foreach ( @{$config_sections} ) {
		  $substitution = &get_from_configuration($replacement, TRUE, $_);
		  if ( defined($substitution) ) {
		    $item =~ s/${begin_marker}${replacement}${end_marker}/${substitution}/;
			$replaced = TRUE;
			last;
		  }
		}
		
		if ( $replaced eq FALSE ) {
		  $item =~ s/${begin_marker}${replacement}${end_marker}//;
		}
		$changed = TRUE;
	  }
	  &__print_debug_output("(A) $item ++++", __PACKAGE__) if ( $is_debug );
    } elsif ( $ref_type =~ m/scalar/i ) {
	  $item = ${$item};
	  ($item, $changed) = $self->replace_configuration_items($item, $other_sections);
	} elsif ( $ref_type =~ m/^array/i ) {
	  my $has_changed = FALSE;
	  for ( my $loop = 0; $loop < scalar(@{$item}); ++$loop ) {
	    ($item->[$loop], $has_changed) = $self->replace_configuration_items($item->[$loop], $other_sections);
	    $changed = TRUE if ( defined($has_changed) && $has_changed eq TRUE );
	  }
	} elsif ( $ref_type =~ m/hash/i ) {
	  my $has_changed = FALSE;
	  my @keys = keys(%{$item});
	  for ( my $loop = 0; $loop < scalar(@keys); ++$loop ) {
	    ($item->{$keys[$loop]}, $has_changed) = $self->replace_configuration_items($item->{$keys[$loop]}, $other_sections);
	    $changed = TRUE if ( defined($has_changed) && $has_changed eq TRUE );
	  }
	}

	return ($item, $changed);
  }

#=============================================================================
sub replace_linux_environment_items
  {
    my $self = shift;
	my $item = shift;
	
	return $self->__simple_replace_items({'item' => $item, 'begin_marker' => '${', 'end_marker' => '}'});
  }
  
#=============================================================================
sub replace_perl_environment_items
  {
    my $self = shift;
	my $item = shift;
	
	return $self->__simple_replace_items({'item' => $item, 'begin_marker' => '$ENV{', 'end_marker' => '}'});
  }
  
#=============================================================================
sub replace_windows_environment_items
  {
    my $self = shift;
	my $item = shift;
	
	return $self->__simple_replace_items({'item' => $item, 'begin_marker' => '%', 'end_marker' => '%'});
  }

#=============================================================================
1;