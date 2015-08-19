require 'rake/testtask'

Rake::TestTask.new do |t|
    t.pattern = "test/test_*.rb"
end

task :build => :test do
  sh "gem build tempest.gemspec"
end
