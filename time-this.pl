#!/usr/bin/perl -w
use strict;

print("Which window do I track?\n");

my $id;

open(XWININFO, "xwininfo |")
        or die "could not run xwininfo\n";
while (<XWININFO>) {
        chomp;
        # xwininfo: Window id: 0x2a25a69 "slides-dd-title.pdf"
        if (m/xwininfo: Window id: (0x[0-9a-fA-F]+) /) {
                $id = $1;
                print STDERR "ID is $id\n";
                last;
        }
}
close (XWININFO);
die "couldn't get the ID\n" if not defined $id;

my $start = time;
my $page = 1;
my @pend = ();

open(XEV, "xev -id $id |")
        or die "could not start xev\n";
while(<XEV>) {
        chomp;
        # state 0x0, keycode 45 (keysym 0x6b, k), same_screen YES,
        if (m/state.*keycode.*keysym (0x[0-9a-fA-F]{2,}), (\w+)\)/) {
                my ($key, $sym) = ($1, $2);

                if ($sym eq 'j' or $sym eq 'space' or $sym eq 'Return'
                                or $sym eq 'Next') {

                        my $pstart = $start;
                        $pstart = $pend[$page-1] if $page > 1;

                        my $now = time;
                        $pend[$page] = $now;

                        printf "page $page %ds, total %ds\n",
                                ($now - $pstart), ($now - $start);

                        $page++;

                } elsif ($sym eq 'k' or $sym eq 'BackSpace'
                                or $sym eq 'Prior') {

                        $page-- if $page > 1;

                        print "back to page $page\n";
                }
                
        }
}
close(XEV);

