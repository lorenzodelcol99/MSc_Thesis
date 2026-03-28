%basic input - randomly constructed C and rho matrices
Ch=[rand(1,4);0,rand(1,3);0,0,rand(1,2);0,0,0,rand(1,1)];
C=Ch*Ch';
P=rand(4,4);
ei=[.2,.1,.9,.8];
E=diag(ei);
rho=P*E*(P');
%example where you observe second and third elements of theta
R=[0 1 0 0;0 0 1 0];

[mi,mth]=size(R);
bphi=[R*C*R',R*rho*C;C'*(rho')*R',C];
lphi=[C*R',rho*C];
bb=lphi/bphi;
ai=bb(:,[1:mi]);
aith=bb(:,[mi+1:mi+mth]);
