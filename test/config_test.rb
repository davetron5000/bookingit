require 'test_helper'
require 'tempfile'
require 'fileutils'
require 'json'

class Bookingit::ConfigTest < Test::Unit::TestCase

  def setup
    @tempdir = Dir.mktmpdir
  end

  def teardown
    remove_entry @tempdir
  end

  test_that "wraps single files in arrays" do
    Given :some_markdown_files
    And {
      @config = {
        title: "blah town",
        subtitle: "the town of blah",
        whatever: "foobar",
        authors: [
          "Shane Vendrel",
          "Ronnie Gardocki",
        ],
        front_matter: "foo.md",
        main_matter: "bar.md",
        back_matter: "baz.md",
      }
    }
    When {
      @normalized_config = Bookingit::Config.new(@config.to_json,@tempdir)
    }
    Then {
      assert_equal @config[:title], @normalized_config.options['title']
      assert_equal @config[:subtitle], @normalized_config.options['subtitle']
      assert_equal @config[:whatever], @normalized_config.options['whatever']
      assert_equal @config[:authors], @normalized_config.options['authors']
      assert_equal 1,@normalized_config.front_matter.chapters.size
      assert_equal File.join(@tempdir,'foo.md'),@normalized_config.front_matter.chapters[0].markdown_path
      assert_equal 1,@normalized_config.main_matter.chapters.size
      assert_equal File.join(@tempdir,'bar.md'),@normalized_config.main_matter.chapters[0].markdown_path
      assert_equal 1,@normalized_config.back_matter.chapters.size
      assert_equal File.join(@tempdir,'baz.md'),@normalized_config.back_matter.chapters[0].markdown_path
    }
  end

  test_that "does nothing to arrays" do
    Given :some_markdown_files
    And {
      @config = {
        front_matter: ["foo.md"],
        main_matter: ["bar.md"],
        back_matter: ["baz.md"],
      }
    }
    When {
      @normalized_config = Bookingit::Config.new(@config.to_json,@tempdir)
    }
    Then {
      assert_equal 1,@normalized_config.front_matter.chapters.size
      assert_equal File.join(@tempdir,'foo.md'),@normalized_config.front_matter.chapters[0].markdown_path
      assert_equal 1,@normalized_config.main_matter.chapters.size
      assert_equal File.join(@tempdir,'bar.md'),@normalized_config.main_matter.chapters[0].markdown_path
      assert_equal 1,@normalized_config.back_matter.chapters.size
      assert_equal File.join(@tempdir,'baz.md'),@normalized_config.back_matter.chapters[0].markdown_path
    }
  end

  test_that "converts rendering config" do
    Given {
      @config = {
        rendering: {
          stylesheets: 'blah.css',
          languages: {
            ".coffee" => "coffeescript",
            "/^Bowerfile$/" => "ruby",
          },
          git_repos_basedir: "/tmp",
          syntax_theme: "solarized",
        }
      }
    }
    When {
      @normalized_config = Bookingit::Config.new(@config.to_json,@tempdir)
    }
    Then  {
      assert_equal "/tmp",@normalized_config.rendering_config[:basedir]
      assert_equal({ ".coffee" => "coffeescript", /^Bowerfile$/ => "ruby" },@normalized_config.rendering_config[:languages])
      assert_equal ['blah.css'],@normalized_config.rendering_config[:stylesheets]
      assert_equal 'solarized',@normalized_config.rendering_config[:theme]
      refute @normalized_config.cache
    }
  end

  test_that "we can mutate the config" do
    Given {
      @config = {
        rendering: {
          stylesheets: 'blah.css',
          syntax_theme: "solarized",
        }
      }
    }
    When {
      @normalized_config = Bookingit::Config.new(@config.to_json,@tempdir)
      @normalized_config.cache = true
    }
    Then  {
      assert @normalized_config.cache
    }
  end

private

  def some_markdown_files
    chdir @tempdir do
      system "touch foo.md"
      system "touch baz.md"
      system "touch bar.md"
      system "touch blah1.md"
      system "touch blah2.md"
      system "touch blah3.md"
    end
  end
end
