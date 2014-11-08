#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('Cwd');
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Utilities');
	use_ok('HP::FileManager');
	use_ok('HP::DBContainer');
  }

&createDBs();
my $xmlobj = &create_object('c__HP::XMLObject__');
is ( defined($xmlobj), 1 );

# Need to make this more useful...
my $xmlfile = "$FindBin::Bin/sample_out.xml";
&delete("$xmlfile") if ( &does_file_exist("$xmlfile") eq TRUE );
$xmlobj->xmlfile("$xmlfile");

is ( (not defined($xmlobj->rootnode())) == 1, 1 );

my $dummy_hash = &create_object('c__HP::Stream::IO__');				 
&debug_obj($dummy_hash);

$xmlobj->writefile($xmlobj->prepare_xml($dummy_hash));
is ( &does_file_exist("$xmlfile") eq TRUE, 1 );
&delete("$xmlfile");

&debug_obj($xmlobj);
&shutdownDBs()


