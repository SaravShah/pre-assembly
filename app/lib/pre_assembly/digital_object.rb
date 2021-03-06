module PreAssembly
  class DigitalObject
    include PreAssembly::Logging

    attr_reader :bundle, :stageable_items

    delegate :assembly_staging_dir,
             :bundle_dir,
             :content_md_creation,
             :content_structure,
             :project_name,
             :smpl_manifest,
             :staging_style_symlink,
             to: :bundle

    attr_accessor :container,
                  :content_md_xml,
                  :label,
                  :manifest_row,
                  :object_files,
                  :pre_assem_finished,
                  :source_id,
                  :technical_md_xml

    attr_writer :dor_object, :druid_tree_dir

    INIT_PARAMS = [:container, :stageable_items, :object_files].freeze

    # @param [PreAssembly::Bundle] bundle
    # @param [Hash<Symbol => Object>] params
    def initialize(bundle, params = {})
      @bundle = bundle
      INIT_PARAMS.each { |p| instance_variable_set "@#{p}", params[p] }
      bad_params = params.keys.reject { |k| INIT_PARAMS.include?(k) }
      raise ArgumentError, "Unrecognized param #{bad_params.first}" unless bad_params.empty?
      setup
    end

    def setup
      self.label            = 'Unknown' # used for registration when no label is provided in the manifest
      self.content_md_xml   = ''
      self.technical_md_xml = ''
    end

    def stager(source, destination)
      if staging_style_symlink
        FileUtils.ln_s source, destination, force: true
      else
        FileUtils.cp_r source, destination
      end
    end

    # set this object's content_md_creation_style
    # @return [Symbol]
    def content_md_creation_style
      # map the content type tags set inside an object to content metadata creation styles supported by the assembly-objectfile gem
      # format is 'tag_value' => 'gem style name'
      content_type_tag_mapping = {
        'Image' => :simple_image,
        'File' => :file,
        'Book (flipbook, ltr)' => :simple_book,
        'Book (image-only)' => :book_as_image,
        'Manuscript (flipbook, ltr)' => :simple_book,
        'Manuscript (image-only)' => :book_as_image,
        'Map' => :map
      }
      content_type_tag_mapping[content_type_tag] || content_structure.to_sym
    end

    # compute the base druid tree folder for this object
    def druid_tree_dir
      @druid_tree_dir ||= DruidTools::Druid.new(druid.id, assembly_staging_dir).path
    end

    def content_dir
      @content_dir ||= File.join(druid_tree_dir, 'content')
    end

    # the metadata subfolder
    def metadata_dir
      @metadata_dir ||= File.join(druid_tree_dir, 'metadata')
    end

    ####
    # The main process.
    ####

    def pre_assemble
      log "  - pre_assemble(#{source_id}) started"
      stage_files
      generate_content_metadata
      generate_technical_metadata
      initialize_assembly_workflow
      log "    - pre_assemble(#{pid}) finished"
    end

    ####
    # Determining the druid.
    ####

    # @return [DruidTools::Druid]
    def druid
      @druid ||= DruidTools::Druid.new(pid)
    end

    def pid
      @pid ||= begin
        raise 'manifest_row is required' unless manifest_row
        manifest_row[:druid]
      end
    end

    def query_dor_by_barcode(barcode)
      Dor::SearchService.query_by_id barcode: barcode
    end

    def get_dor_item_apos(_pid)
      dor_object.nil? ? [] : dor_object.admin_policy_object
    end

    def dor_object
      @dor_object ||= Dor::Item.find(pid)
    rescue ActiveFedora::ObjectNotFoundError
      @dor_object = nil
    end

    def content_type_tag
      dor_object.nil? ? '' : dor_object.content_type_tag
    end

    def container_basename
      File.basename(container)
    end

    ####
    # Registration and other Dor interactions.
    ####

    def add_collection_relationship_params(druid)
      [:is_member_of_collection, "info:fedora/#{druid}"]
    end

    ####
    # Staging files.
    ####

    # Create the druid tree within the staging directory,
    # and then copy-recursive all stageable items to that area.
    def stage_files
      # these are the names of special datastream files that will be staged in the 'metadata' folder instead of the 'content' folder
      metadata_files = ['descMetadata.xml', 'contentMetadata.xml'].map(&:downcase)
      log "    - staging(druid_tree_dir = #{druid_tree_dir.inspect})"
      create_object_directories
      stageable_items.each do |si_path|
        log "      - staging(#{si_path}, #{content_dir})", :debug
        # determine destination of staged file by looking to see if it is a known datastream XML file or not
        destination = metadata_files.include?(File.basename(si_path).downcase) ? metadata_dir : content_dir
        stager si_path, destination
      end
    end

    # Technical metadata combined file for SMPL.
    def generate_technical_metadata
      create_technical_metadata
      write_technical_metadata
    end

    # create technical metadata for smpl projects only
    def create_technical_metadata
      return unless content_md_creation == 'smpl_cm_style'

      tm = Nokogiri::XML::Document.new
      tm_node = Nokogiri::XML::Node.new('technicalMetadata', tm)
      tm_node['objectId'] = pid
      tm_node['datetime'] = Time.now.utc.strftime('%Y-%m-%d-T%H:%M:%SZ')
      tm << tm_node

      # find all technical metadata files and just append the xml to the combined technicalMetadata
      current_directory = Dir.pwd
      FileUtils.cd(File.join(bundle_dir, container_basename))
      Dir.glob('**/*_techmd.xml').sort.each do |filename|
        tech_md_xml = Nokogiri::XML(File.open(File.join(bundle_dir, container_basename, filename)))
        tm.root << tech_md_xml.root
      end
      FileUtils.cd(current_directory)
      self.technical_md_xml = tm.to_xml
    end

    # write technical metadata out to a file only if it exists
    def write_technical_metadata
      return if technical_md_xml.blank?
      file_name = File.join(metadata_dir, technical_md_file)
      log "    - write_technical_metadata_xml(#{file_name})"
      create_object_directories
      File.open(file_name, 'w') { |fh| fh.puts technical_md_xml }
    end

    # Content metadata.
    def generate_content_metadata
      create_content_metadata
      write_content_metadata
    end

    # Invoke the contentMetadata creation method used by the project
    def create_content_metadata
      if content_md_creation == 'smpl_cm_style'
        self.content_md_xml = smpl_manifest.generate_cm(druid.id)
      else
        # otherwise use the content metadata generation gem
        params = { druid: druid.id, objects: content_object_files, add_exif: false, bundle: content_md_creation.to_sym, style: content_md_creation_style }
        self.content_md_xml = Assembly::ContentMetadata.create_content_metadata(params)
      end
    end

    # write content metadata out to a file
    def write_content_metadata
      file_name = File.join(metadata_dir, content_md_file)
      create_object_directories

      File.open(file_name, 'w') { |fh| fh.puts content_md_xml }

      # NOTE: This is being skipped because it now removes empty nodes, and we need an a node like this: <file id="filename" /> when first starting with contentMetadat
      #        If this node gets removed, then nothing works.  - Peter Mangiafico, October 3, 2015
      # mods_xml_doc = Nokogiri::XML(@content_md_xml) # create a nokogiri doc
      # normalizer = Normalizer.new
      # normalizer.normalize_document(mods_xml_doc.root) # normalize it
      # File.open(file_name, 'w') { |fh| fh.puts mods_xml_doc.to_xml } # write out normalized result
    end

    # Object files that should be included in content metadata.
    def content_object_files
      object_files.reject(&:exclude_from_content).sort
    end

    # Checks filesystem for expected files
    def object_files_exist?
      return false if object_files.empty?
      object_files.map(&:path).all? { |path| File.readable?(path) }
    end

    ####
    # Descriptive metadata.
    ####

    def create_object_directories
      FileUtils.mkdir_p druid_tree_dir unless File.directory?(druid_tree_dir)
      FileUtils.mkdir_p metadata_dir unless File.directory?(metadata_dir)
      FileUtils.mkdir_p content_dir unless File.directory?(content_dir)
    end

    ####
    # Initialize the assembly workflow.
    ####

    # Call web service to add assemblyWF to the object in DOR.
    def initialize_assembly_workflow
      # TODO: use dor-workflow-service gem for this (see #194)
      with_retries(max_tries: Dor::Config.dor_services.num_attempts, rescue: Exception, handler: retry_handler('INITIALIZE_ASSEMBLY_WORKFLOW', method(:log))) do
        RestClient.post(assembly_workflow_url, {}).tap do |result|
          next if result && (200..204).cover?(result.code)
          raise "POST #{assembly_workflow_url} returned #{result.code}"
        end
      end
    end

    def assembly_workflow_url
      "#{Dor::Config.dor_services.url}/objects/#{druid.druid}/apo_workflows/assemblyWF"
    end

    private

    def technical_md_file
      'technicalMetadata.xml'
    end

    def content_md_file
      'contentMetadata.xml'
    end

    def retry_handler(method_name, _logger, params = {})
      proc do |_exception, attempt_number, total_delay|
        log("      ** #{method_name} FAILED **; with params of #{params.inspect}; and trying attempt #{attempt_number} of #{Dor::Config.dor_services.num_attempts}; delayed #{total_delay} seconds")
      end
    end
  end
end
