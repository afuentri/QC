#! /usr/bin/python

import sys
import os
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import seaborn as sns
import numpy as np
import scipy.stats as stats
sns.set(style="whitegrid")
import matplotlib.pyplot as plt

f = sys.argv[1]
outf = sys.argv[2]
outplt = os.path.join(outf, 'mapped_chr.png')

df = pd.read_csv(f, sep=',', header=None)
df.columns = ['sample', 'total Reads', 'reads mapped', 'reference']
df['total Reads'] = df['total Reads'].astype('int')
df['reads mapped'] = df['reads mapped'].astype('int')

df['perc. reads'] = df['reads mapped']/df['total Reads'] * 100

names = sorted(list(df['reference'].unique()))

pivot_df = df.pivot_table(values='perc. reads', index='sample', columns='reference')

## size a4 paper                                                                                        sns.set_style("white")
plt.figure(figsize=(15,8))
sns.set(font_scale = 2)
with sns.color_palette("Paired", 15):
    az = pivot_df.loc[:, names].plot.bar(stacked=True, figsize=(30,15))

labels = [str(item.get_text()) for item in az.get_xticklabels()] 

az.set_xticklabels(labels, rotation=90)
az.set(xlabel='sample', ylabel='%reads')
az.legend(loc='best', mode='expand', fontsize=15, ncol=7)
plt.tight_layout()
plt.savefig(outplt)
plt.gcf().clear()
