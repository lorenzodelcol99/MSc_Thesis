function [B] = solveb(A,alphas, betas,resm,P,n1,q,n,r,m,full_info)
% This function computes the "B" matrix in the policy rule.
% inputs:   A       = "A" matrix in policy rule (feedback part)
%           alphas  = [ alpha_0 alpha_1 ... alpha_r ]
%           betas   = [ beta_0 beta_1 ...beta_r-1 ]
%           P       = matrix for exog. shocks;
%           D       = matrix to take care of different info sets.
%           n1,q,n,r,m = parameters used in model solution
%
% The case considered is that of different information sets.
if full_info==1
dsum = 0.0;
for ii=0:r-1
           dsum = dsum + ((P')^(r-1-ii)) * (betas(:,ii*m+1:(ii+1)*m))';
end;
d = reshape( dsum, n1*m, 1);
Qs = zeros(n1, r*n);         % Qs = [ Q0 Q1 Q2 ... Q(r-1) ]
m1=n-n1;
if m1 == 0
Qs(:,1:n) = alphas(:,1:n1);
else
Qs(:,1:n) = [alphas(:,1:n1) zeros(n1,m1)];
end
 % Q0= alpha0
if m1 == 0
for ii=1:r-1
    Qs(:,ii*n+1:(ii+1)*n) = ( Qs(:,(ii-1)*n+1:ii*n) )*A + ...
                            alphas(:,ii*n1+1:(ii+1)*n1) ;
end;
else
for ii=1:r-1
    Qs(:,ii*n+1:(ii+1)*n) = ( Qs(:,(ii-1)*n+1:ii*n) )*A + ...
                            [alphas(:,ii*n1+1:(ii+1)*n1) zeros(n1,m1)];
end;
end
% Qbars = [ Qbar0 Qbar2 ... Qbar(r-1) ];
%Qbars = zeros(n1,n1*r);
%for ii=0,r-1
%    Qbars(:,ii*n1+1:(ii+1)*n1) = Qs(:,ii*n+1:ii*n+n1);
%end;
qsum = 0.0;
for ii=0:r-1
    qsum = qsum + kron( Qs(:,ii*n+1:ii*n+n1), (P^(r-1-ii))' );
end;
del = -inv(qsum)*d;
B1  = ( reshape(del,m,n1) )';   % since del=vec(B1') and B1 is n1 by m
if n == n1
B   =  B1;
else
B   = [ B1
        zeros(n-n1,m) ];
end

else;
res=0;
%Create the D matrix
disp(' m='); m
for i=1:n1*m
   if resm(i)==0;
   res=res+1;
   end;
end;
m2=m/2;
disp(' m2 = '); m2;
for i=1:n1
    na=0;
    for j=1:m
        na=na+resm((i-1)*m+j);
    end;
naa(i)=na;
end
disp(' naa='); naa
D=zeros(n1*m-res,n1*m);
i=1; jj=1;
for i=1:n1
if naa(i)==m
    D(jj:jj-1+m,m*(i-1)+1:m*(i-1)+m)=eye(m);
    jj=jj+m;
end; 
if naa(i)<m
    for j=1:m2
      if resm(m*(i-1)+j)==1
         D(jj,m*(i-1)+j)=1;
         jj=jj+1;
      end
    end; 
    for j=m2+1:m
       if resm(m*(i-1)+j-m2)==1
         D(jj,m*(i-1)+j)=1;
             else
         D(jj,m*(i-1)+1:m*(i-1)+m)= [P(j-m2,1:m2) P(j,1:m2)];
      end
      jj=jj+1;
    end; 
end
end;
disp('The information matrix D is')
%this old solveb2
dsum = 0.0;
for ii=0:r-1
    dsum = dsum + ((P')^(r-1-ii)) * (betas(:,ii*m+1:(ii+1)*m))';
end;
d = reshape( dsum, n1*m, 1);
d_tilde = D*d;
Qs = zeros(n1, r*n);         % Qs = [ Q0 Q1 Q2 ... Q(r-1) ]
m1=n-n1;
if m1 == 0
Qs(:,1:n) = alphas(:,1:n1) ;   % Q0= alpha0
else
Qs(:,1:n) = [alphas(:,1:n1) zeros(n1,m1) ];   % Q0= alpha0
end
if m1 == 0
for ii=1:r-1
    Qs(:,ii*n+1:(ii+1)*n) = ( Qs(:,(ii-1)*n+1:ii*n) )*A + ...
                            alphas(:,ii*n1+1:(ii+1)*n1) ;
end;
else
for ii=1:r-1
    Qs(:,ii*n+1:(ii+1)*n) = ( Qs(:,(ii-1)*n+1:ii*n) )*A + ...
                            [alphas(:,ii*n1+1:(ii+1)*n1) zeros(n1,m1) ];
end;
end
qsum = 0.0;
for ii=0:r-1
    qsum = qsum + kron( Qs(:,ii*n+1:ii*n+n1), (P^(r-1-ii))' );
end;
temp = D*qsum;
[rtemp,ctemp] = size(temp);
q_tilde1=zeros(rtemp,ctemp-res);
jj=0.0;
for ii = 1:n1*m;
    if resm(:,ii) ==1;
    jj=jj+1;
    q_tilde1(:,jj) = temp(:,ii);
    else;
    end;
end;
del_tilde = -inv(q_tilde1)*d_tilde;

del_tilde1=zeros(n1*m,1);
jj=1;
for ii=1:n1*m;
   if resm(:,ii) ==0;
   del_tilde1(ii,1)=0;
   else
   del_tilde1(ii,1)=del_tilde(jj,1);
   jj=jj+1;
   end;
end;
%del_tilde1
%%%%%%%%%%%%%%%%%%%%    End of part to be modified   %%%%%%%%%%%%%%%%%%%%%

B1  = ( reshape(del_tilde1,m,n1) )';   % since del=vec(B1') and B1 is n1 by m
if n == n1
B   =  B1;
else
B   = [ B1
        zeros(n-n1,m) ];
end
end
