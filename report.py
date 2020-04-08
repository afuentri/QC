#! /usr/bin/python3.5
import sys
from fpdf import FPDF

fof = sys.argv[1]
pdf = FPDF()

## list images
with open(fof, 'r').read().splitlines() as imagelist:
    # imagelist is the list with all image filenames
    for image in imagelist:
        pdf.add_page()
        pdf.image(image,x,y,w,h)
        pdf.output("QC.pdf", "F")
