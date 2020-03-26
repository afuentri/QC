#! /usr/bin/python3.5
import gzip
import sys
import re
import pandas as pd
import os

def revcomp(seq):
    """Sequence to reverse complementary"""
    revcomp = ''.join([{'A':'T', 'C':'G', 'G':'C', 'T':'A', 'a':'T', 'c':'G', 'g':'C', 't':'A', 'n':'N', 'N':'N'}[B] for B in seq][::-1])

    return revcomp



f = sys.argv[1]
p = sys.argv[2]

dprimers = {}

fprimers = open(p, 'r')

for line in fprimers:
    line = line.strip()
    if line.startswith(">"):
        name = line.replace(">", "")
    else:
        dprimers[name] = line

fprimers.close()

print(dprimers)

with gzip.open(f, 'rb') as OPEN_FILE:
    fhand = OPEN_FILE.read()

dcounts = {}
for e in dprimers:
    seq = dprimers[e]
    print(e)
    dcounts[e] = {}
    
    ## ori left
    val = "^" + seq
    words = len(re.findall(val, fhand, re.M|re.I))
    k = "LEFT"
    dcounts[e][k] = words

    ## revcomp left
    val = "^" + revcomp(seq)
    words = len(re.findall(val, fhand, re.M|re.I))
    k = "revcomp_LEFT"
    dcounts[e][k] = words

    ## ori right
    val = seq + "$"
    words = len(re.findall(val, fhand, re.M|re.I))
    k = "RIGHT"
    dcounts[e][k] = words

    ## revcomp right
    val = revcomp(seq) + "$"
    words = len(re.findall(val, fhand, re.M|re.I))
    k = "recomp_RIGHT"
    dcounts[e][k] = words

## write to out table
primers_name = '_'.join(os.path.basename(p).split(".")[0:-1])
out_name = os.path.basename(f).replace(".fastq.gz", "_{}.csv".format(primers_name))
df = pd.DataFrame.from_dict(dcounts, orient='index')
df.to_csv(out_name)
