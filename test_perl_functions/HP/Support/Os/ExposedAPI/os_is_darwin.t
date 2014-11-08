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

my $darwin_machine = &os_is_darwin();
print STDERR "MacOS machine setting --> $darwin_machine\n";
