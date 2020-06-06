#!/usr/bin/env bash
# Script to download datasets
#
#

log(){
    printf "$(date): $1\n"
}
exit_log() {
    log "$2"
    exit $1
}

tool_names=( parallel awkg mtdata )
for tool in ${tool_names[@]} ; do
    which $tool &> /dev/null || exit_log 2 "$tool is required; please install"
done

INP=dataset-selection.tsv
OUT_DIR=datasets

[[ -f $INP ]] || exit_log 3 "$INP file not found"
[[ -d $OUT_DIR ]] || mkdir -p $OUT_DIR

cat $INP | awk -F '\t' 'NR > 1 && NF >= 4'  | awkg -F '\t' "
lang, train, dev, test = R[:4]
if train:
   train = ' '.join([t.strip() for t in train.split(',')])
   cmd = f'mtdata get -l {lang}-eng -tr {train} ' + f\" -o ${OUT_DIR}/{lang}-eng \"
   heldout = (test or '').split(',') + (dev or '').split(',')
   heldout = ' '.join(h.strip() for h in heldout if h.strip())
   if heldout:
      cmd += f' -ts {heldout}'
   print(cmd)
"
