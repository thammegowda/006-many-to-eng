#!/usr/bin/env bash

#SBATCH --mem=16G
# SBATCH --partition=isi
#SBATCH --time=1-00:00:00
#SBATCH --ntasks-per-node=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=3
#SBATCH --gres=gpu:p100:1
#SBATCH --output=R-%x.out.%j
#SBATCH --error=R-%x.err.%j
#SBATCH --export=NONE

# Pipeline script for MT
#

set -e


DATA=data-deen
OUT=$1

usage() {
    echo "Usage: $0 -d <exp/dir>"
    exit 1;
}

while getopts ":d:" o; do
    case "${o}" in
        d) OUT=${OPTARG} ;;
        *) usage ;;
    esac
done


[[ -n $OUT ]] || usage   # show usage and exit

source ~/.bashrc
conda activate fairseq


SRC=deu.tok
TGT=eng.tok
REF=eng
VOCAB_SIZE=8000
VOCAB_FILE=$OUT/bpe.$VOCAB_SIZE.txt
MAX=10000 # for quicktesting
MAX=10000000000

[[ -d $OUT/data-bpe ]] || mkdir -p $OUT/data-bpe
[[ -d $OUT/data-bin ]] || mkdir -p $OUT/data-bin
[[ -d $OUT/checkpoints ]] || mkdir -p $OUT/checkpoints
[[ -d $OUT/test ]] || mkdir -p $OUT/test

function log {
    echo "$(date): $1" >&2 
}

flag=$OUT/data-bpe/_SUCCESS
if [[ ! -f $flag ]]; then
    log "learning BPE"
    
   [[ -s $VOCAB_FILE ]] || cat $DATA/train.$SRC $DATA/train.$TGT | head -$MAX | subword-nmt learn-bpe -t -s $VOCAB_SIZE > $VOCAB_FILE
    log "BPE learn done"
    for split in dev test train; do
	for lang in $SRC $TGT; do
	    log "Apply BPE:  $DATA/$split.$lang >  $OUT/data-bpe/$split.$lang"
	    cat $DATA/$split.$lang | head -$MAX | subword-nmt apply-bpe -c $VOCAB_FILE  >  $OUT/data-bpe/$split.$lang
	done
    done
   touch $flag
fi

flag=$OUT/data-bin/_SUCCESS
if [[ ! -f $flag ]]; then
    fairseq-preprocess --source-lang $SRC --target-lang $TGT \
	  --trainpref $OUT/data-bpe/train \
	  --validpref $OUT/data-bpe/dev --testpref $OUT/data-bpe/test \
	  --destdir $OUT/data-bin/ --joined-dictionary
    touch $flag
fi

flag=$OUT/checkpoints/_SUCCESS
if [[ ! -f $flag ]]; then
    cmd="fairseq-train $OUT/data-bin --save-dir $OUT/checkpoints \
    --arch transformer --share-all-embeddings  \
    --dropout 0.1 --activation-fn gelu --attention-dropout 0.1 --activation-dropout 0.1 \
    --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
    --lr 5e-4 --lr-scheduler inverse_sqrt --warmup-updates 16000 \
    --save-interval-updates 10000 --max-update 200000 --keep-best-checkpoints 10  \
    --weight-decay 0.0001 \
    --criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
    --max-tokens 4200 \
    --eval-bleu \
    --eval-bleu-args '{\"beam\": 4, \"max_len_a\": 1.2, \"max_len_b\": 10}' \
    --eval-bleu-detok moses \
    --eval-bleu-remove-bpe \
    --eval-bleu-print-samples \
    --best-checkpoint-metric bleu --maximize-best-checkpoint-metric \
    --source-lang $SRC --target-lang $TGT"
    log "RUN: $cmd"
    eval "${cmd}" &&  touch $flag
fi


function decode {
    src=$1
    out=$2
    log "Decode $src -> $out"
    # Assumption: tokenized and BPE'd
    fairseq-interactive $OUT/data-bin \
			--path $OUT/checkpoints/checkpoint_best.pt \
			--source-lang $SRC --target-lang $TGT \
			--lenpen 0.6 --beam 4 \
			--tokenizer space --remove-bpe  \
		        --input $src | grep '^H-' | cut -f3  > $out
    # --tokenizer moses --bpe subword_nmt --bpe-codes $VOCAB_FILE \

    sacremoses detokenize < $out > $out.detok
}


for split in dev test; do
    src=$OUT/data-bpe/$split.$SRC
    out=$OUT/test/$split.out
    [[ -s $out ]] || decode $src $out
done
