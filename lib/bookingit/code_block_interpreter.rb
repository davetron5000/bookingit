module Bookingit
  class CodeBlockInterpreter
    def initialize(code)
      @code = code.strip
      @ran = false
    end

    def when_file(&block)
      if @code =~ /^\s*file:\/\/(.*)$/
        @ran = true
        path = $1
        block.call(path)
      end
      self
    end

    def when_git_reference(&block)
      if @code =~ /^\s*git:\/\/(.*)$/
        path = $1
        if path =~ /(^.*).git\/(.*)#([^#]+)$/
          repo_path = $1
          path_in_repo = $2
          path_in_repo = '.' if String(path_in_repo).strip == ''
          reference = $3
          block.call(repo_path,path_in_repo,reference)
        else
          raise "You must provide a SHA1 or tagname: #{path}"
        end
      end
      self
    end

    def when_file_in_git(&block)
      when_git_reference do |repo_path,path_in_repo,reference|
        if reference !~ /^(.+)\.\.(.+)$/ && reference !~ /^(.+)\!(.+)$/ && reference !~ /^\.\.(.+)$/
          @ran = true
          chdir repo_path do
            block.call(path_in_repo,reference)
          end
        end
      end
      self
    end

    def when_git_diff(&block)
      when_git_reference do |repo_path,path_in_repo,reference|
        if reference =~ /^(.+)\.\.(.+)$/
          @ran = true
          chdir repo_path do
            block.call(path_in_repo,reference)
          end
        elsif reference =~ /^\.\.(.+)$/
          @ran = true
          tag_or_sha = $1
          chdir repo_path do
            block.call(path_in_repo,"#{tag_or_sha}^..#{tag_or_sha}")
          end
        end
      end
      self
    end

    def when_shell_command_in_git(&block)
      when_git_reference do |repo_path,path_in_repo,reference|
        if reference =~ /^([^!]+)\!(.+)$/
          reference = $1
          command,exit_type  = parse_shell_command($2)
          @ran = true
          chdir repo_path do
            block.call(reference,shell_command(path: path_in_repo,command: command, exit_type: exit_type))
          end
        end
      end
    end

    def when_shell_command(&block)
      if @code.strip =~ /^\s*sh:\/\/(.+)#([^#]+)$/
        @ran = true
        path = $1
        command,exit_type = parse_shell_command($2)
        block.call(shell_command(path: path,command: command, exit_type: exit_type))
      end
    end

    def otherwise(&block)
      block.call unless @ran
    end


  private

    def shell_command(path: nil, command: nil, exit_type: nil)
      ShellCommand.new(path: path,command: command) do |exit_status|
        case exit_type
        when :zero
          exit_status == 0
        when :nonzero
          exit_status != 0
        else
          raise "unknown exit type #{exit_type}"
        end
      end 
    end
  
    def parse_shell_command(shell_command)
      if shell_command =~ /(^.*)!([^!]+)$/
        [$1,$2.to_sym]
      else
        [shell_command,:zero]
      end
    end
  end
end
