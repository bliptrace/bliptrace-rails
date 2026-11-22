# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  # The runtime g8scope gem lives in a sibling repo during development; place it
  # on the load path so the suite runs without bundler or an installed gem.
  t.libs << "../bliptrace-ruby/lib"
  t.libs << "lib"
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

task default: :test
