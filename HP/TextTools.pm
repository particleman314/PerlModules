package HP::TextTools;

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
                $is_debug
                $is_init

                $module_require_list
                $module_request_list

                $broken_install

                $clearScreen

                @ISA
                @EXPORT
               );

    $VERSION = 0.75;

    @ISA         = qw ( Exporter );
    @EXPORT      = qw (
                       &clean_read_line
		       &compare_numerical_versions
		       &convert_to_binary
		       &deblank
		       &display_text
		       &eat_quotations
		       &eat_white_space
		       &fit_string
		       &get_return_key_input
		       &help
		       &parse_until
		       &read_n_lines
		       &read_input
		       &read_until
		       &read_while
		       &test_attributes
		      );

    $module_require_list = {
                            'HP::RegexLib'      => undef,
                            'HP::BasicTools'    => undef,
                            'HP::ArrayTools'    => undef,
                            'HP::StreamManager' => undef,
                            'HP::Path'          => undef,
                            'HP::Process'       => undef,
			                'HP::String'        => undef,
                           };
    $module_request_list = {
			                'Term::Screen'  => undef,
                            'Term::Cap'     => undef,
                           };

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_texttools_pm'} ||
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
          print STDERR "\t--> Skipping PERL Module << $usemod >>!\n" if ( $is_debug );
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
use constant TRUE  => 1;
use constant FALSE => 0;

#=============================================================================
my %TEST2PERL_FILEATTR = ('l'  =>  'L');

#=============================================================================
sub __initialize()
  {
    if ( not $is_init ) {
      $is_init = 1;
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
sub clean_read_line($)
  {
    &__print_debug_output("Inside 'clean_read_line'", __PACKAGE__);

    return $_[0] if ( ( not defined($_[0]) ) || ( length($_[0]) < 1 ) );

    my $cleaned_line = &eat_white_space(&chomp_r($_[0]));
    &__print_debug_output("After eating excessive whitespace --> << $cleaned_line >>", __PACKAGE__) if ( defined($cleaned_line) );

    if ( &is_comment($cleaned_line) ) {
      $cleaned_line = &strip_comment($cleaned_line);
      &__print_debug_output("After removing comment --> << $cleaned_line >>", __PACKAGE__) if ( defined($cleaned_line) );
    }
    return $cleaned_line;
  }

#=============================================================================
sub compare_numerical_versions($$;$)
  {
    &__print_debug_output("Inside 'compare_numerical_versions'", __PACKAGE__);

    my ($ver1, $ver2, $comparer) = @_;

    $comparer = 'greater' if ( not defined($comparer) );

    my @x = split(/\./, $ver1);
    my @y = split(/\./, $ver2);

    # Ensure equal sizes by padding
    while (scalar(@x) < scalar(@y) ) {
      push(@x, 0);
    }
    while (scalar(@y) < scalar(@x) ) {
      push(@y, 0);
    }

    for (my $idx = 0; $idx < scalar(@x); ++$idx) {
      if ( $comparer !~ m/code/i ) {
	if ( $comparer =~ m/lesser/i ) {
	  if ( $x[$idx] < $y[$idx] ) { return 1; }
	} elsif ( $comparer =~ m/greater/i ) {
	  if ( $x[$idx] > $y[$idx] ) { return 1; }
	}
      } else {
	return &{$comparer}(join("",@x),join("",@y));
      }
    }
    return FALSE;
  }

#=============================================================================
sub convert_to_binary($)
  {
    &__print_debug_output("Inside 'convert_to_binary'", __PACKAGE__);

    return TRUE if ( &is_numeric($_[0]) && ( $_[0] != 0 ) );
    if ( ( lc($_[0]) =~ m/^y/ ) || ( lc($_[0]) eq 'on' ) || ( lc($_[0]) eq 'true' ) ) { return TRUE; }
    return FALSE;
  }

#=============================================================================
sub deblank($$)
  {
    &__print_debug_output("Inside 'deblank'", __PACKAGE__);

    my $input =  $_[0];
    return if (length($input) < 1);

    my $result = &eat_white_space($input);
    return if (length($result) < 1);

    my $len    = length($result);
    chop($result) if ( ( length($result) > 0 ) && ( substr($result, $len - 1, 1) eq ' ' ) );
    $result = reverse ($result);
    return $result if ($_[1]);
    return &deblank($result,1);
  }

#=============================================================================
sub display_text($$)
  {
    &__print_debug_output("Inside 'display_text'", __PACKAGE__);

    my ($display, $screenAction) = @_;
    $screenAction = $screenAction || 0;

    if ($screenAction) {
      my $answer = &has('Term::Screen');
      if ( $answer->[0] ) {
	&__print_debug_output("Has Term::Screen for use!\n", __PACKAGE__ );
	my $screenObj = new Term::Screen();
	return if ( not defined($screenObj) );
	my $cmd = "\$screenObj->clrsrc()";
	eval($cmd) if $screenAction;
	if ($@) { return; }
	
      } else {
	my $answer = &has('Term::Cap');
	if ( $answer->[0] && exists($ENV{'TERM'}) ) {	  
	  my $OSPEED = 9600;
	  eval {
	    require POSIX;
	    my $termios = POSIX::Termios->new();
	    $termios->getattr;
	    $OSPEED = $termios->getospeed;
	  };
	
	  my $terminal;
	  eval "\$terminal = Term::Cap->Tgetent({OSPEED=>$OSPEED})";
	  if ( ! $@ ) {
	    $clearScreen = $terminal->Tputs('cl');
	    &print_2_stream($clearScreen,'STDOUT');
	  }
        }
      }
    }

    &print_2_stream($display);
  }

#=============================================================================
sub eat_white_space($)
  {
    &__print_debug_output("Inside 'eat_white_space'", __PACKAGE__);

    return undef if (scalar(@_) < 1 || $_[0] eq '');

    my @components = split(' ',$_[0]);
    return join(' ', @components);
  }

#=============================================================================
sub eat_quotations($)
  {
    &__print_debug_output("Inside 'eat_quotations'", __PACKAGE__);

    return undef if (scalar(@_) < 1 || $_[0] eq '');

    my $str = shift;
    $str =~ s/["']//g;
    return "$str";
  }

#=============================================================================
sub fit_string($$;$)
  {
    &__print_debug_output("Inside 'fit_string'", __PACKAGE__);

    my $str     = shift;
    my $space   = shift;
    my $justify = shift || 'LJ';

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
sub get_return_key_input($$)
  {
    my ($display, $screenAction) = @_;

    my @tmpDisplay = ();
    if (ref($display) =~ m/scalar/i || ref($display) eq '') {
      push (@tmpDisplay, $display);
    } elsif (ref($display) =~ m/hash/i) {
      push (@tmpDisplay, sort (keys %{$display}));
    } else {
      @tmpDisplay = @{$display};
    }

    push(@tmpDisplay,"Hit <RETURN> to continue\n");
    &display_text($display, $screenAction);

    if ( &has('Term::Screen') ) {
      my $scr = Term::Screen->new()->getch();
    } else {
      &read_input();
    }
  }

#=============================================================================
sub read_n_lines($$)
  {
    my $handle = $_[0];

    return undef if ($handle eq '' &&
		     ref($handle) !~ m/glob/i &&
		     not &is_stream_active($handle));

    my $dont_return = 1;
    my @COMMON_LINE = ();

    for (my $loop = 0; $loop < $_[1]; ++$loop) {
      last if ( eof($handle) );
      $dont_return = 0;
      my $readline = $handle->getline();
      if ( not $dont_return ) {
	push( @COMMON_LINE, "$readline" );
      }
    }

    return undef if ( scalar(@COMMON_LINE) < 1 );
    &__print_debug_output("[ READ_N_LINES ] All data looks like\n\n". join('',@COMMON_LINE). "\nNumber of lines = ". scalar(@COMMON_LINE),__PACKAGE__);
    return \@COMMON_LINE;
  }

#=============================================================================
sub parse_until($$)
  {
    my @COMMON_LINE = ();
    my $readline    = undef;
    my @filelines   = @{$_[0]};

    foreach (@filelines) {
      if ($_ eq 'BLANK_LINE') {
	if (length($_) < 1 || (length($_) == 1 && ord($_) == 10)) {
	  &__print_debug_output("Made a match to 'BLANK_LINE'",__PACKAGE__);
	  last;
	} else {
	  push(@COMMON_LINE, $_);
	}
      } else {
	push(@COMMON_LINE, $_);
	last if (index($_, $_[1]) != -1);
      }
    }
    pop(@COMMON_LINE);
    return undef if ( scalar(@COMMON_LINE) < 1 );
    &__print_debug_output("[ PARSE_UNTIL ] All data looks like\n\n". join('',@COMMON_LINE). "\nNumber of lines = ". scalar(@COMMON_LINE),__PACKAGE__);
    return \@COMMON_LINE;
  }	

#=============================================================================
sub read_input()
  {
    if ( &is_stream_active('STDERR') ) {
      my $response = <STDIN>;
      chomp($response);
      return $response;
    }
  }

#=============================================================================
sub read_until($$$)
  {
    my $handle = $_[0];

    return undef if ($handle eq '' &&
	             ref($handle) !~ m/glob/i &&
	             not &is_stream_active($handle));

    my @COMMON_LINE = ();
    my $check       = $_[1] || undef;
    my $REPLACE     = $_[2] || FALSE;

    while ((my $readline = $handle->getline())) {
      if ($_[1] eq 'BLANK_LINE') {
	if (length($readline) < 1 ||
          (length($readline) == 1 && ord($readline) == 10)) {
	  last;
	} else {
	  push( @COMMON_LINE, "$readline");
	}
      } else {
	if (index($readline,$_[1]) == -1) {
	  push( @COMMON_LINE, "$readline");
	} else {
	  push( @COMMON_LINE, "$readline");
	  last;
	}
      }
    }
    return undef if ( scalar(@COMMON_LINE) < 1 );
    for ( my $loop = 0; $loop < scalar(@COMMON_LINE); ++$loop ) {
      $COMMON_LINE[$loop] =~ s/$check//g if ( defined($check) && $check ne 'BLANK_LINE' && $REPLACE );
    }
    &__print_debug_output("[ READ_UNTIL ] All data looks like\n\n". join('',@COMMON_LINE). "\nNumber of lines = ". scalar(@COMMON_LINE),__PACKAGE__);
    return \@COMMON_LINE;
  }

#=============================================================================
sub read_while($$;$)
  {
    my $handle = $_[0];
    return undef if ($handle eq '' &&
		     ref($handle) !~ m/glob/i &&
		     not &is_stream_active($handle));

    my @COMMON_LINE = ();
    my $check       = $_[1] || undef;
    my $REPLACE     = $_[2] || FALSE;
    my $flag        = 0;

    &__print_debug_output("Check line --> << $check >>\t REPLACE flag is << $REPLACE >>", __PACKAGE__);
    while (my $readline = $handle->getline()) {
      if ( not $flag ) {
	my $idx = index($readline, $check);
	&__print_debug_output("Found expected line at line #$flag with index $idx",__PACKAGE__);
	++$flag if ($idx >= 0);
      } else {
	&__print_debug_output("Adding line read from file to internal buffer...", __PACKAGE__);
	push( @COMMON_LINE, "$readline" );
      }
    }

    for ( my $loop = 0; $loop < scalar(@COMMON_LINE); ++$loop ) {
      $COMMON_LINE[$loop] =~ s/$check//g if ( defined($check) && $REPLACE );
    }
    &__print_debug_output("[ READ_WHILE ] All data looks like\n\n". join('',@COMMON_LINE). "\nNumber of lines = ". scalar(@COMMON_LINE), __PACKAGE__);
    return \@COMMON_LINE;
  }

#=============================================================================
sub test_attributes($$)
  {
    my @different_attrs  = split('',$_[1]);
    my @allowableSymbols = qw( ! & | );

    my $specialCode = undef;
    my $specialLink = undef;
    my $testCommand = " ";

    foreach my $symbol (@different_attrs) {
      if ( &set_contains( $symbol, @allowableSymbols ) ) {
	if ($symbol eq '!') {
	  $specialCode = $symbol;
	  next;
	}
	if ($symbol eq '&') {
	  $specialLink = ' -a ';
	} elsif ($symbol eq '|') {
	  $specialLink = ' -o ';
	}
	$testCommand .= " $specialLink ";
	next;
      } else {
	$symbol = $TEST2PERL_FILEATTR{$symbol} if ( defined($TEST2PERL_FILEATTR{$symbol}) );
	$testCommand .= "$specialCode -$symbol $_[0]";
	$specialCode = undef
        $specialLink = undef;
      }
    }
    my $comresult = &which('test') . " $testCommand";
    my $hashcmd   = {
	             'command' => "$comresult",
		     'verbose' => $is_debug,
                    };

    my $retval    = &runcmd($hashcmd);

    return &decode_error_status($retval);
}

#=============================================================================
&__initialize();

#=============================================================================
1;
