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
  
my $result = $HP::Mailer::subjectprefix;
is ( ( $result eq "[MAILER]" ), 1 );

&mailer_set_subject_prefix('Test');
$result = $HP::Mailer::subjectprefix;
is ( ( $result eq "Test" ), 1 );
