package HP::Mailer;

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
    use lib "$FindBin::Bin/..";

    use vars qw(
                $VERSION
                $is_debug
                $is_init

                $module_require_list
                $module_request_list

                $broken_install

		        $fromname
		        $fromaddress
		        $subjectprefix
		        $signature
		        $smtpserver
				$business_ext

                @ISA
                @EXPORT
               );

    @ISA    = qw(Exporter);
    @EXPORT = qw(
		         &mailer_send_mail
		         &mailer_set_signature
		         &mailer_set_from_address
		         &mailer_set_from_name
		         &mailer_set_subject_prefix
		         &mailer_set_smtp_server
		        );

    $module_require_list = {
	                        'HP::Constants'         => undef,
							'HP::Support::Base'     => undef,
                            'HP::Support::Os'       => undef,
							'HP::Support::Hash'     => undef,
							
                            'HP::Process'           => undef,
							'HP::Os'                => undef,
                            'HP::Path'              => undef,
							'HP::Array::Tools'      => undef,
							'HP::Stream::Constants' => undef,
							'HP::DBContainer'       => undef,
                           };

    $VERSION  = 0.9;
    $is_init  = 0;
    $is_debug = (
		         $ENV{'debug_mailer_pm'} ||
		         $ENV{'debug_hp_modules'} ||
		         $ENV{'debug_all_modules'} || 0
		        );

    $broken_install = 0;

    print STDERR "BEGIN <". __PACKAGE__ .">\n" if ( $is_debug );

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "\t--> Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
        if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug );
          eval "use $usemod;";
        }
        if ( $@ ) {
          print STDERR "\t--> Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
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
          print STDERR "\t--> REQUESTED [". __PACKAGE__ ."]:: use $usemod $module_request_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_request_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUESTED [". __PACKAGE__ ."]:: use $usemod;\n" if ( $is_debug );
          eval "use $usemod;";
        }
        if ( $@ ) {
          print STDERR "\t--> Cannot find PERL Module << $usemod >>! Please have this installed or accessible!\n";
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
$fromname      = &get_hostname();
$fromaddress   = 'noreply@dev.nul';
$subjectprefix = '[MAILER]';
$signature     = "\nbuildmail\n";
$business_ext  = 'hp.com';
$smtpserver    = 'mail.'.$business_ext;

#=============================================================================
sub __initialize()
  {
    if ( not $is_init ) {
      $is_init = 1;
      print STDERR "INIITALIZED <".__PACKAGE__."> Module\n" if ( $is_debug );
    }
  }

#=============================================================================
sub mailer_set_signature(;$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
    return if ( &valid_string($_[0]) eq FALSE );
    $signature = "$_[0]";
  }

#=============================================================================
sub mailer_set_from_address(;$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
    return if ( &valid_string($_[0]) eq FALSE );
    $fromaddress = "$_[0]";
  }

#=============================================================================
sub mailer_set_from_name(;$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
    return if ( &valid_string($_[0]) eq FALSE );
    $fromname = "$_[0]";
  }

#=============================================================================
sub mailer_set_subject_prefix(;$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
    return if ( &valid_string($_[0]) eq FALSE );
    $subjectprefix = "$_[0]";
  }

#=============================================================================
sub mailer_set_smtp_server(;$)
  {
    &__print_debug_output("Inside ". &get_method_name() ."\n", __PACKAGE__) if ( $is_debug );
    return if ( &valid_string($_[0]) eq FALSE );
    $smtpserver = "$_[0]";
  }

#=============================================================================
sub mailer_send_mail($$$$;$)
  {
	my $inputdata = {};
    if ( ref($_[0]) !~ m/hash/i ) {
      $inputdata = &convert_input_to_hash([ 'filename', \&valid_string, 'recipients', \&valid_string,
                                            'subject', \&valid_string, 'msg', \&valid_string,
											'attachments', undef ], @_);
    } else {
	  $inputdata = $_[0];
	}
	
    return undef if ( scalar(keys(%{$inputdata})) == 0 );

	my $fn      = $inputdata->{'filename'}   || return;
	my $recip   = $inputdata->{'recipients'} || return;
	my $subject = $inputdata->{'subject'}    || 'NO SUBJECT DEFINED';
	my $msg     = $inputdata->{'msg'}        || 'NO MSG DEFINED';
	my $attach  = $inputdata->{'attach'}     || '';

    my $cmd;
    my @tolist = split /\s*,\s*/, $recip;
	
	my $tolist_obj = &create_object('c_HP::Array::Set__');
	$tolist_obj->add_elements({'entries' => \@tolist});
	
    foreach ( @{$tolist_obj->get_elements()} ) {
      next if (/\@/); # Skip addresses that already have a hostname
      $_ .= '@hp.com';
    }
	$tolist_obj->unique();
    $recip = join(',', @{$tolist_obj->get_elements()});

	my $strDB = &getDB('stream');
	my $mailstream = $strDB->make_stream("$fn", OUTPUT, '__MAIL_OUTPUT__');
    if ( not defined($mailstream) ) {
      &raise_exception(
                       {
					    'type'    => 'c__HP::FileManager::FileNotFoundException__',
                        'msg'     => "Failed to create e-mail message file ($fn) [ ". &get_method_name(). " ]",
                        'streams' => [ 'STDERR' ],
                        'bypass'  => TRUE,
 					   }
		              );
      return;
    }
    print $mailstream <<EOT;
$msg

--
$signature
EOT
    $strDB->remove_stream('__MAIL_OUTPUT__');

    $attach  = "-a \"$attach\"" if ($attach ne '');
    $subject = "$subjectprefix $subject";

    my $emailtool = &which('email');
    if ( ( not defined($emailtool) ) || &os_is_linux() ) {
        $emailtool = &which('mail');
        $cmd .= "$emailtool -s \"$subject\" \"$recip\" < \"$fn\"";
    } else {
        $emailtool = 'email' if ( not -f "$emailtool" );
        $cmd = "$emailtool -r $smtpserver -s \"$subject\" -n \"$fromname\" -f \"$fromaddress\" $attach \"$recip\" < \"$fn\"";
    }
	
    my $hashcmd = {
	               'command' => "$cmd",
		           'verbose' => $is_debug,
                  };
    my ($rval,$output) = &runcmd($hashcmd, 1);
    if ( $rval ) {
      &raise_exception(
                       {
                        'type'    => 'c__HP::Path::NoExecutableFoundException__',
                        'msg'     => "Error found delivering mail [ ". &get_method_name() ." ].",
                        'streams' => [ 'STDERR' ],
                        'bypass'  => TRUE,
 					   }
		              );
    }
	return ($rval, $output);
  }

#=============================================================================
&__initialize();

#=============================================================================
1;