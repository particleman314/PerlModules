#! /usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN
  {
    require_ok("HP/TestTools.pl");
    use_ok("File::Spec");
    use_ok("File::Path");
    use_ok("Cwd");
    use_ok("HP::Path");
    use_ok("HP::FileManager");
  }

exit 0;
my $numTests = 1;
my @madeDirs = ();

my $testDir = &MakeTempDir('STRIPDIRS');

for (my $testcounts = 0; $testcounts < $numTests; ++$testcounts) {
   my $dirnameSize  = &MakeNumbers(3, 20, 1, 0);
   my $inputdirname = join("",&MakeLetters($dirnameSize));
   my $outputgolden = File::Spec->catdir("$testDir", "$inputdirname");

   diag("Making golden dir --> $outputgolden");
   mkpath("$outputgolden", 0, 0777);
   is( (-d "$outputgolden"), 1);
   push(@madeDirs, "$inputdirname");
}

&strip_directories("$testDir", @madeDirs);

foreach (@madeDirs) {
   my $outputgolden = File::Spec->catdir("$testDir","$_");
   isnt( (-d "$outputgolden"), 1);
}

@madeDirs = ();
my @allDirs = ();

for (my $testcounts = 0; $testcounts < $numTests; ++$testcounts) {
   my $dirnameSize  = &MakeNumbers(3, 20, 1, 0);
   my $inputdirname = join("",&MakeLetters($dirnameSize));
   my $outputgolden = File::Spec->catdir("$testDir", "$inputdirname");
   mkpath("$outputgolden", 0, 0777);
   is( (-d "$outputgolden"), 1);
   push(@madeDirs, "$outputgolden") if ($testcounts % 3 == 0);
   push(@allDirs, "$outputgolden");
}

&strip_directories("$testDir", @madeDirs);

#foreach (@allDirs) {
#   my $outputgolden = $_;
#   if ( &ART_Contains("$_", \@madeDirs) ) {
#     is( (-d "$outputgolden"), 1);
#   } else {
#     isnt ( (-d "$outputgolden"), 1);
#   }
#}

rmtree("$testDir");
