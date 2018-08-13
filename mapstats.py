#! /usr/env/python

import sys
import os
import pandas as pd
import seaborn as sns
sns.set(style="whitegrid")
import matplotlib.pyplot as plt

fhand = sys.argv[1]
path_name1 = os.path.join(os.path.dirname(fhand), 'counts.png')
path_name2 = os.path.join(os.path.dirname(fhand), 'percent.png')

a = pd.read_csv(fhand, sep=',')

# number of reads mapped
# size a4 paper
plt.figure(figsize=(15,8))
az = sns.barplot(x="file_name", y="counts_reads_mapped", data=a)
plt.savefig(path_name1)
plt.gcf().clear()

# percent of reads from the total reads which map against Norovirus (any ref)
# size a4 paper
plt.figure(figsize=(15,8))
az = sns.barplot(x="file_name", y="percent_reads_mapped", data=a)
plt.savefig(path_name2)
plt.gcf().clear()
