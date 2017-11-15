# frozen_string_literal: true

require 'yard'
require 'rubocop/rake_task'

YARD_DIR = 'doc'.freeze
DOCS_DIR = 'docs'.freeze

task :default do
  sh %(rake -T)
end

namespace :gem do
  require 'bundler/gem_tasks'
end

task yard: :'docs:yard'
namespace :docs do
  # docs:yard task
  YARD::Rake::YardocTask.new

  desc 'Clean/remove the generated YARD Documentation cache'
  task :clean do
    original_dir = Dir.pwd
    Dir.chdir(File.expand_path(File.dirname(__FILE__)))
    sh "rm -rf #{YARD_DIR}"
    Dir.chdir(original_dir)
  end

  desc 'Tell me about YARD undocummented objects'
  YARD::Rake::YardocTask.new(:undoc) do |t|
    t.stats_options = ['--list-undoc']
  end

  desc 'Measure YARD coverage'
  require 'yardstick/rake/measurement'
  Yardstick::Rake::Measurement.new(:measure) do |measurement|
      measurement.output = 'yardstick/report.txt'
  end

  desc 'Verify YARD coverage'
  require 'yardstick/rake/verify'
  Yardstick::Rake::Verify.new(:verify) do |verify|
    verify.threshold = 100
  end

  desc 'Generate static project architecture graph. (Calls docs:yard)'
  # this calls `yard graph` so we can't use the yardoc tasks like above
  #   We could create a YARD:CLI:Graph object.
  #   But we still have to send the output to the graphviz processor, etc.
  task arch: [:yard] do
    original_dir = Dir.pwd
    Dir.chdir(File.expand_path(File.dirname(__FILE__)))
    graph_processor = 'dot'
    if exe_exists?(graph_processor)
      FileUtils.mkdir_p(DOCS_DIR)
      if system("yard graph --full | #{graph_processor} -Tpng " \
          "-o #{DOCS_DIR}/arch_graph.png")
        puts "we made you a class diagram: #{DOCS_DIR}/arch_graph.png"
      end
    else
      puts 'ERROR: you don\'t have dot/graphviz; punting'
    end
    Dir.chdir(original_dir)
  end
end

namespace :test do
  RuboCop::RakeTask.new

  begin
    require 'rspec/core/rake_task'
    RSpec::Core::RakeTask.new(:spec)
    puts ENV['TRAVIS_JOB_ID']
  # if rspec isn't available, we can still use this Rakefile
  rescue LoadError
  end
end

# Cross-platform exe_exists?
def exe_exists?(name)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{name}#{ext}")
      return true if File.executable?(exe) && !File.directory?(exe)
    end
  end
  false
end
