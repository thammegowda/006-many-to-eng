#!/usr/bin/env bash

#SBATCH --partition=v100
#SBATCH --mem=240G
#SBATCH --time=0-36:59:00
#SBATCH --nodes=1 --ntasks=1
#SBATCH --cpus-per-task=150
#SBATCH --gres=gpu:v100:0
#SBATCH --output=R-%x.out.%j
#SBATCH --error=R-%x.err.%j
#SBATCH --export=NONE


source ~/.bashrc
conda activate rtg

cd /scratch/07394/tgowda/papers/many-to-eng/data 



echo "Running tokenizer and filtering"

./01-dataprep-tok.py || exit 2

echo "going to dedupe and remove test sentences from training"
./02-dataprep-dedup.py || exit 3



