#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More tests => 4;

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('HP::Mailer');
  }
  
my $result = $HP::Mailer::smtpserver;
is ( ( $result eq "mail.hp.com" ), 1 );

&mailer_set_smtp_server('mail.server');
$result = $HP::Mailer::smtpserver;
is ( ( $result eq "mail.server" ), 1 );
