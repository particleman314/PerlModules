#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use lib "$FindBin::Bin/../../../PerlModules";

use Test::More tests => 6;

BEGIN
  {
    use_ok("HP::Mailer");
  }
  
eval { &mailer_set_signature('foosball'); };
is(length($@), 0);
eval { &mailer_set_from_address('me@myself.i'); };
is(length($@), 0);
eval { &mailer_set_from_name('Bob'); };
is(length($@), 0);
eval { &mailer_set_subject_prefix('Test'); };
is(length($@), 0);
eval { &mailer_set_smtp_server('mail.server'); };
is(length($@), 0);
