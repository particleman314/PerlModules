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

my $result = &convert_from_colon_module();
is ( scalar(@{$result}) eq 0, 1 );

$result = &convert_from_colon_module('Text::Format');
is ( scalar(@{$result}) eq 1, 1 );
is ( $result->[0] eq 'Text/Format.pm', 1 );

&debug_obj($result);

my @inputs = qw(Text::Format HP::OsSupport HP::Array::Set);
my @answers = qw(Text/Format.pm HP/OsSupport.pm HP/Array/Set.pm);

my @result = &convert_from_colon_module(@inputs);
is ( scalar(@result) eq 3, 1 );
for ( my $loop = 0; $loop < scalar(@result); ++$loop ) {
  is ( $result[$loop] eq $answers[$loop], 1 );
}

&debug_obj(\@result);

$result = &convert_from_colon_module(@inputs);
is ( scalar(@{$result}) eq 3, 1 );
for ( my $loop = 0; $loop < scalar(@{$result}); ++$loop ) {
  is ( $result->[$loop] eq $answers[$loop], 1 );
}