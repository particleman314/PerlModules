#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok('HP::Constants');
	use_ok('HP::Support::ProgramManagement');
  }

my $sample_hash = {
                   '-k, --key1' => 'sample key',
				   '-h, --help' => 'help option',
				   '-a, --ada'  => 'a computer language',
				   '-c, --cloud_computing' => 'the new wave of the future',
				   '--amazon' => 'a book online seller',
                  };

my ($maxs, $maxl) = &HP::Support::ProgramManagement::__find_max_length_key();
is ( ( not defined($maxs) ), 1 );
is ( ( not defined($maxl) ), 1 );

my $simple_scalar = '-h --help';
($maxs, $maxl) = &HP::Support::ProgramManagement::__find_max_length_key($simple_scalar);
is ( ( not defined($maxs) ), 1 );
is ( ( not defined($maxl) ), 1 );

my $sample_array = [];
($maxs, $maxl) = &HP::Support::ProgramManagement::__find_max_length_key($sample_array);
is ( ( not defined($maxs) ), 1 );
is ( ( not defined($maxl) ), 1 );

my $empty_hash = {};
($maxs, $maxl) = &HP::Support::ProgramManagement::__find_max_length_key($empty_hash);
is ( defined($maxs), 1 );
is ( defined($maxl), 1 );
is ( $maxs == 0, 1 );
is ( $maxl == 0, 1 );

($maxs, $maxl) = &HP::Support::ProgramManagement::__find_max_length_key($sample_hash);
is ( defined($maxs), 1 );
is ( defined($maxl), 1 );
is ( $maxs == 1, 1 );
is ( $maxl == 15, 1 );

&debug_obj($sample_hash);