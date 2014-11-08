#! /usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('Cwd');
	use_ok('HP::Constants');
    use_ok('HP::Support::Object::Tools');
  }

my $obj = &create_object('c__HP::FileFinder__');
is ( $obj->valid() eq FALSE, 1 );

$obj->add_test_condition('-e $_');
$obj->add_test_condition('! -d $_');
is ( scalar(@{$obj->test_conditions()->get_elements()}) == 2, 1 );
is ( $obj->valid() eq FALSE, 1 );

$obj->validate();  # Chooses current directory and sets up necessary settings
is ( $obj->valid() eq TRUE, 1 );

$obj->set_max_depth(1);

is ( $obj->valid() eq FALSE, 1 );

$obj->set_rootpath($obj->rootpath());
$obj->validate();
$obj->run();
is ( scalar(@{$obj->matches()->get_elements()}) >= 4, 1 );

$obj->add_test_condition('$_ =~ m/\.pl$/');
is ( scalar(@{$obj->test_conditions()->get_elements()}) == 3, 1 );
$obj->validate();
is ( $obj->valid() eq TRUE, 1 );

$obj->run();
is ( scalar(@{$obj->matches()->get_elements()}) == 2, 1 );

&debug_obj($obj);