#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::CheckLib');
	use_ok('HP::Support::Object');
	use_ok('HP::Support::Object::Tools');
    use_ok('HP::XML::Utilities');
  }

my @expected_keys = qw(attribute_fields convertible_fields data_fields forced_output_fields skipped_fields);
my $objtemplate = { 'test1' => undef, 'test2' => undef, 'test3' => undef, 'test4' => undef, 'test5' => undef };

my $obj = &create_object($objtemplate);
is ( defined($obj) == 1, 1 );

foreach ( @{&get_fields($obj)} ) {
  my $value = "$_";
  $value =~ s/test//;
  
  $obj->{"$_"} = $value;
}

my $result = &HP::XML::Utilities::__get_xml_control_data($objtemplate);  # Straight hash

foreach (@expected_keys) {
  is ( exists($result->{'method'}->{"$_"}) == 1, 1 );
  next if ( "$_" eq 'convertible_fields' );
  if ( $_ eq 'data_fields' ) {
    is ( &is_type($result->{'method'}->{"$_"}, 'HP::ArrayObject') eq TRUE, 1 );
    next;
  }
  is ( &is_type($result->{'method'}->{"$_"}->[1], 'HP::ArrayObject') eq TRUE, 1 );
}

$result = undef;
is ( ( not defined($result) ) == 1, 1 );

$result = &HP::XML::Utilities::__get_xml_control_data($obj); # Perl Object
foreach (@expected_keys) {
  is ( exists($result->{'method'}->{"$_"}) == 1, 1 );
  next if ( "$_" eq 'convertible_fields' );
  if ( $_ eq 'data_fields' ) {
    is ( &is_type($result->{'method'}->{"$_"}, 'HP::ArrayObject') eq TRUE, 1 );
    next;
  }
  is ( &is_type($result->{'method'}->{"$_"}->[1], 'HP::ArrayObject') eq TRUE, 1 );
}

&debug_obj($result);
&debug_obj($obj);
