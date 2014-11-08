#! /usr/bin/env perl
 
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More tests => 104;

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('File::Spec');
	use_ok('HP::Support::Object::Tools');
    use_ok('HP::FileManager');
  }

my $testdir  = &MakeTempDir('DELETIONS');
my $numTests = 50;

my $strobj = &create_object('c__HP::Stream::IO::Output__');

for (my $testcounts = 0; $testcounts < $numTests; ++$testcounts) {
   my $filenameSize  = &MakeNumbers(3, 20, 1, 0);
   my $inputfilename = join("",&MakeLetters($filenameSize));
   my $outputgolden  = File::Spec->catfile("$testdir","$inputfilename.LOCK");
   $strobj->touch_file("$outputgolden");
   is( (-e "$outputgolden"), 1);
   &delete("$outputgolden");
   isnt( (-e "$outputgolden"), 1);
}

rmtree("$testdir");
