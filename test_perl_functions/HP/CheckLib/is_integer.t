#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok("HP::Constants");
    use_ok("HP::CheckLib");
  }

my $str = undef;
my $satisfy = &is_integer($str);
is ( $satisfy eq FALSE, 1);

$str = '';
$satisfy = &is_integer($str);
is ( $satisfy eq FALSE, 1);

$str = '-100.05';
$satisfy = &is_integer($str);
is ( $satisfy eq FALSE, 1);

$str = '0';
$satisfy = &is_integer($str);
is ( $satisfy eq TRUE, 1);

$str = '1';
$satisfy = &is_integer($str);
is ( $satisfy eq TRUE, 1);

$str = '010001011010101010';
$satisfy = &is_integer($str);
is ( $satisfy eq FALSE, 1);

$str = '0b010001011010101010';
$satisfy = &is_integer($str);
is ( $satisfy eq FALSE, 1);

$str = '0x010001011010101010';
$satisfy = &is_integer($str);
is ( $satisfy eq FALSE, 1);

$str = 'deadbeaf';
$satisfy = &is_integer($str);
is ( $satisfy eq FALSE, 1);

$str = '0XDEADBEEF';
$satisfy = &is_integer($str);
is ( $satisfy eq FALSE, 1);

$str = '04653';
$satisfy = &is_integer($str);
is ( $satisfy eq FALSE, 1);

my @tests = ( -4 .. 4 ); # Integer testing
print STDERR "\nTesting integers...\n";
print STDERR "@tests\n";
foreach ( @tests ) {
  $str = $_;
  $satisfy = &is_integer($str);
  is ( $satisfy eq TRUE, 1, "Tried to determine if $str is an integer");
}

@tests = &MakeLetters(10);
print STDERR "\nTesting letters within A-Z...\n";
print STDERR "@tests\n";
foreach ( @tests ) {
  $str = $_;
  $satisfy = &is_integer($str);
  is ( $satisfy eq FALSE, 1);
}
