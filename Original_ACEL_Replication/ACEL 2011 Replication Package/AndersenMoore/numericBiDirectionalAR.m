function [zb,hb,zf,hf]=numericBiDirectionalAR(hmat)
[hrows,hcols]=size(hmat);
[zf,hf]=numericRightAR(hmat);
%'done forward'
%p=hcols:-1:1;
%ps=(hcols-hrows):-1:1;
%hrev=hmat(:,p);
[zb,hb]=numericLeftAR(hmat);
%'done backward'
%[zbrows,zbcols]=size(zb);
%if zbrows > 0
%zb=zb(:,ps);
%end
%hb=hb(:,p);
