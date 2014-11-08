package HP::SupportMatrix::HTMLReport;

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
	                        'HTML::Stream'                 => undef,
							'Tie::IxHash'                  => undef,
							'GD::Graph'                    => undef,
							
	                        'HP::RegexLib'                 => undef,
							'HP::ArrayTools'               => undef,
							'HP::StreamManager'            => undef,
							'HP::FileManager'              => undef,
							'HP::Path'                     => undef,
							'HP::CSLTools::Common'         => undef,
							'HP::CSLTools::Constants'      => undef,
							
							'HP::SupportMatrix::Constants' => undef,
							'HP::SupportMatrix::Tools'     => undef,
							'HP::SupportMatrix::Graph'     => undef,
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
use constant NO_COLOR => '#000000';
use constant SUPPORT_COLOR => '#00FF00';
use constant NO_SUPPORT_COLOR => '#000000';

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
sub data_types
  {
    # See if there is a way to read this from file.
    my %data_fields = (
	                   'filename'         => undef,
					   'HTMLheaders'      => undef,
					   'HTMLheaderlayout' => undef,
					   'HTMLoutput'       => undef,
					   'themes'           => {},
		              );
    
    return \%data_fields;
  }

#=============================================================================
sub DESTROY
  {
    my $self = shift;

    &__print_debug_output("Calling destructor for object ".ref($self)."\n");
	return;
  }

#=============================================================================
sub __build_html_table_headers
  {
    my $self     = shift;
	my $ucs      = shift || return FALSE;
	my $theme    = shift || return FALSE;
	my $analyzer = shift || return FALSE;
	
	tie my %associated_software, 'Tie::IxHash';
	tie my %subtable_header, 'Tie::IxHash';
	
	foreach my $uc ( @{$ucs} ) {
	  my $reqobj   = $analyzer->get_requirements_data( "$uc" );
	  my $softgrps = $reqobj->get_software_groups();
	  foreach my $sg ( sort keys( %{$softgrps} ) ) {
	    my $products = $reqobj->get_software_products( "$sg" );
		foreach my $prod ( sort keys( %{$products} ) ) {
		  my $versions = $analyzer->find_unique_versions_of_software_for_usecase( "$uc", "$sg", "$prod" );
		  my $num_versions = scalar(@{$versions});
		  
		  if ( $num_versions > 0 ) {
		    $associated_software{"$sg"}->{"$prod"} = $versions;			   
		  }
		  
		  if ( $num_versions > 1 ) {
		    $subtable_header{"$sg"}->{"$prod"} = 1;
		  }
		}
	  }	
	}
	
	$self->HTMLheaders(\%associated_software);
	$self->HTMLheaderlayout(\%subtable_header);
	
	return TRUE;
  }
  
#=============================================================================
sub __create_table_body
  {
    my $self     = shift;
	my $uc       = shift || return;
	my $analyzer = shift || return;
	
	my $HTML = $self->HTMLoutput() || return;
	
	$HTML->tag('TBODY')->nl();
    $HTML->tag('TR')->nl();
	$HTML->tag('TD');
	$HTML->text("$uc");
	$HTML->tag('_TD')->nl();

	my $header_elements = $self->HTMLheaders();
	my $subtable_header = $self->HTMLheaderlayout();
	
	# Loop over header elements by type so that the table can have
	# overlapping rows when needed...
	foreach my $head_grp_element ( sort keys(%{$header_elements}) ) {
	  foreach my $head_element ( sort keys(%{$header_elements->{"$head_grp_element"}} ) ) {
	    print STDERR "$head_grp_element -- $head_element\n";
	    if ( not defined( $subtable_header->{"$head_grp_element"}->{"$head_element"} ) ) {
		  # Sub table for multiple versions.  Need to produce a table...
	      my $bg_color_code = $self->determine_support( {
			                                             'softgroup'       => "$head_grp_element",
														 'softprod'        => "$head_element",
														 'usecase'         => "$uc",
														 'supportversions' => $header_elements->{"$head_grp_element"}->{"$head_element"},
														 'analyzer'        => $analyzer } );
	      $HTML->tag('TD', BGCOLOR=>"$bg_color_code");
		  $HTML->tag('_TD')->nl();
		} else {
		  foreach my $v ( @{$header_elements->{"$head_grp_element"}->{"$head_element"}} ) {
		    my $bg_color_code = $self->determine_support( {
			                                               'softgroup'       => "$head_grp_element",
														   'softprod'        => "$head_element",
														   'usecase'         => "$uc",
														   'supportversions' => [ $v ],
														   'analyzer'        => $analyzer } );
	        $HTML->tag('TD', BGCOLOR=>"$bg_color_code");
	        $HTML->tag('_TD')->nl();		
		  }
		}
	  }
	}
	$HTML->tag('_TR')->nl();
	$HTML->tag('_TBODY')->nl();
	return;
  }

#=============================================================================
sub __create_table_button
  {
    my $self  = shift;
	my $theme = shift;
	my $HTML  = $self->HTMLoutput() || return;
	
	$HTML->tag('INPUT', TYPE=>'BUTTON', VALUE=>'Hide Table', ONCLICK=>"return hideTable('$theme', 'block')")->nl();
	$HTML->tag('INPUT', TYPE=>'BUTTON', VALUE=>'Show Table', ONCLICK=>"return showTable('$theme', 'block')")->nl();
	
	return;
  }
  
#=============================================================================
sub __create_table_footer
  {
    my $self = shift;
	my $HTML = $self->HTMLoutput() || return;
	
	$HTML->tag('TFOOT')->nl();
	$HTML->tag('_TFOOT')->nl();
	$HTML->tag('_TABLE')->nl();
	$HTML->tag('_DIV')->nl();
	$HTML->tag('P')->nl();
	return;
  }

#=============================================================================
sub __create_table_header
  {
    my $self     = shift;
	my $theme    = shift || '__ALL__';
	my $analyzer = shift || return FALSE;
	
	my $HTML  = $self->HTMLoutput() || return FALSE;
	
	$HTML->tag('P')->nl();
	$HTML->tag('DIV', ID=>"'$theme'")->nl();
	$HTML->tag('TABLE', ALIGN=>'CENTER', BORDER=>'2', STYLE=>'font-family:Arial,Helvetica,sans-serif;font-size:75%')->nl;
	
	my $grpd_products = $self->HTMLheaders();
	
	$HTML->tag('THEAD')->nl();
	$HTML->tag('TR')->nl();
	$HTML->tag('TD');
	$HTML->tag('_TD')->nl();
	
	# Handle table header row for "Grouped" software products
	foreach my $sg ( keys(%{$grpd_products}) ) {
	  my $sg_colspan = $self->collect_table_column_parameters("$sg");
	  $HTML->tag('TD', COLSPAN=>"$sg_colspan")->tag('STRONG');
	  $HTML->text("$sg");
	  $HTML->tag('_STRONG')->tag('_TD')->nl();
	}
	$HTML->tag('_TR')->nl();
	
	# Handle table header row for software products
	if ( scalar(keys(%{$grpd_products})) ) {
      $HTML->tag('TR')->nl();
	  $HTML->tag('TD');
	  $HTML->tag('_TD')->nl();
	  foreach my $sg ( keys( %{$grpd_products} ) ) {
	    foreach my $prod ( sort keys( %{$grpd_products->{"$sg"}} ) ) {
		  my $versions = $grpd_products->{"$sg"}->{"$prod"};
		  my $num_versions = scalar(@{$versions});
	      $HTML->tag('TD', COLSPAN=>"$num_versions")->tag('STRONG');
	      $HTML->text("$prod");
	      $HTML->tag('_STRONG')->tag('_TD')->nl();
	    }
	  }
	  $HTML->tag('_TR')->nl();
	}
	
	# Handle table header row for Versions of each software products
	if ( scalar(keys(%{$grpd_products})) ) {
      $HTML->tag('TR')->nl();
	  $HTML->tag('TD');
	  $HTML->tag('_TD')->nl();
	  
	  my $allowed_attrs_2_show = [ 'cp', 'type' ];
	  
	  foreach my $sg ( keys( %{$grpd_products} ) ) {
	    foreach my $prod ( sort keys( %{$grpd_products->{"$sg"}} ) ) {
		  my $versions = $grpd_products->{"$sg"}->{"$prod"};
		  my $num_versions = scalar(@{$versions});
		  if ( $num_versions < 1 ) {
		    $HTML->tag('TD')->tag('_TD')->nl();
			next;
		  } else {
			foreach my $v ( @{$versions} ) {
	          $HTML->tag('TD')->tag('STRONG');
			  $HTML->text($v->get_version( $allowed_attrs_2_show ));
			  $HTML->tag('_STRONG')->tag('_TD')->nl();
			}
		  }
	    }
	  }
	  $HTML->tag('_TR')->nl();
	}
	$HTML->tag('_THEAD')->nl();

	return TRUE;
  }

#=============================================================================
sub __create_use_case_tables
  {
    my $self     = shift;
	my $ucs      = shift || return;
	my $theme    = shift || return;
	my $analyzer = shift || return;
	
	my $HTML = $self->HTMLoutput() || return;
	
	return if ( ref($ucs) !~ m/array/i );
	
	# Headers are CPID and Theme based so either one changing
	# should enforce "rebuild" of headers
	$self->__build_html_table_headers( $ucs, "$theme", $analyzer );
	
	if ( $self->__create_table_header( "$theme", $analyzer ) == TRUE ) {
	  foreach ( @{$ucs} ) {
	    $self->__create_table_body("$_", $analyzer);
	    $self->__create_table_footer();
	    $self->__create_table_button("$theme");
	  }
	}
	
	$self->HTMLheaders(undef);
	return;
  }

#=============================================================================
sub collect_table_column_parameters
  {
    my $self = shift;
	my $num_versions_in_prods = 0;
	
	my $softgrp = shift || return $num_versions_in_prods;
	
	my $grpd_products = $self->HTMLheaders();
	
	foreach my $prod ( sort keys( %{$grpd_products->{"$softgrp"}} ) ) {
	  my $versions = $grpd_products->{"$softgrp"}->{"$prod"};
	  $num_versions_in_prods += scalar( @{$versions} );
	}
	
	return $num_versions_in_prods;
  }
  
#=============================================================================
sub determine_support
  {
    my $self           = shift;
	my $hashinput      = shift || return NO_COLOR;
	
	if ( ref($hashinput) !~ m/hash/i ) { return NO_COLOR; }
	
	my $header_grp     = $hashinput->{'softgroup'}       || return NO_COLOR;
	my $header_element = $hashinput->{'softprod'}        || return NO_COLOR;
	my $uc             = $hashinput->{'usecase'}         || return NO_COLOR;
	my $softversions   = $hashinput->{'supportversions'} || return NO_COLOR;
	my $analyzer       = $hashinput->{'analyzer'}        || return NO_COLOR;
	
	my $use_case_products = $analyzer->get_requirements_data( "$uc" )->get_software_products_with_versions( "$header_grp" );
	my @uc_prod_names = keys( %{$use_case_products} );
	if ( &set_contains( "$header_element", \@uc_prod_names ) ) {
	  foreach my $v1 ( @{$softversions} ) {
	    foreach my $v2 ( @{$use_case_products->{"$header_element"}} ) {
	      if ( $v1->equals($v2) ) { return SUPPORT_COLOR; }
		}
	  }
	}
	
	return NO_SUPPORT_COLOR;
  }
  
#=============================================================================
sub getCSSsupport
  {
    my $self = shift;
	my $css_support =<<__CSS__;
table {
    display: table;
    border-spacing: 2px;
    border-color: gray
	border-collapse: collapse;
	table-layout: auto;
    width: 100%
}

thead {
    display: table-header-group;
    vertical-align: middle;
    border-color: inherit
}

tbody {
    display: table-row-group;
    vertical-align: middle;
    border-color: inherit
}

tfoot {
    display: table-footer-group;
    vertical-align: middle;
    border-color: inherit
}

col {
    display: table-column
}

colgroup {
    display: table-column-group
}

tr {
    display: table-row;
    vertical-align: inherit;
    border-color: inherit
}

td, th {
    display: table-cell;
    vertical-align: inherit
}

th {
    font-weight: bold
}

th, td {
    padding: 2px;
    text-align: center;
}

caption {
    display: table-caption;
}

body{font-family:Arial,Helvetica,sans-serif;font-size:100%;}

__CSS__

	return $css_support;
  }
  
#=============================================================================
sub make_body
  {
    my $self     = shift;
	my $analyzer = shift || return;
	my $HTML     = $self->HTMLoutput() || return;
	
	$HTML->tag('BODY')->nl;
	  
	my $cpIDs = $analyzer->determine_content_pack_ids();
	foreach my $cpID ( sort @{$cpIDs} ) {
	  $HTML->tag('H3');
	  $HTML->text("Content Pack $cpID");
	  $HTML->tag('_H3')->nl;
	  
	  my $themes = $analyzer->determine_themes();
	  foreach my $theme ( sort @{$themes} ) {
	    my $ucs = $analyzer->get_usecases_per_contentpack_id_and_theme( "$cpID", "$theme" );	  
	    $self->__create_use_case_tables($ucs, $theme, $analyzer);
	  }
	}
	$HTML->tag('_BODY')->nl;
    return;
  }
  
#=============================================================================
sub make_charts
  {
    my $self = shift;
	my $analyzer = shift || return;
	
	my @metrics_2_plot = qw(dependency_metrics blueprint_metrics software_metrics);
	foreach my $m2p ( @metrics_2_plot ) {
	  my $statdata = $analyzer->statistics()->{$m2p}->{'frequency'};
      next if ( not defined($statdata) );
		
	  my $graph = HP::SupportMatrix::Graph->new();
	  next if ( not defined($graph) );
		
	  &HP::RegexLib::allow_space_as_valid_string(1);
	  $graph->add_data_item( 'xdata', $self->make_ref(keys( %{$statdata} )), undef, 'ARRAY' );
	  $graph->add_data_item( 'ydata', $self->make_ref(values( %{$statdata} )), undef, 'ARRAY' );
	  $graph->add_data_item( 'x_label', 'Software Product', 'X axis', '' );
	  $graph->add_data_item( 'y_label', 'Count', 'Y axis', '' );
	  $graph->add_data_item( 'title', 'Sample', 'Title', '' );
	  $graph->add_data_item( 'bar_spacing', 8, 8, '' );
	  $graph->add_data_item( 'shadow_depth', 4, 4, '' );
	  $graph->add_data_item( 'shadow_clr', 'dred', 'dred', '' );
	  $graph->add_data_item( 'transparent', 0, 0, '' );
	  &HP::RegexLib::allow_space_as_valid_string(0);
		
	  $graph->filename(&join_path('HTML', "$m2p.png"));
	  $graph->make_graph('hbars');
    }
    return;
  }
  
#=============================================================================
sub make_ref
  {
    my $self = shift;
	my @all_items = @_;
	
	if ( scalar(@all_items) > 1 ) { return \@all_items; }
	return $all_items[0];
  }

#=============================================================================
sub make_header
  {
    my $self = shift;
	my $HTML = $self->HTMLoutput() || return;

	$HTML->tag('HEAD')->nl;
	$HTML->tag('STYLE')->nl;
	$HTML->text($self->getCSSsupport());
    $HTML->tag('_STYLE')->nl;
	$HTML->tag('H1');
	$HTML->text('Cloud Solutions Lab Support Matrix');
	$HTML->tag('_H1')->nl;
	$HTML->tag('HR')->nl;
	$HTML->tag('SCRIPT', LANGUAGE=>'javascript', TYPE=>'text/javascript')->nl();
	$HTML->text($self->__visibility_js());
	$HTML->tag('_SCRIPT')->nl;
	$HTML->tag('_HEAD')->nl;
	return;
  }
  
#=============================================================================
sub make_title
  {
    my $self  = shift;
	my $HTML  = $self->HTMLoutput() || return;
	
    $HTML->tag('TITLE');
	$HTML->text('CSL Support Matrix');
	$HTML->tag('_TITLE')->nl;
	
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
      if ( not defined($directive->{'indent'}) )  { $directive->{'indent'} = ''; }
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
  }

#=============================================================================
sub __visibility_js
  {
    my $self = shift;
	
	my $jsfunction =<<__JSFUNC__;
function hideTable(tableID, action) {
   var tableObject = document.getElementById(tableID);
   if ( action == \"visibility\" )
      tableObject.style.visibility = "hidden";
   else if ( action == \"block\" )
      tableObject.style.visibility = "none";
}

function showTable(tableID, action) {
   var tableObject = document.getElementById(tableID);
   if ( action == \"visibility\" )
      tableObject.style.visibility = "visible";
   else if ( action == \"block"\ )
      tableObject.style.visibility = "block";
}
__JSFUNC__

    return $jsfunction;
  }

#=============================================================================
sub write_output
  {
    my $self     = shift;
	my $analyzer = shift;
	
	my $opfref = {
	              'filename'    => $self->filename(),
				  'permissions' => 'w',
				  'idhandle'    => '__HTMLOUT__',
				 };
	
	if ( not defined($opfref->{'filename'}) ) {
	  &csl_print_output("No filename specified for output.  No output written!", WARNING);
	} else {
	  $self->make_charts();
	  my $htmlstream = &open_stream($opfref);
	  my $HTML = HTML::Stream->new($htmlstream);
	  $self->HTMLoutput($HTML);
	  
      $HTML->auto_format(1);
 	  $HTML->tag('HTML', XLMNS=>"http://www.w3.org/1999/xhtml", LANG=>"en")->nl;
	  
	  $self->make_title();
	  $self->make_header();
	  $self->make_body($analyzer);
	  
	  $HTML->tag('_HTML')->nl;
	  #$self->HTMLoutput = 
    }
	return;
  }

#=============================================================================
1;