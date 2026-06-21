function nozero = f(xx)
%  This function will take a 2-dimensional matrix, xx,
%   and replace all 0s with NaNs
nozero = xx;
[ii,jj] = find(xx == 0);
for kk = 1:length(ii)
   nozero(ii(kk),jj(kk)) = NaN;
end
