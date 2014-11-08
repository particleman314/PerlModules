package HP::Support::BasePrint;

################################################################################
# Copyright (c) 2013 HP.   All rights reserved
# HP
# HP IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
# COURTESY TO YOU.   BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
# ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION OR
# STANDARD, HP IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION
# IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE
# FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.
# HP EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO
# THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO
# ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
# FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.
################################################################################

use warnings;
use strict;
use diagnostics;

#=============================================================================
BEGIN
  {
    use Exporter();

    use FindBin;
    use lib "$FindBin::Bin/../..";

	use HP::Constants;
	use HP::Support::PerlModuleUtils;
	use HP::Support::BasePrint::Constants;
	
    use vars qw(
				$VERSION
				$is_init
				$is_debug

                $prefix
				$allow_space
				
				$module_require_list
				
				@ISA
				@EXPORT
	       );

	@ISA     = qw(Exporter);
    @EXPORT  = qw(
                  &__print_debug_output
				  &__print_inputs
                  &__print_output
				  &print_msg
				  &print_baseobj
 		         );

	$module_require_list = {
	                        'Storable'         => undef,
							'Text::Format'     => undef,
	                        #'Text::Autoformat' => undef,
	                       };
    $VERSION     = 0.86;
	$allow_space = FALSE();
    $prefix      = '';
	
    $is_init  = FALSE();
    $is_debug = (
	             $ENV{'debug_support_baseprint_pm'} ||
	             $ENV{'debug_support_modules'} ||
		         $ENV{'debug_hp_modules'} ||
		         $ENV{'debug_all_modules'} || FALSE()
		        );
  }

#=============================================================================
END
  {
    print STDERR "UNLOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
my $local_true  = TRUE();
my $local_false = FALSE();

#=============================================================================
sub __initialize()
  {     
    if ( $is_init eq $local_false ) {
      $is_init = $local_true;
	  &load_modules({'package' => __PACKAGE__,
	                 'perl_modules' => $HP::Support::BasePrint::module_require_list});
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }     
  }       

#=============================================================================
sub __print_debug_output($;$)
  {
    my $dbg_varname  = DEBUG_VARIABLE();
    my $msg          = $_[0];
	my $result       = undef;
	
	my $store_output = wantarray();
	if ( defined($store_output) && $store_output eq '' ) {
	  $store_output = $local_true;
	} else {
	  $store_output = $local_false;
	}
	
    goto __END_OF_SUB if ( not defined($msg) );

    my $call_pkg = caller();
    $call_pkg =~ s/\s*//g;

    goto __END_OF_SUB if ( ( length($call_pkg) < 1 ) || ( $call_pkg eq ' ' ) );

    my $stack_uplevel_1 = "$call_pkg".'::'."$dbg_varname";

    my $depth = 0;
    1 while caller(++$depth);

	$result = '';
	
    $prefix = "   " x $depth;
    if ( $stack_uplevel_1 =~ m/\S\:\:$dbg_varname/ ) {
      my $caller_is_debug = 0;
      my $cmd = "\$caller_is_debug = \$$stack_uplevel_1;";
      eval "$cmd";

      if ( $msg !~ m/^Inside/ ) { $prefix .= "--> "; };
      if ( $msg =~ m/^Inside/ ) { $prefix .= ' '. "+" x $depth; };
	  if ( scalar(@_) == 1 ) {
         $result .= &__print_output({'data'  => @_,
		                             'prefix'=> 'DEBUG',
									 'reply' => $store_output}) if ( $caller_is_debug );
	  } else {
	     $result .= &__print_output({'data'  => @_,
		                             'reply' => $store_output}) if ( $caller_is_debug );
	  }
    }
	
  __END_OF_SUB:
	return $result if ( $store_output eq $local_true && length($result) > 0 );
	return;
  }

#=============================================================================
sub __print_inputs(@)
  {
    my $line = undef;
	return $line if ( scalar(@_) < 1 );
	
	$line = '[< ';
	my $first = 1;
    foreach (@_) {
	  my $reftype = ref($_);
	  if ( defined($_) ) {
	    if ( $first ) {
		  $first = 0;
		  $line .= $reftype if ( $reftype ne '' );
		  $line .= "\"$_\"" if ( $reftype eq '' );
		}
		else {
		  $line .= ', '. ref($_) if ( $reftype ne '' );
		  $line .= ', '. "\"$_\"" if ( $reftype eq '' );
		}
	  }
	  else { $line .= ', <<UNDEFINED>>'; }
	}
	
	$line .= ' >]';
	return $line;
  }
  
#=============================================================================
sub __print_output($;$)
  {
    my $input = $_[0];
	my ($msg, $packname, $reply) = (undef, undef, $local_false);
	
	if ( ref($input) !~ m/hash/i ) {
      $msg      = $_[0];
      $packname = $_[1] || INFO();
	  $reply    ||= $_[2];
    } else {
	  $msg      = join('', $_[0]->{'data'});
	  $packname = $_[0]->{'prefix'} || INFO();
	  $reply    ||= $_[0]->{'reply'};
	}
	
	$reply = $local_false if ( not defined($reply) );
	
    return if ( not defined($msg) );

	my $fullmsg = &print_msg($msg, $packname, \*::STDERR);
	return $fullmsg if ( $reply eq $local_true);
	return undef;
  }

#=============================================================================
sub __set_debug(;$)
  {
    return if ( not defined($_[0]) );
    &HP::Support::PerlModuleUtils::__set_debug_on(__PACKAGE__) if ( $_[0] eq $local_true );
  }
  
#=============================================================================
sub print_msg($;$$$)
  {
    my $msg    = $_[0];
    my $header = $_[1] || INFO();
	my $stream = $_[2] || \*::STDOUT;
	my $scrnsz = $_[3] || -1;
	
    return if ( not defined($msg) );

	my $text = Text::Format->new();
    $text->columns($scrnsz) if ( $scrnsz > 0 );
	$text->firstIndent($local_false);
	$text->hangingIndent($local_false);
	$text->bodyIndent(length($header) + 3);

	#$msg = $entry_line ."\n[$header] " . $msg;
	$msg = "[$header] " . $msg;
	#my $expanded_text  = $text->expand($msg);
	my $formatted_text = $text->format($msg);
	
	#my $formatted_text = autoformat $msg;
    print $stream "$formatted_text\n";
	return $formatted_text;
  }

#=============================================================================
sub print_baseobj($)
  {
    my $msg = '';
    my $obj     = $_[0] || return $msg;
    my $header  = $_[1] || INFO();
	my $stream  = $_[2] || \*::STDOUT;
	my $objtype = ref($obj);
	
	if ( $objtype eq '' ) {
	  $msg .= "SCALAR : $obj\n";
	} elsif ( $objtype =~ m/^scalar/i ) {
	  $msg .= "SCALAR : ${$obj}\n";
	} elsif ( $objtype =~ m/^array/i ) {
	  my $tmpmsg = '';
	  $tmpmsg .= "$_, " foreach ( @{$obj} );
	  chop($tmpmsg); chop($tmpmsg);
	  $msg .= "ARRAY : [ $tmpmsg ]\n";
	} elsif ( $objtype =~ m/^hash/i ) {
	  my $tmpmsg = '';
	  $tmpmsg .= "$_ -> $obj->{$_}, " foreach ( keys(%{$obj}) );
	  chop($tmpmsg); chop($tmpmsg);
	  $msg .= "HASH : { $tmpmsg }\n";	
	}
	
	my $fullmsg = &__print_output($msg, $header, TRUE());
	return $fullmsg;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;