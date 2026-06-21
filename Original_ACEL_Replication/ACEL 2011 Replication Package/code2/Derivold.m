function [QQ]=deriv(psi,par,func,Eul)
t1=clock;
tol=1e-6;
%
iend=length(psi);
QQ   = zeros(iend,1);
der  = zeros(iend,1);
pert = zeros(iend,1);
psid = zeros(iend,1);
%
yy=feval(func,psi,par);

if Eul == 1
  
if abs(yy) > .1e-10,
  disp(' warning:  euler equation not satisfied')
  yy
  keyboard
end
  yy=0;
end
%
for ii=1:iend
psid=psi;
 if abs(psi(ii)) > .1e-15
  pert(ii)=tol*psi(ii);
  psid(ii)=psid(ii) + pert(ii);
 else
  pert(ii)=tol;
  psid(ii)=psid(ii) + pert(ii);
 end
y=feval(func,psid,par);
der(ii)=(y-yy);
end
for ii = 1:iend
QQ(ii)=der(ii)/pert(ii);
end
t2=clock;
%fprintf('%5.2f seconds used to linearize function\n' ...
%  ,etime(t2,t1))

