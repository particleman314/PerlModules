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
my $satisfy = &is_numeric($str);
is ( $satisfy eq FALSE, 1);

$str = '';
$satisfy = &is_numeric($str);
is ( $satisfy eq FALSE, 1);

$str = '-100.05';
$satisfy = &is_numeric($str);
is ( $satisfy eq TRUE, 1);

$str = '0';
$satisfy = &is_numeric($str);
is ( $satisfy eq TRUE, 1);

$str = '1';
$satisfy = &is_numeric($str);
is ( $satisfy eq TRUE, 1);

$str = '010001011010101010';
$satisfy = &is_numeric($str);
is ( $satisfy eq FALSE, 1);

$str = '0b010001011010101010';
$satisfy = &is_numeric($str);
is ( $satisfy eq FALSE, 1);

$str = '0x010001011010101010';
$satisfy = &is_numeric($str);
is ( $satisfy eq FALSE, 1);

$str = 'deadbeaf';
$satisfy = &is_numeric($str);
is ( $satisfy eq FALSE, 1);

$str = '0XDEADBEEF';
$satisfy = &is_numeric($str);
is ( $satisfy eq FALSE, 1);

my @tests = ( -4 .. 4 ); # Integer testing
print STDERR "\nTesting integers...\n";
print STDERR "@tests\n";
foreach ( @tests ) {
  $str = $_;
  $satisfy = &is_numeric($str);
  is ( $satisfy eq TRUE, 1);
}

$str = '1.567e-32';
$satisfy = &is_numeric($str);
is ( $satisfy eq TRUE, 1);

$str = '-1.567E3';
$satisfy = &is_numeric($str);
is ( $satisfy eq TRUE, 1);

$str = '-1.567E+3';
$satisfy = &is_numeric($str);
is ( $satisfy eq TRUE, 1);

@tests = &MakeNumbers(-3, 3, 25, 1); # Floating Number testing
print STDERR "\nTesting floats...\n";
print STDERR "@tests\n";
foreach ( @tests ) {
  $str = $_;
  $satisfy = &is_numeric($str);
  is ( $satisfy eq TRUE, 1);
}

@tests = &MakeLetters(10);
print STDERR "\nTesting letters within A-Z...\n";
print STDERR "@tests\n";
foreach ( @tests ) {
  $str = $_;
  $satisfy = &is_numeric($str);
  is ( $satisfy eq FALSE, 1);
}
