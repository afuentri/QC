# !/usr/env/python

import sys
import xlsxwriter

pre = sys.argv[1]
post = sys.argv[2]
qual = sys.argv[3]

f_pre = open(pre, 'r')
f_post = open(post, 'r')
f_qual = open(qual, 'r')

text = f_post.readlines()
text2 = f_qual.readlines()
inf = f_pre.readlines()

# Create workbook
workbook = xlsxwriter.Workbook('fastq_stats+qual.xlsx')
worksheet = workbook.add_worksheet()

# Add a bold format to use to highlight cells
bold = workbook.add_format({'bold': True})
format.set_align('right')

worksheet.write('A1', 'Muestra', bold)
worksheet.write('B1', 'numero_lecturas_inicial', bold)
worksheet.write('D1', 'numero_lecturas_qualfilter', bold)
worksheet.write('C1', 'numero_lecturas_trim', bold)
worksheet.write('F1', '% reads eliminadas qualfilter', bold)
worksheet.write('E1', '% reads eliminadas trimming', bold) 
worksheet.write('G1', 'numero posibles primer dimers', bold)
 
row = 1
col = 0
 
for i in range(0,len(inf),11):
    d = {}
    
    if inf[i + 3].startswith('Filename'):
        inf[i + 3] = inf[i + 3].strip()
        nombre = inf[i + 3].split('\t')[1]
        d['nombre'] = nombre.split('-')[:1]
    if inf[i + 6].startswith('Total Sequences'):
        inf[i + 6] = inf[i + 6].strip()
        d['numero_lecturas_inicial'] = inf[i + 6].split('\t')[1]
            
        for j in range(0, len(text2), 11):
            if text2[j + 3].startswith('Filename'):
                text2[j + 3] = text2[j + 3].strip()
                if d['nombre'] == text2[j + 3].split('\t')[1].split('-')[:1]:
                    text2[j + 6] = text2[j + 6].strip()
                    d['numero_lecturas_qualfilter'] = text2[j + 6].split('\t')[1]

        for l in range(0, len(text), 11):
            if text[l + 3].startswith('Filename'):
                text[l + 3] = text[l + 3].strip()
                
                if d['nombre'] == text[l + 3].split('\t')[1].split('-')[:1]:
        
                    text[l + 6] = text[l + 6].strip()
                    
                    d['numero_lecturas_trim'] = text[l + 6].split('\t')[1] 
                    
                
                    worksheet.write(row, col, ''.join(d['nombre']))
                    worksheet.write(row, col + 1, d['numero_lecturas_inicial'])
                    worksheet.write(row, col + 2, d['numero_lecturas_trim'])
                    worksheet.write(row, col + 3, d['numero_lecturas_qualfilter'])
                    worksheet.write(row, col + 4, (1-(int(d['numero_lecturas_trim'])/float(d['numero_lecturas_inicial'])))*100)
                    worksheet.write(row, col + 5, (1-(int(d['numero_lecturas_qualfilter'])/float(d['numero_lecturas_inicial'])))*100)
                    worksheet.write(row, col + 6, int(d['numero_lecturas_inicial'])-int(d['numero_lecturas_trim'])) 
                    col = 0
                    row += 1
                    break
                
workbook.close()
f_pre.close()
f_post.close()
                
                    
