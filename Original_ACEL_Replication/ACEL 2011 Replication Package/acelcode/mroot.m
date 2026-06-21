function [f] = mroot(x0,param)
global m_ alpha_
n=sqrt(length(x0));
alpha=alpha_;
m=m_;
if round(n) ~= n,
   disp(' fatal (mroot) input matrix not square')
   return
end
for i=1:n
  for j=1:n
  A(i,j)=x0((i-1)*n+j);
  end
end
Q=alpha(:,[1:n]);
for i=1:m
   Q=Q*A+alpha(:,[i*n+1:i*n+n]);
end
f=zeros(n*n,1);
for i=1:n
   for j=1:n
   f((i-1)*n+j)=Q(i,j);
  end
end

