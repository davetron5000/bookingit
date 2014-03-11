require 'gli'
module Bookingit
  class UnexpectedShellCommandExit < StandardError
    include GLI::StandardException
    attr_reader :command, :stdout, :stderr
    def initialize(command,stdout,stderr)
      @command = command
      @stdout = stdout
      @stderr = stderr
    end

    def exit_code
      126
    end
  end
end
