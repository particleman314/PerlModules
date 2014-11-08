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
my $satisfy = &is_binary($str);
is ( $satisfy eq FALSE, 1);

$str = '';
$satisfy = &is_binary($str);
is ( $satisfy eq FALSE, 1);

$str = '0';
$satisfy = &is_binary($str);
is ( $satisfy eq TRUE, 1);

$str = '1';
$satisfy = &is_binary($str);
is ( $satisfy eq TRUE, 1);

$str = '010001011010101010';
$satisfy = &is_binary($str);
is ( $satisfy eq TRUE, 1);

$str = '0b010001011010101010';
$satisfy = &is_binary($str);
is ( $satisfy eq TRUE, 1);

$str = 'deadbeef';
$satisfy = &is_binary($str);
is ( $satisfy eq FALSE, 1);

$str = '0b01000101ab54d1010';
$satisfy = &is_binary($str);
is ( $satisfy eq FALSE, 1);

@tests = &MakeLetters(20);
print STDERR "\nTesting letters within A-Z...\n";
print STDERR "@tests\n";
foreach ( @tests ) {
  $str = $_;
  $satisfy = &is_binary($str);
  is ( $satisfy eq FALSE, 1);
}
