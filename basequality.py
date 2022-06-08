#! /usr/bin/python3.5
import sys
import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import seaborn as sns
import numpy as np
import pandas as pd
print(pd.__version__)

def calcQual(f):

    """Obtain sequencing qualities dictionary"""
    dqual = {}
    with open(f, 'r') as fqual:
        init = False
        for q in fqual:
            if q.startswith('>>Per base sequence quality'):
                init = True
                continue
            if init:
                if not q.startswith('>>'):
                    if not q.startswith('#'):
                        q = q.strip()
                        base = q.split('\t')[0]
                        meanqual = q.split('\t')[1]
                        if '-' in base:
                            start, end = base.split('-')
                            for j in range(int(start), int(end) + 1):
                                dqual[j] = meanqual
                        else:
                             dqual[base] = meanqual
                else:
                    init = False

    return dqual

## FOF FILES FOR FASTQ_STATS.TXT (FASTQC PARSER) ##
prefof = sys.argv[1]
postfof = sys.argv[2]
out = sys.argv[3]

## initialize matplotlib
#sns.set_style('white')
sns.set_style('ticks')
sns.set_context('notebook')
sns.set(font_scale=2)
tt = 'Mean base quality per sample'
plotn = os.path.join(out, 'meanseqqual_sample.png')

fig, (ax1, ax2) = plt.subplots(1, 2, sharey=True, figsize=(20, 10))
sns.despine(ax=ax1, offset=10)
sns.despine(ax=ax2, offset=10)

ax1.set(ylim=(0, 40))
ax2.set(ylim=(0, 40))
ax1.set_xlim(right=150)
ax2.set_xlim(right=150)

## initialize pretrimming qualities loop
with open(prefof, 'r') as fpre:

    fl = fpre.read().splitlines()
    for s in fl:
        if fl != '':
            dqual = calcQual(s)

            ## dictionary to dataframe
            df = pd.DataFrame.from_dict(dqual, orient='index', columns=['qual']).reset_index().dropna()
            df.columns = ['base', 'qual']
            df['qual'] = df['qual'].astype(float)
            df['base'] = df['base'].astype(int)
            df = df.sort_values('base')
            ax1.plot(df['base'], df['qual'], color='#74c2b4', lw=1.6)

with open(postfof, 'r') as fpost:

    fo = fpost.read().splitlines()
    for t in fo:
        if fo != '':
            dqual = calcQual(t)
            ## dictionary to dataframe
            df = pd.DataFrame.from_dict(dqual, orient='index', columns=['qual']).reset_index().dropna()
            df.columns = ['base', 'qual']
            df['qual'] = df['qual'].astype(float)
            df['base'] = df['base'].astype(int)
            df = df.sort_values('base')
            if sum(df['base'] > 140) == 0:
                print(df)
            ax2.plot(df['base'], df['qual'], color='#ed728a', lw=1.6)
    

ax1.set_title('Pretrimming')
ax2.set_title('Postrimming')
ax1.set_xlabel('Base position in read')
ax2.set_xlabel('Base position in read')
ax1.set_ylabel('Quality score')
ax2.set_ylabel('Quality score')

fig.suptitle(tt)
#plt.tight_layout()
plt.savefig(plotn)
plt.gcf().clear()
