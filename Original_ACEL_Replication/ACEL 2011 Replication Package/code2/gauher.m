function [w,x] = gauher(n)
maxit=10;

w=zeros(n,1);
x=zeros(n,1);

% given n, this routine returns arrays x(1),...,x(n), and w(1),...,w(n) 
% containing the abscissas and weights of the n-point
% Gauss-Hermite quadrature formula. The largest abscissa is returned in
% x(1), the most negative in x(n).
% This was copied from Numerical Recipes.

pim4=pi^(-.25);
eps=3.e-14;
m=(n+1)/2;

for i = 1:m
  if i == 1 
    z=sqrt(2*n+1)-1.85575*((2*n+1)^(-.16667));
   elseif i == 2
    z=z-1.14*(n^.426)/z;
   elseif i == 3
    z=1.86*z-.86*x(1);
   elseif i == 4
    z=1.91*z-.91*x(2);
   else 
    z=2*z-x(i-2);
  end
  
  for its=1:maxit
    p1=pim4;
    p2=0;
    for j=1:n
      p3=p2;
      p2=p1;
      p1=z*sqrt(2/j)*p2-sqrt((j-1)/j)*p3;
    end

    pp=sqrt(2*n)*p2;
    z1=z;
    z=z1-p1/pp;
    if abs(z-z1) <= eps; break ; end
  end
  if its > maxit
     disp('fatal (gauher) maximum iterations exceeded')
     disp('you now have control of the keyboard...')
     keyboard
  end
  
  x(i)=z;
  x(n+1-i)=-z;
  w(i)=2/(pp*pp);
  w(n+1-i)=w(i);
end


