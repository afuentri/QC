# !/usr/env/python

import sys
import xlsxwriter
import os
# add the environment variable 'scripts_repo'
repo = os.environ['scripts_repo']
path_fastq_unifier = os.path.join(repo, 'NGS-tools')
# add the folder of fastq_unifier.py script tothe system to import the script
sys.path.append(path_fastq_unifier)
# import the module
import fastq_unifier

pre = sys.argv[1]
post = sys.argv[2]
# out path must be given
out_path = sys.argv[3]

with open(pre, 'r') as f_pre:
    inf = f_pre.readlines()

with open(post, 'r') as f_post:
    text = f_post.readlines()

# Create workbook
out = os.path.join(out_path, 'fastq_stats.xlsx')

# Error handling
try:
    workbook = xlsxwriter.Workbook(out)
except IOError as e:
    print "I/O error({0}): {1}".format(e.errno, e.strerror)
except:
    print "Unexpected error:", sys.exc_info()[0]
    raise
else:
    worksheet = workbook.add_worksheet()

# Add a bold format to use to highlight cells
bold = workbook.add_format({'bold': True})

worksheet.write('A1', 'Muestra', bold)
worksheet.write('B1', 'numero lecturas inicial', bold)
worksheet.write('D1', 'secuencias baja calidad inicial', bold)
worksheet.write('C1', 'numero lecturas trim', bold)
worksheet.write('E1', 'secuencias baja calidad trim', bold)
worksheet.write('F1', '% lecturas eliminadas', bold) 
worksheet.write('G1', 'numero lecturas eliminadas', bold)

row = 1
col = 0

for i in range(0,len(inf),11):
    d = {}
    
    if inf[i + 3].startswith('Filename'):
        inf[i + 3] = inf[i + 3].strip()
        nombre = inf[i + 3].split('\t')[1]
        nombre_list = [nombre]
        fastq_dict = fastq_unifier.fastq_dictionary(nombre_list)

        d['muestra'] = fastq_dict[nombre]['sample_name'] + '_' + fastq_dict[nombre]['read']
        trimmed_name = fastq_dict[nombre]['trimmed_name']

    if inf[i + 6].startswith('Total Sequences'):
        inf[i + 6] = inf[i + 6].strip()
        d['numero_lecturas_inicial'] = inf[i + 6].split('\t')[1]
    else:
        d['numero_lecturas_inicial'] = 'None'

    if inf[i + 7].startswith('Sequences flagged as poor quality'):
        inf[i + 7] = inf[i + 7].strip()
        d['secuencias_baja_calidad_inicial'] = inf[i + 7].split('\t')[1]
    else:
        d['secuencias_baja_calidad_inicial'] = 'None'

    for l in range(0, len(text), 11):
            
        if text[l + 3].startswith('Filename'):
            text[l + 3] = text[l + 3].strip()
            nombre2 = text[l + 3].split('\t')[1]
            if nombre2 == trimmed_name:
                print 'Found pair %s' %nombre2
                text[l + 6] = text[l + 6].strip()
                text[l + 7] = text[l + 7].strip()
                d['numero_lecturas_trim'] = text[l + 6].split('\t')[1] 
                d['secuencias_baja_calidad_trim'] = text[l + 7].split('\t')[1]
                
                worksheet.write(row, col, ''.join(d['muestra']))
                worksheet.write(row, col + 1, d['numero_lecturas_inicial'])
                worksheet.write(row, col + 2, d['numero_lecturas_trim'])
                worksheet.write(row, col + 3, d['secuencias_baja_calidad_inicial'])
                worksheet.write(row, col + 4, d['secuencias_baja_calidad_trim'])
                worksheet.write(row, col + 5, (1-(int(d['numero_lecturas_trim'])/float(d['numero_lecturas_inicial'])))*100)
                worksheet.write(row, col + 6, int(d['numero_lecturas_inicial'])-int(d['numero_lecturas_trim'])) 
                col = 0
                row += 1
                break
        else:
            d['numero_lecturas_trim'] = 'None'
            d['secuencias_baja_calidad_trim'] = 'None'
            
workbook.close()
