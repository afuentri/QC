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

fof = sys.argv[1]
outf = sys.argv[2]
bigdf = pd.DataFrame.from_dict({})

plotname = os.path.join(outf, fof.replace('.fof', '.png'))
with open(fof, 'r') as ffof:

    for line in ffof:
        line = line.strip()
        sample_name = line.split('_')[0]
        
        df = pd.read_csv(line, sep=',', header=0,
                         names=['primer','revcomp_right','right','revcomp_left', 'left'])

        df['total'] = df.sum(axis=1)
        
        df2 = df[['primer', 'total']].pivot_table(columns='primer', values='total')
        df2.index = [sample_name]
        
        if bigdf.empty:
            bigdf = df2
        else:
            bigdf = bigdf.append(df2)
        
pltdf = bigdf.groupby(level=0).sum().reset_index()
pltdf = pltdf.set_index('index')
print(pltdf)

## plot stacked
sns.set_style("white")
pltdf.plot(kind='bar', stacked=True, figsize=(15,8),
            title="Primers count on each sample")
plt.legend(loc='best', mode='expand', fontsize=9, ncol=7)
plt.xticks(rotation=90)
plt.tight_layout()
plt.savefig(plotname)
plt.gcf().clear()
