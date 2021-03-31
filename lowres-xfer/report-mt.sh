#!/usr/bin/env bash

[[ $# -eq 0 ]] && {
    echo "Usage:: $./report-mt.sh <exp1> <exp2> <exp3>"
    echo "   <exp1> ... positional args are path to experiment dirs"
    exit 1
}


#LC="-lc"
LC=""

delim=${delim:-','}
#delim='\t'

# extract test names automatically
names=$(for i in ${@}; do [[ -d $(echo $i/test_*) ]] || continue; for j in ${i}/test_*/*.ref ; do basename $j; done done | sed 's/.ref$//' | sort | uniq)
names_str=$(echo $names | sed "s/ /$delim/g")

echo "Reporting BLEU with $LC detok"
printf "Experiment/BLEU${delim}${names_str}\n"
for d in ${@}; do
    for td in $d/test_*; do
    printf "$td"
        for t in $names; do
            hyp_detok=${td}/$t.out.mosesdetok
            ref=${td}/$t.ref
	    printf "${delim}"
	    if [[ ! -f $hyp_detok ]]; then
		printf "No-Hyp${delim}No-Hyp"
	    elif [[ ! -f $ref ]]; then
		printf "No-Ref${delim}No-Ref"
	    else
		scores=$(cat $hyp_detok | sed 's/<unk>//g' | sacrebleu -m bleu -b $LC $ref)
		printf "${scores}"
	    fi
        done
        printf "\n"
    done
    #printf "\n"
done
