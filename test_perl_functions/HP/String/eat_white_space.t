#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::Base');
    use_ok('HP::String');
  }

my $result = &eat_white_space();
is ( (not defined($result)), 1 );

&HP::Support::Base::allow_space_as_valid_string(TRUE);

$result = &eat_white_space(' ');
is ( defined($result), 1 );
is ( $result eq '', 1 );

my @topten = &MakeNumbers(10, 20, 10, 'fixed');

foreach ( @topten ) {
  $result = &eat_white_space(' ' x $_);
  is ( defined($result), 1 );
  is ( $result eq '', 1 );
}

my @front = &MakeNumbers(10, 20, 10, 'fixed');
my @back = &MakeNumbers(10, 20, 10, 'fixed');

for ( my $loop = 0; $loop < scalar(@front); ++$loop ) {
  my $str = ' ' x $front[$loop] . 'This is a test' . ' ' x $back[$loop];
  $result = &eat_white_space("$str");
  is ( defined($result), 1 );
  is ( $result eq 'This is a test', 1 );
}