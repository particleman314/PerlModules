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

my $type = 'HP::BaseObject';
my $ctype = 'c__'. $type .'__';

$objtemplate = { 'field2' => [], 'field1' => "[] $ctype 1" };
$obj = &create_object($objtemplate);
is ( defined($obj) == 1, 1 );
is ( scalar(keys(%{$obj})) == 2, 1 );
is ( &is_type($obj->{'field1'}, "$type") eq TRUE, 1 );

my $result = &get_template_obj($obj->{'field1'});
is ( defined($result) == 1, 1 );
is ( &is_type($result, "$type") eq TRUE, 1 );

&debug_obj($obj);
&debug_obj($obj->{'field1'});