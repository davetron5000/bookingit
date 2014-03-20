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
        @stdout, @stderr, status = Open3.capture3(@command)
        @exit_code = status.exitstatus
      end
      unless @exit_status_checker.(@exit_code)
        raise UnexpectedShellCommandExit.new(@command,@stdout,@stderr)
      end
    end
  end
end
