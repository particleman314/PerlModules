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

my $basic_string = 'XYZ';

my $input = ' ';
my $result = &dereference($input);
is ( $result eq $input, 1 );

$input = [ 1, 3, 6 ];
my @result = &dereference($input);
&debug_obj(\@result);

$input = \$basic_string;
my @result = &dereference($input);
&debug_obj(\@result);

$input = {'one' => 1, 'two' => 2};
my %result = &dereference($input);
&debug_obj(\%result);
