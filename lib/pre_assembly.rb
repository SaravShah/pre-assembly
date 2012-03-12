require 'csv-mapper'
require 'fileutils'
require 'yaml'

require 'pre_assembly/version'

require 'pre_assembly/bundle'
require 'pre_assembly/digital_object'
require 'pre_assembly/image'


Dor::Config.configure do

  pre_assembly do

    # Default file names.
    cm_file_name        'content_metadata.xml'
    dm_file_name        'desc_metadata.xml'
    manifest_file_name  'manifest.cvs'
    checksums_file_name 'checksums.txt'

    # Default preserve-shelve-publish attribritutes.
    publish_attr Hash[:preserve => 'yes', :shelve => 'no', :publish => 'no']

    # The assembly workflow parameters.
    assembly_wf  'assemblyWF'
    assembly_wf_steps Hash[
      'start-assembly'   => 'completed',
      'checksum'         => 'waiting',
      'checksum-compare' => 'waiting',
    ]

  end

end