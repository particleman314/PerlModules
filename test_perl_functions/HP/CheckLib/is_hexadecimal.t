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
my $satisfy = &is_hexadecimal($str);
is ( $satisfy eq FALSE, 1);

$str = '';
$satisfy = &is_hexadecimal($str);
is ( $satisfy eq FALSE, 1);

$str = '0';
$satisfy = &is_hexadecimal($str);
is ( $satisfy eq TRUE, 1);

$str = '1';
$satisfy = &is_hexadecimal($str);
is ( $satisfy eq TRUE, 1);

$str = '010001011010101010';
$satisfy = &is_hexadecimal($str);
is ( $satisfy eq TRUE, 1);

$str = '0x010001011010101010';
$satisfy = &is_hexadecimal($str);
is ( $satisfy eq TRUE, 1);

$str = 'deadbeef';
$satisfy = &is_hexadecimal($str);
is ( $satisfy eq TRUE, 1);

$str = 'gooddeadbeef';
$satisfy = &is_hexadecimal($str);
is ( $satisfy eq FALSE, 1);

$str = 'dead-beef';
$satisfy = &is_hexadecimal($str);
is ( $satisfy eq FALSE, 1);

$str = '0XDEADBEEF';
$satisfy = &is_hexadecimal($str);
is ( $satisfy eq TRUE, 1);

@tests = &MakeCharacters(72, 90, 10);
print STDERR "\nTesting letters within G-Z...\n";
print STDERR "@tests\n";
foreach ( @tests ) {
  $str = $_;
  $satisfy = &is_hexadecimal($str);
  is ( $satisfy eq FALSE, 1);
}
