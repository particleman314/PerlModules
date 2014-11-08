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
    use_ok('HP::String');
    use_ok('HP::Path');
  }

my $is_windows = &os_is_windows_native();
my $conversion_from = 'backward';
my $conversion_to   = 'forward';

if ( $is_windows eq TRUE ) {
    $conversion_from = $conversion_to;
    $conversion_to   = 'backward';
}

is(&path_find_common_root("c:/root", "c:/root/notroot"), &make_converted_path("c:/root/"));
is(&path_find_common_root("c:/temp/stuff", "c:/windows"), &make_converted_path("c:/"));
is(&path_find_common_root("/tmp/stuff", "/usr/var"), &make_converted_path("/"));
is(&path_find_common_root("/usr/local/bin", "/usr/bin"), &make_converted_path("/usr/"));

sub make_converted_path($)
{
    my $result    = undef;
    my $component = shift;

    my $stmt = "\$result = \&HP\:\:Path\:\:__flip_slashes(\"\$component\", \"$conversion_from\", \"$conversion_to\");";
    eval "$stmt";
    if ( &os_is_windows() eq TRUE ) {
	  $result = &path_to_mixed("$result",{'cygpath_options' => '-m' });
    }
    if ( &HP::Path::__is_letter_drive("$result") ) {
	  $result = &lowercase_first("$result");
    }
    return $result;
}
