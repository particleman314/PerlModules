#! /usr/bin/env perl
 
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";
use Test::More tests => 105;

BEGIN
  {
    require_ok('HP/TestTools.pl');
    use_ok('File::Spec');
    use_ok('File::Path');
	use_ok('HP::Constants');
    use_ok('HP::FileManager');
  }

my $testdir  = &MakeTempDir('DIRS');
my $numTests = 50;
for (my $testcounts = 0; $testcounts < $numTests; ++$testcounts) {
   my $filenameSize  = &MakeNumbers(3, 20, 1, 0);
   my $inputfilename = join("",&MakeLetters($filenameSize));
   my $outputgolden  = File::Spec->catdir("$testdir","$inputfilename");

   mkdir("$outputgolden", 0777);
   is( (-e "$outputgolden" and -d "$outputgolden"), 1);
   is( &does_directory_exist("$outputgolden") eq TRUE , 1);
   rmdir("$outputgolden");
}

rmtree("$testdir");
