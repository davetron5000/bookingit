require 'tempfile'
require 'fileutils'

When /^I get help for "([^"]*)"$/ do |app_name|
  @app_name = app_name
  step %(I run `#{app_name} help`)
end

Given(/^the file "(.*?)" contains:$/) do |filename, contents|
  FileUtils.chdir "tmp/aruba" do
    @files_created << filename
    File.open(filename,'w') do |file|
      file.puts contents
    end
  end
end

Given(/^this config file:$/) do |string|
  FileUtils.chdir "tmp/aruba" do
    @files_created << "config.json"
    File.open("config.json",'w') do |file|
      file.puts string
    end
  end
end

