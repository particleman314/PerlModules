#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
	use_ok('HP::Support::Module');
	use_ok('HP::Support::Object');
	use_ok('HP::Support::Object::Tools');
    use_ok('HP::XML::Utilities');
  }

my $converter_hash = {
                      'test1' => {
					              &BACKWARD => [ 'main::convert1', TRUE ],
					             },
					  'test2' => {
					              &FORWARD  => [ 'main::convertF2', TRUE ],
					              &BACKWARD => [ 'main::convertB2', TRUE ],
								 },
					  'test3' => 'main::convert3',
					  'test4' => {
					              &BACKWARD => [ 'main::convert4' ],
					             },
					  'test5' => {
					              &BACKWARD => [ 'main::convert5', undef ],
					             },
					 };

my $objtemplate = { 'test1' => undef, 'test2' => undef, 'test3' => undef, 'test4' => undef, 'test5' => undef };
my $obj = &create_object($objtemplate);
is ( defined($obj) == 1, 1 );

foreach ( @{&get_fields($obj)} ) {
  my $value = "$_";
  $value =~ s/test//;
  
  $obj->{"$_"} = $value;
}

my $result = &HP::XML::Utilities::__convert_xml_data($obj, 'test1', $converter_hash);  # Defaults to FORWARD direction
print STDERR "Answer = $result\n";
is ( $result eq '1', 1 );

$result = &HP::XML::Utilities::__convert_xml_data($obj, 'test1', $converter_hash, BACKWARD);
print STDERR "Answer = $result\n";
is ( $result eq '1 -- converted1', 1 );

$result = &HP::XML::Utilities::__convert_xml_data($obj, 'test2', $converter_hash);
print STDERR "Answer = $result\n";
is ( $result eq '2 -- FORWARD converted2', 1 );

$result = &HP::XML::Utilities::__convert_xml_data($obj, 'test2', $converter_hash, BACKWARD);
print STDERR "Answer = $result\n";
is ( $result eq '2 -- converted2 BACKWARD', 1 );

$result = &HP::XML::Utilities::__convert_xml_data($obj, 'test3', $converter_hash);
print STDERR "Answer = $result\n";
is ( $result eq '3 -- converted3', 1 );

$result = &HP::XML::Utilities::__convert_xml_data($obj, 'test3', $converter_hash, BACKWARD);
print STDERR "Answer = $result\n";
is ( $result eq '3 -- converted3', 1 );

$result = &HP::XML::Utilities::__convert_xml_data($obj, 'test4', $converter_hash, FORWARD);
print STDERR "Answer = $result\n";
is ( $result eq '4', 1 );

$result = &HP::XML::Utilities::__convert_xml_data($obj, 'test4', $converter_hash, BACKWARD);
print STDERR "Answer = $result\n";
is ( $result eq '4 -- converted4', 1 );

$result = &HP::XML::Utilities::__convert_xml_data($obj, 'test5', $converter_hash, FORWARD);
print STDERR "Answer = $result\n";
is ( $result eq '5', 1 );

$result = &HP::XML::Utilities::__convert_xml_data($obj, 'test5', $converter_hash, BACKWARD);
print STDERR "Answer = $result\n";
is ( $result eq '5 -- converted5', 1 );

&debug_obj($converter_hash);
&debug_obj($obj);
					 
					 
# --------------------------

sub convert1($)
  {
    my $input = shift;
	my $output = "$input -- converted1";
	return $output;
  }

sub convertF2($)
  {
    my $input = shift;
	my $output = "$input -- FORWARD converted2";
	return $output;
  }

sub convertB2($)
  {
    my $input = shift;
	my $output = "$input -- converted2 BACKWARD";
	return $output;
  }

sub convert3($)
  {
    my $input = shift;
	my $output = "$input -- converted3";
	return $output;
  }

sub convert4($)
  {
    my $input = shift;
	my $output = "$input -- converted4";
	return $output;
  }

sub convert5($)
  {
    my $input = shift;
	my $output = "$input -- converted5";
	return $output;
  }
