function quadform   =   quadform(xx,fixedpars,taux,nsteps,psihat,Vhat,A,computeA,chk,criterion)

optpars  =  map(xx);

%Generate IRFs in the model
[modirfpol,modirfemt,modirfnet,ErrFlagVal]  =  modirf(optpars,fixedpars,taux,nsteps,A,computeA,chk);

if ErrFlagVal > 0
    quadform = 10e50;
    return
end

% Stacking the matrices to a 60 x 11 matrix, same ordering as in the data (psihat)
[modirfpol,modirfemt,modirfnet] = setcrit(modirfpol,modirfemt,modirfnet,criterion);
psiphihat = [-modirfpol; modirfemt; modirfnet];%note, minus policy shock


% nozero function replaces all zeros with NaN (policy shocks)
%%%%% LORENZO DEL COL changes line 20 (now are line from 20 to 24) from  calcff = ([nozero(psihat) - nozero(psiphihat)].^2) ./ nozero(Vhat); --> to calcff = ([nonzeros(psihat) - nonzeros(psiphihat)].^2) ./ nonzeros(Vhat);
% Replicating the missing 'nozero' function by replacing 0 with NaN
psihat(psihat == 0) = NaN;
psiphihat(psiphihat == 0) = NaN;
Vhat(Vhat == 0) = NaN;
calcff = ((psihat - psiphihat).^2) ./ Vhat;
calcff = calcff(:);
quadform = sum(calcff(find(~isnan(calcff))));