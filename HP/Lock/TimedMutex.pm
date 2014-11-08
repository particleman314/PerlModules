package HP::Lock::TimedMutex;

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

	use parent qw(HP::Lock::Mutex);
	
    use vars qw(
                $VERSION
                $is_debug
                $is_init

                $module_require_list
                $module_request_list

                $broken_install

                @ISA
                @EXPORT
               );

    $VERSION     = 1.2;

    @EXPORT      = qw (
                      );


    $module_require_list = {
							'HP::Constants'                => undef,
							'HP::Support::Base'            => undef,
							'HP::Support::Base::Constants' => undef,
							'HP::Support::Hash'            => undef,
							'HP::Support::Object::Tools'   => undef,
							
							'HP::CheckLib'                 => undef,
							'HP::Path'                     => undef,
							'HP::FileManager'              => undef,
							'HP::Utilities'                => undef,
							'HP::Lock::Constants'          => undef,
							'HP::DBContainer'              => undef,
                           };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_lock_timedmutex_pm'} ||
                 $ENV{'debug_lock_modules'} ||
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
sub data_types
  {
    my $self = shift;
	my $which_fields = shift || COMBINED;
	
    my $data_fields = {
	                   'timeout'      => DEFAULT_TIMEOUT,
					   'timer_active' => FALSE,
		              };
	if ( $which_fields eq COMBINED ) {
      foreach ( @ISA ) {
	    my $parent_types = undef;
	    my $evalstr      = "\$parent_types = $_->data_types()";
	    eval "$evalstr";
	    $data_fields     = &HP::Support::Hash::__hash_merge( $data_fields, $parent_types ) if ( defined($parent_types) );
	  }
	}
	
    return $data_fields;
  }

#=============================================================================
sub display
  {
    my $self   = shift;
	my $handle = shift || 'STDERR';
	
	$self->SUPER::display($handle);
	
	my $strDB  = &getDB('stream');
	my $stream = $strDB->find_stream_by_handle("$handle");
	
	$stream->raw_output("\tTimeout   --> ". $self->timeout()) if ( defined($self->timeout()) );
	$stream->raw_output("\tTimer Active --> ". &convert_boolean_to_string($self->timer_active()));
  }

#=============================================================================
sub is_timer_active
  {
    my $self = shift;
	return $self->timer_active();
  }
  
#=============================================================================
sub lock
  {
    my $self = shift;
	$self->timer_active(TRUE);
	$self->SUPER::lock();
	return;
  }
  
#=============================================================================
sub new
  {
    my $class       = shift;
    my $data_fields = &data_types();

    my $self = {
		        %{$data_fields},
	           };
			   
	if ( @_ ) {
	  if ( ref($_[0]) =~ m/hash/i ) {
	    foreach my $key (keys{%{$_[0]}}) {
		  if ( exists($self->{"$key"}) ) { $self->{"$key"} = $_[0]->{"$key"}; }
		}
	  } else {
	    &__print_output("Please use a hash as input to construct this class << $class >>", 'STDERR');
		return undef;
	  }
	}
	
    bless $self, $class;
	$self->instantiate();
	return $self;  
  }

#=============================================================================
sub release
  {
    my $self = shift;
	$self->stop();
	$self->unlock();
	$self->SUPER::clear();
	return TRUE;
  }

#=============================================================================
sub start
  {
    my $self = shift;
	my $result = FALSE;
	
    if ( $self->is_timer_active() eq FALSE ) {
	  alarm 0;

	  my $coderef = UNIVERSAL::can($self, 'stop');
	  if ( $coderef =~ m/code/i ) {
	    $SIG{'ALRM'} = sub { &{$coderef}($self); };
	    &__print_debug_output("Set ALARM to remove the spinlock...", __PACKAGE__) if ( $is_debug );
	    alarm $self->timeout();
	    $self->lock();
		$result = TRUE;
	  }
    } else { 
      &__print_output("Current timer underway...", INFO);
    }
	return $result;
  }
  
#=============================================================================
sub stop
  {
    my $self = shift;
	
	&__print_debug_output("STOP ACTIVE TIMER...", __PACKAGE__) if ( $is_debug );
    alarm 0;
    $self->timer_active(FALSE);
	return $self->unlock();
  }

#=============================================================================
sub update_timeout
  {
	my $self = shift;
    my $badinput = 0;

    my $isint   = &is_integer($_[0]);
    my $isneg   = -1;
    if ( $isint eq TRUE ) {
      if ( $_[0] < 0 ) { $isneg = 1; }
    }
    my $isalnum = &is_alphanumeric($_[0]);

    if ( ( $isint eq FALSE ) && ( $isalnum eq TRUE ) ) { $badinput = 1; }
    if ( ( $isint eq TRUE ) && ( $isalnum eq FALSE ) ) { $badinput = 1; }

    if ( $badinput || ( $isneg == 1 ) ) {
      &__print_debug_output("User requested spinlock timeout [ $_[0] ] is either NOT A INTEGER or is less than 0.  Keeping ". DEFAULT_TIMEOUT ." seconds!", __PACKAGE__) if ( $is_debug );
      return FALSE;
    }
    $self->timeout($_[0]);
    &__print_debug_output("Updated spinlock timeout to << $_[0] >> seconds", __PACKAGE__) if ( $is_debug );
	return TRUE;
  }
  
#=============================================================================
1;