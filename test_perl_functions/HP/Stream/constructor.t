#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::Stream');
  }

my $personal_stream = HP::Stream->new();
is ( defined($personal_stream), 1 );
is ( (not defined($personal_stream->entry()->get_path())) == 1, 1);
is ( $personal_stream->valid() eq FALSE, 1 );

&debug_obj($personal_stream);


