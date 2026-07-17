%$Author: m1gsa00 $
%$Date: 1998/09/09 18:34:43 $
%$Id: reliableMLab.w,v 1.14 1998/09/09 18:34:43 m1gsa00 Exp m1gsa00 $

function [orig,extension]=numericExtendToBasis(matRows)
zeroTol=10^(-10);
[nrows,ncols]=size(matRows);
v=orth([full(matRows);eye(ncols)]');
orig=v(:,1:nrows)';%assuming full rank
extension=(v(:,nrows+1:ncols))';%assuming full rank
