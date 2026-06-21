function [auxConds,hstar]=numericRightAR(hmat)
fhmat=full(hmat);
oldAuxRows=-1;
[hrows,hcols]=size(hmat);
[auxConds,hstar]=numericShiftRightAndRecord(zeros(0,hcols-hrows),fhmat);
[newAuxRows,ignore]=size(auxConds);
while(oldAuxRows ~= newAuxRows)
oldAuxRows=newAuxRows;
[auxConds,hstar]=numericShiftRightAndRecord(auxConds,numericAnnihilateRows(hstar));
[newAuxRows,ignore]=size(auxConds);
end%end while
if(issparse(hmat))
auxConds=sparse(auxConds);
hstar=sparse(hstar);
end