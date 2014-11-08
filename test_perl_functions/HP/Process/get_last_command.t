#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../.."; 

use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('File::Path');
	use_ok('HP::Constants');
    use_ok('HP::Support::Os');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Os');
    use_ok('HP::Path');
	use_ok('HP::FileManager');
    use_ok('HP::Process');
  }

my $tempdir = &MakeTempDir('RUNCMD');
my $basecmd = undef;

if ( &os_is_windows_native() eq FALSE ) {
  $basecmd = &which('ls');
} else {
  $basecmd = 'dir';
}

if ( &os_is_cygwin() eq TRUE ) { $basecmd = &path_to_mixed("$basecmd", { 'cygpath_options' => '-m' }); }

diag($basecmd);
my ($status, $output) = &runcmd("$basecmd");
is ($status, 0);

my $tempfile = undef;
$tempfile = &join_path("$tempdir",'TemporaryFile.txt');
$tempfile = &path_to_mixed("$tempfile") if ( &os_is_windows_native() eq FALSE);
diag("Temp file --> $tempfile");

my $strobj = &create_object('c__HP::Stream::IO::Output__');
$strobj->touch_file("$tempfile");
my $hashref = {
               'command' => "$basecmd",
	           'arguments' => &join_path("$tempdir","*.txt"),
              };

if ( &os_is_windows_native() eq FALSE ) {
  $hashref->{'arguments'} = &path_to_mixed("$hashref->{'arguments'}");
  if ( index("$hashref->{'arguments'}", ' ') > -1 ) { $hashref->{'arguments'} = "\"$hashref->{'arguments'}\""; }
}
($status, $output) = &runcmd($hashref);
is ($status, 0);
diag(join("\n",@{$output}));

$hashref->{'arguments'} = "$tempfile";
($status, $output) = &runcmd($hashref);
is ($status, 0);
diag(join("\n",@{$output}));

&delete("$tempfile");
rmtree("$tempdir", 0, 0);

my $result = &get_last_command();
is ( defined($result), 1 );

&debug_obj($result);