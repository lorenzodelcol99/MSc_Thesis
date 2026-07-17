%$Author: m1gsa00 $
%$Date: 1998/09/09 18:34:43 $
%$Id: reliableMLab.w,v 1.14 1998/09/09 18:34:43 m1gsa00 Exp m1gsa00 $

function kronMat=numericMapper(bigJ0,bigPi,evMat)
[jrows,jcols]=size(bigJ0);
[evrows,evcols]=size(evMat);
kronMat=(kron(speye(jrows),evMat) - kron(bigJ0.',speye(evrows)))\kron(bigPi.',speye(evrows));
