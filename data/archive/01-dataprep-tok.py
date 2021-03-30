#!/usr/bin/env python
# coding: utf-8


CPUS = 80
MEM = '220g'
TMP_DIR = 'tmp.spark'


from pyspark.sql import SparkSession
import pyspark
from functools import partial
from pathlib import Path
from sacremoses import MosesTokenizer, MosesPunctNormalizer
from html import unescape
import logging as log

SCHEMA = 'lang STRING, ds_name STRING, src STRING, eng STRING'
def row_to_tsv(row):
    return f'{row.lang}\t{row.ds_name}\t{row.src}\t{row.eng}'

log.basicConfig(level=log.INFO)


import sacremoses
print(sacremoses.__version__)




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

tokenize_src = tokenize_eng # using english ton source; not terrific, but not terrible either
print(tokenize_eng("This's cool-stuff...! http://isi.edu  @id #hashtag email@gmail.com and,this but oh.no  no... no."))
print(tokenize_src("मैं तुमसे प्यार करता हूँ!। चिल्लाईए मत।"))


# In[4]:


spark = (SparkSession.builder
         .master(f"local[{CPUS}]")
         .appName("SacreMoses Tokenizer on PySpark")
         .config("spark.driver.memory", MEM)
         .config("spark.local.dir", TMP_DIR)
         .getOrCreate())

print(spark)


# In[5]:


raw_file = 'merged/train.raw.tsv'
df = spark.read.csv(raw_file, sep='\t', schema=SCHEMA)


# ## Tokenize 

# In[6]:


rdd_tok = df.rdd.map(lambda r: (r.lang, r.ds_name, tokenize_src(r.src), tokenize_eng(r.eng)))


def to_tsv(rec):
    return '\t'.join(col.replace('\t', ' ') for col in rec)

tok_file = raw_file.replace('.raw.tsv', '.tok.tsv')
#rdd_tok.map(to_tsv).saveAsTextFile(tok_file)


# ## Filter bad segs

# In[ ]:


import re

class MyFilter:

    def __init__(self):
        self.min_len = 1
        self.max_len = 120
        self.len_ratio = 5
        self.max_word_len = 30
        self.remove_urls = True
        #self.stats = stats 

    
    def __call__(self, rec):
        lang, provenance, src, eng = rec
        if not src or not eng or not src.strip() or not eng.strip():
            return 'EMPTY'
        src, tgt = src.strip(), eng.strip()

        if src == eng:
            return 'COPY'

        src_toks = src.split()
        eng_toks = eng.split()
        
        if len(src_toks) < self.min_len or len(eng_toks) < self.min_len:
            return 'MIN_LEN'

        if len(src_toks) > self.max_len or len(eng_toks) > self.max_len:
            return 'MAX_LEN'

        if not (1/self.len_ratio <= len(src_toks)/len(eng_toks) <= self.len_ratio):
            return 'LEN_RATIO'
        
        if any(len(t) > self.max_word_len for t in src_toks)            or any(len(t) > self.max_word_len for t in eng_toks):
            return 'MAX_WORD_LEN'
        
        if 'http' in src or 'http' in eng:
            return 'HTTP'
        
        return None # no reason to drop

my_filter = MyFilter()


tok_good_file = tok_file.replace('.tok', '.good.tok')
rdd_tok_good = rdd_tok.filter(lambda row: not(my_filter(row)))
rdd_tok_good.map(to_tsv).saveAsTextFile(tok_good_file)

print("==== 01: Tok and filter done ===")

# ## Deduplicate 
