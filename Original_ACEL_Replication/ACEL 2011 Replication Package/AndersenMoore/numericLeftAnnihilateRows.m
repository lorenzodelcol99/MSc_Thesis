function newhmat = numericLeftAnnihilateRows(hmat)
[hrows,hcols]=size(hmat);
newhmat=numericComputeAnnihilator(hmat(:,1:hrows),hmat);
%newhmat=zapper*hmat;
