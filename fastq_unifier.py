#! /usr/bin/python

import re

print 'This script recognizes the fastq format names to use them as the input of a pipeline. The considerations are that FASTQ names must be inside the universal format of FASTQ files and that the sample name can not contain "_" in it In this case FASTQ names have to be changes (for example replace "_" by "-", though "_" is already the universal separator for the rest of the fields.)'

n = ["sample_1.fastq.gz", "sample_2.fastq.gz", "sample_S_L_R1_001.fastq.gz", "sample_S_L_R2_001.fastq.gz", "sample_1.fastq", "sample_2.fastq", "80195_TGACCA_L007_R1_001.fastq.gz", "80195_TGACCA_L007_R2_001.fastq.gz", "sample.fastq"]

d = {}

for fastq in n:

    d[fastq] = { 'path' : '', 'compressed' : '', 'name_without_extension' : '', 'extension': '', 'sample_name' : '', 'pair' : '', 'mate' : '', 'read' : '', 'lane' : '', 'barcode' : ''}
    
    if fastq.endswith(".gz"):
        d[fastq]['compressed'] = 'True'
        name_without_extension = '.'.join(fastq.split('.')[:-2])
        extension = '.'.join(fastq.split('.')[-2:])
    else:
        d[fastq]['compressed'] = 'False'
        name_without_extension = '.'.join(fastq.split('.')[:-1])
        extension = '.'.join(fastq.split('.')[-1:]) 

    d[fastq]['name_without_extension'] = name_without_extension
    d[fastq]['extension'] = extension
    name_list = name_without_extension.split('_')

    # We expect the first element of our list to be the sample name
    sample_name = name_list[0]
    d[fastq]['sample_name'] = sample_name
    name_list_without_samplename = name_list[1:]
    
    # detect read (R1, R2)
    paired = True
    if 'R1' in name_list_without_samplename:
        inde = name_list_without_samplename.index('R1')
        pair = 'forward'
        mate = (sample_name + '_' + '_'.join(name_list_without_samplename)).replace('R1', 'R2') + '.' + extension
        
    elif 'R2' in name_list_without_samplename:
        inde = name_list_without_samplename.index('R2')
        pair = 'reverse'
        mate = (sample_name + '_' + '_'.join(name_list_without_samplename)).replace('R2', 'R1') + '.' + extension
    elif '1' in name_list_without_samplename:
        inde = name_list_without_samplename.index('1')
        pair = 'forward'
        mate = (sample_name + '_' + '_'.join(name_list_without_samplename)).replace('_1', '_2') + '.' + extension
    elif '2' in name_list_without_samplename:
        inde = name_list_without_samplename.index('2')
        pair = 'reverse'
        mate = (sample_name + '_' + '_'.join(name_list_without_samplename)).replace('_2', '_1') + '.' + extension
        
    else:
        paired = False
        pair = 'single'
        
    d[fastq]['pair'] = pair
    d[fastq]['mate'] = mate
    
    if paired:
        read = name_list_without_samplename[inde]
        d[fastq]['read'] = read
        
    # detect lane and barcode (6 nucleotides)
    for element in name_list_without_samplename:
        if element.startswith('L'):
            lane = element
            d[fastq]['lane'] = lane
        elif re.match('(?=[TCGA]){6}', element):
            barcode = element
            d[fastq]['barcode'] = barcode

print d
        
    
    
