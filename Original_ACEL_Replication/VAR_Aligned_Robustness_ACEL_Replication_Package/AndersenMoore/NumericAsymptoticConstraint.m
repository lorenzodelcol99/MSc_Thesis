
%$Author: m1gsa00 $
%$Date: 1998/09/09 18:34:43 $
%$Id: reliableMLab.w,v 1.14 1998/09/09 18:34:43 m1gsa00 Exp m1gsa00 $
%this was changed by Riccardo Dicecio

function qmat=numericAsymptoticConstraint(af,ab,hf,nlag)
[hrows,hcols]=size(hf);
[frows,ignore]=size(af);
[brows,ignore]=size(ab);
tm=numericTransitionMatrix(hf);
[j0,pimat,lila,qmat]=numericSqueeze([ab;af],hf);
[nrows,ncols]=size(lila);
[vm,lm]=numericSelectLargeIS(lila,max(nrows,(hcols-hrows)-frows-nlag*hrows+2));
bigOnes=numericEvExtend(j0,pimat,lm,vm,qmat);
%[tmlil,tmia]=numericEliminateInessentialLags(hf);
%[nrows,ncols]=size(tmlil);
%[vm,lm]=numericSelectLargeIS(tmlil,max(nrows,(hcols-hrows)-frows-nlag*hrows+2));
%[nrvm,ncvm]=size(vm);
%bigOnes(1:nrvm,tmia)=vm;
[nrb,nrc]=size(bigOnes);
qmat=[af;bigOnes];

