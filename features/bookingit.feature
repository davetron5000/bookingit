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
    And the file "chapter1.md" contains:
    """
# It Begins

This is the beginning

```
sh:///# ls
```
    """
    And the file "chapter2.1.md" contains:
    """
# The continuation

This is how we work

## Some section

Some more stuff
    """
    And the file "chapter2.2.md" contains:
    """
## Some other section

Even more stuff
    """
    And the file "appendix.md" contains:
    """
# Glossary

This is the glossary
    """
    And this config file:
    """
{
  "front_matter": [
    "intro.md"
  ],
  "main_matter": [
    "chapter1.md",
    "chapter2.*.md"
  ],
  "back_matter": [
    "appendix.md"
  ]
}
    """
    When I run `bookingit build config.json book`
    Then the exit status should be 0
    And the file "book/front_matter_1.html" should contain "This is the introduction"
    And the file "book/main_matter_1.html" should contain "This is the beginning"
    And the file "book/main_matter_1.html" should contain "ls"
    And the file "book/main_matter_2.html" should contain "This is how we work"
    And the file "book/main_matter_2.html" should contain "Even more stuff"
    And the file "book/back_matter_1.html" should contain "This is the glossary"
    And the file "book/index.html" should contain "front_matter_1.html"
    And the file "book/index.html" should contain "My awesome book"
    And the file "book/index.html" should contain "main_matter_1.html"
    And the file "book/index.html" should contain "It Begins"
    And the file "book/index.html" should contain "main_matter_2.html"
    And the file "book/index.html" should contain "The continuation"
    And the file "book/index.html" should contain "back_matter_1.html"
    And the file "book/index.html" should contain "Glossary"
