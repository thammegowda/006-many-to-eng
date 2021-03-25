echo "dev wmt18
test wmt19" | while read alias orig; do
    for x in {{t2t,fairseq}-01/test,rtg-01-*/test_*}/$alias.out.detok; do
	echo $x;
	sacrebleu -l de-en -t $orig --short < $x 
    done
done
