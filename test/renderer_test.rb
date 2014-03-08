require 'test_helper'
require 'tempfile'
require 'fileutils'

include FileUtils

class RendererTest < Test::Unit::TestCase

  def setup
    @tempdir = Dir.mktmpdir
  end

  def teardown
    remove_entry @tempdir
  end

  test_that "block_code can read a file URL and guess ruby" do
    Given a_file_with_extension(".rb") 
    When render_file_url_code_block
    Then {
      assert_equal %{<pre><code class="language-ruby">#{@code}</code></pre>},@html
    }
  end

  test_that "block_code can read a file URL and guess ruby from Gemfile" do
    Given a_file_named("Gemfile") 
    When render_file_url_code_block
    Then {
      assert_equal %{<pre><code class="language-ruby">#{@code}</code></pre>},@html
    }
  end

  test_that "block_code can read a file URL and be OK if it cannot guess" do
    Given a_file_with_extension(".blah") 
    When render_file_url_code_block
    Then {
      assert_equal %{<pre><code>#{@code}</code></pre>},@html
    }
  end

  test_that "we can tell the renderer about other languages and extensions" do
    Given a_file_with_extension(".blah") 
    When render_file_url_code_block([{ languages: { '.blah' => 'blahscript' }}])
    Then {
      assert_equal %{<pre><code class="language-blahscript">#{@code}</code></pre>},@html
    }
  end

  test_that "block_code can read a file URL and guess scala" do
    Given a_file_with_extension(".scala") 
    When render_file_url_code_block
    Then {
      assert_equal %{<pre><code class="language-scala">#{@code}</code></pre>},@html
    }
  end

  test_that "it HTML-escapes" do
    Given a_file_with_extension_and_contents('.html',%{<!DOCTYPE html>
<html>
  <body>
    <h1>HELLO!</h1>
    <h2>&amp; Goodbye</h2>
  </body>
</html>
})
    When render_file_url_code_block
    Then {
      assert_equal %{<pre><code class="language-html">&lt;!DOCTYPE html&gt;
&lt;html&gt;
  &lt;body&gt;
    &lt;h1&gt;HELLO!&lt;/h1&gt;
    &lt;h2&gt;&amp;amp; Goodbye&lt;/h2&gt;
  &lt;/body&gt;
&lt;/html&gt;
</code></pre>},@html
    }
  end

  test_that "a git url without a SHA1 or tag raises" do
    Given a_git_repo_with_file("foo.rb")
    When {
      @code = -> {
        Bookingit::Renderer.new.block_code(@file_git_url,nil)
      }
    }
    Then {
      assert_raises RuntimeError,&@code
    }
  end

  test_that "a git url with a SHA1 gets that version" do
    Given a_git_repo_with_two_verions_of_file("foo.rb")
    When {
      @parsed_versions = Hash[@versions.map { |sha1,_|
        [sha1, Bookingit::Renderer.new.block_code(@file_git_url + "##{sha1}",nil)]
      }]
    }
    Then {
      @parsed_versions.each do |sha1,code|
        assert_equal %{<pre><code class="language-ruby">#{@versions[sha1]}\n</code></pre>},code,"For SHA: #{sha1}"
      end
    }
  end

  test_that "a git url with a tag gets that version" do
    Given a_git_repo_with_two_tagged_verions_of_file("foo.rb")
    When {
      @parsed_versions = Hash[@versions.map { |tagname,_|
        [tagname, Bookingit::Renderer.new.block_code(@file_git_url + "##{tagname}",nil)]
      }]
    }
    Then {
      @parsed_versions.each do |tagname,code|
        assert_equal %{<pre><code class="language-ruby">#{@versions[tagname]}\n</code></pre>},code,"For Tag: #{tagname}"
      end
    }
  end

  test_that "a git url with a diff spec shows the diff instead" do
    Given a_git_repo_with_two_tagged_verions_of_file("foo.rb")
    When {
      url = @file_git_url + "#" + @versions.keys[0] + ".." + @versions.keys[1]
      @html = Bookingit::Renderer.new.block_code(url,nil)
    }
    Then {
      assert_match /<pre><code class=\"language-diff\">diff --git/,@html
      assert_match /a\/foo.rb b\/foo.rb/,@html
      assert_match /index [a-z0-9]+..[a-z0-9]+ 100644/,@html
      assert_match /\-\-\- a\/foo.rb/,@html
      assert_match /\+\+\+ b\/foo.rb/,@html
    }
  end

  test_that "a git url with a shell command runs that command on that version of the repo" do
    Given a_git_repo_with_two_tagged_verions_of_file("foo.rb")
    When {
      @version = @versions.keys[0]
      git_url = @file_git_url.gsub(/\/foo.rb/,'/')
      @html = Bookingit::Renderer.new.block_code("#{git_url}##{@version}!cat foo.rb",nil)
    }
    Then {
      assert_equal %{<pre><code class="language-shell">&gt; cat foo.rb\n#{@versions[@version]}\n</code></pre>},@html
    }
  end

  test_that "an sh url will run the given command and put the contents into the output" do
    Given {
      chdir @tempdir do
        mkdir "play"
        chdir "play" do
          system "touch blah"
          system "touch bar"
          system "touch quux"
        end
      end
    }
    When {
      @html = Bookingit::Renderer.new.block_code("sh://#{@tempdir}/play#ls -1",nil)
    }
    Then {
      assert_equal %{<pre><code class="language-shell">&gt; ls -1
bar
blah
quux
</code></pre>},@html
    }
  end

  test_that "we pass through inline code blocks" do
    When {
      @html = Bookingit::Renderer.new.block_code("class Foo", 'coffeescript')
    }
    Then {
      assert_equal %{<pre><code class="language-coffeescript">class Foo</code></pre>},@html
    }
  end

  test_that "we omit the language class if it's not provided in inline code" do
    When {
      @html = Bookingit::Renderer.new.block_code("class Foo", nil)
    }
    Then {
      assert_equal %{<pre><code>class Foo</code></pre>},@html
    }
  end

private

  def create_and_commit_file(file,contents)
    File.open(file,'w') do |file|
      file.puts contents
    end
    system "git add .  #{devnull}"
    system "git commit -m \"new file\" #{devnull}"
    `git rev-parse HEAD`.chomp
  end

  def a_git_repo_with_two_verions_of_file(file)
    -> {
      @versions = {}
      git_repo_in_tempdir do
        code = %{class Foo
  def initialize
  end
end}
        2.times {
          @versions[create_and_commit_file(file,code)] = code

          code = %{class Foo
  def initialize
    @added = true
  end
end}
        }
        create_and_commit_file(file,code)
        # make sure test doesn't get the HEAD version
      end
      @file_git_url = "git://#{File.join(@tempdir,'git_repo.git')}/#{file}"
    }
  end

  def a_git_repo_with_two_tagged_verions_of_file(file)
    -> {
      @versions = {}
      git_repo_in_tempdir do
        code = %{class Foo
  def initialize
  end
end}
        2.times { |index|
          create_and_commit_file(file,code)
          tag = "tag-#{index}"
          system "git tag #{tag} #{devnull}"

          @versions[tag] = code

          code = %{class Foo
  def initialize
    @added = true
  end
end}
        }
        create_and_commit_file(file,code)
        # make sure test doesn't get the HEAD version
      end
      @file_git_url = "git://#{File.join(@tempdir,'git_repo.git')}/#{file}"
    }
  end

  def git_repo_in_tempdir(&block)
    chdir @tempdir do
      mkdir 'git_repo'
      chdir 'git_repo' do
        system "git init #{devnull}"
        system "git add . #{devnull}"
        system "git commit -m \"initial commit\" #{devnull}"
        block.()
      end
    end
  end

  def a_git_repo_with_file(file)
    -> {
      git_repo_in_tempdir do
        @code = %{class Foo
  def initialize
  end
end}
        create_and_commit_file(file,@code)
      end
      @file_git_url = "git://#{File.join(@tempdir,'git_repo.git')}/#{file}"
    }
  end

  def render_file_url_code_block(constructor_args=[])
    -> {
      @html = Bookingit::Renderer.new(*constructor_args).block_code("file://#{@path}",nil)
    }
  end

  def a_file_named(filename)
    -> {
      @code = %{#{any_string}
}
      @path = File.join(@tempdir,filename)
      File.open(@path,'w') do |file|
        file.puts @code
      end
    }
  end

  def a_file_with_extension_and_contents(extension,contents)
    -> {
      file = Tempfile.new(['foo',extension])
      @path = file.path
      @code = contents
      File.open(@path,'w') do |file|
        file.puts @code
      end
    }
  end

  def a_file_with_extension(extension)
    a_file_with_extension_and_contents(extension,%{class SomeCode
  def initialize(ohyeah)
    @oh yeah = ohyeah
  end
end
})
  end

  def devnull
    return "" if ENV['DEBUG']
    " 2>&1 > /dev/null"
  end
end
