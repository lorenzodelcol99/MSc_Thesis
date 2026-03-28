%$Author: m1gsa00 $
%$Date: 1998/09/09 18:34:43 $
%$Id: reliableMLab.w,v 1.14 1998/09/09 18:34:43 m1gsa00 Exp m1gsa00 $

function [j0,pi,a,qout]=numericSqueeze(auxFAuxB,preTransMat)
zeroTol=10^(-10);
%[tmlil,tmia]=numericEliminateInessentialLags(preTransMat);
tm=numericTransitionMatrix(preTransMat);
if(isempty(auxFAuxB))
afab=[];
notafab=speye(auxcols);
else
[auxRows,auxCols]=size(auxFAuxB);
[afab,notafab]=numericExtendToBasis(auxFAuxB);
end;%end if
qout=[afab;notafab];
if(isempty(auxFAuxB))
j0=[];
pi=[];
a=tm;
else
 j0=afab * tm * afab.';
 pi=notafab * tm * afab.';
 a=notafab * tm * notafab.';
end;
