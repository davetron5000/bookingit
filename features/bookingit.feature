Feature: App does what it's supposed to do
  In order to build a kickass website
  I want to use bookingit to translate markdown
  and all that

  Scenario: App works
    Given the file "intro.md" contains:
    """
# My awesome book

This is the introduction
    """
    And a git repo "foobar" in "repos" containing the file "blah.rb" and a tag "some-tag"
    And the file "chapter1.md" contains:
    """
# It Begins

This is the beginning

```
sh:///# ls
```

And then

```
git://foobar.git/blah.rb#some-tag
```
    """
    And the file "chapter2.md" contains:
    """
# The continuation

This is how we work

## Some section

Some more stuff
    """
    And the file "chapter3.md" contains:
    """
## Some other section

Even more stuff
    """
    And the file "appendix.md" contains:
    """
# Glossary

This is the glossary
    """
    And the file "styles.css" contains:
    """
p, td, li {
  font-family: 'Avenir';
}
    """
    And this config file:
    """
{
  "title": "OH YEAH!",
  "front_matter": [
    "intro.md"
  ],
  "main_matter": [
    "chapter1.md",
    "chapter2.md",
    "chapter3.md"
  ],
  "back_matter": [
    "appendix.md"
  ],
  "rendering": {
    "stylesheets": "styles.css",
    "git_repos_basedir": "repos"
  }
}
    """
    When I run `bookingit build`
    Then the exit status should be 0
    And a file named "book/styles.css" should exist
    And the file "book/intro.html" should contain "This is the introduction"
    And the file "book/intro.html" should contain "styles.css"
    And the file "book/chapter1.html" should contain "This is the beginning"
    And the file "book/chapter1.html" should contain "styles.css"
    And the file "book/chapter1.html" should contain "ls"
    And the file "book/chapter2.html" should contain "This is how we work"
    And the file "book/chapter3.html" should contain "Even more stuff"
    And the file "book/chapter3.html" should contain "styles.css"
    And the file "book/appendix.html" should contain "This is the glossary"
    And the file "book/appendix.html" should contain "styles.css"
    And the file "book/index.html" should contain "OH YEAH"
    And the file "book/index.html" should contain "intro.html"
    And the file "book/index.html" should contain "My awesome book"
    And the file "book/index.html" should contain "chapter1.html"
    And the file "book/index.html" should contain "It Begins"
    And the file "book/index.html" should contain "chapter2.html"
    And the file "book/index.html" should contain "The continuation"
    And the file "book/index.html" should contain "chapter3.html"
    And the file "book/index.html" should contain "styles.css"
    And the file "book/index.html" should contain "appendix.html"
    And the file "book/index.html" should contain "Glossary"

  Scenario: Init a new book
    When I run `bookingit init`
    Then a file named "config.json" should exist

  Scenario: Passes through stderr/stdout of failing commands
    Given the file "intro.md" contains:
    """
```
sh:///# ls bleorgh
```
    """
    And this config file:
    """
{
  "front_matter": [
    "intro.md"
  ],
  "main_matter": [
    "intro.md"
  ],
  "back_matter": [
    "intro.md"
  ]
}
    """
    When I run `bookingit build`
    Then the exit status should not be 0
    And the stderr should contain "ls bleorgh"
    And the stderr should contain "stdout:"
    And the stderr should contain "stderr:"

  Scenario: Use my own template
    Given the file "intro.md" contains:
    """
# My awesome book

This is the introduction
    """
    And the file "chapter1.md" contains:
    """
# It Begins

This is the beginning

    """
    And the file "/tmp/my_index.html.mustache" contains:
    """
<HTML>
  <BODY>
    <CENTER>
      {{#config}}
      <H1><FONT NAME='comic sans'>{{ title }}</FONT></H1>
      <H2>{{ frob }}</H2>
      {{/config}}
    </CENTER>
  </BODY>
</HTML>
    """
    And this config file:
    """
{
  "title": "OH YEAH!",
  "frob": "nosticate",
  "front_matter": [
    "intro.md"
  ],
  "main_matter": [
    "chapter1.md"
  ],
  "templates": {
    "index": "/tmp/my_index.html"
  }
}
    """
    When I run `bookingit build`
    Then the exit status should be 0
    And the file "book/intro.html" should contain "This is the introduction"
    And the file "book/chapter1.html" should contain "This is the beginning"
    And the file "book/index.html" should contain "OH YEAH"
    And the file "book/index.html" should contain "nosticate"

  Scenario: Init a new book
    When I run `bookingit init`
    Then a file named "config.json" should exist

  Scenario: Passes through stderr/stdout of failing commands
    Given the file "intro.md" contains:
    """
```
sh:///# ls bleorgh
```
    """
    And this config file:
    """
{
  "front_matter": [
    "intro.md"
  ],
  "main_matter": [
    "intro.md"
  ],
  "back_matter": [
    "intro.md"
  ]
}
    """
    When I run `bookingit build`
    Then the exit status should not be 0
    And the stderr should contain "ls bleorgh"
    And the stderr should contain "stdout:"
    And the stderr should contain "stderr:"
