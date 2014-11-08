#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../../.."; 
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok("HP::Constants");
    use_ok("HP::Support::Os");
  }

my $windows_machine = &HP::Support::Os::__windows_style();
print STDERR "Windows machine setting --> $windows_machine\n";
