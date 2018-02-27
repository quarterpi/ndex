#!/usr/local/bin/perl
use strict;
use warnings;
use feature qw(switch);
use autodie;  # die if there is an issue reading or writing from file
use JSON;     # use JSON package from cpan

# Checks a given path and returns either Directory, File, or False
# Param1: the file path to check
# Returns: DIR in the case of directory
# Returns: FILE in the case of a file
# Returns: False failing the above
sub dir_file_die {
  my ($file) = @_;
  if (-e $file && -d $file) {
    return "DIR";
  } elsif (-e $file) {
    return "FILE";
  } else {
    return "FALSE";
  }
}

# Strip the path and extension of given file
# Param1: the file to act upon
# Return: the given file name after stripping the path and extension
sub strip_path_and_extension {
  my ($file) = @_;
  $file =~ s{.*/}{};
  $file =~ s{\.[^.]+$}{};
  return $file;
}


# Create unique index of words in a file
# and add them to a hash
# Param1: array of lines from the file
# Param2: hash to add unique words to
# Param3: name of the file being acted upon 
sub unique_index_words_in_file {
  my ($filename, $lines_ref, $hash_ref) = @_;
  my $line_count = 0;
  my $word_count = 0;
  print "filname: $filename\n";
  foreach my $line (@$lines_ref) {
    $line =~ s/[^a-zA-Z0-9']/ /g;
    # split the line into an array fo strings for processing
    my @words = split(' ', $line);
    # make sure this line is not blank
    if (scalar @words > 0) {
      # process each word in this line
      for my $word (@words) {
        $word = lc($word);  
        push @{$hash_ref->{$word}{$filename}},{'word'=>$word_count,'line'=>$line_count};
        $word_count++;
      }
      $word_count = 0;
      $line_count++;
    }
  }
  $word_count = 0;
}


# Write hash to json file
# param1: The name of the file to write out to.
# param2: A reference to the hash to convert to json and write out.
# NOTE: This function will overite the contents of the file if it exists.
sub write_to_json_file {
  my ($output, $hash) = @_;
  my $json = encode_json $hash; # json encode our hash
  open(my $filename, ">", "$output.json") || die "Unable to open file: $output $!";
  print { $filename } $json || die "Cannot write to file: $!";
  close $filename;
}


sub request_files_from_user {
# Ask the user for the file or directory to parse
  print "Please enter the full path to the file/s or directory you would like to process\n";
  my $input = <STDIN>;
  chomp $input;
  return $input;
}

sub parse_files_and_dirs {
  my $input = $_[0];
  my $hash = $_[1] ? $_[1] : {}; 
# Check to make sure the file exists and is not a directory
  my $user_in = dir_file_die($input);
  print "input: $user_in \n";
  given($user_in) {
    when('FILE') { # They gave us a file
      print "file: $input\n";
# strip filepath and extension from filename
      my $filename = strip_path_and_extension($input);

# Try to open the file for reading
      open(DATA, "<$input") or die "Could not read contents of file";
      my @lines = <DATA>;
      close(DATA);
      print "Finding Unique: $filename\n";
      #%hash = unique_index_words_in_file($filename, @lines, %hash);
      unique_index_words_in_file($filename, \@lines, $hash);
    } 
    when('DIR') { # They gave us a directory
      # iterate over the contents of the directory
      opendir(D, $input) or die "Could not read contents of dir: $input\n";
      print "Directory: $input\n";
      while (my $file = readdir(D)) {
        if ($file =~ m/([a-zA-Z0-9]+[.][a-zA-Z0-9]+)/) {
        #if ($file =~ !/^\.{1,2}$/) {
          print "File: $file \n";
          parse_files_and_dirs("$input/$file", $hash);
        } else {
          print "File: $file Continuing.\n";
        }
      }
      closedir(D);
    } 
    when('FALSE') { "Error: file $input not found\n\n" } # They gave us a garbage value;
  }
  return $hash;
}


#==========================__MAIN__==========================

# Ask the user to give us the file they would like to process

my $input = request_files_from_user(); 
my $filename = strip_path_and_extension($input);
my $hash = parse_files_and_dirs($input);
write_to_json_file($filename, $hash);

# attempt at sorting keys alphanumerically not working
#my @keys = sort {
#  my ($aa) = $a =~ /^([A-Za-z]+)(\d*)/;
#  my ($bb) = $b =~ /^([A-Za-z]+)(\d*)/;
#} keys %hash;


