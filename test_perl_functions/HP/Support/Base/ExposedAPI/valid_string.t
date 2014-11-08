#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::Support::Base');
  }

my $str1 = undef;
my $vs = &valid_string($str1);
is( $vs eq FALSE, 1 );
&debug_obj($str1);

my $str2 = '';
$vs = &valid_string($str2);
is( $vs eq FALSE, 1 );
&debug_obj($str2);

my $str3 = ' ';
$vs = &valid_string($str3);
is( $vs eq FALSE, 1 );
&debug_obj($str3);

&HP::Support::Base::allow_space_as_valid_string(TRUE);
$str3 = ' ';
$vs = &valid_string($str3);
is( $vs eq TRUE, 1 );
&debug_obj($str3);
&HP::Support::Base::allow_space_as_valid_string(FALSE);

my $str4 = ' ' x 10;
$vs = &valid_string($str4);
is( $vs eq FALSE, 1 );
&debug_obj($str4);

&HP::Support::Base::allow_space_as_valid_string(TRUE);
$str4 = ' ' x 10;
$vs = &valid_string($str4);
is( $vs eq TRUE, 1 );
&debug_obj($str4);
&HP::Support::Base::allow_space_as_valid_string(FALSE);

my $str5 = 'Hello World -- 5pm';
$vs = &valid_string($str5);
is( $vs eq TRUE, 1 );
&debug_obj($str5);