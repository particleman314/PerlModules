#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
    use_ok('HP::Support::Base');
  }
  
&print_msg("Hello World");
&print_msg("Hello World", INFO);
&print_msg("Hello World", FAILURE, \*STDERR);
&print_msg("A really long string with lots of characters and tabs (\t which may not all fit on the single terminal screen) since it was such a long sentence.\nAmazing that the print method is able to format the string sentence into something which would fit much nice on the screen and allow for a UI means to display information", undef, \*STDERR);