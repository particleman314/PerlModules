package HP::SupportMatrix::Analyzer;

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
	#use Autoloader;
	
    use FindBin;
    use lib "$FindBin::Bin/..";

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

    $VERSION = 0.75;

    @EXPORT      = qw (
                      );

    $module_require_list = {
	                        'HP::RegexLib'                 => undef,
							'HP::ArrayTools'               => undef,
							'HP::CSLTools::Common'         => undef,
							'HP::CSLTools::Constants'      => undef,
							
							'HP::SupportMatrix::Constants' => undef,
							'HP::SupportMatrix::Tools'     => undef,							
	                       };
    $module_request_list = {};

    $is_init  = 0;
    $is_debug = (
                 $ENV{'debug_supportmatrix_htmlreport_pm'} ||
				 $ENV{'debug_supportmatrix_modules'} ||				 
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
sub __add_usecase_2_theme
  {
    my $self  = shift;
	my $uc    = shift || return;
	my $theme = shift || return;
	
	if ( not exists($self->{'themes'}->{"$theme"}) ) {
	  $self->{'themes'}->{"$theme"} = [];
	}
	
	if ( not &set_contains($uc, $self->{'themes'}->{"$theme"}) ) {
	  push ( @{$self->{'themes'}->{"$theme"}}, $uc );
	}
  }
  
#=============================================================================
sub __find
  {
    my $self = shift;
	my $result = undef;
	
	my $metric_type = shift || return $result;
	my $comparer    = shift || '==';
	
    my $freq_data   = $self->{"$metric_type"}->{'frequency'};
	
	if ( not defined($freq_data) ) {
	  return $result;
	} else {
	  foreach my $key ( keys( %{$freq_data} ) ) {
	    if ( not defined($result) ) {
		  $result = $key;
		  next;
		} else {
		  my $compare_result = FALSE;
		  eval "\$compare_result = $\freq_data->{\"$key\"} $comparer \$freq_data->{\"$result\"};";
		  if ( $compare_result == TRUE ) {
		    $result = $key;
		  }
		}
	  }
	}
	return $result;
  }
  
#=============================================================================
sub __generate_reporting
  {
    my $self = shift;
	
    my $uc          = shift || return undef;
	my $report_type = shift || return undef;
	

	my $report_components = {
	                         'install'      => undef,
						     'requirements' => undef,
							 'pdt'          => undef,
							};
	
	# Use dispatch to determine type of item and then let that item
	# if it exists to generate the report...
	
	my $installobj = $self->get_installer_data( "$uc" );
	if ( defined($installobj) ) {
	  if ( $installobj->can( "make_${report_type}_report" ) ) {
	    eval "\$report_components->{'install'} = \$installobj->make_${report_type}_report();";
      }
	}
	  
    my $reqobj = $self->get_requirements_data( "$uc" );
	if ( defined($reqobj) ) {
	  if ( $reqobj->can( "make_${report_type}_report" ) ) {
	    eval "\$report_components->{'install'} = \$reqobj->make_${report_type}_report();";
      }
	}

	my $pdtobj = $self->get_pdt_data( "$uc" );
	if ( defined($pdtobj) ) {
	  if ( $pdtobj->can( "make_${report_type}_report" ) ) {
	    eval "\$report_components->{'install'} = \$pdtobj->make_${report_type}_report();";
      }
	}
	
	return $report_components;
  }
  
#=============================================================================
sub __generate_inconsistency_reporting
  {
    my $self = shift;
	return $self->__generate_reporting( @_, 'inconsistency');
  }
  
#=============================================================================
sub __generate_duplication_reporting
  {
    my $self = shift;
	return $self->__generate_reporting( @_, 'duplication');
  }
  
#=============================================================================
sub __get_toplevel_data_item
  {
    my $self   = shift;
	my $result = undef;
	
	my $uc     = shift || return $result;
	my $itemID = shift || return $result;
	
	my $data   = $self->data();
	
	if ( not defined($data) ) { return $result; }
	if ( exists($data->{ "$uc" }->{ "$itemID" }) ) {
	  $result = $data->{ "$uc" }->{ "$itemID"};
	  if ( ref($result) =~ m/array/i ) { $result = $result->[0]; }
	}
	return $result;  
  }
  
#=============================================================================
sub analyze_data
  {
    my $self = shift;

	$self->collect_statistics();
	
	use Data::Dumper;
	print STDERR Dumper($self->statistics());
	return;
  }

#=============================================================================
sub associate_usecases_2_themes
  {
    my $self = shift;
	
	my $ucs = $self->determine_usecases(@_);
	foreach ( @{$ucs} ) {
	  my $theme = $self->get_theme_from_uc( $_ );
	  $self->__add_usecase_2_theme( $_, $theme );
	}
	
	return;
  }
  
#=============================================================================
sub AUTOLOAD
  {
    our $AUTOLOAD;
    my $self = shift;
    my $type = ref($self) or die "$self is not an object";
    
    # DESTROY messages should never be propagated.
    return if $AUTOLOAD =~ /::DESTROY$/;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    unless ( defined($name) or exists($self->{$name}) ) {
      if ( defined($name) ) {
	    &__print_output("Can't access '$name' field in class $type.  Returning empty string...\n", 'STDERR');
      } else {
	    &__print_output("Can't access an undefined field in class $type.  Returning empty string...\n", 'STDERR');
      }
      return '';
    }

    my $num_elements = scalar( @_ );

    if ( $num_elements >= 1) {
      # Set built-on-the-fly function...
      if ( $num_elements == 1 ) {
	    return $self->{$name} = $_[0];
      } else {
	    return $self->{$name} = \@_;
      }
    } else {
      # Get built-on-the-fly function...
      return $self->{$name};
    }
  }

#=============================================================================
sub collect_base_metrics
  {
    my $self = shift;
	my $ucs  = $self->determine_usecases(@_);
	
	my $stats = $self->statistics()->{'base_metrics'};
	$stats->{'number_uc'} = scalar( @{$ucs} );
	
	foreach my $uc (@{$ucs}) {
	  my $cpID = $self->get_installer_data( "$uc" )->contentpack();
	  $cpID = 'UNKNOWN' if ( not defined($cpID) );
	  if ( not exists($stats->{'usecases_per_cpid'}->{"$cpID"}) ) {
	    $stats->{'usecases_per_cpid'}->{"$cpID"} = [ "$uc" ];
      } else {
		push( @{$stats->{'usecases_per_cpid'}->{"$cpID"}}, "$uc" );
	  }
	}
	return;
  }
  
#=============================================================================
sub collect_blueprint_metrics
  {
    my $self = shift;

	my $statobj = $self->statistics()->{'blueprint_metrics'};
	my $ucs     = $self->determine_usecases(@_);
	
	my $total_deps = [];
	
	foreach my $uc ( @{$ucs} ) {
	  my $installobj = $self->get_installer_data( "$uc" );
	  if ( not defined($installobj) ) { next; }
	  
	  my $bpcnt = $installobj->get_number_blueprints();
	  $statobj->{'frequency'}->{"$uc"} = $bpcnt;
	  $statobj->{'number_blueprints'} += $bpcnt;
	}
	
	return;
  }
  
#=============================================================================
sub collect_dependency_metrics
  {
    my $self = shift;

	my $statobj = $self->statistics()->{'dependency_metrics'};
	my $ucs     = $self->determine_usecases(@_);
	
	my $total_deps = [];
	
	foreach my $uc ( @{$ucs} ) {
	  my $installobj = $self->get_installer_data( "$uc" );
	  if ( not defined($installobj) ) { next; }
	  
      my $depobjs = $installobj->get_dependency_names();
	  $total_deps = &set_union( $total_deps, $depobjs );
	  
      foreach ( @{$depobjs} ) {
	    ++$statobj->{'frequency'}->{"$_"};
	  }
	}
	
	$statobj->{'number_dependencies'} = scalar( @{$total_deps} );
	return;
  }
  
#=============================================================================
sub collect_flow_metrics
  {
    my $self = shift;

	my $statobj = $self->statistics()->{'ooflow_metrics'};
	my $ucs     = $self->determine_usecases(@_);
	
	my $total_ooflows = [];
	
	foreach my $uc ( @{$ucs} ) {
	  my $installobj = $self->get_installer_data( "$uc" );
	  if ( defined($installobj) ) {
        my $known_ooflows = $installobj->get_all_OOTB_ooflows();
		$total_ooflows = &set_union( $total_ooflows, $known_ooflows );

	    foreach ( @{$known_ooflows} ) {
	      ++$statobj->{'frequency'}->{"$_"};
	    }
		
		$statobj->{'oo_version_tags'}->{"$uc"} = $installobj->get_ooflow_tags();
	  } else {
	    &csl_print_output("Strange condition...", WARNING);
	  }
	}
	
	$statobj->{'number_ooflows'} = scalar( @{$total_ooflows} );
	return;
  }

#=============================================================================
sub collect_other_metrics
  {
    my $self = shift;
	
	my $statobj = $self->statistics();
	my $ucs     = $self->determine_usecases(@_);

	foreach my $uc ( @{$ucs} ) {
	  my $report_consistency = $self->__generate_consistency_reporting( "$uc" );
	  my $report_duplication = $self->__generate_duplication_reporting( "$uc" );
	  
	  $statobj->{'inconsistency_metrics'}->{'inconsistency_per_uc'}->{"$uc"} = $self->combine_consistency_reports( $report_consistency );
	  $statobj->{'duplication_metrics'}->{'duplication_per_uc'}->{"$uc"} = $self->combine_duplication_reports( $report_duplication );
	}
	return;
  }

#=============================================================================
sub collect_software_metrics
  {
    my $self = shift;
	
	my $statobj = $self->statistics()->{'software_metrics'};
	my $ucs     = $self->determine_usecases(@_);
	
	my $known_software_groups = [];
	my $total_binaries        = [];
	
	foreach my $uc ( @{$ucs} ) {
	  my $reqobj = $self->get_requirements_data( "$uc" );
	  if ( not defined($reqobj) ) { next; }
	  
	  my $uc_groups = $reqobj->get_software_group_names();
	  $known_software_groups = &set_union( $known_software_groups, $uc_groups );
	  
	  foreach my $ucgrp ( @{$uc_groups} ) {
	    my $known_software_prods = $reqobj->get_software_products( $ucgrp );
		$statobj->{'number_software_products_per_group_per_uc'}->{"$uc"}->{"$ucgrp"} = scalar( keys{%{$known_software_prods}} );
		
		foreach my $ucprod ( keys(%{$known_software_prods}) ) {
		  ++$statobj->{"frequency"}->{"$ucprod"};
		}
      }
	  
	  my $bins = $reqobj->binaries();
	  $total_binaries = &set_union( $total_binaries, $bins );
	}
	
	$statobj->{'number_software_groups'} = scalar( @{$known_software_groups} );
	$statobj->{'number_binaries'} = scalar( @{$total_binaries} );
	
	return;
  }
  
#=============================================================================
sub collect_theme_metrics
  {
    my $self = shift;
	
	$self->associate_usecases_2_themes();
	
	my $statobj      = $self->statistics()->{'theme_metrics'};
	my $known_themes = $self->get_themes();
	
	$statobj->{'number_themes'} = scalar(@{$known_themes});
	foreach ( @{$known_themes} ) {
	  $statobj->{'number_uc_per_theme'}->{"$_"} = scalar( @{$self->{'themes'}->{"$_"}} );
	}
	
	return;
  }
  
#=============================================================================
sub collect_statistics
  {
    my $self = shift;
	my $data = $self->data();
	
	my $statistics = {
	                  'base_metrics'          => {
	                                              'number_uc'         => 0,
												  'usecases_per_cpid' => {},
												 },
					  'dependency_metrics'    => {
					                              'number_dependencies' => 0,
												  'frequency'           => {},
												 },
					  'blueprint_metrics'     => {
					                              'frequency' => {},
												 },
	                  'theme_metrics'         => { 
												  'number_uc_per_theme' => {},
					                              'number_themes'       => 0,
												 },
					  'ooflow_metrics'        => {
					                              'frequency'       => {},
					                              'number_ooflows'  => 0,
												  'oo_version_tags' => {},
												 },
					  'software_metrics'      => {
					                              'number_software_groups'                    => 0,
												  'number_software_products_per_group_per_uc' => {},
												  'frequency'                                 => {},
												  'number_binaries'                           => 0,
					                             },
					  'inconsistency_metrics' => {
					                              'inconsistency_per_uc' => {},
												 },
					  'duplication_metrics'   => {
					                              'duplication_per_uc' => {},
					                             },
					 };
	$self->statistics( $statistics );
	
	if ( defined($data) ) {
	  $self->determine_usecases(TRUE);
	  $self->collect_base_metrics();
      $self->collect_blueprint_metrics();
	  $self->collect_dependency_metrics();
	  $self->collect_theme_metrics();
	  $self->collect_flow_metrics();
	  $self->collect_software_metrics();
	  $self->collect_other_metrics();
	} else {
	  &csl_print_output("Unable to analyze since there is NO data for analysis!", FAILURE);
	}
	
	return
  }

#=============================================================================
sub combine_consistency_reports
  {
    my $self       = shift;
	my $reporthash = shift || return undef;
	
	return;
  }
  
#=============================================================================
sub combine_duplication_reports
  {
    my $self       = shift;
	my $reporthash = shift || return undef;
	
	return;
  }

#=============================================================================
sub data_types
  {
    # See if there is a way to read this from file.
    my %data_fields = (
	                   'data'       => undef,
					   'usecases'   => undef,
		               'statistics' => undef,
					   'themes'     => undef,
		              );
    
    return \%data_fields;
  }

#=============================================================================
sub does_ooflow_exist_in_usecase
  {
    my $self = shift;
	
	my $result = FALSE;
	my $uc     = shift || return $result;
	my $flow   = shift || return $result;
	
	my $data = $self->data();
	
	if ( not defined($data) ) { return $result; }
	my $ucs = $self->determine_usecases(@_);

	foreach my $uc ( @{$ucs} ) {
	  my $installobj = $self->get_installer_data( "$uc" );
	  if ( defined($installobj) ) {
	    my $ooflow_entries = $installobj->ooflows();
	    foreach my $oof ( @{$ooflow_entries} ) {
	      if ( &set_contains( $flow, $oof->get_OOTB_flows() ) ) {
		    $result = TRUE;
		    goto FINISH;
		  }
		}
	  }
	}
	
  FINISH:
	return $result;
  }
  
#=============================================================================
sub DESTROY
  {
    my $self = shift;

    &__print_debug_output("Calling destructor for object ".ref($self)."\n");
	return;
  }

#=============================================================================
sub determine_content_pack_ids
  {
    my $self  = shift;
	my @cpIDs = keys( %{$self->statistics()->{'base_metrics'}->{'usecases_per_cpid'}} );
	return \@cpIDs;
  }

#=============================================================================
sub determine_usecases
  {
    my $self    = shift;
	my $recheck = shift || FALSE;
	my $data    = $self->data();
	
	if ( not defined($data) ) { return []; }

  RESCAN:
	if ( not defined($self->usecases()) ) {
	  my @ucs = keys( %{$data} );
	  $self->usecases( \@ucs );
	} else {
	  if ( $recheck != FALSE ) {
	    $self->usecases( undef );
		goto RESCAN;
	  }
	}
	
	return $self->usecases();
  }
  
#=============================================================================
sub determine_themes
  {
    my $self = shift;
    my $data = $self->data();
	
	if ( not defined($data) ) { return; }
	
	my $ucs = $self->determine_usecases(@_);
	
	my $result = [];
    foreach ( @{$ucs} ) {
	  push ( @{$result}, $self->get_theme_from_uc( "$_" ) );
	}
	
	$result = &set_unique($result) if ( scalar(@{$result}) > 0 );
	$self->themes( $result );
	return $self->themes();
  }

#=============================================================================
sub find_max
  {
    my $self = shift;
	my $result = undef;

	my $metric_type = shift || return $result;
    return $self->__find( "$metric_type", '>' );
  }
  
#=============================================================================
sub find_min
  {
    my $self = shift;
	my $result = undef;

	my $metric_type = shift || return $result;
    return $self->__find( "$metric_type", '<' );
  }

#=============================================================================
sub find_unique_versions_of_software_for_usecase
  {
    my $self   = shift;
	my $result = [];
	
	my $uc       = shift || return $result;
	my $softgrp  = shift || return $result;
	my $software = shift || return $result;
	
	my $ucs = $self->determine_usecases();
	if ( &set_contains($uc, $ucs) ) {
	  my $reqobj = $self->get_requirements_data( "$uc" );
	  if ( defined($reqobj) ) {
	    my $prodhash = $reqobj->get_software_products_with_versions( "$softgrp" );
		if ( defined($prodhash->{"$software"}) ) {
		  foreach my $v ( @{$prodhash->{"$software"}} ) {
		    push ( @{$result}, $v );
		  }
		}
	  }
	}
	
	return $result;
  }

#=============================================================================
sub find_unique_versions_of_software
  {
    my $self   = shift;
	my $result = [];
	
	my $softgrp  = shift || return $result;
	my $software = shift || return $result;
	
	my $ucs = $self->determine_usecases();
	foreach my $uc ( @{$ucs} ) {
	  my $reqobj = $self->get_requirements_data( "$uc" );
	  if ( defined($reqobj) ) {
	    my $prodhash = $reqobj->get_software_products_with_versions( "$softgrp" );
		if ( defined($prodhash->{"$software"}) ) {
		  push ( @{$result}, $prodhash->{"$software"} );
		}
	  }
	}
	
	$result = $self->uniquify_versions($result);
	
	return $result;
  }
  
#=============================================================================
sub getCPID
  {
    my $self = shift;
	my $uc   = shift || return 'UNDEFINED';
	
	my $installdata = $self->get_installer_data( "$uc" );
	if ( defined($installdata) ) {
	  my $cpid = $installdata->contentpack() || 'UNKNOWN';
	  return $cpid;
	}
	return 'UNDEFINED';
  }
  
#=============================================================================
sub get_installer_data
  {
    my $self = shift;
	return $self->__get_toplevel_data_item( @_, 'installer_data' );
  }

#=============================================================================
sub get_pdt_data
  {
    my $self = shift;
	return $self->__get_toplevel_data_item( @_, 'process_definitions' );
  }

#=============================================================================
sub get_requirements_data
  {
    my $self = shift;
	return $self->__get_toplevel_data_item( @_, 'requirements' );
  }
  
#=============================================================================
sub get_themes
  {
    my $self = shift;
	my @known_themes = keys( %{$self->themes()} );
	return \@known_themes;
  }
  
#=============================================================================
sub get_theme_from_uc
  {
    my $self   = shift;
	my $ucname = shift || return '__ALL__';
	
    my $data = $self->data() || return '__ALL__';
	my $ucs = $self->determine_usecases(@_);

	if ( &set_contains( $ucname, $ucs ) ) {
	  my $reqobj = $self->get_requirements_data( "$ucname" );
	  if ( defined($reqobj) ) { return $reqobj->theme(); }
	}
	return '__ALL__';
  }

#=============================================================================
sub get_usecases_per_contentpack_id
  {
    my $self = shift;
	my $cpid = shift || return [];
	
	my $ucs = $self->statistics()->{'base_metrics'}->{'usecases_per_cpid'}->{"$cpid"};
	if ( not defined($ucs) ) { return []; }
	
	return $ucs;
  }
 
#=============================================================================
sub get_usecases_per_theme
  {
    my $self   = shift;
	my $result = [];
	
	my $theme  = shift || return $result;
	
	my $ucs = $self->determine_usecases();
	foreach ( @{$ucs} ) {
	  push ( @{$result}, "$_" ) if ( $self->get_theme_from_uc("$_") eq $theme );
	}
	return $result;
  }

#=============================================================================
sub get_usecases_per_contentpack_id_and_theme
  {
    my $self   = shift;
	my $result = [];

	my $cpid   = shift || return $result;
    my $theme  = shift || return $result;
	
	my $ucs = $self->determine_usecases();
	foreach ( @{$ucs} ) {
	  push ( @{$result}, "$_" ) if ( $self->get_theme_from_uc("$_") eq $theme );
	}

    $ucs = $self->statistics()->{'base_metrics'}->{'usecases_per_cpid'}->{"$cpid"};
    $result = &set_intersect($result, $ucs);
	
    return $result;	
  }
  
#=============================================================================
sub get_software_per_use_case
  {
    my $self   = shift;
	my $result = [];
	
	my $uc = shift || return $result;
    my $data = $self->data() || return $result;
	
	my $ucs = $self->determine_usecases(@_);

	if ( &set_contains( $uc, $ucs ) ) {
	  my $reqobj   = $self->get_requirements_data( "$uc" );
	  my $softgrps = $reqobj->get_software_groups();
	  foreach my $sg ( @{$softgrps} ) {
	    $result = &set_union( $result, $reqobj->get_software_products( "$sg" ) );
	  }
	}
	
	return $result;
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
		  $self->{"$key"} = $_[0]->{"$key"} if ( exists($self->{"$key"}) );
		}
	  } else {
	    &__print_output("Please use a hash as input to construct this class < $class >", 'STDERR');
		return undef;
	  }
	}
	
    bless $self, $class;
    return $self;  
  }
  
#=============================================================================
sub print
  {
    my $self        = shift;
    my $directive   = shift;
    my $data_fields = $self->data_types();

    my $skip_keys   = [];
    my @show_keys   = keys(%{$data_fields});
	
	if ( defined($directive) ) {
      if ( not defined($directive->{'streams'}) ) { $directive->{'streams'} = [ 'STDERR' ]; }
      if ( not defined($directive->{'indent'}) )  { $directive->{'indent'}  = ''; }
      if ( not defined($directive->{'package'}) ) { $directive->{'package'} = __PACKAGE__; }
	} else {
	  $directive = {
	                'streams' => [ 'STDERR' ],
					'indent'  => '',
					'package' => __PACKAGE__,
				   };
	}
	
    foreach my $key (sort(@show_keys)) {
      if ( defined($self->{$key}) ) {
	    my $sub_str = $self->{$key};
	    my $outstr = sprintf("$directive->{'indent'}$directive->{'package'}::%-32s --> []",$key);
	    if ( length($sub_str) > 0 ) {
	      $outstr = sprintf("$directive->{'indent'}$directive->{'package'}::%-32s --> [$sub_str]",$key);
	    }
	    &__print_output("$outstr\n",$directive->{'package'});
      }
    }
	return;
  }

#=============================================================================
sub uniquify_versions
  {
    my $self             = shift;
	my $list_of_versions = shift || return [];
	
	my $unique_list     = [];
	my @skip_list       = ();
	
	if ( ref($list_of_versions) !~ m/array/i ) { return []; }

	for ( my $outer_loop = 0; $outer_loop < scalar( @{$list_of_versions} ); ++$outer_loop ) {
	  for ( my $inner_loop = $outer_loop + 1; $inner_loop < scalar( @{$list_of_versions} ); ++ $inner_loop ) {
	    if ( $list_of_versions->[$outer_loop]->equals($list_of_versions->[$inner_loop]) == TRUE ) {
		  push( @skip_list, $inner_loop );
		}
	  }
	}
	
	if ( scalar(@skip_list) < 1 ) { return $list_of_versions; }
	for ( my $loop = 0; $loop < scalar( @{$list_of_versions} ); ++$loop ) {
	  push ( @{$unique_list}, $list_of_versions->[$loop] ) if ( not &set_contains($loop, \@skip_list) );
	}
	
	return $unique_list;
  }
  
#=============================================================================
1;