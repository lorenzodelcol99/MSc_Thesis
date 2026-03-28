function [B,P] = solveb(A,alphas,betas,rho,tau,Ve)
%*****************************************************************************
%        [B,P] = solveb(A,alphas,betas,rho,tau,Ve)
%Inputs:
%
% A:  the nXn matrix that characterizes the feedback part of the policy rule
%
%The elements of the linearized Euler equations:
%
% alphas:  [alpha_0,alpha_1,...,alpha_r], a n1X(r+1)*n matrix
% betas:   [beta_0,beta_1,...,beta_r-1], a n1Xr*mt matrix
%
%The input betas are constructed under the assumption, s(t)=th(t).
%This assumption is modified later if the program determines this is appropriate.
%
%The exogenous shocks satisfy the following time series representation:
%
%    th(t) = rho*th(t-1) + e(t), E[e(t)e(t)']=Ve,
%
%where e(t) is an mthX1 vector of iid shocks and Ve is mthXmth, symmetric, 
%and positive semidefinite.
%
%tau:  [tau1,tau2,...,taui,...,taun1], a mthXn1 matrix composed of 0's or 1's
%
%Element j of taui = 0 if the jth element of th(t) is not included in the
%information set of equation i.  Since the endogenous variables of B must 
%be ordered to correspond to these info sets, this also corresponds to the
%restriction that variable i in z1(t) can't respond to the jth shock at 
%time t.  Here, z1(t) is the n1X1 vector of endogenous variables.  Thus, if
%there is a restriction on the ith variable in z1(t), the Eulers must be
%ordered so that this variable's corresponding Euler is the ith equation as 
%well.  The vector taui then should reflect this restriction.
%
%We distinguish the following two conditions:
% (a) If only the first four arguments (A, alphas, betas, and rho) of solveb are present,
%     then the B corresponding to the full information case is returned, and m=mth.  
% (b) If only the first five arguments of solveb are present, Ve is assumed to be diagonal.
% (c) If solveb has five or six arguments and if some element in tau is zero,
%     then m=2*mth. Otherwise, m=mth.%
%
% Outputs:
%
%  B: The nXm 'feedforward' matrix B in the policy rule.  
%  P: The mXm matrix:
%
%       s(t) = P*s(t-1)+e(t)
%
%  where s(t) is th(t) if m=mth, and [th(t)',th(t-1)']' if m=2*mth.
%*****************************************************************************
if ~(nargin == 4 | nargin == 5 | nargin == 6)
   sprintf('fatal (solveb) number of inputs into solveb = %d',nargin)
   error('fatal (solveb) Wrong number of inputs into solveb');
end;

%get values of n, r, n1, mth:
dim_of_A = size(A);
dim_of_alphas = size(alphas);
n = dim_of_A(1);  n1 = dim_of_alphas(1);
r = dim_of_alphas(2)/n-1;
dim_of_rho = size(rho);
if dim_of_rho(1) ~= dim_of_rho(2)
   disp('rho=')
   rho
   error('fatal (solveb) rho is not a square matrix.');
end;
mth = dim_of_rho(1);

%check dimensions of betas
dim_of_betas = size(betas);
if dim_of_betas(1) ~= n1
   disp('dimension of betas = ')
   dim_of_betas
   disp('n1 = ')
   n1
   error('fatal (solveb) left dimension of betas and alphas not the same');
end;
if dim_of_betas(2)/r ~= mth
   error('fatal (solveb) column dimension of betas misspecified')
end

m=mth;
ichange=0;
%Adjust the betas if we're interested in limited information
%Also, if no Ve is provided, set one up. Otherwise, verify that Ve is ok.
if nargin == 5 | nargin == 6
   %See if tau correctly specified
   dim_of_tau = size(tau);
   if dim_of_tau(1) ~= mth
      disp('tau = ')
      tau
      error('fatal (solveb) number of rows of tau misspecified.');
    end;
    if dim_of_tau(2) ~= n1
      error('fatal (solveb) number of columns of tau misspecified.');
    end;

    %Make sure tau consists only of 0's or 1's
    if any(any(~(tau == 0 | tau == 1)))
       disp('tau = ')
       tau
       error('fatal (solveb) tau must consist only of 0s or 1s.');
    end;

    sumtau = sum(sum(tau));
    if sumtau < mth*n1  
       betta=zeros(n1,2*mth*r);
       ichange = 1;
       m=2*mth;
       for ii=1:r
          betta(:,1+(ii-1)*2*mth:ii*2*mth)=[betas(:,1+(ii-1)*mth:ii*mth),zeros(n1,mth)];
       end
       betas=betta;
    end    
        
    if nargin == 5
       Ve = eye(mth,mth);
    else
       dim_of_Ve = size(Ve);
       if any((dim_of_Ve ~= mth))
          disp('Ve = ')
          Ve
          error('fatal (solveb) Ve dimensions misspecified.');
       end
       if any(any((Ve ~= Ve')))
          disp('Ve = ')
          Ve
          error('fatal (solveb) Ve is not symmetric.');
       end;
       if min(eig(Ve)) < 0
          error('fatal (solveb) Ve not positive semi definite')
       end    
    end
end
         
if m == mth
   P = rho;
else
   P = [rho zeros(mth,mth); eye(mth) zeros(mth,mth)];
end

%Construct d and q matrices in d+q*vec(B') = 0

dsum = 0;
q = 0;

for ii = 0:r-1
  dsum = dsum + ((P')^(r-1-ii)*(betas(:,ii*m+1:(ii+1)*m))');
  if ii == 0, Qtemp = alphas(:,1:n);
  else, Qtemp = Qtemp*A+alphas(:,ii*n+1:(ii+1)*n);  end;
  q = q + kron(Qtemp(:,1:n1),(P^(r-1-ii))');
end;


d = reshape(dsum,n1*m,1);

%Calculate vec(B') under full info
del = -q\d;


if ichange == 1
   %Solve for del in partial info case
   
   [R,ind1] = solver(tau,rho,Ve);
   
   qtilde = R*q;
   del_bar = -(qtilde(:,ind1)\R*d);
   del = zeros(n1*m,1);  del(ind1) = del_bar;
end;  %end of partial info case

%Form B
B1 = reshape(del,m,n1)';
if n == n1, 
   B = B1;
else 
   B = [B1; zeros(n-n1,m)];  
end;

if max(max(isnan(B))) > 0
   error('fatal (solveb) solveb failed to solve for B')
end

checksolve(alphas,A,betas,B,rho,P,Ve,n,r,n1,mth,m)


