#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More qw(no_plan);

BEGIN
{
    use_ok('HP::Constants');
	use_ok('HP::Support::Os');
    use_ok('HP::Process');
	use_ok('HP::Utilities');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Stream::Constants');
	use_ok('HP::Path');
	use_ok('HP::FileManager');
}

my $pid     = &get_pid();
my $tempdir = &get_temp_dir();

my $testfile = &join_path("$tempdir", "test_process-$pid.txt");

my $strDB = &create_instance('c__HP::StreamDB__');
my $stream = $strDB->make_stream("$testfile", OUTPUT, '__RunLog__');

is( defined($stream), 1 );
my $script = &join_path("$FindBin::Bin", 'testprocess.pl');

my $cmd = {
           'application' => "$^X",
	       'command'     => "$script",
          };

if ( &os_is_windows_native() eq TRUE ) {
  $cmd->{'application'} = &path_to_mixed($cmd->{'application'});
  $cmd->{'command'}     = &path_to_mixed($cmd->{'command'});
}

diag("\n". $cmd->{'application'} ." -- ". $cmd->{'command'});
ok(&run_and_print($cmd, [ '__RunLog__' ]) == 0);
$strDB->remove_stream('__RunLog__');

# Make sure source file and generated log file are identical.
ok(open(F1, "$testfile"));

my $goldtestfile = &join_path("$FindBin::Bin", 'testfile.txt');

ok(open(F2, "$goldtestfile"));

diag("\nTESTFILE = $testfile :: GOLDFILE = $goldtestfile\n");

my $layers = ":raw:perlio";

binmode(F1, $layers);
binmode(F2, $layers);

my @t = F1->getlines();
my @s = F2->getlines();
close(F1);
close(F2);

diag( "A )\n@t\n" );
diag( "B )\n@s\n" );

is ( scalar(@t) == scalar(@s), 1 );

for ( my $loop = 0; $loop < scalar(@t); ++$loop ) {
  my $stripped_t = &remove_line_endings($t[$loop]);
  my $stripped_s = &remove_line_endings($s[$loop]);
  next if ( length($stripped_t) < 1 );
  is($stripped_t eq $stripped_s, 1);
}

# Cleanup
&delete("$testfile");