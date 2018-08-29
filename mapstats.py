#! /usr/env/python

import sys
import os
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
sns.set(style="whitegrid")

fhand = sys.argv[1]
path_name1 = os.path.join(os.path.dirname(fhand), 'counts.png')
path_name2 = os.path.join(os.path.dirname(fhand), 'percent.png')

# read flagstat out table and convert colums into numeric
a = pd.read_csv(fhand, sep=',')
a['count_reads_mapped'] = a['count_reads_mapped'].astype(int)
a['percent_reads_mapped'] = a['percent_reads_mapped'].astype(int)

# number of reads mapped
# size a4 paper
plt.figure(figsize=(15,8))
az = sns.barplot(x="file_name", y="count_reads_mapped", data=a)
az.set_xticklabels(az.get_xticklabels(), rotation=90)
plt.tight_layout()
plt.savefig(path_name1)
plt.gcf().clear()

# percent of reads from the total reads which map against the reference
# size a4 paper
plt.figure(figsize=(15,8))
az = sns.barplot(x="file_name", y="percent_reads_mapped", data=a)
az.set_xticklabels(az.get_xticklabels(), rotation=90)
plt.tight_layout()
plt.savefig(path_name2)
plt.gcf().clear()
