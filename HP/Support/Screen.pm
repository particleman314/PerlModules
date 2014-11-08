package HP::Support::Screen;

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

    use vars qw(
				$VERSION
				$is_debug
				$is_init

				$module_require_list
                $module_request_list

				$broken_install

				$TermIOCols
				$TermIORows
				$force_screen_check
								
				@ISA
				@EXPORT
               );

    $VERSION    = 0.85;

	@ISA = qw(Exporter);
    @EXPORT = qw(
	             &get_linespace
				 &get_screen_info
				 &recheck_screen

				 $LINESPACE
                );

    $module_require_list = {
							'HP::Constants'                  => undef,
							
							'HP::Support::Base'              => undef,
							'HP::Support::Os'                => undef,
							'HP::Support::Module'            => undef,
							
							'HP::Support::Screen::Constants' => undef,
							'HP::Support::Object::Tools'     => undef,
						   };
    $module_request_list = {
	                       };

    $TermIOCols = 80;  # Default column screen size;
    $TermIORows = 24;  # Default row screen size;
	$force_screen_check = 0;

    $is_init  = 0;
    $is_debug = (
			     $ENV{'debug_support_screen_pm'} ||
			     $ENV{'debug_support_modules'} ||
			     $ENV{'debug_hp_modules'} ||
			     $ENV{'debug_all_modules'} || 0
		        );

    $broken_install = 0;

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
	    if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "REQUIRED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug ); 
          eval "use $usemod;";
        }
	    if ( $@ ) {
	      print STDERR "Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
	      die "Exiting!\n$@";
	    }
      }
    } else {
      my $use_cmd = &load_required_modules( __PACKAGE__, $module_require_list);
      eval "$use_cmd";
    }

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_request_list})) {
        if ( defined($module_request_list->{$usemod}) ) {
          print STDERR "REQUESTED [". __PACKAGE__ ."]:: use $usemod $module_request_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_request_list->{$usemod};";
        } else {
          print STDERR "REQUESTED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug );
          eval "use $usemod;";
        }
        if ( $@ ) {
          print STDERR "Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
        }
      }
    } else {
      my $use_cmd = &load_required_modules( __PACKAGE__, $module_request_list);
      eval "$use_cmd";
    }

    # Print a message stating this module has been loaded.
    print STDERR "LOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
END
  {
    print STDERR "UNLOADING <".__PACKAGE__."> Module\n" if ( $is_debug );
  }

#=============================================================================
my $local_true    = TRUE;
my $local_false   = FALSE;

my $local_fail    = FAIL;
my $local_pass    = PASS;

my $LINESPACE     = undef;

#=============================================================================
sub __define_linespace($)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    goto __END_OF_SUB if ( not defined($_[0]) );

    my $repeat_factor = int($TermIOCols / length($_[0]));
    $LINESPACE = "$_[0]" if ( $repeat_factor < 1 );
    $LINESPACE = "$_[0]" x $repeat_factor;

    $LINESPACE .= substr("$_[0]",0, $TermIOCols - length($LINESPACE)) if ( length($LINESPACE) < $TermIOCols );
	
  __END_OF_SUB:
	return;
  }

#=============================================================================
sub __initialize()
  {
    if ( $is_init eq $local_false ) {
      $is_init = $local_true;
	  &__define_linespace('*');
      print STDERR "INITIALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
sub __set_debug($)
  {
    if ( $_[0] eq $local_true ) {
	  $is_debug = $local_true;
	  eval "use Data::Dumper;";
	  eval "\$Data::Dumper::Sortkeys = 1;";
	}
  }
  
#=============================================================================
sub __use_ioctl()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
	
	my $result = $local_fail;
    eval "require 'sys/ioctl.ph';";
	
	goto __END_OF_SUB if ( $@ );
    goto __END_OF_SUB unless defined &TIOCGWINSZ;
    open(TTY, "+</dev/tty") or return $local_fail;
	
	my $winsize;
    unless (ioctl(TTY, &TIOCGWINSZ, $winsize='')) { return $local_fail; }
	
    my ($xpixel, $ypixel) = (0,0);
    ($TermIORows, $TermIOCols, $xpixel, $ypixel) = unpack('S4', $winsize);
	
	$result = $local_pass;
	
  __END_OF_SUB:
	return $result;
  }

#=============================================================================
sub __use_term_cap()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

 	my $result = $local_fail;
    print STDERR "LOADING [". __PACKAGE__ ."]:: use Term::Cap;\n" if ( $is_debug );
	
	my $has_term_cap = &has('Term::Cap');
	goto __END_OF_SUB if ( $has_term_cap eq $local_false  );
	
	eval "use Term::Cap";
	goto __END_OF_SUB if ( &has('Term::Cap') eq $local_false );
	
    my $term   = Tgetent Term::Cap { 'TERM' => '', 'OSPEED' => TERM_CAP_OSPEED };
	if ( defined($term) ) {
      $TermIOCols = $term->{'_co'} if ( exists($term->{'_co'}) );
      $TermIORows = $term->{'_li'} if ( exists($term->{'_li'}) );
	  $result = $local_pass;
	}
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub __use_term_screen()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    
 	my $result = $local_fail;
    print STDERR "LOADING [". __PACKAGE__ ."]:: use Term::Screen;\n" if ( $is_debug );
	
	my $has_term_screen = &has('Term::Screen');
	goto __END_OF_SUB if ( $has_term_screen eq $local_false  );

	my $src = &create_object('Term::Screen');
	goto __END_OF_SUB if ( not defined($src) );
	
	foreach my $ig (qw(rows cols)) {
	  my $cmd = "\$TermIO".&uppercase_first("$ig")." = \$scr->$ig";
	  &__print_debug_output("Processing command :: $cmd", __PACKAGE__);
	  eval("$cmd");
	  if ( $@ ) {
	    &__print_output("Error when attempting to get $ig for screen\n<$@>\n\n", __PACKAGE__);
		goto __END_OF_SUB;
	  }
	}
	
	$result = $local_pass;
	
  __END_OF_SUB:
    return $result;
  }
  
#=============================================================================
sub __use_term_readkey()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
  
    my $result = $local_false;
    print STDERR "LOADING [". __PACKAGE__ ."]:: use Term::ReadKey;\n" if ( $is_debug );
	
	my $has_term_readkey = &has('Term::ReadKey');
	goto __END_OF_SUB if ( $has_term_readkey eq $local_false  );

	my $src = &create_object('Term::ReadKey');
	goto __END_OF_SUB if ( not defined($src) );

	my $x = 0;
	my $y = 0;
	my $cmd = "(\$TermIOCols, \$TermIORows, \$x, \$y) = \&GetTerminalSize();";

	&__print_debug_output("Processing command :: $cmd", __PACKAGE__);

	eval("$cmd");
	if ( $@ ) {
	  &__print_debug_output("\n\nError when attempting to get GetTerminalSize for screen\n<$@>\n\n", __PACKAGE__);
	  goto __END_OF_SUB;
	}
	
	$result = $local_pass;
	
  __END_OF_SUB:
    return $result;
  }

#=============================================================================
sub get_linespace()
  {
    return $LINESPACE;
  }
  
#=============================================================================
sub get_screen_info(;$)
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );

    my $method = $_[0] || undef;

    $ENV{'SKIP_TERM_CHECK'} = $local_true if &os_is_cygwin();

    my @screenTools_windows = qw( __use_term_cap __use_term_screen __use_term_readkey );
	my @screenTools_linux   = qw( __use_ioctl    __use_term_screen __use_term_readkey );
	
	my @screenTools = ( &os_is_linux() eq $local_true ) ? @screenTools_linux : @screenTools_windows;
	
	if ( $HP::Support::Screen::force_screen_check eq $local_false ) {
      if ( ( not defined($ENV{'TERM'}) ) ||
           ( defined($ENV{'SKIP_TERM_CHECK'}) ) ) {
        $TermIOCols = DEFAULT_COLS;
        $TermIORows = DEFAULT_ROWS;
        return;
      }
    }

  CHECK4SCREEN:

    for (my $idx = 0; $idx < scalar(@screenTools); ++$idx) {

      &__print_debug_output("Method name under query --> $screenTools[$idx]\n", __PACKAGE__) if ( $is_debug );
	  
      if ( $broken_install ) {
	    no strict;
	    my $error = &{$screenTools[$idx]}();
		use strict;
		if ( $error == 0 ) { last; }
      } else {
        # Needs to be written
      }
    }

    $TermIOCols = DEFAULT_COLS if ( not defined($TermIOCols) );
    $TermIORows = DEFAULT_ROWS if ( not defined($TermIORows) );
	return;
  }

#=============================================================================
sub recheck_screen()
  {
    &__print_debug_output("Inside ". &get_method_name(), __PACKAGE__) if ( $is_debug );
    $HP::Support::Screen::force_screen_check = $local_true;
	&get_screen_info();
	$HP::Support::Screen::force_screen_check = $local_false;
  }
  
#=============================================================================
&__initialize();

#=============================================================================
1;