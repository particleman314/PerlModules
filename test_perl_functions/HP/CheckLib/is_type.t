#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok("HP::Constants");
    use_ok("HP::CheckLib");
	use_ok("Text::Format");
  }

my $str = undef;
my $isobj = &is_type($str, 'SCALAR');
is ( $isobj eq FALSE, 1);

$str = '';
$isobj = &is_type($str, 'SCALAR');
is ( $isobj eq FALSE, 1);

$str = Text::Format->new();
$isobj = &is_type($str, 'SCALAR', 'Text::Format', 'HASH');
is ( $isobj eq TRUE, 1);

$str = [];
$isobj = &is_type($str, 'ARRAY');
is ( $isobj eq FALSE, 1);
