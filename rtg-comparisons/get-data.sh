#!/usr/bin/env  bash


for cmd in mtdata sacremoses; do
    $cmd -h &> /dev/null || { echo "ERR: $cmd not found"; exit 2; }
done

data=data-deen
n_procs=20

[[ -f $data/mtdata.signature.txt ]] || mtdata get -l deu-eng --merge \
	 -tr wmt13_europarl_v7 wmt13_commoncrawl wmt18_news_commentary_v13 \
         -ts newstest201{8,9}_deen -o $data 

# designate dev and test sets
echo "dev tests/newstest2018_deen-deu_eng
test tests/newstest2019_deen-deu_eng" | while read split orig; do
    for lang in deu eng; do
	[[ -f $data/$split.$lang ]] || ln -s $orig.$lang $data/$split.$lang
    done
done

echo "de deu
en eng" | while read xy xyz; do
    for raw in $data/{train,dev,test}.$xyz; do
	if [[ ! -s $raw.tok ]]; then
	    echo "$raw -> $raw.tok";
	    sacremoses -l $xy -j $n_procs tokenize -ax < $raw > $raw.tok
	fi
    done
done


# Tokenize using sacremoses
#sacremoses -l en tokenize -a -x 
