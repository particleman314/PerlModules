#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok('HP::Support::Base');
	use_ok('HP::Support::Base::Constants');
  }
  
my $method_name = &get_method_name();
is ( ( not defined($method_name) ), 1 );

&diag($method_name) if ( defined($method_name) );

&trial_sub;


sub trial_sub {
  my $method_name = &get_method_name();
  &diag($method_name);
  is ( defined($method_name), 1 );
  is ( $method_name =~ m/trial_sub/i, 1 );
}