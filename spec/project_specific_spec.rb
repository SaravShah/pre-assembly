describe PreAssembly::DigitalObject do

  before(:each) do
    @ps = {
      :apo_druid_id  => 'qq333xx4444',
      :set_druid_id  => 'mm111nn2222',
      :source_id     => 'SourceIDFoo',
      :project_name  => 'ProjectBar',
      :label         => 'LabelQuux',
      :publish_attr  => { :publish => 'no', :shelve => 'no', :preserve => 'yes' },
      :project_style => {},
      :bundle_dir    => 'spec/test_data/bundle_input_e',
      :content_md_creation => {:style=>:smpl,:pre_md_file=>'preContentMetadata.xml'}
    }
    @dobj         = PreAssembly::DigitalObject.new @ps
    @dru          = 'aa111aa1111'
    @pid          = "druid:#{@dru}"
    @druid        = Druid.new @pid
    @tmp_dir_args = [nil, 'tmp']
    @dobj.druid = @druid
    @dobj.container = @dru    
  end


  ####################

  describe "SMPL specific methods in project_specific module" do

    it "should convert SMPL content metadata into valid base content metadata" do

      @exp_xml = <<-END.gsub(/^ {8}/, '')
      <?xml version="1.0"?>
      <contentMetadata objectId="aa111aa1111" type="file">
        <resource sequence="1" id="aa111aa1111_1" type="file">
          <label>Tape 1, Side A</label>
          <file shelve="no" publish="yes" preserve="yes" id="PM/aa111aa1111_001_a_pm.wav">
            <provider_checksum type="md5">checksumforaa111aa1111_001_a_pm.wav</provider_checksum>
          </file>
          <file shelve="no" publish="yes" preserve="yes" id="SH/aa111aa1111_001_a_sh.wav">
            <provider_checksum type="md5">checksumforaa111aa1111_001_a_sh.wav</provider_checksum>
          </file>
          <file shelve="no" publish="yes" preserve="yes" id="SL/aa111aa1111_001_a_sl.mp3">
            <provider_checksum type="md5">checksumforaa111aa1111_001_a_sl.mp3</provider_checksum>
          </file>
          <file shelve="yes" publish="yes" preserve="yes" id="Images/aa111aa1111_001_img_1.jpg">
            <provider_checksum type="md5">checksumforaa111aa1111_001_img_1.jpg</provider_checksum>
          </file>
        </resource>
        <resource sequence="2" id="aa111aa1111_2" type="file">
          <label>Tape 1, Side B</label>
          <file shelve="no" publish="yes" preserve="yes" id="PM/aa111aa1111_001_b_pm.wav">
            <provider_checksum type="md5">checksumforaa111aa1111_001_b_pm.wav</provider_checksum>
          </file>
          <file shelve="no" publish="yes" preserve="yes" id="SH/aa111aa1111_001_b_sh.wav">
            <provider_checksum type="md5">checksumforaa111aa1111_001_b_sh.wav</provider_checksum>
          </file>
          <file shelve="no" publish="yes" preserve="yes" id="SL/aa111aa1111_001_b_sl.mp3">
            <provider_checksum type="md5">checksumforaa111aa1111_001_b_sl.mp3</provider_checksum>
          </file>
          <file shelve="yes" publish="yes" preserve="yes" id="Images/aa111aa1111_001_img_2.jpg">
            <provider_checksum type="md5">checksumforaa111aa1111_001_img_2.jpg</provider_checksum>
          </file>
        </resource>
        <resource sequence="3" id="aa111aa1111_3" type="file">
          <label>Transcript</label>
          <file shelve="yes" publish="yes" preserve="yes" id="Transcript/aa111aa1111.pdf">
            <provider_checksum type="md5">checksumforedited_transcript.pdf</provider_checksum>
          </file>
        </resource>
      </contentMetadata>
      END
      @exp_xml = noko_doc @exp_xml
      noko_doc(@dobj.create_content_metadata_xml_smpl).should be_equivalent_to @exp_xml
    end

  end
  
end