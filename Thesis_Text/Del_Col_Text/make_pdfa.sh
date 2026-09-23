#!/bin/bash
# Converts main.pdf into a PDF/A-2b file named Del_Col_Lorenzo.pdf, ready for
# Uniweb upload. Run this after every recompile of the thesis, from this folder.
set -e
python3 << 'PYEOF'
import pikepdf
pdf = pikepdf.open("main.pdf")
for page in pdf.pages:
    if "/Annots" not in page:
        continue
    for annot in page["/Annots"]:
        f = int(annot.get("/F", 0))
        annot["/F"] = pikepdf.Integer((f | 4) & ~2 & ~32)  # mark printable, unhide
pdf.save("main_printable.pdf")
PYEOF
gs -dPDFA=2 -dBATCH -dNOPAUSE -dNOOUTERSAVE -dPDFACompatibilityPolicy=1 \
   -sColorConversionStrategy=UseDeviceIndependentColor -sProcessColorModel=DeviceRGB \
   -sDEVICE=pdfwrite -sOutputFile=Del_Col_Lorenzo.pdf main_printable.pdf
rm -f main_printable.pdf
echo "Done: Del_Col_Lorenzo.pdf"
