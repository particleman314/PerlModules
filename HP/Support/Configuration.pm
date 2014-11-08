package HP::Support::Configuration;

################################################################################
# Copyright (c) 2013 HP.   All rights reserved
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

use warnings;
use strict;
use diagnostics;

#=============================================================================
BEGIN
  {
    use Exporter();

    use FindBin;
    use lib "$FindBin::Bin/../..";

    use vars qw(
				$VERSION
				$is_debug
				$is_init

				$module_require_list
                $module_request_list

				$broken_install

                %__most_used_configs
                $internal_cfg
				$allow_caching
				$allow_substitution
				
				@ISA
				@EXPORT
               );

    $VERSION    = 0.90;

	@ISA = qw(Exporter);
    @EXPORT = qw(
				 &allow_substitution
	             &clear_cache
				 &clear_configuration
				 &disable_caching
				 &disable_substitution
				 &enable_caching
				 &enable_substitution
	             &get_configuration
                 &get_from_configuration
				 &normalize_configuration_path
				 &remove_from_configuration
                 &save_to_configuration
				 &set_caching
				 &set_substitution
                 &show_configuration
				 
				 SPLITTERS
                );

    $module_require_list = {
							'Config'                                => undef,

							'HP::Constants'                         => undef,
							'HP::Support::Base'                     => undef,
							'HP::Support::Hash'                     => undef,
							'HP::Support::Module'                   => undef,
							'HP::Support::Module::Tools'            => undef,
							'HP::Support::Object::Tools'            => undef,
							'HP::Support::Configuration::Constants' => undef,
							
							'HP::CheckLib'                          => undef,
							'HP::String'                            => undef,
							'HP::String::Constants'                 => undef,
							'HP::Array::Tools'                      => undef,
							
						   };
    $module_request_list = {
	                       };

    $internal_cfg        = {};
    %__most_used_configs = ();
	$allow_caching       = 0;
	$allow_substitution  = 0;

    $is_init  = 0;
    $is_debug = (
			$ENV{'debug_support_configuration_pm'} ||
			$ENV{'debug_support_modules'} ||
			$ENV{'debug_hp_modules'} ||
			$ENV{'debug_all_modules'} || 0
		);

    $broken_install = 0;

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
	    if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "REQUIRED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug ); 
          eval "use $usemod;";
        }
	    if ( $@ ) {
	      print STDERR "Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
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
          print STDERR "REQUESTED [". __PACKAGE__ ."]:: use $usemod $module_request_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_request_list->{$usemod};";
        } else {
          print STDERR "REQUESTED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug );
          eval "use $usemod;";
        }
        if ( $@ ) {
          print STDERR "Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
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
my $depth       = 0;

#=============================================================================
# Examples if ways to use this configuration module...
#
# 1) (k,v) => (+key+, +value+);
# 2) (k,v) => (+{{{subst_text}}}+, +value+);               # Here substitution markers are {{{, }}}
# 3) (k,v) => (+{{{subst_text}}}->key+, +value+);
# 4) (k,v) => (+[eval_func]+, +value+);                    # Here evaluation markers are [, ]
# 5) (k,v) => (+[eval_func]->key+, +value+);
#
#=============================================================================

#=============================================================================
sub __abs_to_rel_string_coordinate($$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );

    my ($data, $x, $y) = @_;
	my $new_y = $y - $x + 1;
	return substr($data, $x, $new_y);
  }

#=============================================================================
sub __extract_root($)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
    
  }
  
#=============================================================================
sub __build_keypath($)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	
	my $path     = undef;

    my $section  = $_[0] || goto __END_OF_SUB;
	my $basis    = $_[1] || 'internal_cfg';
	
    my @drill   = split(SPLITTER_ARROW,$section);
	
	&__print_debug_output("Drill sections --> @drill",__PACKAGE__) if ( $is_debug );
	
    my $results = undef;
	if ( ref($basis) =~ m/hash/i ) {
	  $results = $basis;
	} else {
      $path    = "\$$basis";
	  eval "\$results = \$$basis;";
	}
	
	if ( defined($results) ) {
      if ( scalar(@drill) ) {
        while ( scalar(@drill) ) {
          if ( exists($results->{"$drill[0]"}) ) {
            $results = $results->{"$drill[0]"};
			$path .= "->{\"$drill[0]\"}";
            shift (@drill);
          } else {
            $results = undef;
            last;
		  }
        }
      }
	}
	
  __END_OF_SUB:
	return $path;
  }
  
#=============================================================================
sub __do_substitution($$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	
	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'content',      undef,
	                                        'replacement',  undef,
											'substitution', undef,
	                                        'begin',        undef,
											'end',          undef,
											'begin_marker', undef,
											'end_marker',   undef, ], @_);
    } else {
	  $inputdata = $_[0];
	}
	
	# No input, return FALSE exit status
    goto __END_OF_SUB if ( scalar(keys(%{$inputdata})) == 0 );
	
    my $content      = $inputdata->{'content'};
	my $replacement  = $inputdata->{'replacement'};
	my $substitution = $inputdata->{'substitution'};
	my $begin        = $inputdata->{'begin'};
	my $end          = $inputdata->{'end'};

    my $begin_marker = $inputdata->{'begin_marker'};
    my $end_marker   = $inputdata->{'end_marker'};
	
	if ( ( length($begin) > 0 ) && ( length($end) > 0 ) ) {
	  $content =~ s/\Q${begin_marker}\E\s*${replacement}\s*\Q${end_marker}\E/${substitution}/;
	}
	if ( ( length($begin) > 0 ) && ( length($end) == 0 ) ) {
	  $content =~ s/\Q${begin_marker}\E\s*${replacement}\s*\Q${end_marker}\E/${substitution}/;
	}
	if ( ( length($begin) == 0 ) && ( length($end) > 0 ) ) {
	  $content =~ s/\Q${begin_marker}\E\s*${replacement}\s*\Q${end_marker}\E/${substitution}/;
	}
	if ( ( length($begin) == 0 ) && ( length($end) == 0 ) ) {
	  $content =~ s/\Q${begin_marker}\E\s*${replacement}\s*\Q${end_marker}\E/${substitution}/;
	}
	
  __END_OF_SUB:
	return $content;
  }
  
#=============================================================================
sub __initialize()
  {
    if ( not $is_init ) {
      $is_init = $local_true;
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
sub __is_configuration_cached($)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );

    return $local_true if exists($__most_used_configs{$_[0]});
	return $local_false;
  }

#============================================================================
sub __make_cfg_entries($;$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	
    my @keys   = ();
    my @values = ();

	goto __END_OF_SUB if ( scalar(@_) < 1 );
	
    my $refinput = ref($_[0]);
	
    if ( $refinput =~ m/^scalar/i || $refinput eq '' ) {
      push ( @keys , "$_[0]" );
      push ( @values, ( defined($_[1]) ) ? $_[1] : undef );
    } elsif ( $refinput =~ m/^array/i ) { 
      @keys   = @{$_[0]};
	  @values = @{$_[1]} if ( defined($_[1]) );
	  @values[scalar(@keys) - 1] = undef if ( not defined($_[1]) );
    } elsif ( $refinput =~ m/hash/i ) {
      @keys   = keys(%{$_[0]});
      @values = values(%{$_[0]});
    } 

  __END_OF_SUB:
    return (\@keys, \@values);
  }

#=============================================================================
sub __parser($$$)
  {
    my $data = $_[0];
	my $bm   = $_[1];
	my $em   = $_[2];
	
	my $match = $local_false;
	
	my $before_b_marker_position = 0;
	my $after_b_marker_position = 0;
	
	# Need to find innermost possible match then substitute.  At this point
	# redo and try to work from the inside out
	my $idx = index($data, $bm, $before_b_marker_position);
	while ( $idx > -1 ) {
	  $before_b_marker_position = $idx;
	  $after_b_marker_position = $before_b_marker_position + 1;
	  $idx = index($data, $bm, $after_b_marker_position);
	}
	
	my $e_marker_position = $after_b_marker_position;
	
	$idx = index($data, $em, $e_marker_position);
	if ( $idx > -1 ) {
	  $e_marker_position = $idx;
	  $match = $local_true;
	}
	
  __END_OF_SUB:
  
	my ($beginning, $middle, $ending) = ( undef, undef, undef );
	if ( $match eq $local_true ) {
	  $beginning = &__abs_to_rel_string_coordinate($data, 0, $before_b_marker_position - 1);
	  $middle    = &__abs_to_rel_string_coordinate($data, $before_b_marker_position + length($bm), $e_marker_position - 1);
	  $ending    = &__abs_to_rel_string_coordinate($data, $e_marker_position + length($em), length($data));
	}
	
	return ($beginning, $middle, $ending, $match);
  }
  
#=============================================================================
sub __set_debug($)
  {
    if ( $_[0] eq $local_true ) {
	  $is_debug = $local_true;
	  eval "use Data::Dumper;";
	  eval "\$Data::Dumper::Sortkeys = 1;";
	}
  }
  
#=============================================================================
sub __substitute_proc($$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	
    my $content      = $_[0];
    my $begin_marker = PROC_SUBSTITUTION_BEGIN_MARKER;
    my $end_marker   = PROC_SUBSTITUTION_END_MARKER;
    my $changed      = $local_false;
  
    goto __END_OF_SUB if ( $content !~ m/\Q$begin_marker\E/ );
    goto __END_OF_SUB if ( $content !~ m/\Q$end_marker\E/ );
	
	my $qm_begin_marker = &convert_to_regexs($begin_marker);
	my $qm_end_marker   = &convert_to_regexs($end_marker);
	
    while ( $content =~ m/(\S*)\[\s*(\S*)\s*\](\S*)/ ) {
      my $substitution = undef;
      my $begin = $1;
      my $end   = $3;

      my $method = $2;
      &__print_debug_output("Method --> << $method >>",__PACKAGE__) if ( $is_debug );
	  
	  my $evalstr = undef;
	  $evalstr = "\$substitution = \&$method;";

	  {
	    no warnings;
	    eval "$evalstr";
      }
	  
      if ( (not $@) && ( defined($substitution) ) ) {
	    $content = &__do_substitution($content, $method, $substitution, $begin, $end, $begin_marker, $end_marker);
        $changed = $local_true;
	  } else {
	    &__print_output("Found 'error' applying function : << $method >>", __PACKAGE__);
	    return ($content, $local_false);	  
	  }
	}
	
  __END_OF_SUB:
	return ($content, $changed);
  }

#=============================================================================
sub __try_substitute_from_main($$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );

    my $data    = 'main::'.$_[0];
	my $handler = $_[1];
	
	my $success      = $local_false;
	my $substitution = undef;
	
    &__print_debug_output("Data --> << $data >>",__PACKAGE__) if ( $is_debug );

	my $evalstr = undef;
    if ( defined($handler) ) {
	  $evalstr = "\$substitution = \&{\$handler}('$data');";
    } else {
	  $evalstr = "\$substitution = \"\$$data\";";
	}

    {
	  no warnings;
	  eval "$evalstr";
      if ( ! $@ ) {
		$success = $local_true;
      }
	}
	
	return ( $substitution, $success );
  }
  
#=============================================================================
sub __try_substitute_from_configuration($$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	
    my $data    = $_[0];
	my $handler = $_[1];
	
	my $success = $local_false;
    my $substitution = &get_from_configuration($data, $local_true);
	
	if ( not defined($substitution) ) {
      &__print_debug_output("Data --> << $data >>",__PACKAGE__) if ( $is_debug );

	  my $evalstr = undef;
      if ( defined($handler) ) {
	    $evalstr = "\$substitution = \&{\$handler}('$data');";
      }

	  if ( defined($evalstr) ) {
	    no warnings;
	    eval "$evalstr";
		if ( ! $@ ) {
		  $success = $local_true;
		}
      }
    } else {
	  $success = $local_true;
	}
	
	return ( $substitution, $success );
  }
  
#=============================================================================
sub __substitute_text($$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	
	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'content',      undef,
											'begin_marker', undef,
											'end_marker',   undef,
											'handler',      undef,], @_);
    } else {
	  $inputdata = $_[0];
	}
	
	my $content = undef;
	my $changed = $local_false;
	
	# No input, return FALSE exit status
    goto __END_OF_SUB if ( scalar(keys(%{$inputdata})) == 0 );
	
    $content         = $inputdata->{'content'};
	my $begin_marker = $inputdata->{'begin_marker'} || TEXT_SUBSTITUTION_BEGIN_MARKER;
	my $end_marker   = $inputdata->{'end_marker'}   || TEXT_SUBSTITUTION_END_MARKER;
	my $handler      = $inputdata->{'handler'}      || undef;

    goto __END_OF_SUB if ( $content !~ m/\Q$begin_marker\E/ );
    goto __END_OF_SUB if ( $content !~ m/\Q$end_marker\E/ );

	my $substitution = undef;
	my ( $begin, $replacement, $end, $found_match ) = &__parser($content, $begin_marker, $end_marker);
	  
	if ( $found_match eq $local_true ) {
	  
	  if ( &valid_string($replacement) eq $local_true ) {
	    my ($substitution, $success_substitution) = &__try_substitute_from_configuration($replacement, $handler);
		
		if ( $success_substitution eq $local_false ) {
	      ($substitution, $success_substitution) = &__try_substitute_from_main($replacement, $handler);
		}
	  
        if ( ( defined($substitution) ) && ( $success_substitution eq $local_true ) ) {
	      $content = &__do_substitution($content, $replacement, $substitution, $begin, $end, $begin_marker, $end_marker);
		  $changed = $local_true;
	    }
	  } else {
	    $changed = $local_true;
	    $content = join('', $begin, $end);
	  }
	}
		
  __END_OF_SUB:
	return ($content, $changed);
  }

#=============================================================================
sub allow_substitution($$$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );

	# Manage the input data to conform to a hash for query
	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'content',      undef,
											'begin_marker', undef,
											'end_marker',   undef,
											'handler',      undef,], @_);
    } else {
	  $inputdata = $_[0];
	}
	
	my $content = undef;
	my $changed = $local_false;
	
	# No input, return FALSE exit status
    goto __END_OF_SUB if ( scalar(keys(%{$inputdata})) == 0 );
	
    $content         = $inputdata->{'content'};
	my $begin_marker = $inputdata->{'begin_marker'} || TEXT_SUBSTITUTION_BEGIN_MARKER;
	my $end_marker   = $inputdata->{'end_marker'}   || TEXT_SUBSTITUTION_END_MARKER;
	my $handler      = $inputdata->{'handler'}      || undef;

	goto __END_OF_SUB if ( &valid_string($content) eq $local_false );
	
	my $reftype = ref($content);

	if ( $reftype eq '' ) {
	  my $changed_text = $local_false;
	  my $changed_proc = $local_false;
	  
	  do {
	    ($content, $changed_text) = &__substitute_text($content, $begin_marker, $end_marker, $handler);
	    ($content, $changed_proc) = &__substitute_proc($content);
		++$changed if ( ( $changed_text || $changed_proc ) eq $local_true && ( $changed < 1 ) );
	  } while ( ( $changed_text || $changed_proc ) eq $local_true );
	  
	  goto __END_OF_SUB;
	} elsif ( $reftype =~ m/array/i ) {
      my $original_content = $content;
      my @result_content   = ();
	  my $has_changed = $local_false;

      foreach my $content (@{$original_content}) {
	    my ($substcontent, $has_changed) = &allow_substitution($content, $begin_marker, $end_marker, $handler);
	    push(@result_content, $substcontent);
		$changed = $local_true if ( defined($has_changed) && $has_changed eq $local_true );
      }
	  $content = \@result_content;
	  goto __END_OF_SUB;
    } elsif ( $reftype =~ m/hash/i ) {
	  my $has_changed = $local_false;
	  my @keys = keys(%{$content});
	  for ( my $loop = 0; $loop < scalar(@keys); ++$loop ) {
	    ($content->{$keys[$loop]}, $has_changed) = &allow_substitution($content->{$keys[$loop]}, $begin_marker, $end_marker);
	    $changed = $local_true if ( defined($has_changed) && $has_changed eq $local_true );
	  }	
	}

  __END_OF_SUB:
    return ($content, $changed);
  }

#=============================================================================
sub clear_cache
  {
    %__most_used_configs = () if ( $allow_caching eq $local_true );
	return $local_true;
  }
  
#=============================================================================
sub clear_configuration($)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );

	my $result  = $local_false;
    my $section = $_[0];
    my $basis   = $_[1] || 'internal_cfg';

	if ( not defined($section) ) {
	  if ( ref($basis) =~ m/hash/i ) {
	    $basis = {};
	  } else {
	    eval "\$$basis = {};";
	  }
	  $result = $local_true;
	  goto __END_OF_SUB;
	}
	
	my $keypath = &__build_keypath($section, $basis);
	eval "delete($keypath);" if ( defined($keypath) );
	( $@ ) ? $result = $local_false : $result = $local_true;
	
  __END_OF_SUB:
    return $result;
  }
  
#=============================================================================
sub disable_caching()
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	&set_caching($local_false);
  }
  
#=============================================================================
sub disable_substitution()
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	&set_substitution($local_false);
  }
  
#=============================================================================
sub enable_caching()
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	&set_caching($local_true);
  }
  
#=============================================================================
sub enable_substitution()
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	&set_substitution($local_true);
  }
  
#=============================================================================
sub get_configuration()
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
    return $internal_cfg;
  }

#=============================================================================
sub get_from_configuration($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );

	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'section',     undef,
	                                        'dereference', \&is_integer,
											'basis',       undef,
											'beginmarker', \&valid_string,
											'endmarker',   \&valid_string ], @_);
    } else {
	  $inputdata = $_[0];
	}

	return undef if ( scalar(keys(%{$inputdata})) == 0 );

    my $section = $inputdata->{'section'};
	my $deref   = $inputdata->{'dereference'} || $local_false;
    my $basis   = $inputdata->{'basis'} || $internal_cfg;
	my $bm      = $inputdata->{'beginmarker'};
	my $em      = $inputdata->{'endmarker'};

	$section = &normalize_configuration_path($section);
	
    if ( ( defined($basis) ) && ( defined($section) ) ) {
      if ( ( $allow_caching eq $local_true ) &&
		   ( &__is_configuration_cached($section) eq $local_true ) ) {
	    &__print_debug_output("Returning data : \n".Dumper($__most_used_configs{"$section"})) if ( $is_debug );
		return &dereference(
		                    $__most_used_configs{"$section"},
							$deref
						   );
      }
	  
      my @drill = split(SPLITTER_ARROW,$section);
	  &__print_debug_output("Drill sections --> @drill",__PACKAGE__) if ( $is_debug );
	  
      my $results = $basis;
	  
      if ( scalar(@drill) && ref($results) =~ m/hash/i ) {
        while ( scalar(@drill) ) {
		  goto NO_MATCH if ( ref($results) !~ m/hash/i );
          if ( exists($results->{"$drill[0]"}) ) {
            $results = $results->{"$drill[0]"};
            shift (@drill);
          } else {
            $results = undef;
            last;
          }
        }
      } else {
        $results = undef;
      }

	  if ( $allow_substitution eq $local_true ) {
        if ( ref($results) eq '' ) {
	      $results = &allow_substitution($results, $bm, $em);
        }# else {
	    #  &allow_substitution($results, $bm, $em);
        #}
	  }
	  &__print_debug_output("Returning data : \n".Dumper($results)) if ( $is_debug );
      return &dereference($results, $deref);
    }

    if ( ( defined($basis) ) && ( not defined($section) ) ) {
 	  &__print_debug_output("Returning data : \n".Dumper($basis)) if ( $is_debug );
      return &dereference($basis, $local_false);
    }

  NO_MATCH:
    return undef;
  }

#=============================================================================
sub normalize_configuration_path($;$$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	
	my $normalized_splitter = SPLITTER_ARROW;
	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'path', \&valid_string,
	                                        'addon_splitters', undef,
											'final_delimiter', \&valid_string ], @_);
    } else {
	  $inputdata = $_[0];
	}

	return undef if ( scalar(keys(%{$inputdata})) == 0 );
	
	my $path                = $inputdata->{'path'} || return;
	my $addon_splitters     = $inputdata->{'addon_splitters'};
	my $final_delimiter     = $inputdata->{'final_delimiter'} || $normalized_splitter;
	
	$addon_splitters = &convert_to_array($addon_splitters, TRUE);
		
	my @allsplitters = @{&SPLITTERS};
	push ( @allsplitters, @{$addon_splitters} );
	
	my $splitset = &create_object('c__HP::Array::Set__');
	$splitset->add_elements({'entries' => \@allsplitters});
	
	foreach ( @{$splitset->get_elements()} ) {
	  my $regex = quotemeta($_);
	  $path =~ s/$regex/$normalized_splitter/g;
	}
	
	if ( $final_delimiter ne $normalized_splitter ) {
	  my $regex = quotemeta($normalized_splitter);
	  $path =~ s/$regex/$final_delimiter/g;
	}
	
	return $path;
  }
  
#=============================================================================
sub remove_from_configuration($;$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );

    my $section = $_[0];
    my $basis   = $_[1] || $internal_cfg;
	
	$section = &normalize_configuration_path($section);
	
    if ( ( defined($basis) ) && ( defined($section) ) ) {
      my @drill = split(SPLITTER_ARROW,$section);
	  my $last_entry = pop (@drill);
	  
	  &__print_debug_output("Drill sections --> @drill",__PACKAGE__) if ( $is_debug );
	  
      my $results = $basis;
      if ( scalar(@drill) ) {
        while ( scalar(@drill) ) {
          if ( exists($results->{"$drill[0]"}) ) {
            $results = $results->{"$drill[0]"};
            shift (@drill);
          } else {
            $results = undef;
            last;
          }
        }
      } else {
        $results = undef;
      }

	  return if ( not defined($results) );
	  delete($results->{"$last_entry"});
	  
	  &__print_debug_output("Remaining data :\n".Dumper($results)) if ( $is_debug );
	}
	return;
  }
  
#=============================================================================
sub set_caching($)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );

	$allow_caching = $_[0] if ( defined($_[0]) );
	return;
  }
 
#=============================================================================
sub set_substitution($)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );

	$allow_substitution = $_[0] if ( defined($_[0]) );
	return;
  }
 
#=============================================================================
sub save_to_configuration($;$$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );

	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'data',  undef,
											'table', undef, ], @_);
    } else {
	  $inputdata = $_[0];
	}

	return $local_false if ( scalar(keys(%{$inputdata})) == 0 );

	my $hashtable = $internal_cfg;
	
	$hashtable = $inputdata->{'table'} if ( defined($inputdata->{'table'}) );
	my $data   = $inputdata->{'data'};
	
	my $cfginput = undef;
	if ( ref($data) !~ m/^array/i ) {
      $cfginput = [ $data ];
	} else {
	  $cfginput = $data;
	}
	#$cfginput = [ $data ];
	
	if ( ref($hashtable) !~ m/hash/i ) {
	  unshift(@{$cfginput}, $hashtable);
	  $hashtable = $internal_cfg;
	}
	
	&__print_debug_output("Table --> \n".Dumper($hashtable)) if ( $is_debug );	
	&__print_debug_output("Data --> \n".Dumper($data)) if ( $is_debug );
	
    my ($keys , $values) = &__make_cfg_entries(@{$cfginput});

    my @keys   = @{$keys};
    my @values = @{$values};

    return $local_false if ( ( defined($hashtable) ) && ( scalar(@keys) == 0 ) );

    for (my $idx = 0; $idx < scalar(@keys); ++$idx ) {
      my $key = $keys[$idx];
	  $key = &normalize_configuration_path($key);

      if ( ( defined($hashtable) ) && ( defined($key) ) ) {
	    my $results = $hashtable;
	    my @drill = split(SPLITTER_ARROW,$key);

	    if ( scalar(@drill) ) {
	      while ( scalar(@drill) ) {
		    if ( scalar(@drill) == 1 ) {
			  my $data = $values[$idx];
			  $data = \$values[$idx] if ( ref($values[$idx]) eq '' );
	          $results->{"$drill[0]"} = $data;
	          $__most_used_configs{$key} = $data if ( $allow_caching eq TRUE );
	          last;
	        } else {
			  last if ( ref($results) !~ m/hash/i);
	          $results->{"$drill[0]"} = {} if ( not exists($results->{"$drill[0]"}) );
	          $results = $results->{"$drill[0]"};
	          shift (@drill);
	        }
	      }
	    }
      }
    }
	
	return $local_true;
  }

#=============================================================================
sub show_configuration()
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	
	my $hashtable    = $_[0] || $internal_cfg;
	my $request_show = $_[1] || $local_false;
	
	if ( $is_debug eq $local_true || $request_show eq $local_true ) {
	  eval "use Data::Dumper;";
	  &__print_debug_output(Dumper($hashtable), __PACKAGE__);
	  eval "no Data::Dumper;";
	}
  }

#=============================================================================
&__initialize();

#=============================================================================
1;