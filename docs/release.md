# tcl-markdown: Release Checklist

The following is a checklist of things to do when releasing the
project.

* Update version number in project.quill.
* Update release notes and other documentation.
* Validate documentation
* Do the complete build: 
  * `quill build all`
    * Run all tests
    * Format all documentation
    * Build library .zip files
    * Build applications
    * Build distribution .zip files
* Tag build in VCS.
* Install for local use, if desired.
  * `quill install`
* Upload distribution .zip files to server
* Send announcements
  * comp.lang.tcl
  * tcl-announce
  * tcl-core
  * ...
