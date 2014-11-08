# -- Extra subroutines

use File::Path;
use File::Spec;
use Time::HiRes;

my %conversion = (
                  '1'           => '',
				  '0.001'       => 'milli',
				  '0.000001'    => 'micro',
				  '0.000000001' => 'nano',
				 );
				 
sub dec2bin($)
  {
    my $str = unpack("B32", pack("N", shift));
    $str =~ s/^0+(?=\d)//;   # otherwise you'll get leading zeros
    return $str;
  }

sub bin2dec($)
  {
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
  }

sub MakeNumbers($$$$;$)
  {
    if (scalar(@_) == 5 && $_[4] eq "fixed") {
      srand(10);  # Set the seed for random number generation
    }
    my @range = ();
    
    if (scalar(@_) >= 2) {
      push(@range, $_[0], $_[1]);
      splice(@_,0,2);
    } elsif (scalar(@_) == 1) {
      push(@range,$_[0]);
      push(@range,1);
      shift;
    } else {
      push(@range, (0,1));
    }
    
    @range = sort {$a <=> $b } @range;
    my $delta = $range[1] - $range[0];
    my $floating = $_[1] || 0;
    
    my @input = ();
    
    for (my $loop = 0; $loop < $_[0]; ++$loop) {
      my $value = (rand() * $delta + $range[0]);
      if ($floating) {
	    push(@input, $value);
      } else {
	    push(@input, int($value));
      }
    }
    return (wantarray() ? @input : $input[0]);
  }

sub MakeCharacters($$;$$)
  {
    my @removals = ();
    if (scalar(@_) == 3 and
	$_[2] eq "fixed") {
      srand(10);  # Set the seed for random number generation
    }
    
    if (scalar(@_) == 4) {
      @removals = @{$_[3]};
    }

    my @range = ();
    
    if (scalar(@_) >= 2) {
      push(@range, $_[0], $_[1]);
      splice(@_,0,2);
    } elsif (scalar(@_) == 1) {
      push(@range,$_[0]);
      push(@range,1);
      shift;
    } else {
      push(@range, (0,1));
    }
    
    @range = sort {$a <=> $b } @range;
    $range[0] = 0 if ($range[0] < 0);
    $range[1] = 255 if ($range[1] > 255);
    
    my $delta = $range[1] - $range[0];
    
    my @input = ();
    
    for (my $loop = 0; $loop < $_[0]; ++$loop) {
      my $chrID = int((rand() * $delta + $range[0]));
      my $skip  = 0;
      foreach (@removals) {
	    if ( $_ == $chrID ) {
	      $skip = 1;
	      last;
	    }
      }
      push(@input, chr($chrID)) if ( not $skip );
    }
    return (wantarray() ? @input : $input[0]);
  }

sub MakeNumbersAsChars($;$)
  {
    if (scalar(@_) == 2 and
	$_[1] eq "fixed") {
      srand(10);  # Set the seed for random number generation
    }

    my @input = ();
    for (my $loop = 0; $loop < $_[0]; ++$loop) {
      push(@input, chr(int(rand() * 9 + 0.5) + 48));
    }
    return (wantarray() ? @input : $input[0]);
  }

sub MakeLetters($;$)
  { 
    if (scalar(@_) == 2 and
	$_[1] eq "fixed") {
      srand(10);  # Set the seed for random number generation
    }
    my @input = ();
    for (my $loop = 0; $loop < $_[0]; ++$loop) {
      my $caseType = ((rand() < 0.5) ? 65 : 97);
      my $letter   = int(rand() * 25 + 0.5) + $caseType;
      push(@input, chr($letter));
    }
    return (wantarray() ? @input : $input[0]);
  }

sub MakeFileNames($$;$)
  {
    if (scalar(@_) == 3 and
	$_[2] eq "fixed") {
      srand(10);
    }

    my @filenames = ();
    for (my $loop = 0; $loop < $_[0]; ++$loop) {
      my $filename_length  = int(rand() * $_[1] + 0.5);
      $filename_length = ( $filename_length ) ? $filename_length : 1;
      my @filename_letters = &MakeLetters($filename_length);
      push (@filenames, join("",@filename_letters));
    }
    return (wantarray() ? @filenames : $filenames[0]);
  }

sub MakeTempDir($)
  {
    my $directory_name = shift;
    $directory_name = 'TEMP_XXX' if ( not defined($directory_name) or
				      "$directory_name" eq '' );
    my $tempdir = File::Spec->catfile(
				      File::Spec->tmpdir(),"$directory_name");
    if ( not -d "$tempdir" ) {
      $tempdir = File::Spec->rel2abs(
				     File::Spec->catfile(
							 File::Spec->curdir(),"$directory_name"));
      if ( not -d "$tempdir" ) {
	    mkpath("$tempdir",0,0777) if ( not -e "$tempdir" );
	    return "$tempdir";
      } else {
	    return "$tempdir";
      }
    } else {
      return "$tempdir";
    }
  }

sub RunTrials($$)
  {
    my $hashresult = {};
    return $hashresult if ( scalar(@_) < 1 );
	
	$_[1] = 1 if ( scalar(@_) < 2 );
	
    my @results = ();
	my @deviations = ();
	
    $results[$_[1] - 1] = -1;
	$deviations[$_[1] - 1] = 0;
	
    $sum = 0;
	$sumdev = 0;

    for ( my $loop = 0; $loop < $_[1]; ++$loop ) {	
	  $results[$loop] = &RunCodeFragment( $_[0] );
	  $sum += $results[$loop];
    }
	
	$hashresult->{'average'} = &ConvertTime($sum/$_[1]);
	
	if ( $_[1] > 1 ) {
	  for ( my $loop = 0; $loop < $_[1]; ++$loop ) {
	    $deviations[$loop] = ($results[$loop] - $hashresult->{'average'})**2;
	    $sumdev += $deviations[$loop];
	  }
	
	  $hashresult->{'stddev'} = &ConvertTime(sqrt($sumdev/( $_[1] - 1 )));
	}
	
	return $hashresult;
  }

sub RunCodeFragment($)
  {
    return 0 if ( scalar(@_) < 1 );

    my $begintime = Time::HiRes::time();
	$_[0]->();
	my $endtime   = Time::HiRes::time();
	my $delta_t = $endtime - $begintime;
	return $delta_t;
  }

sub RemoveObjectCreationBias($)
  {
    return 0 if ( scalar(@_) < 1 );
	$_[0]->();
  }
  
sub ConvertTime($)
  {
    return if ( scalar(@_) < 1 );
	
    my $prefix  = '';
    my $converted = $_[0];
  
    for ( sort { $a <=> $b } (keys(%conversion)) ) {
      if ( $converted < $_ ) { $converted /= $_; $prefix = $conversion{$_}; }
	}

	my $hashresult = {
	                  'prefix'    => $prefix,
					  'converted' => $converted,
					 };
	return $hashresult;
  }
  
sub __debug_print($)
  {
    print STDERR Dumper($_[0]);
  }

sub debug_print_xml($)
  {
    return if ( scalar(@_) < 1 );
    if ( defined($ENV{'HARNESS_PERL_SWITCHES'}) ) {
      if ( $ENV{'HARNESS_PERL_SWITCHES'} =~ m/Data\:\:Dumper/ ) {
  	    my $result = UNIVERSAL::can($_[0], 'isa');
	
        return if ( not defined($result) );
		if ( UNIVERSAL::can($_[0], 'as_xml') ) {
	      print STDERR "\nXML::\n\n";
	      &__debug_print($_[0]->as_xml());
		}
	  }
	}
  }
  
sub debug_print_json($)
  {
    return if ( scalar(@_) < 1 );
    if ( defined($ENV{'HARNESS_PERL_SWITCHES'}) ) {
      if ( $ENV{'HARNESS_PERL_SWITCHES'} =~ m/Data\:\:Dumper/ ) {
  	    my $result = UNIVERSAL::can($_[0], 'isa');
	
        return if ( not defined($result) );
		if ( UNIVERSAL::can($_[0], 'as_json') ) {
	      print STDERR "\nJSON::\n\n";
	      &__debug_print($_[0]->as_json());
		}
	  }
	}
  }

sub debug_print_dumper($)
  {
    return if ( scalar(@_) < 1 );
    if ( defined($ENV{'HARNESS_PERL_SWITCHES'}) ) {
      if ( $ENV{'HARNESS_PERL_SWITCHES'} =~ m/Data\:\:Dumper/ ) {
	    $Data::Dumper::Purity = 1;
		$Data::Dumper::Sortkeys = 1;
	    print STDERR "\nDUMPER result::\n\n";
		&__debug_print(@_);
	    $Data::Dumper::Purity = 0;
		$Data::Dumper::Sortkeys = 0;
      }
	}
  
  }
  
sub debug_obj($)
  {
    return if ( scalar(@_) < 1 );
    if ( defined($ENV{'HARNESS_PERL_SWITCHES'}) ) {
      if ( $ENV{'HARNESS_PERL_SWITCHES'} =~ m/Data\:\:Dumper/ ) {
        &debug_print_xml(@_);
        &debug_print_json(@_);
		&debug_print_dumper(@_);
	  }
	}
  }
  
1;
