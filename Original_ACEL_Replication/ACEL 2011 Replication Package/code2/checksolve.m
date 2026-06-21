function [ ] = checksolve(alphas,A,betas,B,rho,P,Ve,n,r,n1,mth,m)

B1=B([1:n1],:);

Qtemp = alphas(:,1:n);
F=(betas(:,[1:m])+Qtemp(:,[1:n1])*B1)*(P^(r-1));
for ii = 1:r-1
   Qtemp = Qtemp*A+alphas(:,ii*n+1:(ii+1)*n);
   F=F+(betas(:,[1:m]+m*ii)+Qtemp(:,[1:n1])*B1)*(P^(r-1-ii));
end;
Qtemp = Qtemp*A+alphas(:,r*n+1:(r+1)*n);

%check accuracy of feedback part
if max(max(abs(Qtemp))) > .7e-6
   Qtemp
   error('fatal (checksolve) feedback matrix is not accurate')
end

idiag=1;
for i=1:mth
   for j=1:mth
      if abs(Ve(i,j)) > .1e-9 & i ~= j
         idiag=0;
      end
   end
end

if m == mth
   if max(max(abs(F))) > .1e-9
      F
      error('fatal (checksolve) feedforward matrix is not accurate')
   end  
elseif m == 2*mth & idiag == 1
   Q=F(:,[1:mth])*rho+F(:,[mth+1:2*mth]);
   if max(max(abs(Q))) > .12e-8 
      Q
      error('fatal (checksolve) feedback matrix is not accurate')
   end
else
   disp('warning (checksolve) check on feedforward part not yet written for this case')
end

   
   


