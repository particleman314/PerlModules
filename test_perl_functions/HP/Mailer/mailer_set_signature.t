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
  
my $result = $HP::Mailer::signature;
is ( ( $result eq "\nbuildmail\n" ), 1 );

&mailer_set_signature('foosball');
$result = $HP::Mailer::signature;
is ( ( $result eq "foosball" ), 1 );
