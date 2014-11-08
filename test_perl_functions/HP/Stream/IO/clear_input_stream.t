#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
  }

my $personal_stream = &create_object('c__HP::Stream::IO::Input__');
$personal_stream->valid(TRUE);

is ( defined($personal_stream), 1 );
is ( $personal_stream->valid() eq TRUE, 1 );

$personal_stream->clear();
is ( $personal_stream->valid() eq FALSE, 1 );

&debug_obj($personal_stream);
