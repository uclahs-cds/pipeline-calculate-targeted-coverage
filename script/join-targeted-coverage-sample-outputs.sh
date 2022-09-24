#!/bin/bash

# recursive function for joining single sample outputs of pipeline-targeted-coverage
# ie bed files with a fourth column

# Usage: ./join-targeted-coverage-sample-outputs pathfile
# where pathfile = a list of filenames to join. 
# The file names must be separated by NUL (like the output produced by the command "find ... -print0").

sort -k1,1 -k2,2n -s --files0-from $1 | \
mergeBed -c 4 -o collapse -delim DELIM | \
sed 's/DELIM/\t/g'
