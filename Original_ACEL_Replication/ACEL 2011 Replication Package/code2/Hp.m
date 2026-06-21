function [g1,g2]=HP(lam)
%    function [g1 g2]=HP(lam)
%  this function returns the key ingredients of the
%  frequency domain version of the HP filter, as a function
%  of lambda (lam).
%  let y(t) denote the data and HP(L) be the two-sided, symmetric filter.
%  then HP(L)*y(t) is the detrended data, with
%
%  HP(L) = H*(1-L)(1-L)(1-1/L)(1-1/L)/[(1-g1*L-g2*L^2)(1-g1/L-g2/L^2)],
%
%  where H = -g2.
%
dscr=.5*sqrt(16-4*(1+4*lam)/lam);
x1=2+dscr;
x2=2-dscr;
ds1=sqrt(x1*x1-4);
th1=.5*(x1+ds1);
if th1*conj(th1) > 1
th1=.5*(x1-ds1);
end
ds2=sqrt(x2*x2-4);
th2=.5*(x2+ds2);
if th2*conj(th2) > 1
th2=.5*(x2-ds2);
end
g1=th1+th2;
g2=-th1*th2;
