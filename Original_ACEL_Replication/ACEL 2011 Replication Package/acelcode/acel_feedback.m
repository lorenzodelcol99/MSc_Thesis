function [A,ErrFlagVal] = acel_feedback(alpha,hmat,condn,uprbnd)
%%%%% LORENZO DEL COL modified line 1 function [A,ick]=feedback(alpha) (and the name of the file from feedback to acel.feedback)
%    This routine finds the zero, A, of an n by n matrix polynomial,
%
%  al0*A^m + al1*A^(m-1) + ... + alm*I,
%
%  where I is n-th order identity matrix, and ali, i=0,...,m
%  are each n by n matrices.
%     ali = alpha([1:n],(i-1)*n+[1:n]), i = 0,..,m.
%  The routine finds A subject to the condition that
%  its eigenvalues do not exceed 1 in absolute value.
%    It uses the 'QZ algorithm' described by Sims in
%  in his IEM discussion paper 15, "Solving Nonlinear Stochastic
%  Optimization and Equilibrium Problems Backwards."
%    The routine does a check at the end to verify that
%  the computed A matrix indeed is a zero of the above polynomial
%  and if it is not, then it improves on it by using a zero
%  finding algoritm. For this algorithm to work, it is necessary
%  that alpha_ and m_ be two global variable names.
%
%  ick = 1: program ran fine
%  ick = 0: rank(al0) = 0
%  ick = 2: some other fatal error.
%
%  This .m file uses MATLAB function QZ, and the .m files written
%  by Sims, QZDIV.M and QZSWITCH.M, plus CHROOT.M.
[n,j]=size(alpha);
m=j/n-1;
ick=1;
if round(m) ~= m,
   disp(' fatal (feedback)')
   disp(' alpha''s input to feedback not of right dimension')
   disp(' size(alpha)')
   size(alpha)
   disp(' hit any key to continue ...')
   pause
   %%%%% LORENZO DEL COL changed line 38 from "break" to --> "return"
   return
end
%
al0=alpha(:,[1:n]);
if rank(al0) == 0,
   ick=0;
   disp(' warning(feedback) lead alpha zero rank')
   disp(' try dropping the value of m')
   disp(' exiting routine, and returning ick = 0')
   %%%%% LORENZO DEL COL changed line 48 from "break" to --> "return"
   return
end
a = [al0                 zeros(n,n*(m-1))
     zeros(n*(m-1),n)    eye(n*(m-1),n*(m-1))];
b = [alpha(:,[n+1:n*(m+1)])
     -eye(n*(m-1),n*(m-1))      zeros(n*(m-1),n)];
%
%  a*y(t+1)+b*y(t)=0, where y(t) is n*m by 1, and a, b are n*m by n*m.
%
ra=rank(a);
if ra < n*m,
%
%       q*a*z = H0, q*b*z = H1
%
%  q, z are orthonormal, H0, H1 are upper triangular.
%
[H0,H1,q,z,v]=qz(a,b);
%
%    H0*gam(t+1) + H1*gam(t) = 0
%
%     gam(t) = z'*y(t)
%
stake1=1e+08;
stake2 = 1e-13;
[H0,H1,q,z] = qzdiv(stake1,H0,H1,q,z);

%Make sure H0(i,i) ~= 0 and H1(i,i) ~= 0 at the same time
root = abs([diag(H0) diag(H1)]);
chord = sqrt(root(:,1).*root(:,1)+root(:,2).*root(:,2));
if (chord < (1/stake1))
  disp('element of (H0(i,i),H1(i,i)) is close to zero.');
  disp('Warning (Simsback) Solving Routine Questionable.');
end

%Count zero elements of H0(i,i)
root(:,1) = root(:,1)-(root(:,1)<stake2).*(root(:,1)+root(:,2));
root(:,1);
root(:,2) = root(:,2)./root(:,1);
zct = length(find((root(:,2) > stake1 | root(:,2) < -0.1)));

rra = n*m-zct;
ra=rra;
zz=z';
L1=zz([1:ra],:);
L2=zz([ra+1:n*m],:);
ip=n*m-ra;
g0=H0([1:ra],[1:ra]);
g1=H1([1:ra],[1:ra]);

gg=H1([ra+1:n*m],[ra+1:n*m]);
if rank(gg) ~= n*m - ra,
   disp(' fatal (feedback) bottom right block in H1 not full rank')
   disp(' press any key to continue ...')
   pause
   ick=2;
   %%%%% LORENZO DEL COL changed line 104 from "break" to --> "return"
   return
end
PIE=-g0\g1;
%
else
%
PIE=-a\b;
%
end
[V,Dd]=eig(PIE);
rt=diag(Dd);
i=0;
tt=[];
db=1;
for ii = 1:length(rt)
  if abs(rt(ii)) >= db
   i=i+1;
   tt(i)=ii;
  end
end
nl=ra-n;
if i < nl
  disp(' fatal (feedback) too few unstable roots')
  fid = fopen('run2.out', 'a');
  fprintf(fid,'fatal (feedback) too few unstable roots\n');
  fprintf(fid, 'Explosive Roots Needed = %i\n', nl);
  fprintf(fid, 'Explosive Roots = %i\n', i);
  fprintf(fid, '         \n');
  fclose(fid);
  
  disp(' needed nl roots')
  nl
  disp(' absolute value of roots:')
  %abs(rt)
  %tt
  %db
  disp(' you have control of the keyboard ...')
  keyboard
  ick=2;
  %%%%% LORENZO DEL COL changed line 144 from "break" to --> "return"
   return
end
if i > nl
  disp(' fatal (feedback) too many unstable roots')

  fid = fopen('run2.out', 'a');
  fprintf(fid,'fatal (feedback) too many unstable roots\n');
  fprintf(fid, 'Explosive Roots Needed = %i\n', nl);
  fprintf(fid, 'Explosive Roots = %i\n', i);
  fprintf(fid, '         \n');
  fclose(fid);

  %disp(' needed nl roots')
  %nl
  %disp(' absolute value of roots:')
  %abs(rt)
  %tt
  %db
  disp(' hit any key to continue ...')
  pause
  ick=2;
  %%%%% LORENZO DEL COL changed line 166 from "break" to --> "return"
   return
end
VI=inv(V);
p=VI(tt,:);
if ip > 0
  D=[p*L1
     L2];
else
  D=p;
end
nm=n*m;
D1=D(:,[1:nm-n]);
D2=D(:,[nm-n+1:nm]);
if rank(D1) ~= n*(m-1),
   disp(' fatal (feedback) D1 not of full rank')
   disp(' hit any key to continue ...')
   pause
   ick=2;
   %%%%% LORENZO DEL COL changed line 185 from "break" to --> "return"
   return
end
Dec=-(D1\D2);
Idec=imag(Dec);
A=real(Dec([n*(m-2)+1:n*(m-1)],:));
A1=A;
%%%%%% LORENZO DEL COL replacing line 192 (old [A] = chroot(Idec,al0,alpha,nm,n,A1,m);) to the current
[A] = chroot(Idec,alpha,n,A1,m);
%%%%%% LORENZO DEL COL adding the last line (194)
ErrFlagVal = 0;