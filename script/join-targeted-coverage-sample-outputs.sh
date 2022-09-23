#!/bin/bash

# recursive function for joining single sample outputs of pipeline-targeted-coverage
# ie bed files with a fourth column

# Usage: ./join-targeted-coverage-sample-outputs pathfile

tiny1=/hot/user/nzeltser/pipeline-targeted-coverage/test/input/tiny1.bed
tiny2=/hot/user/nzeltser/pipeline-targeted-coverage/test/input/tiny2.bed

recursive_bed_join() {
	file1=$1;
	file2=$2;
	echo "$@"
	shift 2;

	echo $file1
	echo $file2
	#echo "$@"

	if [ $# -gt 0 ]; then
		sort -k1,1 -k2,2n "$file1" "$file2" | \
		mergeBed -c 4 -o collapse -delim DELIM | \
		recursive_bed_join - "$@";
	else
		sort -k1,1 -k2,2n "$file1" "$file2" | \
		mergeBed -c 4 -o collapse -delim DELIM
	fi
}
	
recursive_bed_join $tiny1 $tiny1 $tiny2 $tiny2 $tiny1 #$tiny1 $tiny1
# sed 's/DELIM/\t/g'



# 	f1=$1; f2=$2; shift 2;      if [ $# -gt 0 ]; then;          join "$f1" "$f2" | join_rec - "$@";     else;         join "$f1" "$f2";     fi

# sort -k1,1 -k2,2n $file $file | mergeBed -c 4 -o collapse -delim DELIM | sed 's/DELIM/\t/'