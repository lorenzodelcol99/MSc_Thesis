function newhmat = numericAnnihilateRows(hmat)
[hrows,hcols]=size(hmat);
newhmat=numericComputeAnnihilator(hmat(:,hcols-hrows+1:hcols),hmat);
%newhmat=zapper*hmat;