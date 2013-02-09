#!/usr/bin/env perl

# use strict;
# use warnings;
# use English qw( -no_match_vars );
# use File::Basename;
# use File::Find::Rule;
# use File::Slurp;
# use File::Copy;
# use Getopt::Long;
# use Devel::Comments;
# use 5.010;

# Communicate with the shell wrapper using a temp file instead of STDOUT, since we want to be able to
# show our own interactive menu over STDOUT without confusing the shell wrapper with that output.
# open my $OUT, '>', "/tmp/fuzzycd.pl.out";
open my $OUT, '>', "/tmp/fuzzycd.rb.out";

my $cd_path = $ARGV[0];

# Just invoke cd directly in certain special cases (e.g. when the path is empty, ends in "/" or exactly
# matches a directory).

if (!defined $cd_path || $cd_path eq '.' || $cd_path eq '/' || $cd_path eq '-' ||
    $cd_path eq '~' || $cd_path =~ /\/$/ || $cd_path =~ /^\.\.(\/\.\.)*$/ || -d $cd_path) {
    # print $cd_path;
    print $OUT '@passthrough';
    exit;
}

# find all the subdirectories of a given directory
# my @dirs = File::Find::Rule->directory->maxdepth(1)->in('.');
# my @dirs = grep {-d && /^(?!\.)/} read_dir('.');
my @dirs = grep {-d && /^(?!\.)/} glob('*');  # /^(?!\.)/ filters out the hidden files
# say @dirs;

my @matches;

for my $dir (@dirs) {
    if ($cd_path =~ /[A-Z]/) {   # if cd_path contains captial letter we do case-sensitive matching
        if ($dir =~ m/$cd_path/) {
            push @matches, $dir;
        }
    }
    else {                       # otherwise we do case insensitive matching
        if ($dir =~ m/$cd_path/i) {
            push @matches, $dir;
        }
    }
}

if (scalar @matches == 1) {
    print $OUT $matches[0];
}
elsif (scalar @matches == 0) {
    print $OUT '@nomatches';
}
elsif (scalar @matches >= 100) {
    print "There are more than 100 matches; be more specific.\n";
    print $OUT '@exit';
}
else {
    print "Make a choice:\n";
    # print @matches;
    # choice = present_menu_with_options(matches)
    # @out.puts(choice.nil? ? "@exit" : choice)
    my @a = @matches;
    my @b = @matches;

    chomp($term_width = `tput cols`);

    $maxcol = $term_width / 3;
    $file_num = scalar @a;
    my @lbls = ('a'..'z');
    # @lbls = map {" $_"} @lbls;

    foreach $i ('a'..'z') {
        foreach $j ('a'..'z') {
            push @lbls, $i.$j;
        }
    }
    # say @lbls;

    # Label every file and directory with integers.
    # for ($i = 0; $i < $file_num; $i++) {
    my $file_num = $file_num < 702 ? $file_num : 702;    # We have 26*26+26 = 702 labels
    for ($i = 0; $i < $file_num; $i++) {
        # $a[$i] = sprintf "[%d] %s", $i+1, $a[$i];
        # $b[$i] = sprintf "\e[2;37m[\e[0m\e[2;33m%d\e[0m\e[2;37m]\e[0m %s", $i+1, $b[$i];  # colorize labels
        # $b[$i] = sprintf "\e[2;37m[\e[0m%d\e[2;37m]\e[0m %s", $i+1, $b[$i];

        $a[$i] = sprintf "[%s] %s", $lbls[$i], $a[$i];
        $b[$i] = sprintf "\e[2;37m[\e[0m%s\e[2;37m]\e[0m %s", $lbls[$i], $b[$i];
    }

    # @a = map {"[00] $_"} @a;

    # Find out how many columns we need to print out our new 'ls' table fitting the width of the
    # terminal. We basically use the brutal force search. We start by assuming a hyperthetical table of
    # 1 row can fit all items. Therefore i = 1 here.
    for ($i = 1; $i <= $file_num; $i++) {  # $i is the number of rows in the hyperthetical table.
        $col = 0;
        $curr_length = 0;   # The current table width

        # Then we place every items into this hyperthetical table (and update the current column width
        # at the same time). If all items can be placed without overflowing the terminal width, the
        # column number is found. Otherwise we will try the number of row = 2, 3, ..., N, where N =
        # total number of items. When row number = N, that means we can only place one item at each row,
        # therefore we have 1 column and N rows.
        for ($j = 0; $j < $file_num; $j++) { # $j is the index of the current file
            $idx = int($j/$i);  # The index of columns where the current file resides

            # If the current file is the first element in a new column
            if ($j % $i == 0) {
                $cols[$idx]->{len} = length($a[$j]);  # Initialize the width of the new column

                # Update the current table width
                if ($idx != 0) { # If the current column is not the first one
                    $curr_length += 2 + length($a[$j]);       # Spacing is 2
                }
                else { # If the current column is the first one
                    $curr_length = length($a[$j]);
                }

                # Check overflow
                $curr_length < $term_width ? $col++ : last;
            }
            # If the current file is not the first element in current column
            else {
                # Update the current column width. We need save them for the final print
                if (length($a[$j]) > $cols[$idx]->{len}) {
                    $curr_length += length($a[$j]) - $cols[$idx]->{len};
                    $cols[$idx]->{len} = length($a[$j]);

                    if ($curr_length > $term_width) { # Run overflow
                        last;
                    }
                }
            }
        }

        # If we've placed all items, finish searching. The current row and column numbers will be used
        # later.
        if ($j == $file_num) {
            # printf "i=%d, j=%d\n", $i, $j;
            last;
        }
    }
    # Now $i is the height of the table

    # Print our new table of files and directories across the terminal
    foreach $k (0 .. $i-1) {  # Print table row-by-row
        foreach $m (0 .. $col-1) {  # Fill every column

            if ($m !=0) {
                # If current column is not the first we need to print extra white spaces to align. NOTE:
                # I didn't use 'printf' here because the ASCII color code is easy to screw up in '%'
                # format.
                $p = ($m-1)*$i + $k;    # $p is the index of the file on the left of current file
                print ' ' x ($cols[$m-1]->{len} - length($a[$p]) + 2);    # Spacing is 2
            }

            $p = $m*$i + $k;        # $p is the index of current file or directory
            printf "%s", $b[$p];
        }
        print "\n";
    }

    my $choice = <STDIN>;
    chomp $choice;

    for ($i = 0; $i < $file_num; $i++) {
        if ($lbls[$i] eq $choice) {
            print $OUT $matches[$i];
            exit;
        }
    }
}

# vim: set tabstop=4 shiftwidth=4 tw=78:
