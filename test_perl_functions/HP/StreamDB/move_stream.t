#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
  }

my $strDB = &create_instance('c__HP::StreamDB__');
is ( $strDB->number_streams() == 3, 1);

my $personal_stream = &create_object('c__HP::Stream::IO__');
$personal_stream->active(TRUE);
$strDB->add_stream('PS', $personal_stream);

is ( $strDB->number_streams() == 4, 1);

my $result = $strDB->move_stream();
is ( $result eq FALSE, 1 );

$result = $strDB->move_stream('');
is ( $result eq FALSE, 1 );

$result = $strDB->move_stream('     ', 'PS2');
is ( $result eq FALSE, 1 );

$result = $strDB->move_stream('PS', 'PS2');
is ( $result eq TRUE, 1 );

is ( $strDB->number_streams() == 4, 1 );
$result = $strDB->has_handle('PS2');
is ( $result eq TRUE, 1 );
$result = $strDB->has_handle('PS');
is ( $result eq FALSE, 1 );

&debug_obj($strDB);