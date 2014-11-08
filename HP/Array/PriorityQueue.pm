package HP::Array::PriorityQueue;

################################################################################
# Copyright (c) 2013-2014 HP.   All rights reserved
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

use strict;
use warnings;
use diagnostics;

#=============================================================================
BEGIN 
  {
    use Exporter();

    use FindBin;
    use lib "$FindBin::Bin/../..";

	use overload q{""} => 'HP::Array::PriorityQueue::print';

	use parent qw(HP::ArrayObject);
	
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

    $VERSION = 1.00;

    @EXPORT  = qw (
                  );

    $module_require_list = {
							'List::Util'                          => undef,
							
	                        'HP::Constants'                       => undef,
							'HP::Support::Base'                   => undef,
							'HP::Support::Base::Constants'        => undef,
							'HP::Support::Hash'                   => undef,
							
							'HP::Support::Object'                 => undef,
							'HP::Support::Object::Tools'          => undef,

							'HP::Array::Constants'                => undef,
							'HP::Array::Tools'                    => undef,
							'HP::Array::PriorityQueue::Constants' => undef,
							
							'HP::CheckLib'                        => undef,
							'HP::Utilities'                       => undef,
                          };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_array_priorityqueue_pm'} ||
				 $ENV{'debug_array_modules'} ||
                 $ENV{'debug_hp_modules'} ||
                 $ENV{'debug_all_modules'} || 0
                );

    $broken_install = 0;

    print STDERR "BEGIN <". __PACKAGE__ .">\n" if ( $is_debug );

    eval "use HP::ModuleLoader;";
    if ( $@ ) {
      print STDERR "\t-->Could not find Module::Load::Conditional.  Using fallback for ". __PACKAGE__ ."!\n" if ( $is_debug );
      $broken_install = 1;
    }

    $module_require_list->{'Data::Dumper'} = undef if ( $is_debug );

    if ( $broken_install ) {
      foreach my $usemod (keys(%{$module_require_list})) {
        if ( defined($module_require_list->{$usemod}) ) {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod $module_require_list->{$usemod};\n" if ( $is_debug );
          eval "use $usemod $module_require_list->{$usemod};";
        } else {
          print STDERR "\t--> REQUIRED [". __PACKAGE__ ."]:: use $usemod\n" if ( $is_debug ); 
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
my $local_true  = TRUE;
my $local_false = FALSE;
my $queue_type  = undef;
my $sort_type   = undef;

#=============================================================================
sub __initialize
  {
    if ( $is_init eq $local_false ) {
	  $is_init = $local_true;
	  $HP::Array::PriorityQueue::queue_type = 'HP::Array::Queue';
	  $HP::Array::PriorityQueue::sort_type  = LEXIOGRAPH_SORT;
	}
  }
  
#=============================================================================
sub __make_aoh
  {
	my $self       = $_[0];
	my $priorities = $_[1];
	my $elements   = $_[2];
	
	
	my $result     = [];
	return $result if ( scalar(@_) < 2 );
	
	if ( ref($priorities) =~ m/hash/i ) {
	  foreach ( keys(%{$priorities}) ) {
	    push( @{$result}, {'priority' => $_, 'item' => $priorities->{$_}} );
	  }
	} elsif ( scalar(@_) == 3 ) {
	  for ( my $loop = 0; $loop < scalar(@{$priorities}); ++$loop ) {
	    push( @{$result}, {'priority' => $priorities->[$loop], 'item' => $elements->[$loop]} );
	  }
	}
	
	return $result;
  }
  
#=============================================================================
sub __prepare_data
  {
    my $self = $_[0];
	
	if ( scalar(@_) >= 3 ) {
	  if ( &equal(ref($_[1]), ref($_[2])) eq $local_true &&
	       ref($_[1]) =~ m/^array/i ) {
	  
		if ( ref($_[2]->[0]) =~ m/hash/i ) {
		  my @priorities = ();
		  my @items      = ();
		  
		  foreach (@{$_[2]}) {
		    push( @priorities, keys($_) );
			push( @items, values($_) );
		  }
		  
		  $_[1] = \@priorities;
		  $_[2] = \@items;
		}
		
		my $numpri   = scalar(@{$_[1]});
	    my $numitems = scalar(@{$_[2]});
		my $result   = [];
		
		return $result if ( $numitems == 0 );
		
		if ( $numpri < $numitems ) {
		  my $lowest_priority = List::Util::max(@{$_[1]});
		  $lowest_priority = 1 if ( not defined($lowest_priority) );
		  $_[1]->[$numitems - 1] = $lowest_priority;
		  for ( my $loop = $numpri; $loop < $numitems - 1; ++$loop ) { $_[1]->[$loop] = $lowest_priority; }
		}
        return $self->__make_aoh($_[1], $_[2]);
	  }
	} elsif ( scalar(@_) == 2 ) {
	  if ( ref($_[1]) =~ m/^array/i ) {
	    return $self->__prepare_data([], $_[1]) if ( (ref($_[1]->[0]) !~ m/hash/i) ||
		                                             (not exists($_[1]->[0]->{'priority'})) );
	    return $_[1];
	  } elsif ( ref($_[1]) =~ m/hash/i ) {
		return $self->__make_aoh($_[1]);
	  }
	}
	
	return [];
  }

#=============================================================================
sub __set_queue_type
  {
    my $self     = $_[0];
	my $qtype    = $_[1] || goto __END_OF_SUB;
	my $sorttype = $_[2];
	
	$HP::Array::PriorityQueue::queue_type = $qtype;
	
	if ( defined($sorttype) ) {
	  $HP::Array::PriorityQueue::sort_type = $sorttype;
	}
	
  __END_OF_SUB:
    return;
  }

#=============================================================================
sub __set_sort_type
  {
    my $self     = $_[0];
	my $sorttype = $_[1] || goto __END_OF_SUB;
	
	$HP::Array::PriorityQueue::sort_type = $sorttype;
	
  __END_OF_SUB:
    return;
  }

#=============================================================================
sub add_elements
  {
    my $self = $_[0];
	my $data = $self->__prepare_data(@_[ 1..scalar(@_)-1 ]);
	
	foreach ( @{$data} ) {
	  my $priority = $_->{'priority'};
	  
	  if ( &is_integer($priority) eq $local_false ) {
	    &__print_output("Encountered priority which was NOT an integer.  Skipping!", WARN);
		next;
	  }
	  
	  if ( $priority < MIN_PRIORITY ) {
	    &__print_output("Encountered priority which was less than 1.  Skipping!", WARN);
		next;
	  }
	  
	  my $item = $_->{'item'};
	  next if ( not defined($item) );
	  
	  if ( not exists($self->{'order'}->{"$priority"}) ) {
	    $self->{'order'}->{$priority} = &create_object('c__'. $HP::Array::PriorityQueue::queue_type .'__');
		$self->{'order'}->{$priority}->{'sort_method'} = $HP::Array::PriorityQueue::sort_type;
	  }
	  $self->{'order'}->{$priority}->push($item);
	  $self->priority_list()->push_item($priority);
	}
	
	return;
  }
  
#=============================================================================
sub clear_priority
  {
	my $result   = $local_false;
    my $self     = $_[0];
	my $priority = $_[1] || goto __END_OF_SUB;
	
	my $prlist = $self->priority_list();
	my $idx    = $prlist->find_instance($priority);
	
	if ( $idx ne NOT_FOUND ) {
	  $result = $prlist->delete_elements_by_index([ $idx ]);
	  delete($self->order()->{$priority}) if ( $result eq $local_true );
	}
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub contains
  {
	my $result = $local_false;
	
    my $self = $_[0];
	my $data = $_[1];
	
	goto __END_OF_SUB if ( &valid_string($data) eq $local_false );
	
	my $prlist = $self->priority_list();
	
	foreach ( @{$prlist->get_elements()} ) {
	  my $q = $self->order()->{$_};
	  my $subresult = $q->contains($data);
	  if ( $subresult eq $local_true ) {
	    $result = $local_true;
	    goto __END_OF_SUB;
	  }
    }
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub data_types
  {
    my $self         = $_[0];
	my $which_fields = $_[1] || COMBINED;
	
    my $data_fields = {
	                   'order'         => {},
	                   'priority_list' => 'c__HP::Array::Set__',
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
sub find_priority
  {
    my $self   = $_[0];
	my $item   = $_[1];
	my $result = undef;
	
	return $result if ( &valid_string($item) eq $local_false );
	
	my $prlist = $self->priority_list();
	
	foreach ( @{$prlist->get_elements()} ) {
	  my $q        = $self->order()->{$_};
	  my $elements = $q->get_elements();
	  return $_ if ( &set_contains($item, $elements) eq $local_true );
	}
	
	return $result;  
  }
  
#=============================================================================
sub find_queue
  {
    my $self    = $_[0];
	my $element = $_[1];
	my $result  = [ undef, undef ];
	
	goto __END_OF_SUB if ( &valid_string($element) eq $local_false );
	
	my $prlist = $self->priority_list();
	
	foreach ( @{$prlist->get_elements()} ) {
	  my $q = $self->order()->{$_};
	  if ( $q->contains($element) eq $local_true ) {
	    $result = [ $q, $_ ]; # Queue and priority ID
		goto __END_OF_SUB;
	  }
	}
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub get_elements
  {
    my $self = $_[0];
	my $result = $self->order();
	
	if ( defined($_[1]) ) {
	  $result = undef;
	  my $q = $self->get_queue($_[1]);
	  $result = $q->get_elements() if ( defined($q) );
	}
	return $result;
  }

#=============================================================================
sub get_priorities
  {
    my $self = $_[0];
	return $self->priority_list()->get_elements();
  }

#=============================================================================
sub get_queue
  {
    my $result   = undef;
    my $self     = $_[0];
	my $priority = $_[1];
	
	goto __END_OF_SUB if ( &is_integer($priority) eq $local_false );
	$result = $self->order()->{$priority} if ( exists( $self->order()->{$priority} ) );
	
  __END_OF_SUB:
	return $result;
  }
  
#=============================================================================
sub merge
  {
    &__print_output('NOT YET WRITTEN < '. &get_method_name() .' >', FAILURE);
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
	
    bless $self, $class;
	$self->instantiate();

	if ( @_ ) {
	  if ( ref($_[0]) =~ m/hash/i ) {
	    foreach my $key (keys{%{$_[0]}}) {
		  $self->{"$key"} = $_[0]->{"$key"} if ( exists($self->{"$key"}) );
		}
	  } else {
	    &__print_output("Please use a hash as input to construct this class < $class >", 'STDERR');
		return undef;
	  }
	}

	$self->priority_list()->sort_method(&ASCENDING_SORT);
    return $self;
  }

#=============================================================================
sub next
  {
    my $result    = undef;
    my $self      = $_[0];
    my $num_2_get = $_[1] || 1;
	
	my $prlist = $self->priority_list();
	
	my $item      = [];	
	
  RETRY:
	goto __END_OF_SUB if ( $prlist->number_elements() < 1 );
	
	my $highest_priority = $prlist->get_element(0);
	
	goto __END_OF_SUB if ( not defined($highest_priority) );
	
	my $data = $self->next_by_priority($highest_priority, $num_2_get);
	push ( @{$item}, $data );
	
	my $remaining = 0;
	if ( ref($data) !~ m/^array/i ) {
	  $remaining = --$num_2_get;
	} else {
	  $remaining = $num_2_get - scalar(@{$data});
	}
	
	if ( $remaining > 0 ) {
	  my $remaining_items = $self->next($remaining);
	  push ( @{$item}, $remaining_items ) if ( defined($remaining_items) );
	}
	
	if ( $num_2_get > 1 ) {
	  $result = &flatten($item, $local_true);
	} else {
	  $result = $item->[0];
	}
	
  __END_OF_SUB:
    return $result;
  }

#=============================================================================
sub next_by_priority
  {
    my $result   = undef;
	
    my $self     = $_[0];
	my $prlist   = $self->priority_list();
	
	my $priority  = $_[1] || $prlist->get_element(0) || MIN_PRIORITY;
    my $num_2_get = $_[2] || 1;
	goto __END_OF_SUB if ( $prlist->number_elements() < 1 );
	
	my $item = [];

	my $queue = $self->order()->{$priority};
	
	if ( defined($queue) ) {
	  if ( $queue->number_elements() < 1 ) {
	    $self->clear_priority($priority);
	    $result = $item;
	  } else {
	    $item = $queue->next($num_2_get);
	    if ( $queue->number_elements() < 1 ) {
	      $self->clear_priority($priority);
        }
	  }
	}
	
	if ( $num_2_get > 1 ) {
      $result = &flatten($item, $local_true);
	} else {
	  $result = $item;
	}
	
  __END_OF_SUB:
    return $result;
  }

#=============================================================================
sub number_elements
  {
    my $self = $_[0];
	
	my $count = 0;
	my $priorities = $self->priority_list()->get_elements();
	
	foreach ( @{$priorities} ) {
	  if ( ( not defined($_[1]) ) || $_[1] eq $_ ) {
	    my $q = $self->get_queue($_);
	    $count += $q->number_elements();
	  }
	}
	
	return $count;
  }
  
#=============================================================================
sub print
  {
    my $self        = $_[0];
	my $indentation = $_[1] || '';
	my $result      = '';
	
	$result .= &print_string(ref($self), 'Array Type', $indentation) ."\n";
	my $priorities = $self->priority_list()->get_elements();
	$result .= &print_string(scalar(@{$priorities}), 'Number Priority Queues', $indentation) ."\n\n";

	my $subindent = $indentation . "\t";
	my $orderclasses = $self->order();
	
	foreach ( @{$priorities} ) {
	  $result .= &print_string($_, 'Priority', $subindent) ."\n\n";
	  my $ptr = $orderclasses->{"$_"};
	  if ( &is_blessed_obj($ptr) eq $local_true && &function_exists($ptr, 'print') eq $local_true ) {
	    my $subresult = $ptr->print($subindent);
		$result .= $indentation . $subresult if ( defined($subresult) );
	  } else {
	    $result .= $indentation . $ptr ."\n";
	  }
	}
	
	return $result;
  }

#=============================================================================
sub push
  {
    my $result = $local_false;
    my $self   = $_[0];
	my $data   = undef;
	
	if ( scalar( @_ ) == 2 ) {
	  my $ref_type = ref($_[1]);
	  if ( ($ref_type =~ m/hash/i) || ($ref_type =~ m/^array/i) ) {
	    $data = $self->__prepare_data($_[1]);
	  }
	} elsif ( scalar(@_) >= 3 ) {
	  my $priority = $_[1] || MIN_PRIORITY;
	  my $item     = $_[2] || return $local_false;
	
	  $priority = &convert_to_array($priority, $local_true);
	  $item     = &convert_to_array($item, $local_true);
	
	  $data = $self->__prepare_data($priority, $item);
	} else {
	  goto __END_OF_SUB;
	}
	
	$result = $self->push_item($data);
	
  __END_OF_SUB:
    return $result;
  }

#=============================================================================
sub push_item
  {
    my $self = $_[0];
	return $self->add_elements(@_[ 1..scalar(@_)-1 ]);
  }
  
#=============================================================================
sub sort_method
  {
    my $self   = $_[0];
	my $method = $_[1] || return;
	
	if ( defined($self->priority_list()) ) {
	  $self->priority_list()->sort_method($method);
	}
	
	return;
  }
  
#=============================================================================
&__initialize();
1;