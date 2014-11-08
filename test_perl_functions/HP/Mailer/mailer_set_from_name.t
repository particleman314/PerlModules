#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use lib "$FindBin::Bin/../../../PerlModules";

use Test::More tests => 4;

BEGIN
  {
    use_ok("HP::Os");
    use_ok("HP::Mailer");
  }

my $result = $HP::Mailer::fromname;
is ( ( $result eq &get_hostname() ), 1 );

&mailer_set_from_name('Mike');
$result = $HP::Mailer::fromname;
is ( ( $result eq 'Mike' ), 1 )
