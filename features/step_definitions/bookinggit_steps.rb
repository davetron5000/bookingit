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

Given(/^a git repo "(.*?)" in "(.*?)" containing the file "(.*?)" and a tag "(.*?)"$/) do |repo_name, repo_basedir, file_name, tag_name|
  FileUtils.chdir "tmp/aruba" do
    FileUtils.mkdir repo_basedir
    @dirs_created << repo_basedir
    FileUtils.chdir repo_basedir do
      FileUtils.mkdir repo_name
      FileUtils.chdir repo_name do
        File.open(file_name,'w') do |file|
          file.puts "Some stuff and whatnot"
        end
        system "git init"
        system "git add #{file_name}"
        system "git commit -m 'initial'"
        system "git tag #{tag_name}"
      end
    end
  end
end
