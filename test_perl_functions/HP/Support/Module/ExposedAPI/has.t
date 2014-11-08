#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Support::Module');
  }

my $result = &has();
is ( ( not defined($result) ) , 1 );
  
my $module_name = 'Text::Format';
$result = &has($module_name);
is ( $result eq TRUE, 1 );

$module_name = 'ABC::XYZ';
$result = &has($module_name);
is ( $result eq FALSE, 1 );

my @module_names = qw(Text::Format ABC::XYZ);
$result = &has(@module_names);
is ( scalar(@{$result}) == 2, 1 );
is ( $result->[0] eq TRUE, 1 );
is ( $result->[1] eq FALSE, 1 );

