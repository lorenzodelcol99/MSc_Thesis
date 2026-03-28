function [A] = chroot(Q,alpha,n,A1,m)
global m_ alpha_
A=A1;

ik=0;
for ii=1:n
  for jj=1:n
   if abs(Q(ii,jj)) > 1.d-10;ik=1;end
  end
end
if ik==0
  disp(' (chroot) matrix root passed accuracy test')
end

% if A failed the accuracy test, then try to make it more accurate

if ik==1
   x0=zeros(n*n,1);
   for i=1:n
     for j=1:n
     x0((i-1)*n+j)=A(i,j);
     end
   end
   m_=m;
   alpha_=alpha;
   param(1)=1;
%   x = secant('mroot',x0,[],[],param);
   x = secant('mroot',x0,param);
   [f]=mroot(x,param);
   for i=1:n
     for j=1:n
      Q(i,j)=f((i-1)*n+j);
      A(i,j)=x((i-1)*n+j);
     end
   end
%
% check that the attempt to improve accuracy succeeded:
%
   ik=0;
   for ii=1:n
     for jj=1:n
       if abs(Q(ii,jj)) > 1.d-8;ik=1;end
     end
   end

   me=max(abs(eig(A)));
   if me > 1
    s=sprintf(' fatal (chroot) max root of A > 1 in abs val, root = %5.3f',me);
    disp(s)   
    disp(' you have control of the keyboard')
    keyboard
    return
   end

   if ik==1
     disp(' fatal (chroot) matrix root not accurate, even after attempt to improve it')
     Q
     A
     disp(' you have control of the keyboard...')
     keyboard
     return
   end
end
