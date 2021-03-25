#!/usr/bin/env bash

#SBATCH --mem=16G
#SBATCH --partition=isi
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
# Author = Thamme Gowda (tg@isi.edu)
# Last revised March 20, 2021

set -e # exit on failure


DATA=$PWD/data-deen
#OUT=$PWD/t2t-01

OUT=

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

T2T_USR_DIR=$PWD/t2t_usr_dir
TRAIN="${DATA}/train"
DEV="${DATA}/dev"
TEST="${DATA}/test"
SRC="deu.tok"
TGT="eng.tok"
REF="eng"

# for a quick test
#TRAIN="${DATA}/dev"
#OUT=$PWD/t2t-01-debug


# Tensor 2 tensor
PROBLEM=translate_src_tgt8k
MODEL=transformer
HPARAMS=transformer_base_single_gpu
BEAM_SIZE=4
ALPHA=0.6
TRAIN_STEPS=200000

#################
source ~/.bashrc
conda activate t2t # should have tensorflow_gpu

# Clone https://github.com/thammegowda/tensor2tensor
echo "Output dir = $OUT"
[ -d $OUT/data ] || mkdir -p $OUT/data
[ -d $OUT/model ] || mkdir -p $OUT/model
[ -d $OUT/test ] || mkdir -p $OUT/test

# this is an hack -- to skip remote corpus download -- because our corpus is local
[ -f $OUT/data/dummy.txt ] || touch $OUT/data/dummy.txt

function log {
    printf "`date '+%Y-%m-%d %H:%M:%S'`:: $1\n" >> $OUT/job.log
}

# copy this script for reproducibility
cp "${BASH_SOURCE[0]}"  $OUT/job.sh.bak

log "Starting..."

########### PREPARE #########
if [[ -f $OUT/._SUCCESS_DATAGEN ]]; then
    log "Step : Skipping data processing... Files already exist"
else
    log "Step : Creating links. \n extensions: $SRC -> $TGT \n Train: $TRAIN \n Dev: $DEV \n Test: $TEST"

    ln -s $TRAIN.$SRC $OUT/data/train.src
    ln -s $TRAIN.$TGT $OUT/data/train.tgt

    ln -s $DEV.$SRC $OUT/data/dev.src
    ln -s $DEV.$TGT $OUT/data/dev.tgt
    ln -s $DEV.$REF $OUT/data/dev.ref

    # keeping test data aside in a different directory
    ln -s $TEST.$SRC $OUT/test/test.src
    ln -s $TEST.$TGT $OUT/test/test.tgt
    ln -s $TEST.$REF $OUT/test/test.ref    

    log "Step : preparing training and dev data"
    cmd="t2t-datagen --data_dir=$OUT/data --tmp_dir=$OUT/data --problem=$PROBLEM --t2t_usr_dir=$T2T_USR_DIR "
    log "$cmd"
    eval "$cmd"
    touch $OUT/._SUCCESS_DATAGEN
fi
####### TRAIN ########
if [[ -f "$OUT/._SUCCESS_TRAIN" ]]; then
    log "Step : Skipping Training... "
else
    log "Step : Starting trainer"
    # If you run out of memory, add .
    cmd="t2t-trainer --data_dir=$OUT/data \
        --problem=$PROBLEM --model=$MODEL --hparams='batch_size=4200' \
        --hparams_set=$HPARAMS --output_dir=$OUT/model \
        --train_steps=$TRAIN_STEPS --t2t_usr_dir=$T2T_USR_DIR "
    log "$cmd"
    eval "$cmd"
    touch "$OUT/._SUCCESS_TRAIN"
fi
########## DECODE #####
function decode {
    # accepts two args: <src-file> <out-file>
    FROM=$1
    TO=$2
    cmd="t2t-decoder --t2t_usr_dir=$T2T_USR_DIR \
        --data_dir=$OUT/data \
        --problem=$PROBLEM \
        --model=$MODEL \
        --hparams_set=$HPARAMS \
        --output_dir=$OUT/model \
        --decode_hparams=\"beam_size=$BEAM_SIZE,alpha=$ALPHA\" \
        --decode_from_file=$FROM \
        --decode_to_file=$TO "
    log "$cmd"
    eval "$cmd"
}

log "Step : decoding the test set"
decode $OUT/test/test.src $OUT/test/test.out
t2t-bleu --translation=$OUT/test/test.out --reference=$OUT/test/test.ref > $OUT/test/test.bleu
# NOTE : For reporting, evaluate outputs with proper detokenization and no alteration of references

log "Step : decoding the dev set"
decode $OUT/data/dev.src $OUT/test/dev.out
t2t-bleu --translation=$OUT/test/dev.out --reference=$OUT/data/dev.ref > $OUT/test/dev.bleu


log "Done"
