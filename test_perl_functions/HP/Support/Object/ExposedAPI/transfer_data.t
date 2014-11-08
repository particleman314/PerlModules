#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
	use_ok('HP::Support::Object::Tools');
    use_ok('HP::Support::Object');
  }

my $details = { 'abc' => 'xyz', '123' => 'alpha-beta-gamma'};
my $copy_details = {};

is ( &equal($details, $copy_details) eq FALSE, 1 );

my $result = &transfer_data($details, $copy_details);
is ( $result eq FALSE, 1 );
is ( &equal($details, $copy_details) eq FALSE, 1 );

$copy_details->{'abc'} = undef;
$result = &transfer_data($details, $copy_details);
is ( $result eq TRUE, 1 );
is ( &equal($details, $copy_details) eq FALSE, 1 );

$copy_details->{'123'} = undef;
$result = &transfer_data($details, $copy_details);
is ( $result eq TRUE, 1 );
is ( &equal($details, $copy_details) eq TRUE, 1 );

&debug_obj($details);
&debug_obj($copy_details);
