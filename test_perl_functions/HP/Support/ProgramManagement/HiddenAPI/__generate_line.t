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

my ($maxs, $maxl) = &HP::Support::ProgramManagement::__find_max_length_key($sample_hash);
my $line = &HP::Support::ProgramManagement::__generate_line($maxs, $maxl, '-k, --key1', $sample_hash->{'-k, --key1'});
chomp($line);
is ( defined($line), 1 );
is ( $line eq '    -k, --key1              [O]  sample key', 1 );

&debug_obj($line);

$line = &HP::Support::ProgramManagement::__generate_line($maxs, $maxl, '--amazon', $sample_hash->{'--amazon'});
chomp($line);
is ( defined($line), 1 );
is ( $line eq '     , --amazon             [O]  a book online seller', 1 );

&debug_obj($line);