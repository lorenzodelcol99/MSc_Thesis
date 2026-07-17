%$Author: m1gsa00 $
%$Date: 1998/09/09 18:34:43 $
%$Id: reliableMLab.w,v 1.14 1998/09/09 18:34:43 m1gsa00 Exp m1gsa00 $

function [bigv,biglam]=numericSelectLargeIS(tmat,numToComp)
[allv,alllam]=eigs(tmat.',numToComp);
[iv,jv]=find(abs(alllam)>1);
bigv=allv(:,iv).';
biglam=alllam(iv,jv);
