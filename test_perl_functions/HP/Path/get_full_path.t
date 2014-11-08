#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN
  {
    use_ok('Cwd');
    use_ok('File::Spec');
	use_ok('HP::Constants');
    use_ok('HP::String');
    use_ok('HP::Os');
    use_ok('HP::Support::Os');
    use_ok('HP::Path');
  }

my $is_windows = &os_is_windows_native();
my $conversion_from = 'backward';
my $conversion_to   = 'forward';

if ( $is_windows eq TRUE ) {
    $conversion_from = $conversion_to;
    $conversion_to   = 'backward';
}

is(&get_full_path('.'), &make_converted_path(getcwd()));
is(&get_full_path('/tmp'), &make_converted_path('/tmp'))          if ( &os_is_linux() eq TRUE);
is(&get_full_path('/tmp'), &make_converted_path('c:/cygwin/tmp')) if ( &os_is_cygwin() eq TRUE );

my $currdir = &getdcwd();
my $joindir = &make_converted_path(&join_path("$currdir", 'foo'));
is(&get_full_path('foo'), "$joindir");

sub make_converted_path($)
{
    my $result    = undef;
    my $component = shift;

    my $stmt = "\$result = \&HP\:\:Path\:\:__flip_slashes(\"\$component\", \"$conversion_from\", \"$conversion_to\");";
    eval "$stmt";
    $result = &lowercase_first("$result") if ( &HP::Path::__is_letter_drive("$result") );
    return $result;
}
