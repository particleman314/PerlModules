#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN
  {
    use_ok('Cwd');
    use_ok('HP::Os');
    use_ok('HP::Support::Os');
    use_ok('HP::Path');
  }

my $is_windows = &os_is_windows_native();
my $conversion_from = 'backward';
my $conversion_to   = 'forward';

if ( $is_windows ) {
    $conversion_from = $conversion_to;
    $conversion_to   = 'backward';
}

is(&find_relative_path("c:/root/bin", "c:/root/sbin"), &make_converted_path("../sbin"));
is(&find_relative_path("/usr/src/sg/base/src/some/code", "/usr/src/sg/output/release/bin"), &make_converted_path("../../../../output/release/bin")) if ( &os_is_linux() );

is(&find_relative_path(getcwd(), '.'), '.');
is(&find_relative_path('.', getcwd()), '.');
is(&find_relative_path('c:/src/include', 'c:/src'), '..');
is(&find_relative_path('c:/src', 'c:/src/include'), 'include');
is(&find_relative_path('c:/src', 'c:/src'), '.');

sub make_converted_path($)
{
    my $result    = undef;
    my $component = shift;

    my $stmt = "\$result = \&HP\:\:Path\:\:__flip_slashes(\"$component\", \"$conversion_from\", \"$conversion_to\");";
    eval "$stmt";
    return $result;
}
