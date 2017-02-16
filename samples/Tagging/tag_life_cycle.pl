#!/usr/bin/perl

#
# @author: VMware, Inc.
# @copyright: copyright 2014, 2016, 2017 VMware, Inc.  All rights reserved.
# @vcenter version: 6.0+

#
# Perl Core Modules
#
use strict;
use Getopt::Long;

#
# VMware runtime library
#
use Com::Vmware::Vapi::Util::Logger
  qw(log_info log_dumper log_framework log_warning set_verbosity);

#
# Sample helper module
#
use Common::SampleBase;

#
# Generated SDK's
#
use Com::Vmware::Cis::Session;
use Com::Vmware::Cis::Tagging::Category;
use Com::Vmware::Cis::Tagging::Tag;
use Com::Vmware::Cis::Tagging::CategoryModel;

# Set the logger level
set_verbosity( 'level' => 3 );

# Initialize the global variable
my (
   %params,      $sampleBase, $tag_name,         $category_name,
   $stubFactory, $stubConfig, $category_service, $tagging_service,
   $category_id, $tag_id
) = ();
my $tag_description = "Sample Tag";
my $CARDINALITY_MULTIPLE =
  Com::Vmware::Cis::Tagging::CategoryModel::Cardinality::MULTIPLE;

# Declare the mandatory parameter list
my @required_options = ( 'username', 'password', 'lsurl', 'server', 'cleanup' );

sub init {

   #
   # User inputs
   #
   GetOptions(
      \%params,     "server=s",     "lsurl=s",      "username=s",
      "password=s", "privatekey:s", "servercert:s", "cert:s",
      "tagname:s",  "mgmtnode:s",   "cleanup:s",    "help:s"
     )
     or die
"\nValid options are --server <server> --username <user> --password <password> --lsurl <lookup service url>
                         --privatekey <private key> --cert <cert> --tagname <tag name> --mgmtnode <management node name found on server> --cleanup <value should be true or false> or --help\n";

   if ( defined( $params{'help'} ) ) {
      print "\nCommand to execute sample:\n";
      print
"tag_life_cycle.pl --server <server> --username <user> --password <password> --lsurl <lookup service url> \n";
      print
"               --privatekey <private key> --cert <cert> --tagname <tag name> --cleanup <value should be true or false> \n";
      exit;
   }

   my $mandatory_params_list = 'Missing mandatory parameter(s) i.e. ';
   my $flag                  = 0;
   foreach (@required_options) {
      if ( !defined( $params{$_} ) ) {
         $flag = 1;
         $mandatory_params_list =
           ' ' . $mandatory_params_list . '--' . $_ . ', ';
      }
   }
   if ( $flag == 1 ) {
      print $mandatory_params_list;
      exit;
   }

   $tag_name = $params{'tagname'};

   #
   # If tag name is not supplied use the default
   #
   if ( !defined($tag_name) ) {
      $tag_name = "Sample-Tag";
   }
   $category_name = $tag_name . "-Category";

   $sampleBase  = new Common::SampleBase( 'params' => \%params );
   $stubConfig  = $sampleBase->{'stub_config'};
   $stubFactory = $sampleBase->{'stub_factory'};
}

sub setup {

   #
   # Get the Tag Category Service
   #
   log_info( MSG => "Creating Tag Category Service..." );
   $category_service = $stubFactory->create_stub(
      'service_name' => 'Com::Vmware::Cis::Tagging::Category',
      'stub_config'  => $stubConfig
   );

   #
   # Get the Tagging Service
   #
   log_info( MSG => "Creating Tagging Service..." );
   $tagging_service = $stubFactory->create_stub(
      'service_name' => 'Com::Vmware::Cis::Tagging::Tag',
      'stub_config'  => $stubConfig
   );
}

sub run {
   log_info( MSG => "Creating a new Tag category '$category_name' ..." );
   $category_id = createTagCategory(
      'category_name' => $category_name,
      'description'   => $tag_description,
      'cardinality'   => $CARDINALITY_MULTIPLE
   );
   log_info( MSG => "Tag category create result: '$category_id'" );

   #
   # Create the tag
   #
   log_info( MSG => "Creating a new tag '$tag_name' ..." );
   $tag_id = createTag(
      'name'        => $tag_name,
      'description' => $tag_description,
      'category_id' => $category_id
   );
   log_info( MSG => "Tag create result: '$tag_id'" );

   #
   # Read the tag
   #
   log_info( MSG => "Reading the tag '$tag_name' from tagging service ..." );
   getTag( 'tag_id' => $tag_id );

   #
   # Update the asset tag
   #
   log_info( MSG => "Updating the tag '$tag_name' ..." );
   updateTag( 'tag_id' => $tag_id, 'description' => $tag_description );
}

#
# API to create a category. User who invokes this needs create category privilege.
#
sub createTagCategory {
   my %args            = @_;
   my $category_name   = $args{'category_name'};
   my $tag_description = $args{'description'};
   my $cardinality     = $args{'cardinality'};

   #
   # Create a new tag category
   #
   my $spec = new Com::Vmware::Cis::Tagging::Category::CreateSpec();
   $spec->set_name( 'name' => $category_name );
   $spec->set_description( 'description' => $tag_description );
   $spec->set_cardinality( 'cardinality' => $cardinality );

   # Set empty types
   $spec->set_associable_types( 'associable_types' => [] );
   $category_id = $category_service->create( 'create_spec' => $spec );
   return $category_id;
}

#
# Creates a tag
#
sub createTag {
   my %args            = @_;
   my $tag_name        = $args{'name'};
   my $tag_description = $args{'description'};
   my $cardinality     = $args{'category_id'};

   my $spec = new Com::Vmware::Cis::Tagging::Tag::CreateSpec();
   $spec->set_name( 'name' => $tag_name );
   $spec->set_description( 'description' => $tag_description );
   $spec->set_category_id( 'category_id' => $category_id );
   $tag_id = $tagging_service->create( 'create_spec' => $spec );
   return $tag_id;
}

#
# Reads a tag
#
sub getTag {
   my %args     = @_;
   my $tag_name = $args{'tag_id'};

   return $tagging_service->get( 'tag_id' => $tag_id );
}

#
# Updates a tag
#
sub updateTag {
   my %args            = @_;
   my $tag_id          = $args{'tag_id'};
   my $tag_description = $args{'description'};
   my $spec            = new Com::Vmware::Cis::Tagging::Tag::UpdateSpec();
   $spec->set_description( 'description' => $tag_description );
   $tagging_service->update( 'tag_id' => $tag_id, 'update_spec' => $spec );
}

#
# Cleanup any data created by the sample run, if cleanup=true
#
sub cleanup() {
   log_info( MSG => "Deleting the tag '$tag_name' ..." );
   $tagging_service->delete( 'tag_id' => $tag_id );

   log_info( MSG => "Deleting the tag category '$category_name' ..." );
   $category_service->delete( 'category_id' => $category_id );
}

#
# This sample demonstrates vAPI connection and service initialization callflow
# Step 1: Connect to the vapi service endpoint.
# Step 2: Use the basic authentication to login to vAPI service endpoint.
# Step 3: Create a vAPI session.
# Step 4: Creates a new Tag Category.
# Step 5: Creates a new Tag
# Step 6: Read and Update the Tag
# Step 7: Cleanup - Delete the Tag and Tag Category
#

# Call main
&main();

sub main() {
   init();
   setup();
   run();
   if ( $params{cleanup} eq 'true' ) {
      cleanup();
   }
   log_info( MSG => "#### Done!" );
}

# END
