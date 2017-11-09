# frozen_string_literal: true

require 'spec_helper'

# FIXME
# rubocop:disable Metrics/ModuleLength
module DoctorTeeth
  # FIXME
  # rubocop:disable Metrics/BlockLength
  # rubocop:disable Metrics/LineLength
  describe NewLineJsonFileParser do
    shared_examples 'found file' do
      it 'should have all applicable test record fields' do
        # stub File.open
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(/some_file.json/).and_return(files_like_object)

        job_url = 'https://jenkins-master-prod-1.delivery.puppetlabs.net/job/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a/4/'
        expect(json_file_parser.test_runs[job_url]['execution_id']).to eq(job_url)
        expect(json_file_parser.test_runs[job_url]['project']).to eq('platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x')
        expect(json_file_parser.instance_variable_get(:@test_record)['configuration']).to eq(['SLAVE_LABEL=beaker', 'TEST_TARGET=fedora24-64a'])
        expect(json_file_parser.test_runs[job_url]['start_time']).to eq(Time.parse('2017-06-28 12:16:49 UTC'))
        # because the final object does not expose these?
        expect(json_file_parser.test_runs[job_url]['suite_name']).to be_nil
        expect(json_file_parser.test_runs[job_url]['suite_duration']).to be_nil
        expect(json_file_parser.test_runs[job_url]['test_name']).to be_nil
        expect(json_file_parser.test_runs[job_url]['test_status']).to be_nil
        expect(json_file_parser.test_runs[job_url]['test_duration']).to be_nil
        expect(json_file_parser.test_runs[job_url]['pre_suite_time']).to be_nil
        expect(json_file_parser.test_runs[job_url]['tests_time']).to be_nil
        expect(json_file_parser.test_runs[job_url]['duration']).to eq(4553.732448999999)
      end
      it 'should generate single json file' do
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(/some_file.json/).and_return(files_like_object)
        mock_file_buffer = StringIO.new
        allow(File).to receive(:open).with('somefile', 'w').and_yield(mock_file_buffer)
        expect { json_file_parser.generate_new_line_delimited_json_file('somefile') }.to_not raise_error
        expect(mock_file_buffer.string.chomp).to eq(output_contents)
      end
      it 'should generate multiple json files' do
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(/some_file.json/).and_return(files_like_object)
        mock_file_buffer = StringIO.new
        # allow(File).to receive(:open).with('somefile','w').and_yield( mock_file_buffer)
        allow(File).to receive(:open).with('somedir/file1', 'w').and_yield(mock_file_buffer)
        expect { json_file_parser.generate_new_line_delimited_json_files('somedir', number_of_files_to_generate) }.to_not raise_error
        expect(mock_file_buffer.string.chomp).to eq(output_contents)
      end
    end
    shared_examples 'missing file' do
      it 'and should raise error' do
        expect { json_file_parser }.to raise_error(Errno::ENOENT)
      end
    end
    shared_examples 'invalid json' do
      it 'should raise a runtime error' do
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(/some_file.json/).and_return(files_like_object)
        expect { json_file_parser }.to raise_error(RuntimeError)
          .with_message(/nvalid JSON in file.* .*some_file.* .*unexpected token/)
      end
    end
    shared_examples 'missing key' do
      it 'should raise a runtime error' do
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(/some_file.json/).and_return(files_like_object)
        expect { json_file_parser }.to raise_error(RuntimeError)
          .with_message(/missing.*key.*in file.*some_file/)
      end
    end

    shared_examples 'a directory of files' do
      it 'find the files and do stuff properly' do
        allow(File).to receive(:directory?).and_call_original
        allow(File).to receive(:directory?).with('some_dir').and_return(true)
        allow(Dir).to receive(:entries).and_call_original
        allow(Dir).to receive(:entries).with('some_dir').and_return(dir_like_object)
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(/some_file.json/).and_return([''])
        allow(File).to receive(:open).with(/some_other.json/).and_return([''])
        expect { json_file_parser }.to raise_error(RuntimeError)
          .with_message(/nvalid JSON in file.* .*some_file.* .*unexpected token/)
      end
    end
    shared_examples 'too many splits' do
      it 'should error helpfully' do
        allow(File).to receive(:open).and_call_original
        allow(File).to receive(:open).with(/some_file.json/).and_return(files_like_object)
        expect { json_file_parser.generate_new_line_delimited_json_files('somedir', number_of_files_to_generate) }.to raise_error(RuntimeError)
          .with_message(/too few runs to split: #{number_of_files_to_generate} files/)
      end
    end

    context 'single file' do
      context 'single pre-suite test' do
        it_behaves_like 'found file' do
          let(:files_like_object) { StringIO.new('{"_index":"acceptance-2017.06.28","_type":"qaelk","_id":"AVzvCqqHXp-Ctj2bRDfA","_score":1,"_source":{"type":"qaelk","jenkins_build_url":"https://jenkins-master-prod-1.delivery.puppetlabs.net/job/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a/4/","command_line":"/tmp/jenkins/workspace/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL/beaker/TEST_TARGET/fedora24-64a/puppet/acceptance/.bundle/gems/ruby/2.3.0/bin/beaker --options-file merged_options.rb --hosts hosts.yaml","start_time":"2017-06-28 12:16:49 +0000","beaker_version":"3.14.0","pre_suite_timestamp":"2017-06-28 12:16:49 +0000","job_config":"SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a","job_name":"platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x","job_id":4,"configs":{"SLAVE_LABEL":"beaker","TEST_TARGET":"fedora24-64a"},"pre_suite_time":125.752715,"tests_timestamp":"2017-06-28 12:16:49 +0000","tests_time":4427.979734,"@timestamp":"2017-06-28T12:16:49.000Z","@version":"1","test_case_classname":"setup/common/pre-suite","test_case_name":"000-delete-puppet-when-none.rb","test_case_time":0.000938,"test_case_status":"pass","test_case_suite":"pre_suite","tags":["_elasticsearch_lookup_failure"],"flaky":0}}') }
          let(:output_contents) { '{"test_run":{"execution_id":"https://jenkins-master-prod-1.delivery.puppetlabs.net/job/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a/4/","project":"platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x","duration":4553.732448999999,"configuration":["SLAVE_LABEL=beaker","TEST_TARGET=fedora24-64a"],"start_time":"2017-06-28 12:16:49 UTC","test_suites":[{"name":"pre_suite","duration":125.752715,"test_cases":[{"name":"000-delete-puppet-when-none.rb","duration":0.000938,"status":"pass"}]}]}}' }
          let(:number_of_files_to_generate) { 1 }
          let(:json_file_parser) { described_class.new('some_file.json') }
        end
      end

      context 'single test test' do
        it_behaves_like 'found file' do
          let(:files_like_object) { StringIO.new('{"_index":"acceptance-2017.06.28","_type":"qaelk","_id":"AVzvCqqHXp-Ctj2bRDfH","_score":1,"_source":{"type":"qaelk","jenkins_build_url":"https://jenkins-master-prod-1.delivery.puppetlabs.net/job/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a/4/","command_line":"/tmp/jenkins/workspace/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL/beaker/TEST_TARGET/fedora24-64a/puppet/acceptance/.bundle/gems/ruby/2.3.0/bin/beaker --options-file merged_options.rb --hosts hosts.yaml","start_time":"2017-06-28 12:16:49 +0000","beaker_version":"3.14.0","pre_suite_timestamp":"2017-06-28 12:16:49 +0000","job_config":"SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a","job_name":"platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x","job_id":4,"configs":{"SLAVE_LABEL":"beaker","TEST_TARGET":"fedora24-64a"},"pre_suite_time":125.752715,"tests_timestamp":"2017-06-28 12:16:49 +0000","tests_time":4427.979734,"@timestamp":"2017-06-28T12:16:49.000Z","@version":"1","test_case_classname":"tests","test_case_name":"allow_arbitrary_node_name_fact_for_agent.rb","test_case_time":20.735541,"test_case_status":"pass","test_case_suite":"tests","tags":["_elasticsearch_lookup_failure"],"flaky":0}}') }
          let(:output_contents) { '{"test_run":{"execution_id":"https://jenkins-master-prod-1.delivery.puppetlabs.net/job/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a/4/","project":"platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x","duration":4553.732448999999,"configuration":["SLAVE_LABEL=beaker","TEST_TARGET=fedora24-64a"],"start_time":"2017-06-28 12:16:49 UTC","test_suites":[{"name":"tests","duration":4427.979734,"test_cases":[{"name":"allow_arbitrary_node_name_fact_for_agent.rb","duration":20.735541,"status":"pass"}]}]}}' }
          let(:number_of_files_to_generate) { 1 }
          let(:json_file_parser) { described_class.new('some_file.json') }
        end
      end

      context 'pre-suite and tests' do
        it_behaves_like 'found file' do
          let(:files_like_object) do
            StringIO.new('{"_index":"acceptance-2017.06.28","_type":"qaelk","_id":"AVzvCqqHXp-Ctj2bRDfG","_score":1,"_source":{"type":"qaelk","jenkins_build_url":"https://jenkins-master-prod-1.delivery.puppetlabs.net/job/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a/4/","command_line":"/tmp/jenkins/workspace/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL/beaker/TEST_TARGET/fedora24-64a/puppet/acceptance/.bundle/gems/ruby/2.3.0/bin/beaker --options-file merged_options.rb --hosts hosts.yaml","start_time":"2017-06-28 12:16:49 +0000","beaker_version":"3.14.0","pre_suite_timestamp":"2017-06-28 12:16:49 +0000","job_config":"SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a","job_name":"platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x","job_id":4,"configs":{"SLAVE_LABEL":"beaker","TEST_TARGET":"fedora24-64a"},"pre_suite_time":125.752715,"tests_timestamp":"2017-06-28 12:16:49 +0000","tests_time":4427.979734,"@timestamp":"2017-06-28T12:16:49.000Z","@version":"1","test_case_classname":"setup/aio/pre-suite","test_case_name":"045_EnsureMasterStarted.rb","test_case_time":34.932252,"test_case_status":"pass","test_case_suite":"pre_suite","tags":["_elasticsearch_lookup_failure"],"flaky":0}}
{"_index":"acceptance-2017.06.28","_type":"qaelk","_id":"AVzvCqqHXp-Ctj2bRDfH","_score":1,"_source":{"type":"qaelk","jenkins_build_url":"https://jenkins-master-prod-1.delivery.puppetlabs.net/job/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a/4/","command_line":"/tmp/jenkins/workspace/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL/beaker/TEST_TARGET/fedora24-64a/puppet/acceptance/.bundle/gems/ruby/2.3.0/bin/beaker --options-file merged_options.rb --hosts hosts.yaml","start_time":"2017-06-28 12:16:49 +0000","beaker_version":"3.14.0","pre_suite_timestamp":"2017-06-28 12:16:49 +0000","job_config":"SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a","job_name":"platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x","job_id":4,"configs":{"SLAVE_LABEL":"beaker","TEST_TARGET":"fedora24-64a"},"pre_suite_time":125.752715,"tests_timestamp":"2017-06-28 12:16:49 +0000","tests_time":4427.979734,"@timestamp":"2017-06-28T12:16:49.000Z","@version":"1","test_case_classname":"tests","test_case_name":"allow_arbitrary_node_name_fact_for_agent.rb","test_case_time":20.735541,"test_case_status":"pass","test_case_suite":"tests","tags":["_elasticsearch_lookup_failure"],"flaky":0}}
{"_index":"acceptance-2017.06.28","_type":"qaelk","_id":"AVzvCqqHXp-Ctj2bRDfI","_score":1,"_source":{"type":"qaelk","jenkins_build_url":"https://jenkins-master-prod-1.delivery.puppetlabs.net/job/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a/4/","command_line":"/tmp/jenkins/workspace/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL/beaker/TEST_TARGET/fedora24-64a/puppet/acceptance/.bundle/gems/ruby/2.3.0/bin/beaker --options-file merged_options.rb --hosts hosts.yaml","start_time":"2017-06-28 12:16:49 +0000","beaker_version":"3.14.0","pre_suite_timestamp":"2017-06-28 12:16:49 +0000","job_config":"SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a","job_name":"platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x","job_id":4,"configs":{"SLAVE_LABEL":"beaker","TEST_TARGET":"fedora24-64a"},"pre_suite_time":125.752715,"tests_timestamp":"2017-06-28 12:16:49 +0000","tests_time":4427.979734,"@timestamp":"2017-06-28T12:16:49.000Z","@version":"1","test_case_classname":"tests","test_case_name":"allow_arbitrary_node_name_fact_for_apply.rb","test_case_time":1.737995,"test_case_status":"pass","test_case_suite":"tests","tags":["_elasticsearch_lookup_failure"],"flaky":0}}')
          end
          let(:output_contents) { '{"test_run":{"execution_id":"https://jenkins-master-prod-1.delivery.puppetlabs.net/job/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a/4/","project":"platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x","duration":4553.732448999999,"configuration":["SLAVE_LABEL=beaker","TEST_TARGET=fedora24-64a"],"start_time":"2017-06-28 12:16:49 UTC","test_suites":[{"name":"pre_suite","duration":125.752715,"test_cases":[{"name":"045_EnsureMasterStarted.rb","duration":34.932252,"status":"pass"}]},{"name":"tests","duration":4427.979734,"test_cases":[{"name":"allow_arbitrary_node_name_fact_for_agent.rb","duration":20.735541,"status":"pass"},{"name":"allow_arbitrary_node_name_fact_for_apply.rb","duration":1.737995,"status":"pass"}]}]}}' }
          let(:number_of_files_to_generate) { 1 }
          let(:json_file_parser) { described_class.new('some_file.json') }
        end
      end
      it_behaves_like 'too many splits' do
        let(:files_like_object) { StringIO.new('{"_index":"acceptance-2017.06.28","_type":"qaelk","_id":"AVzvCqqHXp-Ctj2bRDfH","_score":1,"_source":{"type":"qaelk","jenkins_build_url":"https://jenkins-master-prod-1.delivery.puppetlabs.net/job/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a/4/","command_line":"/tmp/jenkins/workspace/platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x/SLAVE_LABEL/beaker/TEST_TARGET/fedora24-64a/puppet/acceptance/.bundle/gems/ruby/2.3.0/bin/beaker --options-file merged_options.rb --hosts hosts.yaml","start_time":"2017-06-28 12:16:49 +0000","beaker_version":"3.14.0","pre_suite_timestamp":"2017-06-28 12:16:49 +0000","job_config":"SLAVE_LABEL=beaker,TEST_TARGET=fedora24-64a","job_name":"platform_puppet-agent_intn-van-sys_suite-daily-puppet-5.0.x","job_id":4,"configs":{"SLAVE_LABEL":"beaker","TEST_TARGET":"fedora24-64a"},"pre_suite_time":125.752715,"tests_timestamp":"2017-06-28 12:16:49 +0000","tests_time":4427.979734,"@timestamp":"2017-06-28T12:16:49.000Z","@version":"1","test_case_classname":"tests","test_case_name":"allow_arbitrary_node_name_fact_for_agent.rb","test_case_time":20.735541,"test_case_status":"pass","test_case_suite":"tests","tags":["_elasticsearch_lookup_failure"],"flaky":0}}') }
        let(:number_of_files_to_generate) { 2 }
        let(:json_file_parser) { described_class.new('some_file.json') }
      end

      it_behaves_like 'missing file' do
        let(:json_file_parser) { described_class.new('some_missing_file.json') }
      end
      it_behaves_like 'missing file' do
        let(:json_file_parser) { described_class.new('some_dir/some_missing_file.json') }
      end
      it_behaves_like 'invalid json' do
        # dunno why this can't be a stringIO object?
        # an array causes negative test case to pass for valid reasons, i think
        let(:files_like_object) { [''] }
        let(:json_file_parser) { described_class.new('some_file.json') }
      end
      it_behaves_like 'missing key' do
        let(:files_like_object) { StringIO.new('{}') }
        let(:json_file_parser) { described_class.new('some_file.json') }
      end
      it_behaves_like 'missing key' do
        let(:files_like_object) { StringIO.new('{"_source": "blah"}') }
        let(:json_file_parser) { described_class.new('some_file.json') }
      end
    end
    context 'single dir' do
      it_behaves_like 'missing file' do
        let(:json_file_parser) { described_class.new('some_missing_dir/') }
      end
      it_behaves_like 'a directory of files' do
        let(:dir_like_object) { ['.', '..', 'some_file.json', 'some_other.json'] }
        let(:json_file_parser) { described_class.new('some_dir') }
      end
    end
  end
end
