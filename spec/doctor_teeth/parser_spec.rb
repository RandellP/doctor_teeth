# frozen_string_literal: true

require 'spec_helper'

# FIXME
# rubocop:disable Metrics/ModuleLength
module DoctorTeeth
  # FIXME
  # rubocop:disable Metrics/BlockLength
  # rubocop:disable Metrics/LineLength
  describe Parser do
    shared_examples 'minimal file' do
      it 'should not raise error when file found and empty configuration sent' do
        # stub File.open
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(/some_file.xml/)
                                     .and_return(files_like_object)
        expect do
          described_class.new('some_file.xml',
                              configuration: {})
        end
          .to_not raise_error
      end

      it 'should find test_run fields with no option parameters sent' do
        # stub File.open
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(/some_file.xml/)
                                     .and_return(files_like_object)
        test_run = described_class
                   .new('some_file.xml', configuration: {})
                   .instance_variable_get(:@test_run)['test_run']
        expect(test_run['project']).to be_nil
        expect(test_run['duration']).to eq(0.010325)
        expect(test_run['configuration']).to eq([])
        expect(test_run['start_time']).to eq(Time.parse('2016-08-01 23:09:46 UTC'))
        expect(test_run['execution_id']).to be_nil
        pre_suite = test_run['test_suites'][0]
        expect(pre_suite['name']).to eq('pre_suite')
        expect(pre_suite['duration']).to eq(0.010325)
        expect(pre_suite['test_count']).to eq(2)
        test_case1 = pre_suite['test_cases'][0]
        expect(test_case1['name']).to eq('01_install_rototiller.rb')
        expect(test_case1['duration']).to eq(0.009558)
        expect(test_case1['status']).to eq('error')
        expect(test_case1['system_out'])
          .to match(%r{acceptance\/pre-suite.*cannot infer basepath.*End teardown}m)
      end

      it 'should find test_run fields with option parameters sent' do
        # stub File.open
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(/some_file.xml/)
                                     .and_return(files_like_object)
        config = { 'LAYOUT' => 'default',
                   'LDAP_TYPE' => 'default',
                   'PLATFORM' => 'default',
                   'SAUCE' => 'default',
                   'label' => 'beaker' }
        test_run = described_class
                   .new('some_file.xml', configuration: config, project: 'myproj', execution_id: 42_424_242)
                   .instance_variable_get(:@test_run)['test_run']

        expect(test_run['project']).to eq('myproj')
        expect(test_run['duration']).to eq(0.010325)
        expect(test_run['configuration']).to eq(['LAYOUT=default',
                                                 'LDAP_TYPE=default',
                                                 'PLATFORM=default',
                                                 'SAUCE=default',
                                                 'label=beaker'])
        expect(test_run['start_time']).to eq(Time.parse('2016-08-01 23:09:46 UTC'))
        expect(test_run['execution_id']).to eq(42_424_242)
        pre_suite = test_run['test_suites'][0]
        expect(pre_suite['name']).to eq('pre_suite')
        expect(pre_suite['duration']).to eq(0.010325)
        expect(pre_suite['test_count']).to eq(2)
        test_case1 = pre_suite['test_cases'][0]
        expect(test_case1['name']).to eq('01_install_rototiller.rb')
        expect(test_case1['duration']).to eq(0.009558)
        expect(test_case1['status']).to eq('error')
        expect(test_case1['system_out'])
          .to match(%r{acceptance\/pre-suite.*cannot infer basepath.*End teardown}m)
      end
    end

    shared_examples 'complete file' do
      it 'should not raise error when file found and empty configuration sent' do
        # stub File.open
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(/some_file.xml/)
                                     .and_return(files_like_object)
        expect do
          described_class.new('some_file.xml',
                              configuration: {})
        end
          .to_not raise_error
      end

      it 'should find test_run fields with no option parameters sent' do
        # stub File.open
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(/some_file.xml/)
                                     .and_return(files_like_object)
        test_run = described_class
                   .new('some_file.xml', configuration: {})
                   .instance_variable_get(:@test_run)['test_run']

        tests = test_run['test_suites'][1]
        test_case1 = tests['test_cases'][0]
        expect(test_case1['name']).to eq('command_arguments_with_override.rb')
        expect(test_case1['duration']).to eq(0.567921)
        expect(test_case1['status']).to eq('pass')
        expect(test_case1['system_out']).to be_nil

        test_case2 = tests['test_cases'][1]
        expect(test_case2['status']).to eq('fail')
        expect(test_case2['system_out'])
          .to match(%r{minitest/assertions.rb:129:in.*be loaded}m)

        test_case3 = tests['test_cases'][2]
        expect(test_case3['status']).to eq('skip')
        expect(test_case3['system_out']).to be_nil

        test_case4 = tests['test_cases'][3]
        expect(test_case4['status']).to eq('pending')
        expect(test_case4['system_out']).to be_nil
      end
    end

    it_behaves_like 'minimal file' do
      let(:files_like_object) { File.read('spec/fixtures/beaker_junit_02.xml') }
    end

    it_behaves_like 'complete file' do
      let(:files_like_object) { File.read('spec/fixtures/beaker_junit_03.xml') }
    end

    context 'missing file' do
      it 'should error when file not found' do
        expect do
          expect { described_class.new('some_file_missing.xml') }
            .to output('No such file or directory').to_stderr
        end.to raise_error(SystemExit)
      end
    end
  end # describe Parser
end
