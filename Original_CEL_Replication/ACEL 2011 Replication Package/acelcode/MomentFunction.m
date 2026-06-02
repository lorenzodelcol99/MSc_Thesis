function [ff,ErrFlagVal] = MomentFunction(allparams,comp_psihat,baseline,criterion)
ErrFlagVal = 0;
load fixparams;
psihat = allparams(nepar+1:end);

% Case #1: baseline == 1.
if baseline == 1
    xx = allparams(1:nepar);
    [modirfpol,modirfemt,modirfnet,ErrFlagVal] = modirf(xx,par,taux,nsteps,[],1,0);
    IRFFF = -modirfpol(:);%vector, negative policy shock
    IRFu  = modirfemt(:);%vector
    IRFz  = modirfnet(:);%vector
    Indvec = find(IRFFF~=0);
    IRFFF = IRFFF(Indvec);
    IRFz  = IRFz(1:end-nsteps);
    
    % --- LORENZO'S FIX: Slice empirical vectors to match criterion ---
    L1 = length(IRFFF); L2 = length(IRFu); L3 = length(IRFz);
    emp_p1 = psihat(1:L1); emp_p2 = psihat(L1+1:L1+L2); emp_p3 = psihat(L1+L2+1:end);
    emp_v1 = Vhat(1:L1); emp_v2 = Vhat(L1+1:L1+L2); emp_v3 = Vhat(L1+L2+1:end);
    [emp_p1, emp_p2, emp_p3] = setcrit(emp_p1, emp_p2, emp_p3, criterion);
    [emp_v1, emp_v2, emp_v3] = setcrit(emp_v1, emp_v2, emp_v3, criterion);
    psihat = [emp_p1; emp_p2; emp_p3];
    Vhat = [emp_v1; emp_v2; emp_v3];
    save lorenzofix psihat Vhat; % Save fixed sizes for Cases 3 & 4
    % -----------------------------------------------------------------

    [IRFFF,IRFu,IRFz] = setcrit(IRFFF,IRFu,IRFz,criterion);
    psiphihat = [IRFFF;IRFu;IRFz]; 
    
    save psiphihat psiphihat;
end

% Case #2: comp_psihat == 1 and baseline == 0.
if comp_psihat == 1 & baseline == 0
   xx = allparams(1:nepar);
   [modirfpol,modirfemt,modirfnet,ErrFlagVal] = modirf(xx,par,taux,nsteps,[],1,0);
   IRFFF = -modirfpol(:);%vector, negative policy shock
   IRFu  = modirfemt(:);%vector
   IRFz  = modirfnet(:);%vector  
   Indvec = find(IRFFF~=0);
   IRFFF = IRFFF(Indvec);
   IRFz  = IRFz(1:end-nsteps);
   
    % --- LORENZO'S FIX: Slice empirical vectors to match criterion ---
    L1 = length(IRFFF); L2 = length(IRFu); L3 = length(IRFz);
    emp_p1 = psihat(1:L1); emp_p2 = psihat(L1+1:L1+L2); emp_p3 = psihat(L1+L2+1:end);
    emp_v1 = Vhat(1:L1); emp_v2 = Vhat(L1+1:L1+L2); emp_v3 = Vhat(L1+L2+1:end);
    [emp_p1, emp_p2, emp_p3] = setcrit(emp_p1, emp_p2, emp_p3, criterion);
    [emp_v1, emp_v2, emp_v3] = setcrit(emp_v1, emp_v2, emp_v3, criterion);
    psihat = [emp_p1; emp_p2; emp_p3];
    Vhat = [emp_v1; emp_v2; emp_v3];
    save lorenzofix psihat Vhat; % Save fixed sizes for Cases 3 & 4
    % -----------------------------------------------------------------

   [IRFFF,IRFu,IRFz] = setcrit(IRFFF,IRFu,IRFz,criterion);
   psiphihat = [IRFFF;IRFu;IRFz]; 
   save workingphat psiphihat;
end

% Case #3: comp_psihat == 2 and baseline == 0.
if comp_psihat == 2 & baseline == 0
   load workingphat;
   load lorenzofix; % Load the correctly sized psihat and Vhat
end

% Case #4: comp_psihat == 3 and baseline == 0.
if comp_psihat == 3 & baseline == 0
   load psiphihat;
   load lorenzofix; % Load the correctly sized psihat and Vhat
end

if ErrFlagVal == 1
    ff=10^6;
    return
end

calcff = ([nozero(psihat) - nozero(psiphihat)].^2) ./ nozero(Vhat);
calcff = calcff(:);
ff = sum(calcff(find(~isnan(calcff))));
if baseline == 1
   ff
end


%%% ORIGINAL --> 
%function [ff,ErrFlagVal] = MomentFunction(allparams,comp_psihat,baseline,criterion);

%ErrFlagVal = 0;

%load fixparams;
%psihat = allparams(nepar+1:end);

%% Case #1: baseline == 1.
%% Compute psiphihat which is used to form f0 in g1g2Func.m.
%if baseline == 1;
%    xx = allparams(1:nepar);
%    [modirfpol,modirfemt,modirfnet,ErrFlagVal] = modirf(xx,par,taux,nsteps,[],1,0);
%    IRFFF = -modirfpol(:);%vector, negative policy shock
%    IRFu  = modirfemt(:);%vector
%    IRFz  = modirfnet(:);%vector
%    Indvec = find(IRFFF~=0);
%    IRFFF = IRFFF(Indvec);
%    IRFz  = IRFz(1:end-nsteps);
%    [IRFFF,IRFu,IRFz] = setcrit(IRFFF,IRFu,IRFz,criterion);
%    psiphihat = [IRFFF;IRFu;IRFz]; % a j x 1 vector with impulse responses.
    
%    save psiphihat psiphihat;
%end;

%% Case #2: comp_psihat == 1 and baseline == 0.
%% Computing dff/d(gamma(i))d(gamma(j)) - i.e. for the cases when only gammas are involved in the derivatives.
%if comp_psihat == 1 & baseline == 0;
%   xx = allparams(1:nepar);
%   [modirfpol,modirfemt,modirfnet,ErrFlagVal] = modirf(xx,par,taux,nsteps,[],1,0);
%   IRFFF = -modirfpol(:);%vector, negative policy shock
%   IRFu  = modirfemt(:);%vector
%   IRFz  = modirfnet(:);%vector  
%   Indvec = find(IRFFF~=0);
%   IRFFF = IRFFF(Indvec);
%   IRFz  = IRFz(1:end-nsteps);
%   [IRFFF,IRFu,IRFz] = setcrit(IRFFF,IRFu,IRFz,criterion);
%   psiphihat = [IRFFF;IRFu;IRFz]; % a j x 1 vector with impulse responses.
%   save workingphat psiphihat;
%end;

%% Case #3: comp_psihat == 2 and baseline == 0.
%% This is for the case when computing cross derivatives, i.e dff/(dgamma*dpsi).
%if comp_psihat == 2 & baseline == 0;
%   load workingphat;
%end;

%% Case #4: comp_psihat == 3 and baseline == 0.
%% This is for the case when only psi's are involved in the computations, then we
%% use the baseline decision rule results.
%if comp_psihat == 3 & baseline == 0;
%   load psiphihat;
%end;

%if ErrFlagVal == 1
%    ff=10^6;
%    return
%end

%calcff = ([nozero(psihat) - nozero(psiphihat)].^2) ./ nozero(Vhat);
%calcff = calcff(:);
%ff = sum(calcff(find(~isnan(calcff))));
%if baseline == 1;
%   ff
%   %keyboard;
%end;
