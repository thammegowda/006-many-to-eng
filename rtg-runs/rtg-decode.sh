#!/usr/bin/env bash

## SBATCH --account=saral
#SBATCH --partition=isi
#SBATCH --mem=12000
#SBATCH --time=0-3:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --gres=gpu:p100:1
#SBATCH --output=RD-%x.out.%j
#SBATCH --error=RD-%x.err.%j

#
# Author = Thamme Gowda (tg@isi.edu)
# Date = April 3, 2019;
# revised March 2020
# Revised Oct 2020
   
#SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]}")  # get the directory name
#RTG_PATH=$(realpath "${SCRIPTS_DIR}/..")


XDIR=
INP=
OUT=
CONDA_ENV=rtg     # empty means don't activate environment
BATCH=18000
MAX_SRC_LEN=300

usage() {
    echo "Usage: $0 -d <exp/dir>
    -i INPUT file to decode
    -o OUTPUT file to store translations
    [-b batch_size (default: $BATCH) ]
    [-e conda_env  default:$CONDA_ENV (empty string disables activation)]
" 1>&2;
    exit 1;
}


while getopts ":b:d:e:i:o:a:m:n:" o; do
    case "${o}" in
	b) BATCH=${OPTARG} ;;
        d) XDIR=${OPTARG} ;;
        e) CONDA_ENV=${OPTARG} ;;
        i) INP=${OPTARG} ;;
        o) OUT=${OPTARG} ;;
        *) usage ;;
    esac
done


[[ -n $XDIR ]] || usage   # show usage and exit
[[ -n $INP ]] || usage   # show usage and exit
[[ -n $OUT ]] || usage   # show usage and exit

#if [[ ! ( $INP == *.tsv ) || ! ( $OUT == *.tsv ) ]]; then
#    echo "Error: Input $INP and output $OUTP should be TSV files having ID<tab>Text"
#    exit 4
#fi

#defaults
source ~/.bashrc

#################

echo "Experiment Dir = $XDIR"
[[ -d $XDIR ]] || { echo "$XDIR directory not found"; exit 3; }

if [[ -n ${CONDA_ENV} ]]; then
    echo "Activating environment $CONDA_ENV"
    source activate ${CONDA_ENV} || { echp "Unable to activate $CONDA_ENV" ; exit 3; }
fi

export PYTHONPATH=$XDIR/rtg.zip
#export PYTHONPATH=~/sc2/repos/rtg/  
echo  "`date`: Starting decoding ... $OUT"

function unssplit(){
    awk -F '\t' '{if (last != $1) {printf "%s%s\t%s", last==""?"":"\n",$1, $2 } else { printf " %s", $2 } last=$1 } END {printf "\n"}'
}

cmd="python -m rtg.decode $XDIR -sc -b $BATCH -if $INP -of $OUT -msl $MAX_SRC_LEN "
echo "command::: $cmd"

if eval ${cmd}; then
    # echo "preparing output file $OUT"
   # paste <(cut -f1 $INP) <(cut -f1 $OUT.ssplit | sed 's/<unk>//g;') | unssplit > $OUT
    #rm $OUT.ssplit
    echo "`date` :: Done"
else
    echo "Error: exit status=$?"
fi
