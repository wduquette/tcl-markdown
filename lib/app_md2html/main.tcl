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
    puts "[quillinfo project] [quillinfo version]"
    puts ""

    if {[llength $argv] == 0} {
        return -code error -errorcode FATAL "No documents to process"
    }

    foreach infile $argv {
        puts $infile
        if {[file extension $infile] ne ".md"} {
            puts "$infile: Not a markdown file; skipping"
            continue
        }
        set mdtext [readfile $infile]

        set outfile [file rootname $infile].html

        writefile $outfile [markdown convert $mdtext]
    }
}
