function [tsecoef] = tsemat(func,pars,x)

% Function to find the taylor series expansion of a matrix function

% Written by: V.Valdivia (Economics Department, Northwestern University)

% Date:       Dec, 1993.
% Updated for matrix functions by H. Siu, Aug, 1998.


f = feval(func,pars,x);
dim = length(f);

for i = 1:dim
   for ii=1:length(x)
      [tsecoef(ii,i),err]=derivmat(func,i,pars,x,ii,1e-4);
   end
end

 

