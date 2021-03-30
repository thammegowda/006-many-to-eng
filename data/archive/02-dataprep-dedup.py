#!/usr/bin/env python
# coding: utf-8


CPUS = 100
MEM = '210g'
TMP_DIR = './tmp.spark'

# Tokenized, filtered
INP_FILE = 'merged/train.good.tok.tsv'
OUT_FILE = 'merged/train.good.dedup.notest.tok.tsv'

TESTS_DIR = 'tests'
 

from pyspark.sql import SparkSession
import pyspark
from functools import partial
from pathlib import Path
from sacremoses import MosesTokenizer, MosesPunctNormalizer
from html import unescape
import logging as log

log.basicConfig(level=log.INFO)
SCHEMA = 'lang STRING, ds_name STRING, src STRING, eng STRING'

def row_to_tsv(row):
    return f'{row.lang}\t{row.ds_name}\t{row.src}\t{row.eng}'

def to_tsv(rec):
    return '\t'.join(col.replace('\t', ' ') for col in rec)


normr = MosesPunctNormalizer(
        lang='en',
        norm_quote_commas=True,
        norm_numbers=True,
        pre_replace_unicode_punct=True,
        post_remove_control_chars=True,
    )
tok = MosesTokenizer(lang='en')

def tokenize_eng(text):
    try:
        text=unescape(text)
        text = normr.normalize(text)
        text = tok.tokenize(text, escape=False, return_str=True, aggressive_dash_splits=True,
            protected_patterns=tok.WEB_PROTECTED_PATTERNS)
        return text
    except:
        if text:
            log.exception(f"error: {text}")
            return '<TOKERR> ' + text
        else:
            return ''

tokenize_src = tokenize_eng


# ==============
log.info("Creating spark session")
spark = (SparkSession.builder
         .master(f"local[{CPUS}]")
         .appName("SacreMoses Tokenizer on PySpark")
         .config("spark.driver.memory", MEM)
         .config("spark.local.dir", TMP_DIR)
         .getOrCreate())

log.info("Spark session created")

## Deduplicate 
# check if test pairs are accidentally got into train
def tok_file(inp, out, tokr):
    log.info(f"TOK --> {out}")
    with out.open('w', encoding='utf-8', errors='ignore') as wrt, \
                  inp.open(encoding='utf-8', errors='ignore') as rdr:
        for line in rdr:
            wrt.write(tokr(line.strip()))
            wrt.write('\n')


tests_tok = []
for eng in Path(TESTS_DIR).glob("*.eng"):
    src_name = eng.name.replace(".eng", "").split("-")[-1].split("_")[0]
    src = eng.with_suffix("."+src_name)
    assert src.exists()
    src_tok = src.with_suffix(src.suffix + '.tok')
    eng_tok = eng.with_suffix(eng.suffix + '.tok')
    tests_tok.append((src_tok, eng_tok))
    if not src_tok.exists():
        tok_file(src, src_tok, tokr=tokenize_src)
    if not eng_tok.exists():
        tok_file(eng, eng_tok, tokr=tokenize_eng)    
    
log.info(f"Found {len(tests_tok)} held out sets")


from itertools import zip_longest
held_out_sents = set()
for src_tok, eng_tok in tests_tok:
    with src_tok.open() as srcs, eng_tok.open() as engs:
        for s, e in zip_longest(srcs, engs):
            assert s and e
            held_out_sents.add(s.strip())
            held_out_sents.add(e.strip())

log.info(f"Held out size: {len(held_out_sents):,}  sents from all languages")
log.info("Deduplicating and removing test sentences (if any)")


(spark.read.csv(INP_FILE, sep='\t', schema=SCHEMA)
    .dropDuplicates(['src', 'eng'])
    .rdd.filter(lambda r: r.src.strip() not in held_out_sents and r.eng.strip() not in held_out_sents)
    .map(row_to_tsv)
    .saveAsTextFile(OUT_FILE)
)


log.info("==== 02: Dedupe and Tokenization done ====")
