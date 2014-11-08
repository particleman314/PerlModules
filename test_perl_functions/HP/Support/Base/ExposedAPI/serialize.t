#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok('HP::Support::Base');
	use_ok('HP::Support::Base::Constants');
	use_ok('HP::Support::Object::Tools');
  }
  
my $serialized_obj = undef;
my $data = &serialize($serialized_obj);
is ( ( not defined($data) ), 1 );

$serialized_obj = 'Four score and seven years ago...';
$data = &serialize($serialized_obj);
is ( defined($data), 1 );
&debug_obj($data);

$serialized_obj = &create_object('HP::ArrayObject');
is ( defined($serialized_obj), 1 );
$data = &serialize($serialized_obj);
is ( defined($data), 1 );
&debug_obj($data);

$serialized_obj = [];
push(@{$serialized_obj}, &create_object('HP::ArrayObject'), &create_object('HP::ArrayObject'));
is ( scalar(@{$serialized_obj}) == 2, 1 );
$data = &serialize($serialized_obj);
is ( defined($data), 1 );
&debug_obj($data);
