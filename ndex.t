#!/usr/bin/perl -Tw

use Test::More tests => 5;
use lib './';
use NDex;

is(dir_file_die("README.md"), "FILE", "dir_file_die() found a file");
is(dir_file_die("Cats.txt"), "FALSE", "dir_file_die() did not find the file");
is(dir_file_die("./"), "DIR", "dir_file_die() found a directory");
is(dir_file_die(""), "FALSE", "dir_file_die() found nothing");

isnot(subdirectory(), 1, "what?");
