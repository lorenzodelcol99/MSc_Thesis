function [A,ErrFlagVal] = feedback(alpha,hmat,condn,uprbnd);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Written and last modified by Jesper Lindé 2004-01-15.
%
% Let alpha = alpha(0), alpha(1), ...., alpha(r),
% where alphai is n by n, for i=0,1,...,r.
% this routine finds an n by n matrix root, A, of the polynomial
% alpha(0)*(A^r)) + alpha(1)*(A^(r-1)) + ... + alpha(r) = 0
% 
% Remark #1: Note that hmat = [alpha(r), ..., alpha(0)];
%
% Also, modified 13/1 2003 to report ErrFlagVal equal to 0 if solution is ok, 1 if not.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[n,n2]=size(hmat);
r=(n2/n)-1;
if round(r) ~= r
   error('fatal (feedback) dimension of alphas not right')
end

ErrFlagVal = 0; %initializing

% Using the most recent version of AIM to solve the model.
% Obtained by G. Anderson 2004-01-15.

[A,rts,ia,nexact,nnumeric,lgroots,aimcode] =  SPAmalg(hmat,size(hmat,1),1,1,condn,uprbnd);

% See SPAimerr.m for how this variable is defined
if aimcode ~= 1;
   ErrFlagVal = 1;
   A = [];
end;

if ErrFlagVal == 1;%I don't know what ErrFlagVal == 1 means, so in this case we take a trip into findandcheckA, which 
                   %will explain what is wrong, if something is wrong.
    alpha_0=alpha(:,1:n);
    i=1;
    alpha_1=alpha(:,[i*n+1:i*n+n]);
    i=2;
    alpha_2=alpha(:,[i*n+1:i*n+n]);
    [A] = findandcheckA(alpha,alpha_2,alpha_1,alpha_0);
end
%Verify that A is a root of the matrix polynomial and that its eigenvalues
%are stable
ErrFlagVal=0;
Q = alpha(:,1:n);
for i=1:r, Q = Q*A+alpha(:,[i*n+1:i*n+n]); end;
tol=.1e-7;
if max(max(abs(Q))) > tol | max(abs(eig(A))) > 1
    ErrFlagVal = 1;
    A = [];
end;