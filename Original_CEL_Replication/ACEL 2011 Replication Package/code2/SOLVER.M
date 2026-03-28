function [R,ind1] = solver(tau,rho,Ve)
%Solver:  Solve for the matrix R used to compute the matrix, B, in the case
%where there is partial information.
%
%R is a (n1*mth+m1+m2+...+mn1)Xm*n1 matrix where m = 2*mth. R is defined by
%
%  vec_bar(F_tilde') = R*vec(F')
%
%where vec_bar removes the zero restrictions from F_tilde'.
%
%ind1 indexes the non-zero restrictions in vec(B'). It also
%indexes these non-zeros in vec(F_tilde') due to the requirement
%that the ordering of z1(t) corresponds to the ordering of the equations.
%
%Inputs:
%
%tau:  a mthXn1 matrix containing 1s or 0s indicating whether a variable in
%th(t) is included in the info sets for equations, i = 1,2,...,n1.
%
% (rho, Ve) are mthXmth matrices given by
%
%  th(t) = rho*th(t-1) + e(t)
%
%  Ve = E(e(t)*e(t)')
%
%mth:  no. of variables in th(t)
%mi:  no. of 1's in tau(i) where i = 1,2,...,n1
%n1:  no. of endogenous equations or variables in z1(t)
%m:  no. of variables in s(t);

%Determine mth,n1,m
[mth,n1] = size(tau);  m = 2*mth;

%Form C matrix, C = E(th(t)*th(t)')
 
vecVe = reshape(Ve,mth*mth,1);

vecC = (eye(mth*mth)-kron(rho,rho))\vecVe;

C = reshape(vecC,mth,mth);

R = [];  ind1 = [];
for ii = 1:n1
  indi = find(tau(:,ii));
  indtemp = [indi+2*(ii-1)*mth; ((2*ii-1)*mth+1:2*ii*mth)'];
  mi = length(indi);
  if mi == mth
     Rtemp = zeros(m,n1*m);
     Rtemp(:,(ii-1)*m+1:ii*m) = eye(m);
  elseif mi == 0
    Rtemp = zeros(mth,n1*m);
    Rtemp(:,(ii-1)*m+1:ii*m) = [rho eye(mth)];
  else
    Ri = eye(mth);  Ri = Ri(indi,:);
    PHI = [Ri*C*Ri' Ri*rho*C; C'*rho'*Ri' C];
    phi = [C*Ri' rho*C];
    if rank(PHI) == size(PHI,1), amat = (PHI'\phi')';
    else, amat = (pinv(PHI')*phi')';  end;
    ai = amat(:,1:mi);  aith = amat(:,mi+1:mth+mi);
    aiRip = (ai*Ri)';
    aiRip = aiRip(indi,:);
    Rtemp = zeros(mth+mi,n1*m);
    Rtemp(:,(ii-1)*m+1:ii*m) = [aiRip zeros(mi,mth); aith' eye(mth)];
  end;
  R = [R; Rtemp];  ind1 = [ind1; indtemp];
end;

