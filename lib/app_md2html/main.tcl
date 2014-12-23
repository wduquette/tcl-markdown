#-------------------------------------------------------------------------
# TITLE: 
#    main.tcl
#
# PROJECT:
#    tcl-markdown: Markdown Processor
#
# DESCRIPTION:
#    app_md2html(n): main procedure
#
#-------------------------------------------------------------------------

#-------------------------------------------------------------------------
# Commands

# main argv
#
# Dummy procedure

proc main {argv} {
    if {[llength $argv] == 0} {
        return -code error -errorcode FATAL "No documents to process"
    }

    foreach infile $argv {
        set mdtext [readfile $infile]
        puts [markdown convert $mdtext]
    }
}
