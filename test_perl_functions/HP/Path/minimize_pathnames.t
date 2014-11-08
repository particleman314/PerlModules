#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../..";

use Test::More qw(no_plan);

BEGIN
  {
    use_ok('HP::Os');
	use_ok('HP::Constants');
    use_ok('HP::Support::Os');
    use_ok('HP::String');
    use_ok('HP::Path');
  }

exit 0;
  
my $is_windows = &os_is_windows_native();
my $conversion_from = 'backward';
my $conversion_to   = 'forward';

if ( $is_windows eq TRUE ) {
    $conversion_from = $conversion_to;
    $conversion_to   = 'backward';
}

is(&normalize_path('//xcopsg/users/mhirsch/'), &make_converted_path('//xcopsg/users/mhirsch/'));
is(&normalize_path('a//'), &make_converted_path('a/'));
is(&normalize_path('/xcopsg/users//mhirsch/'), &make_converted_path('/xcopsg/users/mhirsch/'));
is(&normalize_path('/xcopsg/users/../mhirsch/'), &make_converted_path('/xcopsg/mhirsch/'));
is(&normalize_path('/xcopsg/users/./mhirsch/'), &make_converted_path('/xcopsg/users/mhirsch/'));
is(&normalize_path('/xcopsg/users/mhirsch/'),  &make_converted_path('/xcopsg/users/mhirsch/'));
is(&normalize_path('/xcopsg/users/mhirsch/', 0), &make_converted_path('/xcopsg/users/mhirsch'));
is(&normalize_path('C://'), &make_converted_path('C:/'));
is(&normalize_path('C://foo'), &make_converted_path('C:/foo'));
is(&normalize_path('x://foo/bar'), &make_converted_path('x:/foo/bar'));
is(&normalize_path('x://output/release/lib/FPShared.map'), &make_converted_path('x:/output/release/lib/FPShared.map'));
is((not defined(&normalize_path(undef))),1);

sub make_converted_path($)
{
    my $result    = undef;
    my $component = shift;

    my $stmt = "\$result = \&HP\:\:Path\:\:__flip_slashes(\"\$component\", \"$conversion_from\", \"$conversion_to\");";
    eval "$stmt";
    if ( &HP::Path::__is_letter_drive("$result") ) {
	$result = &lowercase_first("$result");
    }
    return $result;
}
