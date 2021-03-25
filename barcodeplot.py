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
count = sys.argv[2]
outf = sys.argv[3]

def execute(CMD):

    """"""
    subprocess.call([CMD], shell=True)
            


bigdf = pd.DataFrame.from_dict({})
bigdfperc = pd.DataFrame.from_dict({})

plotname = os.path.join(outf, os.path.basename(fof).replace('.fof', '.png'))
plotname2 = os.path.join(outf, os.path.basename(fof).replace('.fof', '-percent.png'))

with open(fof, 'r') as ffof:

    for line in ffof:
        line = line.strip()
        sample_name = os.path.basename(line).split('_')[0]
        sname = '/{}_'.format(sample_name)
        CMD = 'grep -A1 {} {} | head -n2 | tail -n +2'.format(sname, count)
        print(CMD)
        proc = subprocess.Popen(CMD, shell=True, stdout=subprocess.PIPE)
        total_reads = int(proc.communicate()[0].replace(b'\n', b''))
        print(sample_name, total_reads)
                        

        ## extract total number of reads
        df = pd.read_csv(line, sep=',', header=0,
                         names=['adapter','revcomp_right','right','revcomp_left', 'left'])
        
        df.index = [sample_name]
        print(df.head())
        
        df2 = df.copy()
        
        df2['revcomp_right'] = df2['revcomp_right']/total_reads
        df2['right'] = df2['right']/total_reads
        df2['revcomp_left'] = df2['revcomp_left']/total_reads
        df2['left'] = df2['left']/total_reads
        print(df2.head())
        if bigdf.empty:
            bigdf = df
        else:
            bigdf = bigdf.append(df)

        if bigdfperc.empty:
            bigdfperc = df2
        else:
            bigdfperc = bigdfperc.append(df2)

pltdf = bigdf.groupby(level=0).sum().reset_index()
pltdf = pltdf.set_index('index')
print(pltdf.head())

pltdfperc = bigdfperc.groupby(level=0).sum().reset_index()
pltdfperc = pltdfperc.set_index('index')

## plot stacked counts
sns.set_style("white")
pltdf.plot(kind='bar', stacked=True, figsize=(15,8),
            title="Nextera adapter count in different orientations")
plt.xticks(rotation=90)
plt.tight_layout()
plt.savefig(plotname)
plt.gcf().clear()

## plot stacked percent
sns.set_style("white")
pltdfperc.plot(kind='bar', stacked=True, figsize=(15,8),
            title="Nextera adapter percentage in different orientations")
plt.xticks(rotation=90)
plt.tight_layout()
plt.savefig(plotname2)
plt.gcf().clear()
