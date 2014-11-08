#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
	use_ok('HP::Path');
  }
  
my $obj = &create_object('c__HP::CSL::Driver__');
is ( defined($obj), 1 );

my $bldxml = &normalize_path("$FindBin::Bin/../../SettingsFiles/build.xml");
diag("$bldxml");

$obj->readfile("$bldxml");

is ( $obj->executables()->number_elements() > 0, 1 );
is ( $obj->executables()->number_elements() == 6, 1 );

is ( $obj->mode() eq 'capsule', 1 );
&debug_obj($obj);