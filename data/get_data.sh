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

# use mtdata 0.2.7 (or maybe newer)

tool_names=( parallel awkg mtdata )
for tool in ${tool_names[@]} ; do
    which $tool &> /dev/null || exit_log 2 "$tool is required; please install"
done

INP=dataset-selection.tsv
OUT_DIR=datasets
ERR_OUT=errouts
N_JOBS=20

[[ -f $INP ]] || exit_log 3 "$INP file not found"
[[ -d $OUT_DIR ]] || mkdir -p $OUT_DIR
[[ -d $ERR_OUT ]] || mkdir -p $ERR_OUT

cat $INP | awk -F '\t' 'NR > 1 && NF >= 4'  | awkg -F '\t' "
lang, train, dev, test = R[:4]
out_dir=f'${OUT_DIR}/{lang}-eng'

if train and not Path(f'{out_dir}/mtdata.signature.txt').exists():
   train = ' '.join([t.strip() for t in train.split(',')])
   cmd = f'mtdata get -l {lang}-eng -tr {train} -o {out_dir} --merge '
   heldout = (test or '').split(',') + (dev or '').split(',')
   heldout = ' '.join(h.strip() for h in heldout if h.strip())
   if heldout:
      cmd += f' -ts {heldout}'
   print(cmd + f' &> ${ERR_OUT}/{lang}')
" 
# |  tail -$N_JOBS | parallel -j $N_JOBS 
