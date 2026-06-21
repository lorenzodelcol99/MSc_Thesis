function [ind,dropm,A] = solvea(alphas,qq,ne)
%Solvea:  Solves for the "A" matrix in the policy rule.
%Output: A matrix
%
%        ind where ind = 0 if solution is indeterminate
%                  ind = 1 if unique
%                  otherwise explosive
%
%        dropm where dropm = 0 if no need to drop alph_0
%                    otherwise drop alph_0
%                    drop alph_0 when it is all zeroes
%
%If nargout == 2, then only ind and dropm will be returned.
%
% inputs:   alphas   = [ alpha_0 alpha_1 ... alpha_r ]
%
%           qq:  the number of lagged z1t in Zt; where z1t is an n1x1 vector
%           of endogenous variables;  qq = 0 if Zt = z1t so there are no lags
%           as is usually the case
%
%           ne:  position of eigenvalue associated with minimal rank solution
%                when there is indeterminacy
%                User should not specify argument for ne unless solvea returns
%                a message specifying a value for ne; also can set ne = []
%                solvea reports how to specify ne in the case of indeterminacy
%                and there are minimal rank solutions
%
%In case where qq = 0 and ne is not necessary, solvea can be called with one 
%input argument.  If ne is not necessary, solvea can be called with two
%input arguments.
%
% The basic method to solve for this "A" matrix is to consider the equation:
%  a*y(t+1)+b*y(t)=0, where y(t) is m by 1, and "a", "b" are m by m.
% if "a" is nonsingular, then we consider the matrix: PIE = -inv(a)*b
% if "a" is singular, then the QZ MATLAB function, and the QZDIV.M and 
% QZSWITCH.M files (by Sims) are used.

%Check input arguments
if all(nargin ~= [1; 2; 3]) 
   error('fatal (solvea) Wrong number of input arguments');
end;
if nargin == 1, ne = [];  qq = 0;  end;
if nargin == 2, ne = [];  end;

%Polynomial Solution Tolerance
tol = 1e-6;

%Default is alph_0 is not all zeroes
dropm = 0;

%Get the following from the alphas
%               n1:  number of lagged endogenous variables of z1t
%               n:  number of lagged endogenous variables in Zt
%               r:  order of matrix polynomial solved by A
%               m:  dimension of square matrices, a and b

[n1,j] = size(alphas);
n = (qq+1)*n1;
r = j/n-1;

if round(r) ~= r
   fprintf('rows of alphas = %1.1f and cols of alphas = %1.1f\n', n1,j);
   error('fatal (solvea) alphas input not of right dimension');
end;

m = (r-1)*n1+n;

%Check rank of alpha_0
if rank(alphas(:,1:n)) == 0
   dropm = 1;  ind = [];  A = [];
else
   
   %Get "a" matrix from the alphas. 
   a=eye(m);
   a(1:n1,1:n1) = alphas(:,1:n1);
   
   %Get "b" matrix from the alphas:
   topb = zeros(n1,m);             
   % topb will hold top n1 rows of b matrix
   for ii=1:r-1
      topb(:,(ii-1)*n1+1:ii*n1) = alphas(:,ii*(qq+1)*n1+1:ii*(qq+1)*n1+n1);
   end;
   topb(:,(r-1)*n1+1:m) = alphas(:,r*(qq+1)*n1+1:r*(qq+1)*n1+n); 
   b = [topb; -eye(m-n1)  zeros(m-n1,n1)];
   
   %Check Invertibility of a
   K = rank(a);
   
   if K < m,
      % This is the case where "a" is singular and requires the QZ
      %decomposition
      % to remove the singularity.
      % q*a*z = H0, q*b*z = H1
      % where:  q, z are orthonormal. H0 and H1 are upper triangular.
      
      [H0,H1,q,z,v]=qz(a,b);
      
      % H0*gam(t+1) + H1*gam(t) = 0
      % gam(t) = z'*y(t)
      
      %re-order matrices:
      %stake1 compares H0(i,i) to H1(i,i) and 0; stake2 compares H0(i,i) to 0
      %Success of QZ decomp can be very sensitive to these values
      stake1 = 1e+08;
      stake2 = 1e-05;
      [H0,H1,q,z] = qzdiv(stake1,H0,H1,q,z);
      
      %Make sure H0(i,i) ~= 0 and H1(i,i) ~= 0
      root = abs([diag(H0) diag(H1)]);
      chord = sqrt(root(:,1).*root(:,1)+root(:,2).*root(:,2));
      if (min(chord) < (1/stake1))
         error('fatal (solvea) element of (H0(i,i),H1(i,i)) is close to (0,0)');
      end;
      
      %Count zero elements of H0(i,i)
      root(:,1) = root(:,1)-(root(:,1)<stake2).*(root(:,1)+root(:,2));
      root(:,2) = root(:,2)./root(:,1);
      zct = length(find((root(:,2) > stake1 | root(:,2) < -0.1)));
      K = m-zct;
            
      %L2*y(t) = 0 by construction
      zz  = z';
      L1  = zz([1:K],:);
      L2  = zz([K+1:m],:);
      g0  = H0([1:K],[1:K]);
      
      if rank((g0)) < K
         error('fatal (Solvea) rank of g0 too small')
      end
      
      g1  = H1([1:K],[1:K]);
      gg  = H1([K+1:m],[K+1:m]);
      PIE = -g0\g1;
   else    % This is the case where "a" is nonsingular.
      PIE = -a\b;
   end;  %if,then (QZ decomp)
   
   % Perform eigenvalue, eigenvector decomposition and search for 
   % explosive eigenvalues:
   [V,Dd] = eig(PIE');
   rt = diag(Dd);
   VI = V';
   db = 1;    % criterium for explosiveness
   posexp = find(abs(rt) >= db);  %Vector indexing explosive eigenvalues
   posnexp = find(abs(rt) < db);  %Vector indexing non_exp eigenvalues
   num_exp = length(posexp);  %number of explosive eigenvalues
   num_need = K-n;  %number of explosive eigenvalues needed for uniqueness
   
   if nargout == 2
      
      %Determine whether solution is unique, explosive, or indeterminate
      if num_exp < num_need, ind = 0;
      elseif num_exp == num_need, ind = 1;
      else ind = 2; end;
      
   elseif nargout == 3
      
      %Determine whether solution is unique, explosive, or indeterminate
      if num_exp < num_need, ind = 0;
      elseif num_exp == num_need, ind = 1;
      else ind = 2; end;
      
      %Make sure ne has length of 0 or 1
      if all(length(ne) ~= [0; 1])
         fprintf('ne must be a positive integer\n');
         error('fatal (solvea) ne is not specified correctly');
      end;
      
      %If ne = 1, make sure it indexes a nonexplosive eigenvalue
      if length(ne) == 1 & all(ne ~= posnexp)
         fprintf('ne must index a nonexplosive eigenvalue\n');
         error('fatal (solvea) ne specified incorrectly');
      end;
      
      %  if length(ne) == 0,
      %    (1) in case of indeterminacy:
      %          a)  Check size of indeterminacy
      %          b)  If one dimensional, report the number of minimal rank
      %              solutions before displaying error message.  Tell user 
      %              how to set ne to compute the A matrix or matrices 
      %              associated with minimal rank solutions.
      %          c)  If larger than one dimension, program returns error message
      %    (2)  Unique solution:  attempt to solve for unique A matrix
      %    (3)  Explosive solution:  Return error message
      %  if length(ne) == 1, attempt to compute the minimal rank solution 
      %  associated with eigenvalue indexed by ne
      % if length(ne) anything else, return error message
      
      num_exp = num_exp + length(ne);
      
      if num_exp < num_need  %Case of indeterminacy
         
         if length(ne) == 1
            fprintf('Tried to compute minimal rank solution in case of ');
            fprintf('indeterminacy, but solvea not able to do this.\n');
            fprintf('Need: %1.0f explosive roots for uniqueness\n',num_need);
            fprintf('Found: %1.0f explosive roots\n',num_exp-1);
            error('fatal (solvea) Indeterminacy is not one dimensional');
         else
            fprintf('Need: %1.0f explosive roots for uniqueness\n',num_need);
            fprintf('Found: %1.0f explosive roots\n',num_exp);
            fprintf('\n');
            if num_need-num_exp == 1
               %set_for_ne contains eigenvalues associated with
               %minimal rank solution
               set_for_ne = [];
               for ii = 1:length(posnexp)
                  p = VI([posexp; posnexp(ii)],:);
                  if m-K > 0, D = [p*L1; L2];
                  else D = p; end;
                  D1 = D(:,[1:n1*(r-1)]);
                  D2 = D(:,[n1*(r-1)+1:m]);
                  
                  if rank(D1) == n1*(r-1)
                     Dec = -(D1\D2);
                     Idec = imag(Dec);
                     At = [real(Dec([n1*(r-1)-n1+1: n1*(r-1)],:))
                        eye(n-n1) zeros(n-n1,n1) ];
                     
                     Q = alphas(:,1:n);
                     for i=1:r, Q = Q*At+alphas(:,[i*n+1:i*n+n]); end;
                     
                     me = max(abs(eig(At)));
                     if max(max(abs(Q))) < tol & me < 1
                        set_for_ne = [set_for_ne; posnexp(ii)];
                     end;
                  end;
               end;  %end of for loop for checking for mrs
               
               fprintf('There is a one dimensional continuum of solutions.\n');
               fprintf('There are %1.0f minimal rank ', length(set_for_ne));
               fprintf('solutions in this case.\n');
               if length(set_for_ne) == 0  %Case of No MRS
                  error('fatal (solvea) ne can not be used in this case.');
               else  %Case of minimal rank solutions
                  fprintf('To compute an A which is a minimal rank solution:\n');
                  fprintf('Set ne to the following number or one of');
                  fprintf(' the following numbers:\n');
                  for ii = 1:length(set_for_ne)
                     if ii ~= length(set_for_ne) 
                        fprintf('     ne = %1.0f or \n', set_for_ne(ii));
                     else 
                        fprintf('     ne = %1.0f\n', set_for_ne(ii));
                        fprintf('\n');
                     end;
                  end;  %end of for loop for reporting
                  error('fatal (solvea) Reset ne.');
               end;  %end of checking for at least one mrs
            else  %Indeterminacy multidimensional
               fprintf('It is not possible to use ne in this case\n');
               error('fatal (solvea) Indeterminacy is not one dimensional');
            end;  %if, then for one dim or multi dim indeterminacy
         end;  %if, then for length(ne)
      elseif num_exp > num_need  %Explosive Case
         
         if length(ne) == 0
            fprintf('Need: %1.0f explosive roots\n',num_need);
            fprintf('Found: %1.0f explosive roots\n',num_exp);
            error('fatal (solvea) too many unstable roots');
         else
            fprintf('ne is misspecified.  Drop ne from input of solvea\n');
            error('fatal (solvea) ne is misspecified');
         end;
      else
         %attempt to calculate A in case of unique solution
         %or a minimal rank solution when there is one dimensional
         %indeterminacy
         p = VI([posexp; ne],:);
         if (m-K) > 0,  D = [p*L1; L2];
         else,  D = p;  end;
         
         D1 = D(:,[1:n1*(r-1)]);
         D2 = D(:,[n1*(r-1)+1:m]);
         
         if rank(D1) ~= n1*(r-1)
            error('fatal (solvea) D1 not full rank');
         end;
         
         Dec = -(D1\D2);
         Idec = imag(Dec);
         A = [real(Dec([n1*(r-1)-n1+1: n1*(r-1)],:))
            eye(n-n1) zeros(n-n1,n1) ];
                 
              
         Q = alphas(:,1:n);
         for i=1:r, Q = Q*A+alphas(:,[i*n+1:i*n+n]); end;
         
         if max(max(abs(Q))) > tol
            
            A1=A;
            
            [A] = chroot(Q,alphas,n,A1,r);
            
            Q1 = alphas(:,1:n);
            for i=1:r, Q1 = Q1*A+alphas(:,[i*n+1:i*n+n]); end;
            
            if max(max(abs(Q1))) > tol
               error('fatal (solvea) matrix root not accurate, even after improvement');
            end;
            
             
         end;
         
         
         me = max(abs(eig(A)));
         if me > 1
            fprintf('Largest eigenvalue of A = %8.4e\n',me);
            error('fatal (solvea) max root of A>1 in abs. value');
         end;
      end;  %if, then for unique, indet, explosiveness
   else
      error('fatal (solvea) Wrong Number of output arguments');
   end;  %if else (nargout)
end;  %if else (dropm)

