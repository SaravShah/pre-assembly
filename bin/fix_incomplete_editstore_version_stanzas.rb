#! /usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')


# Run with
# ROBOT_ENVIRONMENT=test bin/fix_incomplete_edistore_version_stanzas.rb PATH_TO_CSV_OF_DRUIDS
#CSV is expected to have headers of druid, dor_version, sdr_version


require 'rubygems'
require 'dor-services'
require 'dor-workflow-service'
require 'logger'
require 'csv'
require 'nokogiri'

#Load CSV and process it
CSV.foreach(ARGV[0], :headers => true) do |row|
  #puts row['druid']
  
  #Get the Item and datastream
  item = Dor::Item.find(row['druid'])
  vmd = item.datastreams['versionMetadata'].ng_xml
  
  #Remove All But the First Version (due to possible incomplete stanzas)
  v = 2
  begin (v <= row['dor-version'].to_i) do
    vmd.xpath("//versionMetadata/version[@versionId=#{v}]").remove
    v+=1
  end
  
  item.datastreams['versionMetadata'].content = vmd.to_xml
  item.datastreams['versionMetadata'].dirty = true
  item.datastreams['versionMetadata'].save
  
  #Replace the ones we just removed with new ones
  v = 2
  while(v <= rows['sdr-version'].to_i+1) do
    item.open_new_version(:assume_accessioned=>true) # we are already doing all of our checks to see if updates are allowe and versioning is required
    item.versionMetadata.update_current_version({:description => "descriptive metadata update from editstore",:significance => :admin})
    item.versionMetadata.content_will_change!
    item.versionMetadata.save
    v+=1
  end
  
  #Restart The Workflow
  Dor::WorkflowService.update_workflow_status 'dor', row['druid'], 'accessionWF', 'sdr-ingest-transfer', 'waiting'
  
  #Check for incomplete stanza
  #Delete incomplete stanza, lower number on all others
  #If no incomplete stanza, delete highest stanza 
  #Make sure no more than one total stanza is deleted or else we won't be in sync
  
  
  #Or nuke everything but version one and make n-2
  
  # <version tag="1.0.x-1" versionId="x">
 #     <description>descriptive metadata update from editstore</description>
 #   </version>
 #
 #   up to dorversion -1 = sdr +1 (remember we are keeping version 1)
  
end

