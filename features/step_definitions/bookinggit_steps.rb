require 'tempfile'

When /^I get help for "([^"]*)"$/ do |app_name|
  @app_name = app_name
  step %(I run `#{app_name} help`)
end

Given(/^this Ruby source:$/) do |source|
  file = Tempfile.new(['foo','.rb'])
  @data[:ruby_source] = file.path
  File.open(file.path,'w') do |file|
    file.puts source
  end
end

Given(/^this markdown:$/) do |source|
  file = Tempfile.new(['foo','.markdown'])
  @data[:markdown] = file.path
  File.open(file.path,'w') do |file|
    file.puts source.gsub("%%PATH_TO_RUBY_FILE%%",@data[:ruby_source])
  end
end

Given(/^an output dir$/) do
  @data[:output_dir] = Dir.mktmpdir
end

When(/^I run "(.*?)" on the markdown pointed at the output dir$/) do |invocation|
  cmd = "#{invocation} #{@data[:markdown]} #{@data[:output_dir]}"
  puts ENV['PATH'].split(File::PATH_SEPARATOR).join("\n")
  step %(I run `#{cmd}`)
end

Then(/^the markdown file in the output dir should be$/) do |string|
  contents = File.read(File.join(@data[:output_dir],File.basename(@data[:markdown])))
  expect(contents).to eq(string)
end

