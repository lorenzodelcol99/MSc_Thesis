function annmat=numericComputeAnnihilator(amat,hmat)
zeroTol=10^(-10);
[arows,acols]=size(amat);
%p=arows:-1:1;
if(norm(reshape(amat,1,arows*acols))<zeroTol)
annmat=hmat;
else
if(issparse(amat))
[annmat,r]=qr(amat,hmat);
else
[annmat,r,e]=qr(amat);
annmat=(annmat')*hmat;
end%end if
%annmat=annmat(:,p);%want to place zero rows at top of matrix
%annmat=annmat';
end;%end if
