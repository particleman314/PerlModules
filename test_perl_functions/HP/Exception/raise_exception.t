#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('HP::Constants');
    use_ok('HP::Exception::Tools');
	use_ok('HP::DBContainer');
  }

&createDBs();
my $e = &make_exception('HP::FileManager::Exception::ChangePermissions');
is ( defined($e), 1 );
&debug_obj($e);

&raise_exception(
                 {
				  'type'    => 'HP::FileManager::Exception::ChangePermissions',
				  'message' => 'What a test this is...',
				  'handles' =>  [ 'STDERR' ],
				  'bypass'  => TRUE,
				 }
				);

#&raise_exception(
#                 {
#				  'type'    => 'HP::FileManager::Exception::ChangePermissions',
#				  'message' => 'What a test this is...',
#				  'handles' =>  [ 'STDERR' ],
#				  'callback'  => \&callback_func,
#				 }
#				);

$SIG{'__DIE__'} = \&callback_func;
&raise_exception(
                 {
				  'type'    => 'HP::FileManager::Exception::ChangePermissions',
				  'message' => 'What a test this is...',
				  'handles' =>  [ 'STDERR' ],
				 }
				);
$SIG{'__DIE__'} = undef;
&shutdownDBs();

sub callback_func()
{
  print STDERR "CALLBACK FUNCTION FOUND!\n";
}
			