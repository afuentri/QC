# !/usr/env/python

import sys
import xlsxwriter

pre = sys.argv[1]
post = sys.argv[2]

f_pre = open(pre, 'r')
f_post = open(post, 'r')
text = f_post.readlines()
inf = f_pre.readlines()

# Create workbook
workbook = xlsxwriter.Workbook('fastq_stats.xlsx')
worksheet = workbook.add_worksheet()

# Add a bold format to use to highlight cells
bold = workbook.add_format({'bold': True})

worksheet.write('A1', 'Muestra', bold)
worksheet.write('B1', 'numero_lecturas_inicial', bold)
worksheet.write('D1', 'secuencias_baja_calidad_inicial', bold)
worksheet.write('C1', 'numero_lecturas_trim', bold)
worksheet.write('E1', 'secuencias_baja_calidad_trim', bold)
worksheet.write('F1', '% reads eliminadas', bold) 
worksheet.write('G1', 'numero posibles primer dimers', bold)
 
row = 1
col = 0
 
for i in range(0,len(inf),11):
    d = {}
    
    if inf[i + 3].startswith('Filename'):
        inf[i + 3] = inf[i + 3].strip()
        nombre = inf[i + 3].split('\t')[1]
        d['nombre'] = nombre.split('.')[0] #+ '.' + nombre.split('.')[1]
        print d['nombre']
    if inf[i + 6].startswith('Total Sequences'):
        inf[i + 6] = inf[i + 6].strip()
        d['numero_lecturas_inicial'] = inf[i + 6].split('\t')[1]
    if inf[i + 7].startswith('Sequences flagged as poor quality'):
        inf[i + 7] = inf[i + 7].strip()
        d['secuencias_baja_calidad_inicial'] = inf[i + 7].split('\t')[1]
        
        for l in range(0, len(text), 11):
            if text[l + 3].startswith('Filename'):
                text[l + 3] = text[l + 3].strip()
                print text[l + 3].split('\t')[1].split('-')[0]
                if d['nombre'] == text[l + 3].split('\t')[1].split('-')[0]:
        
                    text[l + 6] = text[l + 6].strip()
                    text[l + 7] = text[l + 7].strip()
                    d['numero_lecturas_trim'] = text[l + 6].split('\t')[1] 
                    d['secuencias_baja_calidad_trim'] = text[l + 7].split('\t')[1]
                
                    worksheet.write(row, col, ''.join(d['nombre']))
                    worksheet.write(row, col + 1, d['numero_lecturas_inicial'])
                    worksheet.write(row, col + 2, d['numero_lecturas_trim'])
                    worksheet.write(row, col + 3, d['secuencias_baja_calidad_inicial'])
                    worksheet.write(row, col + 4, d['secuencias_baja_calidad_trim'])
                    worksheet.write(row, col + 5, (1-(int(d['numero_lecturas_trim'])/float(d['numero_lecturas_inicial'])))*100)
                    worksheet.write(row, col + 6, int(d['numero_lecturas_inicial'])-int(d['numero_lecturas_trim'])) 
                    col = 0
                    row += 1
                    break
workbook.close()
f_pre.close()
f_post.close()
                
                    
