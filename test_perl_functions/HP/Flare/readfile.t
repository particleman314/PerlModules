#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
  }
  
my $obj = &create_object('c__HP::Flare::Directive__');
is ( defined($obj), 1 );

my $trialfile = "$FindBin::Bin/../SettingsFiles/flare.xml";
$obj->readfile("$trialfile");

&debug_obj($obj);