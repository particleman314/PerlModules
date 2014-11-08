#! /usr/bin/env perl

use diagnostics;
use warnings;
use strict;

# Basic PERL modules
use File::Spec;
use File::Find;
use FileHandle;
use Config;

### PERL Test Harness Infrastructure
BEGIN {
  # Need to test for installed modules and die gracefully if necessary
  my @optional_modules  = qw( Test::Harness Test::More );
  foreach (@optional_modules) {
    print STDOUT "Attempting to load $_\n";
    eval "use $_";
    die "Could not load necessary module :\t$_\n" if ($@);
  }

  require "requirements.pl";
}

my @testFiles         = ();
my $show_listing      = 0;
my $coverage_model    = 0;
my $profiler_model    = 0;
my $is_windows_native = 0;

# Hacky way to determine if we are running from windows or (unix/cygwin)
my $is_shell_cygwin = 0;
$is_shell_cygwin = 1 if ( exists($ENV{'CYGWIN'}) || ( exists($ENV{'OLDPWD'}) && $ENV{'OLDPWD'} =~ m/cygdrive/i ) );

if ( $^O =~ m/MSWin/ ) { $is_windows_native = 1; }

my $skips = {
             'directories' => [],
	         'files'       => []
            };

&collect_skips();

print STDOUT "Beginning Unit Testing...\n";

&handle_options();

if ( not scalar(@ARGV) ) {
  print STDOUT "Running all available unit tests...\n";
  find(\&wanted, ( "." ));
} else {
  foreach my $arg (@ARGV) {
    if ( $arg eq '-t' ) {
      $show_listing = 1;
      if (scalar(@ARGV) == 1) {
	 find(\&wanted, ("."));
      }
      next;
    }
    
    if ( $is_windows_native ) { $arg =~ s/\\/\//g; }
    if ( not $show_listing ) {
       if ( $arg =~ /\.t\b/ ) {
          print STDOUT "Launching test $arg\n";
       } else {
          print STDOUT "Launching tests for PERL module $arg\n";
       }
       if ( -d $arg and ( $arg !~ m/\.svn/ )) {
          find(\&wanted, ($arg));
          next;
       }

       if ( -e $arg) {
          push(@testFiles, $arg);
       }
    } else {
       if ( -d $arg and ( $arg !~ m/\.svn/ )) {
          find(\&wanted, ($arg));
          next;
       }
    }
  }
}

print STDOUT "Running Tests --->\n";
@testFiles = sort @testFiles;
@testFiles = @{&prune_list()};

if ( scalar(@testFiles) > 0 ) {
  if ( not $show_listing ) {
    runtests(@testFiles);

    # Allow for coverage and profiling post processing...
    if ( $coverage_model ) {
    }

    if ( $profiler_model ) {
    }
  } else {
    print STDERR join("\n",@testFiles)."\n";
  }
}

# -------------------
sub collect_skips()
  {
    if ( -f "./skipfile.txt" ) {
      my $handle = FileHandle->new();
      $handle->open("< ./skipfile.txt");
      if ( $handle ) {
	while ( my $line = $handle->getline() ) {

	  chop($line);
	  next if ( $line =~ m/^#/ );
	  my $cmt_indx = index("$line", "#");
	  if ( $cmt_indx > -1 ) {
	    $line = substr("$line",0,$cmt_indx-1);
	  }

	  my $header = substr("$line",0,2);
	  my $type   = undef;
	  if ( uc("$header") eq 'D:' ) {
	    $type = 'directories';
	  }
	  if ( uc("$header") eq 'F:' ) {
	    $type = 'files';
	  }

	  my @parts = split(":","$line");
	  if ( defined($parts[1]) ) {
	    $parts[1] =~ s/^\s*//;
	    $parts[1] =~ s/\s*$//;

	    push(@{$skips->{$type}}, "$parts[1]");
      }
	  next;
	}
      }
    }
  }

sub handle_options()
  {
  RESTART:
    for ( my $idx = 0; $idx < scalar(@ARGV); ++$idx ) {
      if ( $ARGV[$idx] eq '-c' ) {
	    $ENV{'HARNESS_PERL_SWITCHES'} .= '-MDevel::Cover ';
	    splice(@ARGV,$idx,1);
	    $coverage_model = 1;
	    goto RESTART;
      }
      if ( $ARGV[$idx] eq '-p' ) {
	    #$ENV{'HARNESS_PERL_SWITCHES'} .= '-MDevel::Profile ';
		$ENV{'HARNESS_PERL_SWITCHES'} .= '-MDevel::NYTProf ';
	    splice(@ARGV,$idx,1);
	    $profiler_model = 1;
	    goto RESTART;
      }
      if ( $ARGV[$idx] eq '-d' ) {
	    $ENV{'HARNESS_PERL_SWITCHES'} .= '-MData::Dumper ';
	    splice(@ARGV,$idx,1);
	    goto RESTART;
      }
    }
  }

sub prune_list()
  {
    my @removeidx = ();

    for ( my $loop = 0; $loop < scalar(@testFiles); ++$loop ) {
      for my $skipfile (@{$skips->{'files'}}) {
	    push(@removeidx, $loop) if ( "$skipfile.t" eq $testFiles[$loop] );
      }
      for my $skipdir (@{$skips->{'directories'}}) {
	    my $regex = quotemeta($skipdir);
	    push(@removeidx, $loop) if ( $testFiles[$loop] =~ m/$regex/ );
      }
    }
    my %tmphash = map { $_, 1 } @removeidx;
    @removeidx = sort {$a <=> $b} keys(%tmphash);

    my @reduced_testFiles = ();
    for ( my $loop = 0; $loop < scalar(@testFiles); ++$loop ) {
      if ( scalar(@removeidx) < 1 || $loop < $removeidx[0] ) {
	    push( @reduced_testFiles, $testFiles[$loop] );
	    next;
      }

      if ( $loop == $removeidx[0] ) { shift(@removeidx); }
    }

    return \@reduced_testFiles;
  }

sub wanted
  {
    my $applicable_test = 1 if ( -e $_ and
				 -f $_ and
				 -s $_ and
				 $_ =~ m/\.t$/ and
				 $_ !~ m/^__ignore__/ and
				 $_ !~ m/~/ and
				 $_ !~ m/\.swp$/ and
				 $File::Find::dir !~ m/\.svn/
                               );
	if ( $applicable_test ) {
	   my $testNameID = $File::Find::name;
	   $testNameID =~ s/^\.\///;
       push (@testFiles, $testNameID)
    }
  }
