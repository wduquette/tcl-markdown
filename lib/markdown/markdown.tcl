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
#-------------------------------------------------------------------------

#-------------------------------------------------------------------------
# Exported Commands

namespace eval ::markdown {
    #---------------------------------------------------------------------
    # Ensemble
    namespace export \
        convert \
        refs

    namespace ensemble create

    #---------------------------------------------------------------------
    # Package Variables

    # references_: Array, ref -> {url title}.  This contains named
    # references, as described at 
    # http://daringfireball.net/projects/markdown/syntax#link:
    #
    #    [foo]: http://example.com/ "Optional Title Here"

    variable references_
}

#-------------------------------------------------------------------------
# Commands

# markdown convert markdown
#
# markdown - Markdown text to convert.
#
# Converts text written in markdown to HTML.  The result is an XHTML
# fragment, not a complete document.

proc ::markdown::convert {markdown} {
    variable references_

    # FIRST, normalize whitespace
    append markdown \n

    regsub -all {\r\n}  $markdown \n     markdown
    regsub -all {\r}    $markdown \n     markdown
    regsub -all {\t}    $markdown {    } markdown
    set markdown [string trim $markdown]

    # NEXT, Collect references
    CollectReferences $markdown

    # NEXT, Produce output
    return [ApplyTemplates $markdown]
}

# CollectReferences markdown
#
# markdown  - The Markdown text to convert
#
# Extracts explicitly defined references from the input as a first
# pass.  References look more or less like this:
#
#    [foo]: http://example.com/ "Optional Title Here"
#
# See http://daringfireball.net/projects/markdown/syntax#link
# for the full syntax.

proc ::markdown::CollectReferences {markdown} {
    variable references_

    set lines [split $markdown \n]
    set no_lines [llength $lines]
    set index 0

    array unset references_
    array set references_ {}

    while {$index < $no_lines} {
        set line [lindex $lines $index]

        if {[regexp \
            {^[ ]{0,3}\[(.*?[^\\])\]:\s+(\S+)(?:\s+(([\"\']).*[^\\]\4|\(.*[^\\]\))\s*$)?} \
            $line match ref link title]} \
        {
            set title [string trim [string range $title 1 end-1]]
            if {$title eq {}} {
                set next_line [lindex $lines [expr $index + 1]]

                if {[regexp \
                    {^(?:\s+(?:([\"\']).*[^\\]\1|\(?:.*[^\\]\))\s*$)} \
                    $next_line]} \
                {
                    set title [string range [string trim $next_line] 1 end-1]
                    incr index
                }
            }
            set ref [string tolower $ref]
            set link [string trim $link {<>}]
            set references_($ref) [list $link $title]
        }

        incr index
    }
}

# ApplyTemplates markdown ?parent?
#
# markdown   - Some markdown text to process
# parent     - The parent (an element name?)
#
# TBD?

proc ::markdown::ApplyTemplates {markdown {parent {}}} {
    set lines    [split $markdown \n]
    set no_lines [llength $lines]
    set index    0
    set result   {}

    set ul_match {^[ ]{0,3}(?:\*|-|\+) }
    set ol_match {^[ ]{0,3}\d+\. }

    # PROCESS MARKDOWN
    while {$index < $no_lines} {
        set line [lindex $lines $index]

        switch -regexp $line {
            {^\s*$} {
                # EMPTY LINES
                if {![regexp {^\s*$} [lindex $lines [expr $index - 1]]]} {
                    append result "\n\n"
                }
                incr index
            }
            {^[ ]{0,3}\[(.*?[^\\])\]:\s+(\S+)(?:\s+(([\"\']).*[^\\]\4|\(.*[^\\]\))\s*$)?} {
                set next_line [lindex $lines [expr $index + 1]]

                if {[regexp \
                    {^(?:\s+(?:([\"\']).*[^\\]\1|\(?:.*[^\\]\))\s*$)} \
                    $next_line]} \
                {
                    incr index
                }

                incr index
            }
            {^[ ]{0,3}-[ ]*-[ ]*-[- ]*$} -
            {^[ ]{0,3}_[ ]*_[ ]*_[_ ]*$} -
            {^[ ]{0,3}\*[ ]*\*[ ]*\*[\* ]*$} {
                # HORIZONTAL RULES
                append result "<hr/>"
                incr index
            }
            {^[ ]{0,3}#{1,6}} {
                # ATX STYLE HEADINGS
                set h_level 0
                set h_result {}

                while {$index < $no_lines && ![IsEmptyLine $line]} {
                    incr index

                    if {!$h_level} {
                        regexp {^\s*#+} $line m
                        set h_level [string length [string trim $m]]
                    }

                    lappend h_result $line

                    set line [lindex $lines $index]
                }

                set h_result [\
                    ParseInline [\
                        regsub -all {^\s*#+\s*|\s*#+\s*$} [join $h_result \n] {} \
                    ]\
                ]

                append result "<h$h_level>$h_result</h$h_level>"
            }
            {^[ ]{0,3}\>} {
                # BLOCK QUOTES
                set bq_result {}

                while {$index < $no_lines} {
                    incr index

                    lappend bq_result [regsub {^[ ]{0,3}\>[ ]?} $line {}]

                    if {[IsEmptyLine [lindex $lines $index]]} {
                        set eoq 0

                        for {set peek $index} {$peek < $no_lines} {incr peek} {
                            set line [lindex $lines $peek]

                            if {![IsEmptyLine $line]} {
                                if {![regexp {^[ ]{0,3}\>} $line]} {
                                    set eoq 1
                                }
                                break
                            }
                        }

                        if {$eoq} { break }
                    }

                    set line [lindex $lines $index]
                }
                set bq_result [string trim [join $bq_result \n]]

                append result <blockquote>\n \
                                [ApplyTemplates $bq_result] \
                              \n</blockquote>
            }
            {^\s{4,}\S+} {
                # CODE BLOCKS
                set code_result {}

                while {$index < $no_lines} {
                    incr index

                    lappend code_result [HtmlEscape [\
                        regsub {^    } $line {}]\
                    ]

                    set eoc 0
                    for {set peek $index} {$peek < $no_lines} {incr peek} {
                        set line [lindex $lines $peek]

                        if {![IsEmptyLine $line]} {
                            if {![regexp {^\s{4,}} $line]} {
                                set eoc 1
                            }
                            break
                        }
                    }

                    if {$eoc} { break }

                    set line [lindex $lines $index]
                }
                set code_result [string trim [join $code_result \n]]

                append result <pre><code> $code_result </code></pre>
            }
            {^[ ]{0,3}(?:\*|-|\+) |^[ ]{0,3}\d+\. } {
                # LISTS
                set list_type ul
                set list_match $ul_match
                set list_result {}

                if {[regexp $ol_match $line]} {
                    set list_type ol
                    set list_match $ol_match
                }

                set last_line AAA

                while {$index < $no_lines} {
                    set item_result {}

                    if {![regexp $list_match [lindex $lines $index]]} {
                        break
                    }

                    set in_p 1
                    set p_count 1

                    if {[IsEmptyLine $last_line]} { incr p_count }

                    for {set peek $index} {$peek < $no_lines} {incr peek} {
                        set line [lindex $lines $peek]

                        if {$peek == $index} {
                            set line [regsub "$list_match\\s*" $line {}]
                            set in_p 1
                        }

                        if {[IsEmptyLine $line]} {
                            set in_p 0
                        }\
                        elseif {[regexp {^    } $line]} {
                            if {!$in_p} {
                                incr p_count
                            }
                            set in_p 1
                        }\
                        elseif {[regexp $list_match $line]} {
                            if {!$in_p} {
                                incr p_count
                            }
                            break
                        }\
                        elseif {!$in_p} {
                            break
                        }

                        set last_line $line
                        lappend item_result [regsub {^    } $line {}]
                    }

                    set item_result [join $item_result \n]

                    if {$p_count > 1} {
                        set item_result [ApplyTemplates $item_result li]
                    } else {
                        if {[regexp -lineanchor \
                            {(\A.*?)((?:^[ ]{0,3}(?:\*|-|\+) |^[ ]{0,3}\d+\. ).*\Z)} \
                            $item_result \
                            match para rest]} \
                        {
                            set item_result [ParseInline $para]
                            append item_result [ApplyTemplates $rest]
                        } else {
                            set item_result [ParseInline $item_result]
                        }
                    }

                    lappend list_result "<li>$item_result</li>"
                    set index $peek
                }

                append result <$list_type>\n \
                                [join $list_result \n] \
                            </$list_type>\n\n
            }
            {^<(?:p|div|h[1-6]|blockquote|pre|table|dl|ol|ul|script|noscript|form|fieldset|iframe|math|ins|del)} {
                # HTML BLOCKS
                set re_htmltag {<(/?)(\w+)(?:\s+\w+=\"[^\"]+\")*\s*>}
                set buffer {}

                while {$index < $no_lines} \
                {
                    while {$index < $no_lines} \
                    {
                        incr index

                        append buffer $line \n

                        if {[IsEmptyLine $line]} {
                            break
                        }

                        set line [lindex $lines $index]
                    }

                    set tags [regexp -inline -all $re_htmltag  $buffer]
                    set stack_count 0

                    foreach {match type name} $tags {
                        if {$type eq {}} {
                            incr stack_count +1
                        } else {
                            incr stack_count -1
                        }
                    }

                    if {$stack_count == 0} { break }
                }

                append result $buffer
            }
            default {
                # PARAGRAPHS AND SETTEXT STYLE HEADERS
                set p_type p
                set p_result {}

                while {($index < $no_lines) && ![IsEmptyLine $line]} \
                {
                    incr index

                    switch -regexp $line {
                        {^[ ]{0,3}=+$} {
                            set p_type h1
                            break
                        }
                        {^[ ]{0,3}-+$} {
                            set p_type h2
                            break
                        }
                        {^[ ]{0,3}(?:\*|-|\+) |^[ ]{0,3}\d+\. } {
                            if {$parent eq {li}} {
                                incr index -1
                                break
                            } else {
                                lappend p_result $line
                            }
                        }
                        {^[ ]{0,3}-[ ]*-[ ]*-[- ]*$} -
                        {^[ ]{0,3}_[ ]*_[ ]*_[_ ]*$} -
                        {^[ ]{0,3}\*[ ]*\*[ ]*\*[\* ]*$} -
                        {^[ ]{0,3}#{1,6}} \
                        {
                            incr index -1
                            break
                        }
                        default {
                            lappend p_result $line
                        }
                    }

                    set line [lindex $lines $index]
                }

                set p_result [\
                    ParseInline [\
                        string trim [join $p_result \n]\
                    ]\
                ]

                if {[IsEmptyLine [regsub -all {<!--.*?-->} $p_result {}]]} {
                    # Do not make a new paragraph for just comments.
                    append result $p_result
                } else {
                    append result "<$p_type>$p_result</$p_type>"
                }
            }
        }
    }

    return $result
}

# ParseInline text
#
# text - Markdown text to parse
#
# TBD?

proc ::markdown::ParseInline {text} {
    variable references_

    set text [regsub -all -lineanchor {[ ]{2,}$} $text <br/>]

    set index 0
    set result {}

    set re_backticks   {\A`+}
    set re_whitespace  {\s}
    set re_inlinelink  {\A\!?\[((?:[^\]\\]|\\\])*)\]\s*\(((?:[^\)\\]|\\\))*)\)}
    set re_reflink     {\A\!?\[((?:[^\]\\]|\\\])*)\]\s*\[((?:[^\]\\]|\\\])*?)\]}
    set re_urlandtitle {\A(\S+)(?:\s+([\"'])((?:[^\"\'\\]|\\\2)*)\2)?}
    set re_htmltag     {\A</?\w+\s*>|\A<\w+(?:\s+\w+=\"[^\"]+\")*\s*/?>}
    set re_autolink    {\A<(?:(\S+@\S+)|(\S+://\S+))>}
    set re_comment     {\A<!--.*?-->}
    set re_entity      {\A\&\S+;}

    while {[set chr [string index $text $index]] ne {}} {
        switch $chr {
            "\\" {
                # ESCAPES
                set next_chr [string index $text [expr $index + 1]]

                if {[string first $next_chr {\`*_\{\}[]()#+-.!}] != -1} {
                    set chr $next_chr
                    incr index
                }
            }
            {_} -
            {*} {
                # EMPHASIS
                if {[regexp $re_whitespace [string index $result end]] &&
                    [regexp $re_whitespace [string index $text [expr $index + 1]]]} \
                {
                    #do nothing
                } \
                elseif {[regexp -start $index \
                    "\\A(\\$chr{1,2})((?:\[^\\$chr\\\\]|\\\\\\$chr)*)\\1" \
                    $text m del sub]} \
                {
                    if {[string length $del] > 1} {
                        set tag strong
                    } else {
                        set tag em
                    }

                    append result "<$tag>[ParseInline $sub]</$tag>"
                    incr index [string length $m]
                    continue
                }
            }
            {`} {
                # CODE
                regexp -start $index $re_backticks $text m
                set start [expr $index + [string length $m]]

                if {[regexp -start $start -indices $m $text m]} {
                    set stop [expr [lindex $m 0] - 1]

                    set sub [string trim [string range $text $start $stop]]

                    append result "<code>[HtmlEscape $sub]</code>"
                    set index [expr [lindex $m 1] + 1]
                    continue
                }
            }
            {!} -
            {[} {
                # LINKS AND IMAGES
                set ref_type link

                if {$chr eq {!}} {
                    set ref_type img
                }

                set match_found 0

                if {[regexp -start $index $re_reflink $text m txt lbl]} {
                    # REFERENCED
                    incr index [string length $m]

                    if {$lbl eq {}} { set lbl $txt }

                    set ref [string tolower $lbl]
                    if {[info exists references_($ref)]} {
                        lassign $references_($ref) url title

                        set url [HtmlEscape [string trim $url {<> }]]
                        set txt [ParseInline $txt]
                        set title [ParseInline $title]

                        set match_found 1
                    } else {
                        # Unknown ref: just put in the matching text.
                        append result $m
                        continue
                    }
                } elseif {[regexp -start $index $re_inlinelink $text m txt url_and_title]} {
                    # INLINE
                    incr index [string length $m]

                    set url_and_title [string trim $url_and_title]
                    set del [string index $url_and_title end]

                    if {[string first $del "\"'"] >= 0} {
                        regexp $re_urlandtitle $url_and_title m url del title
                    } else {
                        set url $url_and_title
                        set title {}
                    }

                    set url [HtmlEscape [string trim $url {<> }]]
                    set txt [ParseInline $txt]
                    set title [ParseInline $title]

                    set match_found 1
                }

                # PRINT IMG, A TAG
                if {$match_found} {
                    if {$ref_type eq {link}} {
                        if {$title ne {}} {
                            append result "<a href=\"$url\" title=\"$title\">$txt</a>"
                        } else {
                            append result "<a href=\"$url\">$txt</a>"
                        }
                    } else {
                        if {$title ne {}} {
                            append result "<img src=\"$url\" alt=\"$txt\" title=\"$title\"/>"
                        } else {
                            append result "<img src=\"$url\" alt=\"$txt\"/>"
                        }
                    }

                    continue
                }
            }
            {<} {
                # HTML TAGS, COMMENTS AND AUTOLINKS
                if {[regexp -start $index $re_comment $text m]} {
                    append result $m
                    incr index [string length $m]
                    continue
                } elseif {[regexp -start $index $re_autolink $text m email link]} {
                    if {$link ne {}} {
                        set link [HtmlEscape $link]
                        append result "<a href=\"$link\">$link</a>"
                    } else {
                        set mailto_prefix "mailto:"
                        if {![regexp "^${mailto_prefix}(.*)" $email mailto email]} {
                            # $email does not contain the prefix "mailto:".
                            set mailto "mailto:$email"
                        }
                        append result "<a href=\"$mailto\">$email</a>"
                    }
                    incr index [string length $m]
                    continue
                } elseif {[regexp -start $index $re_htmltag $text m]} {
                    append result $m
                    incr index [string length $m]
                    continue
                }

                set chr [HtmlEscape $chr]
            }
            {&} {
                # ENTITIES
                if {[regexp -start $index $re_entity $text m]} {
                    append result $m
                    incr index [string length $m]
                    continue
                }

                set chr [HtmlEscape $chr]
            }
            {-} {
                # EMDASH
                if {[string index $text [expr $index + 1]] eq {-}} {
                    append result {&#8212;}
                    incr index 2
                    continue
                }
            }
            {>} -
            {'} -
            "\"" {
                # OTHER SPECIAL CHARACTERS
                set chr [HtmlEscape $chr]
            }
            default {}
        }

        append result $chr
        incr index
    }

    return $result
}

# IsEmptyLine line
#
# line  - A line of text
#
# Returns 1 if the line is empty, and 0 otherwise.

proc ::markdown::IsEmptyLine {line} {
    return [regexp {^\s*$} $line]
}

# HtmlEscape text
#
# text   - some input text
#
# Replaces special characters in the input text with HTML attributes.

proc ::markdown::HtmlEscape {text} {
    return [string map {<!-- <!-- --> --> & &amp; < &lt; > &gt; ' &apos; \" &quot;} $text]
}

