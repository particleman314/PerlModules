#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use lib "$FindBin::Bin/../../../PerlModules";

use Test::More tests => 3;

BEGIN
  {
    use_ok("HP::Mailer");
  }

my $result = $HP::Mailer::fromaddress;
is ( ( $result eq 'noreply@dev.nul' ), 1 );

&mailer_set_from_address('me@myself.i');
$result = $HP::Mailer::fromaddress;
is ( ( $result eq 'me@myself.i' ), 1 )
