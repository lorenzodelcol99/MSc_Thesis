%$Author: m1gsa00 $
%$Date: 1998/09/09 18:34:43 $
%$Id: reliableMLab.w,v 1.14 1998/09/09 18:34:43 m1gsa00 Exp m1gsa00 $

function transMat=numericTransitionMatrix(transF)
[nr,nbc]=size(transF);
nc=nbc-nr;
%transMat = -transF(:,nc+1:nbc)\transF(:,1:nc);
transMat = -inv(transF(:,nc+1:nbc))*transF(:,1:nc);
if (nc > nr)
transMat=[zeros(nc-nr,nr),speye(nc-nr);transMat];
end
