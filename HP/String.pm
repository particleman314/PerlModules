package HP::String;

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
    use lib "$FindBin::Bin/..";

    use vars qw(
                $VERSION
                $is_init
                $is_debug

                $module_require_list
                $module_request_list

                $broken_install

                @ISA
                @EXPORT
               );

    @ISA     = qw(Exporter);
    @EXPORT  = qw(
				  &chomp_r
				  &deblank
				  &eat_white_space
				  &eat_quotations
				  &escapify
				  &fit_string
				  &make_multiline
				  &read_input
                  &remove_line_endings
				  &str_contains
				  &str_starts_with
                  &str_matches

                  &lowercase_all
                  &lowercase_first
                  &uppercase_all
                  &uppercase_first
		 );

    $module_require_list = {
	                        'HP::Constants'     => undef,
                            'HP::Support::Base' => undef,
							'HP::Support::Os'   => undef,
							
							'HP::String::Constants' => undef,
                           };
    $module_request_list = {};

    $VERSION  = 0.85;
    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_string_pm'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    $broken_install = 0;

    print STDERR "BEGIN <". __PACKAGE__ .">\n" if ( $is_debug );

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "\t--> Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
        if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug );
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

    # Print a messages stating this module has been loaded.
    print STDERR "LOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
END
  {
    print STDERR "UNLOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
my @escaped_characters = qw(: +);

#=============================================================================
sub __initialize()
  {     
    if ( not $is_init ) {
      $is_init = 1; 
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if $is_debug;
    }     
  }       

#=============================================================================
sub __str_match($$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
    my $msg    = shift;
    my $match  = shift;
    my $result = FALSE;

    $result = FALSE if ( not defined($match) );
    $result = TRUE if ( defined($match) && $msg =~ m/$match/ );

    &__print_debug_output("Testing << $msg >> to regex << $match >> with result --> $result", __PACKAGE__) if ( $result == 1 &&
																												$is_debug );

    return $result;
  }

#=============================================================================
sub add_escapified_symbol($)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	
	return if ( &valid_string($_[0]) eq FALSE );
	push ( @escaped_characters, $_[0] );
	return;
  }
  
#=============================================================================
sub chomp_r($)
  {
    my $results = shift;
    if ( ref($results) =~ m/array/i ) {
      for (my $loop = 0; $loop < scalar(@{$results}); ++$loop ) {
	    if ( &valid_string($results->[$loop]) eq TRUE ) {
	      chomp $results->[$loop];
	      $results->[$loop] =~ s/\r//g;
	    }
      }
    } else {
      if ( &valid_string($results) eq TRUE ) {
	    chomp $results;
	    $results =~ s/\r//g;
      }
    }
    return $results;
  }

#=============================================================================
sub deblank($$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $input = $_[0];
    return undef if ( &valid_string($input) eq FALSE );

    my $result = &eat_white_space($input);
    return undef if ( &valid_string($input) eq FALSE );

    my $len = length($result);
    chop($result) if ( ( length($result) > 0 ) && ( substr($result, $len - 1, 1) eq ' ' ) );
    $result = reverse ($result);
    return $result if ($_[1]);
    return &deblank($result,1);
  }

#=============================================================================
sub eat_white_space($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    return undef if ( &valid_string($_[0]) eq FALSE );

    my @components = split(' ',$_[0]);
    return join(' ', @components);
  }

#=============================================================================
sub eat_quotations($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    return undef if ( &valid_string($_[0]) eq FALSE );

    my $str = shift;
    $str =~ s/["']//g;
    return "$str";
  }

#=============================================================================
sub escapify($)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	
    my $dummy             = shift;
    my $specchar_location = undef;
	my $specchar_str      = '';
	foreach ( @escaped_characters ) {
	  $specchar_str .= quotemeta($_);
	}

    if ( $dummy =~ m/\S*([$specchar_str])\S*/ ) {
      my $spec_offset    = 0;

    CHECK_PUNCT:
      $specchar_location = index("$dummy", $1, $spec_offset);
      if ( $specchar_location > -1 ) {
	    my $begin = substr("$dummy",
			   0,
			   $specchar_location);
	    my $qm    = substr("$dummy",
			   $specchar_location,
			   1);
	    my $end   = substr("$dummy",
			   $specchar_location + 1,
			   length($dummy) + 1);
	    $dummy    = "$begin". quotemeta("$qm") ."$end";
	    $spec_offset = $specchar_location + 2;
	    goto CHECK_PUNCT;
      }
    }
    return $dummy;
  }

#=============================================================================
sub fit_string($$;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $str     = shift;
    my $space   = shift;
    my $justify = shift || LEFT_JUSTIFIED;

	$justify = LEFT_JUSTIFIED if ( &set_contains($justify, [ LEFT_JUSTIFIED, RIGHT_JUSTIFIED, CENTERED ]) eq FALSE );
	
    my $sizespace = $space;
    if ( int($space) != $space ) {
      $sizespace = int($space);
    }

    if ( length($str) < $sizespace ) {
      $str = "$str" . " " x ($sizespace - length($str)) if ( $justify =~ m/lj/i );
      $str = " " x ($sizespace - length($str)) . "$str" if ( $justify =~ m/rj/i );
      if ( $justify =~ m/center/i ) {
	    my $diff = ($sizespace - length($str));
	    my $leftside = $diff / 2;
	    my $rightside = $leftside;
	    ++$leftside if ( $diff % 2 == 1 );
	    $str = " " x $leftside . "$str" . " " x $rightside;
      }
    } elsif ( length($str) > $sizespace ) {
      $str = substr("$str",0,$sizespace);
    }
    return sprintf('%'.$space.'s',"$str")
  }

#=============================================================================
sub lowercase_all($)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	my $data = '';
	my $original_setting = $HP::Support::Base::allow_space;
	
    &HP::Support::Base::allow_space_as_valid_string(TRUE);
    $data = lc("$_[0]") if ( &valid_string($_[0]) eq TRUE );
    &HP::Support::Base::allow_space_as_valid_string($original_setting);
	
	return $data;
  }

#=============================================================================
sub lowercase_first()
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	my $data = '';
	my $original_setting = $HP::Support::Base::allow_space;
	
    &HP::Support::Base::allow_space_as_valid_string(TRUE);
    $data = lcfirst("$_[0]") if ( &valid_string($_[0]) eq TRUE );
    &HP::Support::Base::allow_space_as_valid_string($original_setting);
	
	return $data;
  }

#=============================================================================
sub make_multiline($$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	
	my $input        = shift;
	my $maximum_line = shift || 1;
	
  	if ( length($input) > $maximum_line ) {
	  my @components = split(" ", $input);
	  $input      = '';
	  my $startpt = 0;
	  
	 LINE_MAKER:
	  my $current_linesize = 0;
	  my $updated_loop_counter = 0;
	  my @line = ();
	  for ( my $loop = $startpt; $loop < scalar(@components); ++$loop ) {
	    if ( $current_linesize + length($components[$loop]) < $maximum_line ) {
		  $current_linesize += length($components[$loop]);
		  push( @line, $components[$loop] );
		  $updated_loop_counter = 1;
		} else {
		  if ( not $updated_loop_counter ) {
			push( @line, $components[$loop] );
		    $startpt = ++$loop;
		  }
		  $startpt = $loop;
		  my $nextline = join(' ',@line)."\n";
		  &__print_debug_output("Next line chunk : <<$nextline>>");
		  $input .= "$nextline";
		  goto LINE_MAKER;
		}
	  }
	  $input .= join(' ',@line);
	}
	return "$input";
  }
  
#=============================================================================
#sub read_input()
#  {
#    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
#	my $streamDB = &getDB('stream');
	
#    if ( ( $streamDB->find_stream_by_handle('STDERR')->active() eq TRUE ) &&
#	     ( $streamDB->find_stream_by_handle('STDIN')->active() eq TRUE ) ) {
#      my $response = <STDIN>;
#      chomp($response);
#      return $response;
#    }
#  }

#=============================================================================
sub remove_line_endings($)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
    my $input = shift;

	return $input if ( &valid_string($input) eq FALSE );
    $input =~ s/\r?\n$/\n/g;
    chomp($input);
    return "$input";
  }

#=============================================================================
sub str_contains($$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
    my $msg  = shift;
    my $aref = shift;

	return FALSE if ( &valid_string($msg) eq FALSE );
	
    $msg = &lowercase_all($msg); # Change message to lower case
    my $len;

    foreach (@{$aref}) {
      # Use index (like C's strstr) to find the offset of the substring.  If
      # the substring is not found in the message, index returns -1.
      my $var = &lowercase_all($_);
      return TRUE if (index($msg, $var) >= 0);
    }
    return FALSE;
  }

#=============================================================================
sub str_matches($$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
    my $msg   = shift;
    my $match = shift;

	return FALSE if ( &valid_string($msg) eq FALSE );
	
    if ( ref($match) =~ m/array/i ) {
      foreach my $mtc (@{$match}) {
        my $result = &__str_match("$msg", $mtc);
		if ( $result eq TRUE ) {
		  if ( not wantarray() ) {
            return TRUE         
		  } else {
	        return (TRUE, $mtc);
		  }
		}
      }
    } else {
      return &__str_match("$msg", $match);
    }

	if ( not wantarray() ) {
      return FALSE;
	} else {
      return (FALSE, undef);
	}
  }

#=============================================================================
sub str_starts_with($$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );

    my $msg  = shift;
    my $aref = shift;

	return FALSE if ( &valid_string($msg) eq FALSE );
	
    $msg = &lowercase_all($msg); # Change message to lower case
    my $len;

    foreach (@{$aref}) {
      $len = length($_);
      # Compare the substring starting from the beginning of the message
      return TRUE if (&lowercase_all($_) eq substr($msg, 0, $len));
    }
    return FALSE;
  }

#=============================================================================
sub uppercase_all($)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	my $data = '';
	my $original_setting = $HP::Support::Base::allow_space;
	
    &HP::Support::Base::allow_space_as_valid_string(TRUE);
    $data = uc("$_[0]") if ( &valid_string($_[0]) eq TRUE );
    &HP::Support::Base::allow_space_as_valid_string($original_setting);
	
	return $data;
  }

#=============================================================================
sub uppercase_first()
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
	my $data = '';
	my $original_setting = $HP::Support::Base::allow_space;
	
    &HP::Support::Base::allow_space_as_valid_string(TRUE);
    $data = ucfirst("$_[0]") if ( &valid_string($_[0]) eq TRUE );
    &HP::Support::Base::allow_space_as_valid_string($original_setting);
	
	return $data;
  }

#=============================================================================
&__initialize();

#=============================================================================
1;