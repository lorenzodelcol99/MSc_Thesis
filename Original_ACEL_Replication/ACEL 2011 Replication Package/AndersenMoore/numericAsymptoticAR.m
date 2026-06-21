%$Author: m1gsa00 $
%$Date: 1998/09/09 18:34:43 $
%$Id: reliableMLab.w,v 1.14 1998/09/09 18:34:43 m1gsa00 Exp m1gsa00 $

function bmat=numericAsymptoticAR(qmat)
[qrows,qcols]=size(qmat);
bmat=-qmat(:,qcols-qrows+1:qcols)\qmat(:,1:qcols-qrows);
