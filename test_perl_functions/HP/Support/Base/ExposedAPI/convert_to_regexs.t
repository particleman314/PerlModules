#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok('HP::Support::Base');
	use_ok('HP::Support::Base::Constants');
  }
  
my $str1    = 'rs';
my $regex1  = &convert_to_regexs($str1);
is ( $regex1 eq quotemeta($str1), 1 );
&debug_obj(\$regex1);

my $str2    = 'rs:';
my $regex2  = &convert_to_regexs($str2);
is ( $regex2 eq quotemeta($str2), 1 );
&debug_obj(\$regex2);

my $str3    = 'sample string with @*% chars';
my $regex3  = &convert_to_regexs($str3);
is ( $regex3 eq quotemeta($str3), 1 );
&debug_obj(\$regex3);

my $arr1 = [ $str1, $str2, $str3 ];
my $regex4 = &convert_to_regexs($arr1);
is ( scalar(@{$regex4}) == 3, 1);
is ( $regex4->[0] eq quotemeta($str1), 1);
&debug_obj(\$regex4);

&debug_obj(COMPILED_REGEX);