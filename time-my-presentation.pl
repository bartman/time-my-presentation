#!/usr/bin/perl -w
use strict;

my $contfile;

# ------------------------------------------------------------------------
# user gave us an argument as a file to write to

my $filearg = $ARGV[0];
if ($filearg && -f $filearg) {
        $contfile = $filearg;

        my $line = `tail -n1 $contfile`;
        chomp $line;
        $line =~ m/^(\d+),\s*(\d+)(,|\s|$)/;
        my $next = $1 + 1;

        print STDERR "Will continue from page $next.\n";
        print STDERR "Press ENTER to continue.\n";
        <STDIN>;
}

# ------------------------------------------------------------------------
# figure out what window to track

print STDERR "Which window do I track?\n";

my $id;
my $title;
open(XWININFO, "xwininfo |")
        or die "could not run xwininfo\n";
while (<XWININFO>) {
        chomp;
        # xwininfo: Window id: 0x2a25a69 "slides-dd-title.pdf"
        if (m/xwininfo: Window id: (0x[0-9a-fA-F]+) "(.*)"\s*$/) {
                $id = $1;
                $title = $2;
                print STDERR "ID is $id\n";
                print STDERR "TITLE is $title\n";
                last;
        }
}
close (XWININFO);
die "couldn't get the ID\n" if not defined $id;

# ------------------------------------------------------------------------
# use xev to track events

open(XEV, "xev -id $id |")
        or die "could not start xev\n";

# ------------------------------------------------------------------------
# the timing info

my $start = time;
my $page = 1;
my @pend = ();

# ------------------------------------------------------------------------
# if we are continuing, then populate the database now

if (defined $contfile && -f $contfile) {
        open(IN, $contfile)
                or die "Cannot open file to continue: $contfile\n";

        my $no = 0;
        my $oldstart;
        my $lastdelta = 0;
        while(<IN>) {
                $no ++;
                m/^(\d+),\s*(\d+)(,|\s|$)/
                        or die "$contfile:$no is not valid\n";

                my ($oldnum, $oldtime) = ($1, $2);

                if ($oldnum == 0) {
                        $oldstart = $oldtime;

                } else {
                        $lastdelta = $oldtime - $oldstart;
                        $pend[$oldnum] = $start + $lastdelta;
                        $page = $oldnum + 1;
                }
        }
        close (IN);

        $start -= $lastdelta;
        for (my $p=1; $p<$page; $p++) {
                $pend[$p] -= $lastdelta;
        }
}

# ------------------------------------------------------------------------
# prepare output file

my $outfile = $filearg || "timing-$title.csv";
open (TIME, "> $outfile")
        or die "could not open $outfile for writing\n";

# ------------------------------------------------------------------------
# signal handler

sub sig_int {
        print STDERR "----\n";

        my $last = $start;
        print TIME "0, $start\n";

        for (my $p=1; $p <= $#pend; $p++) {
                my $relative = $pend[$p] - $start;
                my $delta    = $pend[$p] - $last;
                print TIME "$p, $pend[$p], $relative, $delta\n";
                $last = $pend[$p];
        }
        print STDERR "EXITING\n";
        exit(0);
}
$SIG{INT} = \&sig_int;

# ------------------------------------------------------------------------
# now process events

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

                        printf STDERR "page $page %ds, total %ds\n",
                                ($now - $pstart), ($now - $start);

                        $page++;

                } elsif ($sym eq 'k' or $sym eq 'BackSpace'
                                or $sym eq 'Prior') {

                        $page-- if $page > 1;

                        print STDERR "back to page $page\n";
                }
                
        }
}
close(XEV);

