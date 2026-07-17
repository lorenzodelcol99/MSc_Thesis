function [A]=feedback(alphas,beta,n1,q,n,r)
% This function solves for the "A" matrix in the policy rule.
% inputs:   alphas   = [ alpha_0 alpha_1 ... alpha_r ]
%           beta     = parameter of the model.
%           n1,q,n,r = paramameters used in the model solution.
%
% The basic method to solve for this "A" matrix is to consider the equation:
%  a*y(t+1)+b*y(t)=0, where y(t) is n*m by 1, and "a", "b" are n*m by n*m.
% if "a" is nonsingular, then we consider the matrix: PIE = -inv(a)*b
% if "a" is singular, then the QZ MATLAB function, and the QZDIV.M and 
% QZSWITCH.M files (by Sims) are used.
m = (r-1)*n1+n;
%Get "a" matrix from the alphas. 
a=eye(m);
a(1:n1,1:n1) = alphas(:,1:n1);
if rank(a) == 0,
   disp(' fatal(feedback) alpha(0) zero rank')
   disp(' try dropping the value of m')
   disp(' hit any key to continue ...')
   pause
   break
end
%Get "b" matrix from the alphas:
topb = zeros(n1,m);             
% topb will hold top n1 rows of b matrix
for ii=1:r-1
	topb(:,(ii-1)*n1+1:ii*n1) = alphas(:,ii*n1+1:ii*n1+n1);
end;
topb(:,(r-1)*n1+1:m) = alphas(:,r*n1+1:r*n1+n); 
if m == n1
b = [ topb
	  -eye(m-n1) ];
else
b = [ topb
	  -eye(m-n1)  zeros(m-n1,n1) ];
end
K = rank(a);
if K < m,
	% This is the case where "a" is singular and requires the QZ decomposition
	% to remove the singularity.
	%   q*a*z = H0, q*b*z = H1
	%   where:  q, z are orthonormal. H0 and H1 are upper triangular.
	%
	[H0,H1,q,z,v]=qz(a,b);
	%re-order matrices:
	stake=1000000000;
	[H0,H1,q,z] = qzdiv(stake,H0,H1,q,z);
	zz  = z';
	L1  = zz([1:K],:);
	L2  = zz([K+1:m],:);
	g0  = H0([1:K],[1:K]);
	g1  = H1([1:K],[1:K]);
	gg  = H1([K+1:m],[K+1:m]);
	if rank(gg) ~= m - K,
		disp(' fatal (feedback) bottom right block in H1 not full rank')
		disp(' press any key to continue ...')
		pause
	break
	end
	PIE = -g0\g1;
else    % This is the case where "a" is nonsingular.
	PIE = -a\b;
end
% Perform eigenvalue, eigenvector decomposition and search for 
% explosive eigenvalues:
[V,Dd] = eig(PIE);
rt = diag(Dd);
num_exp = 0;          % number of explosive eigenvalues
tt = [];
db = 1/sqrt(beta);    % criterium for explosiveness
db = 1;
for ii = 1:length(rt)
  if abs(rt(ii)) >= db
   num_exp = num_exp + 1;
   tt(num_exp) = ii;
  end
end
% num_need = number of explosive eigenvalues needed: 
num_need = K-n;
if num_exp < num_need
  disp(' fatal (feedback) too few unstable roots')
  disp(['Need: ',num2str(num_need),' explosive roots']);
  disp(['Found: ',num2str(num_exp),' explosive roots']);
  disp(' hit any key to continue ...')
  pause
  break
end
if num_exp > num_need
  disp(' fatal (feedback) too many unstable roots')
  disp(['Need: ',num2str(num_need),' explosive roots']);
  disp(['Found: ',num2str(num_exp),' explosive roots']);
  disp(' hit any key to continue ...')
  pause
  break
end
VI  = inv(V);
p   = VI(tt,:);
if (m-K) > 0
  D = [ p*L1
		L2  ];
else
  D = p;
end

D1  = D(:,[1:n1*(r-1)]);
D2  = D(:,[n1*(r-1)+1:m]);
Dec = -(D1\D2);
if n == n1
A   = [ real( Dec([n1*(r-1)-n1+1: n1*(r-1)],:) )
		eye(n-n1)  ];
else
A   = [ real( Dec([n1*(r-1)-n1+1: n1*(r-1)],:) )
		eye(n-n1) zeros(n-n1,n1) ];
end
% check eigenvalues of A matrix:         
eigsA = eig(A);
error = 0;
for ii=1:length(eigsA)
   if abs(eigsA(ii)) >= db
      disp('Eigenvalue of A matrix exceeds 1');
		error = 1;
		pause;
		break;
	end;
end;
% check polynomial alpha(A). It should be a zero matrix:
alphaA = zeros(n1,n);
m1=n-n1;
if m1 == 0
for ii=0:r-1
    alphas1(:,ii*n1+1:ii*n1+n)=[alphas(:,ii*n1+1:ii*n1+n1) ];
     alphaA = alphaA + alphas1(:,ii*n1+1:ii*n1+n) * (A^(r-ii));
end;
else
for ii=0:r-1
    alphas1(:,ii*n1+1:ii*n1+n)=[alphas(:,ii*n1+1:ii*n1+n1) zeros(n1,m1)];
     alphaA = alphaA + alphas1(:,ii*n1+1:ii*n1+n) * (A^(r-ii));
end;
end
ii=r;
    alphas1(:,ii*n1+1:ii*n1+n)=alphas(:,ii*n1+1:ii*n1+n);
    alphaA = alphaA + alphas1(:,ii*n1+1:ii*n1+n) * (A^(r-ii));
alphaA;
disp('Checking accuracy of feedback matrix...');
%disp('The following matrix should be close to the zero matrix:')
%disp(alphaA);
% estimate of "size" of elements of "A" matrix:
if ( (ones(1,n1*n)*reshape(alphaA,n1*n,1)>0.00001) | error==1 )
	disp('A matrix failed accuracy test');
	pause;
	break;
else
	disp('A matrix passed accuracy test');
end;
