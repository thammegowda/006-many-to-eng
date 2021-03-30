#!/usr/bin/env bash
# Created by TG on March 4, 2021

#ROOT=$PWD
#cd "$ROOT"

XNLI="https://dl.fbaipublicfiles.com/XNLI/XNLI-1.0.zip"
MultiNLI="https://cims.nyu.edu/~sbowman/multinli/multinli_1.0.zip"

maybe_download() {  # and extract
  url="$1"
  file="${url##*/}"  # delete from front of string (##) the longest match until /
  file=$file
  dir="${file%.*}"  # delete the shortest thing after . (i.e .*) from rear end (i.e %)
  if [[ ! -d $dir ]]; then
    [[ -f $file ]] || wget -O $file "$url"
    unzip $file
    [[ -d __MACOSX ]] && rm -r __MACOSX  # Hmm Apple engineers, what were you thinking?
  fi
}

maybe_download "$XNLI"
maybe_download "$MultiNLI"

# parse JSONL to simple TSV
echo "xnli.dev.tsv XNLI-1.0/xnli.dev.jsonl
xnli.test.tsv XNLI-1.0/xnli.test.jsonl
multinli.dev.matched.tsv multinli_1.0/multinli_1.0_dev_matched.jsonl
multinli.dev.mismatched.tsv multinli_1.0/multinli_1.0_dev_mismatched.jsonl
multinli.train.tsv multinli_1.0/multinli_1.0_train.jsonl" |
while read out inp; do
  [[ -f $out ]] || jq -r '[.sentence1, .sentence2, .gold_label, .language] | @tsv' < $inp > $out
done
