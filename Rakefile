require 'rake/testtask'

ENV['LOG_LEVEL'] ||= 'error'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.pattern = 'test/test_*.rb'
  t.verbose = true
  t.warning = false
end

task default: :test