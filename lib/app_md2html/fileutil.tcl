#-------------------------------------------------------------------------
# TITLE: 
#    main.tcl
#
# PROJECT:
#    tcl-markdown: Markdown Processor
#
# DESCRIPTION:
#    app_md2html(n): File Utilities
#
#-------------------------------------------------------------------------

# readfile filename
#
# filename  - A filename
#
# Opens the named file and reads it into memory.

proc readfile {filename} {
    set f [open $filename r]

    if {[catch {
        return [read $f]
        close $f
    } result eopts]} {
        catch {close $f}
        return {*}$eopts $result
    }
}

# writefile filename text 
#
# filename - The filename
# text     - The file's contents
#
# Writes the text to the file, only if the content of the file has 
# changed.

proc writefile {filename text} {
    # FIRST, create the directory if necessary.
    file mkdir [file dirname $filename]

    # NEXT, save the file.
    set f [open $filename w]

    if {[catch {
        puts -nonewline $f $text
        close $f
    } result eopts]} {
        catch {close $f}
        return {*}$eopts $result
    }
}
