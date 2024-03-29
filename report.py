#! /usr/bin/python3
import sys
import os
from fpdf import FPDF

fof = sys.argv[1]
out = sys.argv[2]
filename = sys.argv[3]

pdf = FPDF()

## list images
with open(fof, 'r') as image:
    imagelist = image.read().splitlines()
    
    # imagelist is the list with all image filenames
    for image in sorted(imagelist):
    
        pdf.add_page()
        name = os.path.basename(image).replace('.png', '').replace('-', ' ').replace('_', ' ')
        pdf.set_font('Arial', 'B', 16)
        pdf.cell(w=1, txt=name)
        pdf.image(image, y=20, w=190, h=150)
    pdf.output(os.path.join(out, '{}.pdf'.format(filename)), 'F')
