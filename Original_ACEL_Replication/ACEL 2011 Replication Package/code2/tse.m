 
function [tsecoef] = tse(func1,pars, x)
% Function to find the taylor series expansion of a function
% Written by: V.Valdivia (Economics Department, Northwestern University)
% Date:       Dec, 1993.
 
ans=zeros(length(x));
for ii=1:length(x)
        [ans(ii),err]=deriv(func1,pars,x,ii,0.001);
end
tsecoef=ans(:,1);
 
