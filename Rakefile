require 'rake/testtask'

Rake::TestTask.new do |t|
    t.pattern = "test/test_*.rb"
end

task :build => :syntax_check do
  sh "gem build tempest.gemspec"
end
