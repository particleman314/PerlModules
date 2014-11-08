#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
	use_ok('HP::Support::Object');
    use_ok('HP::Support::Object::Tools');
  }

my $type = 'HP::ArrayObject';
my $details = { 'class' => "$type" };
my $obj = &HP::Support::Object::Tools::__convert_to_structure($details);

is ( defined($obj) == 1, 1 );
is ( &is_type($obj, "$type") eq TRUE, 1 );

$obj->{'empty1'} = undef;
$obj->{'empty2'} = undef;

&debug_obj($obj);
&HP::Support::Object::__cleanup_internals($obj);
&debug_obj($obj);

$type = 'HP::Array::PriorityQueue';
$details = { 'class' => "$type" };
$obj = &HP::Support::Object::Tools::__convert_to_structure($details);

is ( defined($obj) == 1, 1 );
is ( &is_type($obj, "$type") eq TRUE, 1 );

$obj->{'empty1'} = undef;
$obj->{'empty2'} = undef;
$obj->{'priority_list'}->{'empty1'} = undef;

&debug_obj($obj);
&HP::Support::Object::__cleanup_internals($obj);
&debug_obj($obj);
