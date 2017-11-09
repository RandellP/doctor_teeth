# frozen_string_literal: true

require 'nokogiri'
require 'json'
require 'time'
module DoctorTeeth
  # A json file parser that takes extra metadata from a test_suite/case
  #   metadata that is not always in junit.xml
  # @since v0.0.1
  # @attr [String] test_runs holds the extra test_run data
  # FIXME
  # rubocop:disable Metrics/ClassLength
  class NewLineJsonFileParser
    attr_accessor :test_runs

    # FIXME
    # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize
    def initialize(file)
      json_files = []
      @test_runs = {}

      if File.directory?(file)
        json_files = Dir.entries(file)
        json_files.delete_if { |f| f.chars.first == '.' }
        json_files.map! { |f| File.join(file, f) }

      else
        json_files.push(File.expand_path(file))
      end

      file_count = json_files.length
      puts "Attempting to process #{file_count} json files"
      # FIXME
      # rubocop:disable Metrics/BlockLength
      json_files.each do |json|
        # totally unclear what this is doing
        #   counting chars?  allocating buffer?
        output_char = (file_count % 50).zero? ? ".\n" : '.'

        File.open(json).each do |line|
          # TODO: fix dirty data
          begin
            json_object = JSON.parse(line)
          rescue JSON::ParserError => e
            raise "invalid JSON in file '#{json}': #{e}"
          end
          # translate elasticsearch record to QALEK2 schema

          # TODO: use single instance var, don't pass to other method
          unless json_object['_source']
            raise "missing '_source' key in file '#{json}'"
          end
          %w[jenkins_build_url
             job_name
             start_time
             test_case_suite
             test_case_name
             test_case_status
             test_case_time
             pre_suite_time
             tests_time
             configs].each do |field|
            unless json_object['_source'][field]
              raise "missing #{field} key in '_source' field in file '#{json}'"
            end
          end
          execution_id = json_object['_source']['jenkins_build_url']
          project = json_object['_source']['job_name']
          configuration = []
          start_time = json_object['_source']['start_time']
          suite_name = json_object['_source']['test_case_suite']
          suite_duration = json_object['_source']["#{suite_name}_time"]
          test_name = json_object['_source']['test_case_name']
          test_status = json_object['_source']['test_case_status']
          test_duration = json_object['_source']['test_case_time']

          # configuration experiment
          conf = json_object['_source']['configs']
          conf.each { |k, v| configuration.push("#{k}=#{v}") } if conf

          @test_record = {
            'execution_id' => execution_id,
            # TODO: need to find a better way to translate project name
            'project'         => project,
            # 'duration'        => json_object['_source'][],
            'configuration'   => configuration,
            'start_time'      => (Time.parse(start_time).utc if start_time),
            'suite_name'      => suite_name,

            # need to look up which suite this is
            'suite_duration'  => suite_duration,
            'test_name'       => test_name,
            'test_status'     => test_status,
            'test_duration'   => test_duration
          }

          # add up test_run duration, values could be nil
          suite_durations = [json_object['_source']['pre_suite_time'],
                             json_object['_source']['tests_time']].compact
          @test_record['duration'] = suite_durations.inject(:+)

          # do the thing
          insert_record(@test_record)
        end

        print output_char
        file_count += -1
      end
    end

    # inserts a record into something or other. big query?
    # @since v0.0.1
    # private
    def insert_record(test_record = {})
      id            = test_record['execution_id']
      project       = test_record['project']
      duration      = test_record['duration']
      configuration = test_record['configuration']
      start_time    = test_record['start_time']

      # suite properties
      suite_name    = test_record['suite_name']
      suite_duration = test_record['suite_duration']

      # test cae properties
      test_name     = test_record['test_name']
      test_status   = test_record['test_status']
      test_duration = test_record['test_duration']

      # set keys conditionally one at a time
      @test_runs[id]                  ||= { 'execution_id' => id }
      @test_runs[id]['project']       ||= project
      @test_runs[id]['duration']      ||= duration
      @test_runs[id]['configuration'] ||= configuration
      @test_runs[id]['start_time']    ||= start_time
      @test_runs[id]['test_suites']   ||= []

      test_case  = { 'name' => test_name,
                     'duration' => test_duration,
                     'status' => test_status }
      test_suite = { 'name' => suite_name,
                     'duration' => suite_duration,
                     'test_cases' => [test_case] }

      if @test_runs[id]['test_suites'].empty?

        # create the first
        @test_runs[id]['test_suites'].push(test_suite)
      # does suite exist?
      elsif @test_runs[id]['test_suites']
            .any? { |suite| suite['name'] == suite_name }
        @test_runs[id]['test_suites'].each do |suite|
          next unless suite['name'] == suite_name
          # create empty test_cases array if it does not exist
          suite['test_cases'] ||= []
          # check if this is a duplicate record
          raise 'CRAP! DUPLICATE RECORD!' if suite['test_cases']
                                             .any? { |test| test == test_name }
          # add test case
          suite['test_cases'].push(test_case)
        end
      else
        # create the suite with test_case inside
        @test_runs[id]['test_suites'].push(test_suite)
      end
    end
    private :insert_record

    # make a single file
    def generate_new_line_delimited_json_file(file)
      line_count = @test_runs.length
      puts "\nAttempting to write #{line_count} json objects to #{file}"
      File.open(file, 'w') do |f|
        @test_runs.each do |_k, v|
          output_char = (line_count % 50).zero? ? ".\n" : '.'
          print output_char

          f.write(JSON.generate('test_run' => v))
          f.write("\n")

          line_count += -1
        end
      end
    end

    # for breaking down into smaller files
    def generate_new_line_delimited_json_files(dir, number_of_desired_files)
      line_count = @test_runs.length
      puts "\nAttempting to write #{line_count} json objects " \
        "to files in the directory #{dir}"

      slice_count = 0
      raise "too few runs to split: #{number_of_desired_files} files" unless
      @test_runs.length >= number_of_desired_files
      @test_runs.each_slice(@test_runs.length /
                            number_of_desired_files) do |slice|
        slice_count += 1

        File.open("#{dir}/file#{slice_count}", 'w') do |f|
          slice.each do |_k, v|
            output_char = (line_count % 50).zero? ? ".\n" : '.'
            print output_char

            f.write(JSON.generate('test_run' => v))
            f.write("\n")

            line_count += -1
          end
        end
      end
    end
  end
end
