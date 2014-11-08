#! /usr/bin/env perl
 
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More tests => 8;

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::FileManager');
	use_ok('HP::Path');
  }

my $intended_dir = &get_resolved_path("$FindBin::Bin/../../../..");
&debug_obj($intended_dir);
is ( &does_directory_exist("$intended_dir") eq TRUE, 1 );

my $collection_agency = \&collect_directory_contents;
is ( defined($collection_agency) eq TRUE, 1 );

my $results = &work_in_directory("$intended_dir", $collection_agency, "$intended_dir");
is ( scalar(@{$results->{'directories'}}) > 0 , 1 );
is ( scalar(@{$results->{'files'}}) > 0 , 1 );

&debug_obj($results);
