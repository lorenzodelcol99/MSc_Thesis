%$Author: m1gsa00 $
%$Date: 1998/09/09 18:34:43 $
%$Id: reliableMLab.w,v 1.14 1998/09/09 18:34:43 m1gsa00 Exp m1gsa00 $

function bigEvecs=numericEvExtend(bigJ0,bigPi,evMat,yMat,qmat)
[jrows,jcols]=size(bigJ0);
[evrows,evcols]=size(evMat);
[yrows,ycols]=size(yMat);
numericMapper(bigJ0,bigPi,evMat);
if(jrows>0)
kronMat=(kron(speye(jrows),evMat) - kron(bigJ0.',speye(evrows)))\kron(bigPi.',speye(evrows));
xMat=reshape(kronMat * reshape(yMat,yrows*ycols,1),yrows,jcols);
bigEvecs=[xMat,yMat]*qmat;
else
bigEvecs=yMat*qmat;
end;
