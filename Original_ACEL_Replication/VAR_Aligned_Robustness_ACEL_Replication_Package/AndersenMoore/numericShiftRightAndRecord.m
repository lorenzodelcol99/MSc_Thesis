function [ultimateAuxConds,shiftedHmat] = numericShiftRightAndRecord(auxConds,unshiftedHmat)
[hrows,hcols]=size(unshiftedHmat);
shiftedHmat=zeros(hrows,hcols);
rowsNow=0;
ultimateAuxConds=zeros(hcols-hrows,hcols-hrows); 
zeroTol=10^(-10)*hrows;
for i = 1:hrows
if(norm(unshiftedHmat(i,:))<zeroTol) 
error('zero row for hmat')
end;%if
while(numericRightMostAllZeroQ(hrows,unshiftedHmat(i,:)))
rowsNow=rowsNow+1;
ultimateAuxConds(rowsNow,:)=unshiftedHmat(i,1:hcols-hrows);
unshiftedHmat(i,:)=[zeros(1,hrows),unshiftedHmat(i,1:hcols-hrows)];
end; %end while
shiftedHmat(i,:)=unshiftedHmat(i,:);
end;%for,
ultimateAuxConds=[auxConds;ultimateAuxConds(1:rowsNow,:)];
