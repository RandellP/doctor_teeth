# frozen_string_literal: true

require 'nokogiri'
module DoctorTeeth
  # a Parser type to load and parse xml into test_suites and cases
  # @todo: uncouple loading from parsing
  # @todo: uncouple parsing from storing suites/cases?
  # @since v0.0.1
  # @attr [String] test_run Holds test_run info from the xml, don't write this.
  class Parser
    attr_accessor :test_run

    def initialize(xml, opts = {})
      begin
        xml_read = File.read(xml)
      rescue Errno::ENOENT => e
        $stderr.puts "ERROR: #{e}"
        exit 1
      end
      @xml = Nokogiri::XML(xml_read)
      # TODO: validate initial opts
      @test_run = extract_test_run(opts[:project],
                                   opts[:configuration], opts[:execution_id])
    end

    private

    # TODO: we probably need a class for run, suite, case, etc
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def extract_test_run(project, configuration, execution_id)
      start_time = nil
      @xml.xpath('//testsuites//properties//property').each do |property|
        # do not know if this is part of the junit.xml
        name = property.attributes['name'].value
        next unless name == 'timestamp'
        # BigQuery doesn't like the timezone,
        #   providing it in UTC formats it correctly
        start_time = Time.parse(property.attributes['value'].value).utc
        break
      end

      # TODO
      # update the way that we deal with configuration to match what is done
      # when we convert elasticsearch data to the BigQuery schema
      # we are assuming that the configuration is provided in a hash

      # TODO: allow extra stuff in xml like beaker?

      conf = []
      configuration.each { |k, v| conf.push("#{k}=#{v}") }

      run = {
        'test_run' => {
          'project' => project,
          'duration'      => 0.0, # total duration of all contained test suites
          'configuration' => conf,
          'start_time'    => start_time,
          'execution_id'  => execution_id,
          'test_suites'   => extract_test_suites

        }
      }
      # calculate duration for test_run
      # @todo: whoa this is probably wrong in some cases
      run['test_run']['test_suites'].each do |suite|
        run['test_run']['duration'] += suite['duration']
      end
      run
    end

    # FIXME
    def extract_test_suites
      test_suites = []

      suites = @xml.xpath('//testsuites//testsuite')
      suites.each do |suite|
        name = suite.attributes['name'].value
        duration = suite.attributes['time'].value.to_f
        test_count = suite.attributes['total'].value.to_i
        test_cases = extract_test_cases(suite)
        test_suites.push('name' => name, 'duration' => duration,
                         'test_count' => test_count, 'test_cases' => test_cases)
      end

      test_suites
    end

    # FIXME
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/CyclomaticComplexity
    def extract_test_cases(test_suite)
      test_cases = []

      # FIXME
      # rubocop:disable Metrics/BlockLength
      test_suite.children.each do |tc|
        next unless tc.name == 'testcase'
        test_case = {}
        test_case['name'] = tc.attributes['name'].value
        test_case['duration'] = tc.attributes['time'].value.to_f
        test_case['status'] = 'pass'

        # set status
        # TODO: ensure these status strings match current qaelk
        #   especially fail/skip
        tc.children.each do |child|
          n = child.name
          if n == 'failure'
            # this will set status to failure or error
            test_case['status'] = child.attributes['type'].value
          elsif n == 'skip'
            # this will set status to skipped or pending
            test_case['status'] = child.attributes['type'].value
          end
        end

        if %w[fail error].any? { |state| state == test_case['status'] }
          tc.children.each do |child|
            n = child.name
            # only capture system out if status of failure or error
            next unless n == 'system-out'
            tc.children.each do |c|
              if test_case['system_out']
                test_case['system_out'] << c.content
              else
                test_case['system_out'] = c.content
              end
            end
          end
        end

        test_cases.push(test_case)
      end

      test_cases
    end
  end
end
