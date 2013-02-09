quickcd
=======

A rewrite of [fuzzycd][1] in Perl. You only need to type partial directory names to change
directories. It saves you a lot of keystrokes and enhances your productivity, especially when you
navigate in many subdirectories with tricky names.

This script is inspired by [fuzzycd][1]. Big thanks to the author for sharing his/her great code.
The way of intercepting the system `cd` is genius. I recommend you to try both scripts and choose
the one you like most.

Overview
========

quickcd enables you to use cd with partial directory names. For example:

    $ cd box
      => Dropbox
    $ cd ok
      => Ebook

If there is more than one directory containing your cd path, you just need to type one more letter
to take you to the target folder.

```
~ $ cd D
Make a choice:
[a] Desktop  [b] Documents  [c] Downloads  [d] Dropbox
a
Desktop $
```

Why rewrite?
============

The differences:

1. When your cd path contains capital letter quickcd will match case sensitively. This way can
   result in less matches. fuzzycd seems to do case insensitive match all the time.

2. quickcd prints out a well-formatted candidates. It fits the width of the terminal windows and
   the columns are aligned neatly. I worked really hard on making this right. fuzzycd candidates
   are not always aligned.

3. quickcd doesn't support multi-level directory nagivation. Its main focus is current directory.
   fuzzycd supports fuzzy jumps to multi-level directory but I rarely use this feature.

4. quickcd is written in Perl. Yep, I like Perl! fuzzycd is written in Ruby.

Setup
=====

This following instruction are shamelessly copied from fuzzycd's README.

Modify your ~/.profile (or ~/.bashrc, depending your operating system) and add the following lines.
This assumes you put fuzzycd in the ~/scripts/ directory.

    export PATH=~/scripts/fuzzycd/:$PATH
    source ~/scripts/fuzzycd/fuzzycd_bash_wrapper.sh

This will effectively wrap the builtin bash cd command with the fuzzy cd command. Enjoy!

*Note*: If you have any other shell plugins which try to redefine the "cd" function (e.g.
[rvm](https://rvm.beginrescueend.com/rvm) does this), make sure that the
`source ... fuzzycd_bash_wrapper.sh` line comes last in your bash profile. fuzzycd plays nicely with
other bash modification plugins, but it should be loaded last.


[1]: https://github.com/philc/fuzzycd
