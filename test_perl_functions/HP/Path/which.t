#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN
  {
    use_ok('HP::Constants');
    use_ok('HP::Os');
    use_ok('HP::Support::Os');
    use_ok('HP::Path');
  }

my @commands = qw(
			  date
			  uptime
			  mv
			  cp
			  rm
			 );
my @locations_windows = qw();
my @locations_cygwin = qw(
			  /usr/bin/date::C:/cygwin/bin/date.exe
			  /usr/bin/mv::C:/cygwin/bin/mv.exe
			  /usr/bin/cp::C:/cygwin/bin/cp.exe
			  /usr/bin/rm::C:/cygwin/bin/rm.exe
			 );
my @locations_linux  = qw(
			  /bin/date::/opt/dsptools/tools/bin/date
			  /bin/mv::/opt/dsptools/tools/bin/mv
			  /bin/cp::/opt/dsptools/tools/bin/cp
			  /bin/rm::/opt/dsptools/tools/bin/rm
			 );

my @locations = ();
@locations = @locations_windows if ( &os_is_windows() eq TRUE );
@locations = @locations_cygwin  if ( &os_is_cygwin() eq TRUE );
@locations = @locations_linux   if ( &os_is_linux() eq TRUE );

if ( scalar(@locations) == scalar(@commands) ) {
    for (my $idx = 0; $idx < scalar(@commands); ++$idx) {
	  my $cmd = $commands[$idx];
	  my $resolved_location = &which($cmd);
	
	  my @possible_locations = split("\:\:",$locations[$idx]);
	  my $answer = 0;
	  foreach my $match (@possible_locations) {
	    $answer = ("$resolved_location" eq "$match\.exe") if ( &os_is_windows() || &os_is_cygwin() );
	    $answer = ("$resolved_location" eq "$match")     if ( &os_is_linux() );
	    if ($answer) {
		diag("\nLocation found for $cmd is << $resolved_location >>\n");
		last;
	    }
	  }
	#is ($answer,1);
    }
}
