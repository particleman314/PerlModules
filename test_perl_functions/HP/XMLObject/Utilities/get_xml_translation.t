#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::XML::Utilities');
  }

my $translation = {
                   'xmltranslations' => {
				                         &BACKWARD => {
                                                       'test1' => 'field1',
				                                       'test2' => 'field2',
				                                       'test3' => 'field3',
													  },
					                    },
				  };

my %hash = %{$translation->{'xmltranslations'}->{&BACKWARD}};
my %hsah = reverse %hash;
	  
$translation->{'xmltranslations'}->{&FORWARD} = \%hsah;

my $objtemplate  = { 'test1' => undef, 'test2' => undef, 'test3' => undef, 'test4' => undef, 'test5' => undef };
my $control_data = &HP::XML::Utilities::__get_xml_control_data($objtemplate);

my $result = &get_xml_translation();
is ( (not defined($result)) == 1, 1 );

$result = &get_xml_translation('test1');
is ( $result eq 'test1', 1 );

$result = &get_xml_translation($translation);
is ( (not defined($result)) == 1, 1 );

$result = &get_xml_translation($translation, 'test3');
is ( $result eq 'field3', 1 );

$result = &get_xml_translation($translation, 'test5');
is ( $result eq 'test5', 1 );

$result = &get_xml_translation($translation, 'field3', FORWARD);
is ( $result eq 'test3', 1 );

&debug_obj($translation);
