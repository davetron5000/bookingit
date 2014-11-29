require 'fileutils'
require 'open3'

module Bookingit
  class ShellCommand
    include FileUtils

    attr_reader :stdout, :stderr, :exit_code, :command, :expected_exit_status

    def initialize(command: nil,path: '.',expected_exit_status: 0, &block)
      @command = command
      @path = path
      @exit_status_checker = if block.nil?
                               ->(exit_code) { exit_code == expected_exit_status }
                             else
                               block
                             end
    end

    def run!
      chdir @path do
        bash_script = <<SCRIPT
# Ensure that RVM is properly loaded in the new subshell
source "$HOME/.rvm/scripts/rvm"
unset BUNDLE_GEMFILE

# Tell RVM to use the gemset defined in .ruby-gemset and .ruby-version (e.g. : 2.1.0@receta)
# and to set up environment variables within the new subshell.  This call to 'rvm use'
# is necessary to avoid inheriting RVM environment variables from the calling shell
# (e.g. 2.1.0@angular-rails-book)
rvm use . > /dev/null 2>&1

#{@command}
SCRIPT

        @stdout, @stderr, status = Open3.capture3("bash", stdin_data: bash_script)
        @exit_code = status.exitstatus
      end
      unless @exit_status_checker.(@exit_code)
        raise UnexpectedShellCommandExit.new(@command,@stdout,@stderr)
      end
    end
  end
end
