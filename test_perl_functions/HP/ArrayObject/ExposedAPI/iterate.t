#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Constants');
	use_ok('HP::Array::Tools');
	use_ok('HP::CheckLib');
  }
  
my @input1 = ( 1 .. 5, 7 .. 10 );

my $arrobj1 = &create_object('c__HP::ArrayObject__');
$arrobj1->add_elements( {'entries' => \@input1, 'location' => APPEND} );
$arrobj1->add_elements( {'entries' => [6], 'location' => PREPEND});

my $arrobj2 = $arrobj1->iterate({'return_code_only' => FALSE,
                                 'transformation'   => \&lambda_function,
								 'mutate'           => FALSE});
								 
is ( defined($arrobj2), 1 );
is ( &equal($arrobj1, $arrobj2) eq FALSE, 1 );

my $naked_array = $arrobj1->iterate({'return_code_only' => TRUE,
                                     'transformation'   => \&lambda_function,
							         'mutate'           => FALSE});
&debug_obj($naked_array);
is ( defined($naked_array), 1 );
is ( scalar(@{$naked_array}) == scalar(@input1) + 1, 1 );

&debug_obj( $arrobj1 );
&debug_obj( $arrobj2 );

sub lambda_function
{
  my $input = $_[0];
  
  my $output = undef;
  
  if ( &is_integer($input) ) {
    $output = $input * 3;
  } else {
    $output = $input
  }
  
  return $output;
}