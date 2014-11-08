#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN
  {
    use_ok('HP::Constants');
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

isnt(length(&get_temp_dir()), 0);

is(&path_is_rel('/foo'), 0);
is(&path_is_rel('foo/bar'), 1);
if (&os_is_windows()) {
    is(&path_is_rel('c:/temp'), 0);
}

is(&join_path('foo', 'bar'), &make_converted_path('foo/bar'));
is(&join_path('foo/', 'bar'), &make_converted_path('foo/bar'));
is(&join_path('foo/', '/bar'), &make_converted_path('/bar'));

is(&get_path_delim(), ( &os_is_windows_native() eq TRUE ) ? ';' : ':');

is(&get_dir_sep(), ( &os_is_windows_native() eq TRUE ) ? '\\' : '/');

is(&normalize_path('/foo//bar'), &make_converted_path('/foo/bar'));

sub make_converted_path($)
{
    my $result    = undef;
    my $component = shift;

    my $stmt = "\$result = \&HP\:\:Path\:\:__flip_slashes(\"\$component\", \"$conversion_from\", \"$conversion_to\");";
    eval "$stmt";
    return $result;
}
