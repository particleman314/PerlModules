#!/usr/bin/env perl
#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok("HP::String");
  }

my $str1 = undef;
my $result = &HP::String::remove_line_endings($str1);
is ( (not defined($result)), 1 );

$str1 = '';
$result = &HP::String::remove_line_endings($str1);
is ( defined($result), 1 );
is ( $str1 eq $result, 1 );

$str1 = "abcdef\n";
$result = &HP::String::remove_line_endings($str1);
is ( defined($result), 1 );
is ( $str1 ne $result, 1 );
is ( length($result) == 6, 1 );

$str1 = "ABCDEF\r\n";
$result = &HP::String::remove_line_endings($str1);
is ( defined($result), 1 );
is ( $str1 ne $result, 1 );
is ( length($result) == 6, 1 );
