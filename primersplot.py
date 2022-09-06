#! /usr/bin/python3.5                                                                                                                                                                                 

## import modules                                                                                                                                                                                        
import os
import matplotlib
matplotlib.use('Agg')
import pandas as pd
import seaborn as sns
import numpy as np
import sys
import subprocess
import scipy.stats as stats
sns.set(style="whitegrid")
import matplotlib.pyplot as plt

fof = sys.argv[1]
count=sys.argv[2]
outf = sys.argv[3]

bigdf = pd.DataFrame.from_dict({})
bigdfperc = pd.DataFrame.from_dict({})

plotname = os.path.join(outf, os.path.basename(fof).replace('.fof', '.png'))
plotname2 = os.path.join(outf, os.path.basename(fof).replace('.fof', '-percent.png'))

with open(fof, 'r') as ffof:

    for line in ffof:
        line = line.strip()
        sample_name = os.path.basename(line).split('_')[0]

        CMD = 'grep -A1 {} {} | head -n2 | tail -n +2'.format(sample_name, count)
        proc = subprocess.Popen(CMD, shell=True, stdout=subprocess.PIPE)
        total_reads = int(proc.communicate()[0].replace(b'\n', b''))

        ## extract total number of reads
        df = pd.read_csv(line, sep=',', header=0,
                         names=['primer', 'revcomp_right', 'right',
                                'revcomp_left', 'left'])

        df['total'] = df.sum(axis=1)
        
        df2 = df[['primer', 'total']].pivot_table(columns='primer', values='total')
        df2.index = [sample_name]
        
        df3 = df2.copy()
        df3 = df3/total_reads
                
        if bigdf.empty:
            bigdf = df2
        else:
            bigdf = bigdf.append(df2)

        if bigdfperc.empty:
            bigdfperc = df3
        else:
            bigdfperc = bigdfperc.append(df3)
            
pltdf = bigdf.groupby(level=0).sum().reset_index()
pltdf = pltdf.set_index('index')

pltdfperc = bigdfperc.groupby(level=0).sum().reset_index()
pltdfperc = pltdfperc.set_index('index')

## plot stacked counts
sns.set_style("white")
sns.set(font_scale=2)
pltdf.plot(kind='bar', stacked=True, figsize=(15,8),
            title="Primers count on each sample")
plt.legend(loc='best', mode='expand', fontsize=9, ncol=7)
plt.xticks(rotation=90)
plt.ylabel('counts')
plt.tight_layout()
plt.savefig(plotname, dpi=500)
plt.gcf().clear()

## plot stacked percent
sns.set_style("white")
sns.set(font_scale=2)
pltdfperc.plot(kind='bar', stacked=True, figsize=(15,8),
            title="Primers percentage on each sample")
plt.legend(loc='best', mode='expand', fontsize=9, ncol=7)
plt.xticks(rotation=90)
plt.ylabel('frequency')
plt.tight_layout()
plt.savefig(plotname2, dpi=500)
plt.gcf().clear()
