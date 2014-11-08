#! /usr/bin/env perl
 
use FindBin;
use lib "$FindBin::Bin/../../../..";
use Test::More qw(no_plan);

BEGIN
  {
    require_ok('HP/TestTools.pl');
	use_ok('Time::HiRes');
	use_ok('HP::Support::Object::Tools');
	use_ok('HP::Array::Constants');
	use_ok('HP::Array::Tools');
  }

my @seqcnt = ( 10, 25, 50, 75, 100, 250, 500, 1000, 2000, 5000, 10000 );

foreach my $max_items (@seqcnt) {
  diag("\n -------->>>>>>> Testing with maximum items set to :: $max_items\n");

  my @input1 = &MakeNumbers(0,$max_items,$max_items,0);

  &test_pre_allocate(\@input1);
  &test_push(\@input1);
}

sub test_push($) {
  my $obj1 = &create_object('c__HP::ArrayObject__');

  diag ("\nBeginning Array Adding test with ". scalar(@{$_[0]}) . " elements\n" );

  my ($delta_time, $result) = &time_pushing($obj1, $_[0]);

  diag("\nDelta Time : $delta_time seconds with result $result\n");
}

sub test_pre_allocate($) {
  my $obj1 = &create_object('c__HP::ArrayObject__');

  diag ("\nBeginning Array Allocation test with ". scalar(@{$_[0]}) . " elements\n" );

  my ($delta_time, $result) = &time_pre_allocation($obj1, $_[0]);

  diag("\nDelta Time : $delta_time seconds with result $result\n");
}

sub time_pushing($$) {
  my $bgtime   = Time::HiRes::time();
  my $result   = $_[0]->add_elements({'entries' => $_[1]});
  my $edtime  = Time::HiRes::time();
  
  my $difftime = $edtime - $bgtime;
  return ($difftime, $result);
}

sub time_pre_allocation($$) {
  my $numitems = scalar(@{$_[1]});
  
  my $bgtime   = Time::HiRes::time();
  my $result   = $_[0]->allocate( $numitems );
  for ( my $loop = 0; $loop < $numitems; ++$loop ) {
    $_[0]->set_element($loop, $_[1]->[$loop] );
  }
  my $edtime  = Time::HiRes::time();
  
  my $difftime = $edtime - $bgtime;
  return ($difftime, $result);
}
