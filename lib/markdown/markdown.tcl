#-------------------------------------------------------------------------
# TITLE: 
#    markdown.tcl
#
# PROJECT:
#    tcl-markdown: Markdown Processor for Tcl
#
# DESCRIPTION:
#    markdown(n): Implementation File
#
#    For now, this simply piggy-backs on the caius file; it's easier to
#    provide patches if I don't muck with stuff in it.  In the mean time,
#    I'll continue to work on the test suite.
#
#-------------------------------------------------------------------------

namespace eval ::markdown:: {
    namespace import -force ::Markdown::convert
    namespace export convert
    namespace ensemble create
}
