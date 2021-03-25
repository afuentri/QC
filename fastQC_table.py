# !/usr/env/python

import sys
import xlsxwriter
import os
# add the environment variable 'scripts_repo'
repo = os.environ['scripts_repo']
path_fastq_unifier = os.path.join(repo, 'NGS-tools')
# add the folder of fastq_unifier.py script to the system to import the script
sys.path.append(path_fastq_unifier)
# import the module
import fastq_unifier

pre_folder = sys.argv[1]
pre = os.path.join(pre_folder, 'fastqs_stats.txt')
pre_quality = os.path.join(pre_folder, 'FAILED_per-base-sequence-quality.txt')
post_folder = sys.argv[2]
post = os.path.join(post_folder, 'fastqs_stats.txt')
post_quality = os.path.join(post_folder, 'FAILED_per-base-sequence-quality.txt')
# out path must be given
out_path = sys.argv[3]
folder_fastqs = sys.argv[4]

with open(pre, 'r') as f_pre:
    inf = f_pre.readlines()

with open(post, 'r') as f_post:
    text = f_post.readlines()

with open(pre_quality, 'r') as f_preq:
    infq = f_preq.read().splitlines()

with open(post_quality, 'r') as f_postq:
    textq = f_postq.read().splitlines()

# Create workbook
out = os.path.join(out_path, 'fastq_stats.xlsx')

# Error handling
try:
    workbook = xlsxwriter.Workbook(out)
except IOError as e:
    print("I/O error({0}): {1}".format(e.errno, e.strerror))
except:
    print("Unexpected error:", sys.exc_info()[0])
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
failed_pre = []
failed_post = []

for i in range(0,len(inf),11):
    d = {}
    
    if inf[i + 3].startswith('Filename'):
        inf[i + 3] = inf[i + 3].strip()
        nombre = inf[i + 3].split('\t')[1]
        nombre_list = [nombre]
        fastq_dict, extensions, sample_name_dict, sample_name_read_dict, merged, pairs_raw, pairs_trimmed, trimming, trim_dict = fastq_unifier.fastq_dictionary(nombre_list, folder_fastqs)
        d['muestra'] = fastq_dict[nombre]['sample_name'] + '_' + fastq_dict[nombre]['read']
        trimmed_name = fastq_dict[nombre]['trimmed_name']
        if nombre in infq:
            failed_pre.append(d['muestra'])
        

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
                print('Found pair %s' %nombre2)
                text[l + 6] = text[l + 6].strip()
                text[l + 7] = text[l + 7].strip()
                d['numero_lecturas_trim'] = text[l + 6].split('\t')[1] 
                d['secuencias_baja_calidad_trim'] = text[l + 7].split('\t')[1]
                if nombre2 in textq:
                    failed_post.append(d['muestra'])

                # add colour to cells following quality conditions
                ## red
                format1 = workbook.add_format({'bg_color': '#FFC7CE', 'font_color': '#9C0006'})
                ## green
                format2 = workbook.add_format({'bg_color': '#C6EFCE', 'font_color': '#006100'})
                ## orange
                format3 = workbook.add_format({'bg_color': '#ffc24e', 'font_color': '#d48b00'})
                ## yellow
                format4 = workbook.add_format({'bg_color': '#ffe85d', 'font_color': '#a39c0a'})

                # sample_name
                if d['muestra'] in failed_pre and d['muestra'] not in failed_post:
                    worksheet.write(row, col, ''.join(d['muestra']), format4)
                elif d['muestra'] in failed_post and d['muestra'] not in failed_pre:
                    worksheet.write(row, col, ''.join(d['muestra']), format3)
                elif d['muestra'] in failed_post and d['muestra'] in failed_pre:
                    worksheet.write(row, col, ''.join(d['muestra']), format1)
                else:
                    worksheet.write(row, col, ''.join(d['muestra']))

                # number of total reads
                if int(d['numero_lecturas_inicial']) < 1000:
                    worksheet.write(row, col + 1, d['numero_lecturas_inicial'], format1)
                else:
                    worksheet.write(row, col + 1, d['numero_lecturas_inicial'])
                if int(d['numero_lecturas_trim']) < 1000:
                    worksheet.write(row, col + 2, d['numero_lecturas_trim'], format1)
                else:
                    worksheet.write(row, col + 2, d['numero_lecturas_trim'])

                # low quality sequences (fastqs_stats.txt parsing)
                worksheet.write(row, col + 3, d['secuencias_baja_calidad_inicial'])
                worksheet.write(row, col + 4, d['secuencias_baja_calidad_trim'])

                # percent of reads removed
                percent_reads_removed = (1-(int(d['numero_lecturas_trim'])/float(d['numero_lecturas_inicial'])))*100
                if percent_reads_removed >= 10.0 and percent_reads_removed < 30.0:
                    worksheet.write(row, col + 5, percent_reads_removed, format4)
                elif percent_reads_removed >= 30.0 and percent_reads_removed < 50.0:
                    worksheet.write(row, col + 5, percent_reads_removed, format3)
                elif percent_reads_removed >= 50.0:
                    worksheet.write(row, col + 5, percent_reads_removed, format1)
                else:
                    worksheet.write(row, col + 5, percent_reads_removed)
                # column count of reads removed
                worksheet.write(row, col + 6, int(d['numero_lecturas_inicial'])-int(d['numero_lecturas_trim']))
                
                col = 0
                row += 1
                break
        else:
            d['numero_lecturas_trim'] = 'None'
            d['secuencias_baja_calidad_trim'] = 'None'
            
workbook.close()
