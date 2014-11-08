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
	use_ok('HP::Support::ProgramManagement');
  }

my $sample_option = '-c, --cloud_computing';
my $result = &HP::Support::ProgramManagement::__reformat_option();
is ( (not defined($result)), 1 );

$result = &HP::Support::ProgramManagement::__reformat_option(4);
is ( (not defined($result)), 1 );

$result = &HP::Support::ProgramManagement::__reformat_option(4, $sample_option);
is ( defined($result), 1 );
is ( $result eq '-c  , --cloud_computing', 1 );

&debug_obj($result);