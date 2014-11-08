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
  
my $obj = &create_object('c__HP::HPLN::IndexGenerator__');
is ( defined($obj), 1 );

my $idxfiles = $obj->get_index_files();
is ( scalar(@{$idxfiles}) == 0 , 1 );

&debug_obj($obj);
