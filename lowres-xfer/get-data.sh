#!/usr/bin/env bash

# Author TG ; created on March 2021

DATA=data


tokenize(){
    sacremoses normalize -q -d -p -c tokenize -a -x -p :web:
}

for lang in sme bre kor; do
    data=$DATA/$lang-eng
    
    [[ -f $data//mtdata.signature.txt ]] || 
	mtdata get -l $lang-eng -tr OPUS100v1_train -ts OPUS100v1_dev OPUS100v1_test --merge -o $data

    for split in dev test train; do
	for side in eng $lang; do
	    file=$data/$split.$side
	    [[ -f $file ]] || ln -s tests/OPUS100v1_$split-${lang}_eng.$side $file
	    [[ -f $file.tok ]] || tokenize < $file > $file.tok
	done
    done
done    





