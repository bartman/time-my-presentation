# About

Here is a script I use to time how long it took me to present from
a PDF.

This script assumes you're using something like a PDF viewer, like
evince, and are running on an X-Windows system, like Linux.

# Using

To time something, run:

        # time-my-presentation.pl
        Which window do I track?

You are then expected to click on a PDF viewer, like evince, which
will be monitored for slide changes.  The monitoring is actually done
by watching keyboard events.  Pushing *space*, *enter*, or *j* usually
advances the slide by a page, similarly pushing *back-space*, or *k*
goes back by a slide.

When you're done, push *CTRL-C* and the script will dump out a `.csv`
file named after the title of the window you are watching, which
in the case of evince will be the name of the pdf.

The file will look like this:

        # head timing-my-presentation.pdf.csv
        0, 1255306748
        1, 1255306751, 3, 3
        2, 1255306760, 12, 9
        3, 1255306769, 21, 9
        4, 1255306773, 25, 4
        5, 1255306776, 28, 3
        6, 1255306786, 38, 10
        7, 1255306797, 49, 11
        8, 1255306810, 62, 13
        9, 1255306814, 66, 4

The columns are: page number, absolute time, relative time, and time on
that page.  Note that page 0 is spacial and holds only the starting
time.

# License

GPLv2.

<!-- vim: set ft=mkd : -->
