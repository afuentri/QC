#! /usr/bin/python3.5                                                                                                                                                                                 

## import modules                                                                                                                                                                                        
import os
import matplotlib
matplotlib.use('Agg')
import pandas as pd
import seaborn as sns
import numpy as np
import sys
import scipy.stats as stats
sns.set(style="whitegrid")
import matplotlib.pyplot as plt

f = sys.argv[1]
outf = sys.argv[2]
bigdf = pd.DataFrame.from_dict({})

step = f.split('/')[-2]
plotname = os.path.join(outf, step + '-resume.png')

df = pd.read_csv(f, sep='\t')
df.columns = ['inform', 'parameter']
df['inform'] = df.inform.str.lstrip()
df[['nsamples','state']] = df.inform.str.split(" ", expand=True)
df['parameter'] = df.parameter.str.replace(' ', '_')
df2 = df[['nsamples', 'state', 'parameter']]
df2['nsamples'] = df2['nsamples'].astype('int')

df3 = df2.pivot_table(columns='state', index='parameter')
df3 = df3.fillna(0)


## plot stacked
sns.set_style("white")
fig, ax = plt.subplots()
dfc = df3.columns.to_list()
nrs2 = [id[1] for id in dfc]
tones = sns.color_palette('husl').as_hex()[:len(dfc)]
colors = dict(zip(dfc, tones))
df3.plot(kind='bar', stacked=True, figsize=(15,8),
            title="FastQC quality parameters", ax=ax,
         color=colors)

ax.legend(nrs2, loc='best', fontsize=9)
plt.xticks(rotation=90)
plt.tight_layout()
plt.savefig(plotname)
plt.gcf().clear()
