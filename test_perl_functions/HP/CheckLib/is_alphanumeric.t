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
my $satisfy = &is_alphanumeric($str);
is ( $satisfy eq FALSE, 1);

$str = '';
$satisfy = &is_alphanumeric($str);
is ( $satisfy eq FALSE, 1);

$str = 'fdhsfhgdfhi36438fsdhj42378dsjkd23jfknxsvhxs5442527945';
$satisfy = &is_alphanumeric($str);
is ( $satisfy eq TRUE, 1);

my @tests = ( -4 .. 4 ); # Integer testing
print STDERR "\nTesting integers...\n";
print STDERR "@tests\n";
foreach ( @tests ) {
  $str = $_;
  $satisfy = &is_alphanumeric($str);
  is ( $satisfy eq TRUE, 1);
}

$str = '1.567e-32';
$satisfy = &is_alphanumeric($str);
is ( $satisfy eq TRUE, 1);

@tests = &MakeNumbers(-3, 3, 25, 1); # Floating Number testing
print STDERR "\nTesting floats...\n";
print STDERR "@tests\n";
foreach ( @tests ) {
  $str = $_;
  $satisfy = &is_alphanumeric($str);
  is ( $satisfy eq TRUE, 1);
}

@tests = &MakeLetters(20);
print STDERR "\nTesting letters within A-Z...\n";
print STDERR "@tests\n";
foreach ( @tests ) {
  $str = $_;
  $satisfy = &is_alphanumeric($str);
  is ( $satisfy eq TRUE, 1);
}


@tests = &MakeFileNames(10, 50);
print STDERR "\nTesting longnames...\n";
print STDERR "@tests\n";
foreach ( @tests ) {
  $str = $_;
  $satisfy = &is_alphanumeric($str);
  is ( $satisfy eq TRUE, 1);
}
