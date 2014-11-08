#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
	use_ok('HP::Constants');
    use_ok('HP::Support::Configuration');
  }

my $path  = 'this->is->a->perl->style->test';
my $npath = &normalize_configuration_path("$path");

is ( $path eq $npath, 1 );

$path  = 'this.is.a.java.style.test';
$npath = &normalize_configuration_path("$path");

is ( $path ne $npath, 1 );
is ( $npath eq 'this->is->a->java->style->test', 1 );

$path  = 'this|is|a|unique|style|test';
$npath = &normalize_configuration_path("$path");

is ( $path ne $npath, 1 );
is ( $npath eq 'this->is->a->unique->style->test', 1 );

$path  = 'this->is.a|mixed->style.test';
$npath = &normalize_configuration_path("$path");

is ( $path ne $npath, 1 );
is ( $npath eq 'this->is->a->mixed->style->test', 1 );

$path  = 'this+is+a+made+up+path+using+the+plus+connector';
$npath = &normalize_configuration_path("$path", ['+']);

is ( $path ne $npath, 1 );
is ( $npath eq 'this->is->a->made->up->path->using->the->plus->connector', 1 );

$npath = &normalize_configuration_path("$path", ['+'], '.');

is ( $path ne $npath, 1 );
is ( $npath eq 'this.is.a.made.up.path.using.the.plus.connector', 1 );