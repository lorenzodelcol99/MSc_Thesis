function [derivative,perr]=derivmat(func,line,pars,x,wrt,h,perr)

% returns the derivative of row line, line=1,...,M, of (Mx1) func at the point x,
% and an estimate of the derivative error (in perr)
%        pars = parameters for the function
%        x is the list of variables that the function (func) takes.
%        n_params = number of variables that the function has
%        wrt = indicates "with respect to" which variable we differentiate
%        h = initial estimate of the stepsize used in taking the derivative.
% The algorithm is a multivariable extension of the algorithm presented
% in the "Numerical Recipes in C".
% Written by: Victor Valdivia (Northwestern University)
% Updated for matrix functions by: H. Siu, 1998

NTAB=10;
CON=1.4;
CON2=CON*CON;
BIG=1.0e30;
SAFE=2.0;
a = zeros(NTAB,NTAB);
up=x;
dn=x;

up(wrt) = up(wrt) + h;
dn(wrt) = dn(wrt) - h;
fup = feval(func,pars,up);
fdn = feval(func,pars,dn);
a(1,1) = ( fup(line) - fdn(line) ) / (2.0*h);
perr = BIG;
for i=2:NTAB
   h = h/CON;
   up=x;
   dn=x;
   up(wrt) = up(wrt) + h;
   dn(wrt) = dn(wrt) - h;
   fup = feval(func,pars,up);
   fdn = feval(func,pars,dn);
   a(1,i) = ( fup(line) - fdn(line) ) /(2.0*h);
   fac = CON2;
   for j=2:i
      a(j,i) = ( a(j-1,i)*fac - a(j-1,i-1) ) / (fac-1.0);
      fac = CON2 * fac;
      dum = [ abs(a(j,i) - a(j-1,i))
         abs(a(j,i) - a(j-1,i-1)) ];
      errt = max(dum);
      if errt <= perr
         perr = errt;
         temp = a(j,i);
      end
   end
   if abs(a(i,i) - a(i-1,i-1)) >= SAFE*(perr)
      derivative = temp;break;
   end
end

derivative = temp;
