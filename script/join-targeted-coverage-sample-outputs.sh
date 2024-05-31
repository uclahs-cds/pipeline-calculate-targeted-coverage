#!/bin/bash

# This is a utility script that joins single sample *target-depth-per-base.bed outputs of pipeline-calculate-targeted-coverage
# into one BED file containing the three required BED columns, then one column per sample of per-base read depth information

# Usage: bash join-targeted-coverage-sample-outputs.sh [pathfile] [/path/to/output/file.bed]
# where pathfile = a file containing a NUL-separated list of filenames (target-depth-per-base.bed outputs) to join. 

# Output columns are in the order in which they are inputed, so make sure input paths are sorted
# accordingly (find outputs are typically in order of file creation).

# The following bash command can be used to prep the pathfile:
# find /path/to/pipeline-calculate-targeted-coverage/output/dir/ -name "*target-depth-per-base.bed" | sort | tr '\n' '\0'

## MAIN ##
sort -k1,1 -k2,2n -s --files0-from $1 | \
mergeBed -c 4 -o collapse -delim DELIM | \
sed 's/DELIM/\t/g' > $2
