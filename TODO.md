# TODO.md

* Test against standard test suites: mdtest, commonmark
* mdtest Results
  * I get many more failures on my desktop machine than  my laptop.  The
    The difference seems to be due to how the input and output files are
    being compared on the two machines.  The only obvious difference is
    the version of PHP that's installed.  I suspect that an xml parser is
    being used to compare the output, and that it's more forgiving of
    extraneous whitespace on the later version.
    * I've established that it isn't a difference in tcl-markdown's output;
      I'm producing the same output on both machines, and I'm using the same
      mdtest input and output files on both machines.  
    * So it has to be the comparison.
    * So, I have to assume it's reasonable to ignore the extraneous 
      whitespace.
  * "Links, Reference Style" FAILED
    * Tcl error thrown in parser
  * "Ordered and unordered lists" seems to hang indefinitely.
* Clean up coding style
* Document specific-dialect of Markdown.
* Identify gaps
* Added capabilities?
  * regexp detection of special link syntax (i.e., #num for issue numbers
    in GitHub's markdown).