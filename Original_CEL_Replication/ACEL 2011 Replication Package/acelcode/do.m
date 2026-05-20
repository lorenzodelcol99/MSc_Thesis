xx(1)  =  rho_M      ; % ρxM (1st Vettore Stocastico) (il terzo dei tre) vedi ACEL2011) (tengo come riferimento dell'ordine dei parametri rispetto a quelli del paper finale, solo parametro pxups ho scritto che è il nono del vettore 3 del working paper 2005)
xx(2)  =  rho_xz     ; % ρxz (5th Stochastic Vector)
xx(3)  =  c_z        ; % Cz  (6th Stochastic Vector)
xx(4)  =  rho_muz    ; % ρµz (3th Stochastic Vector)
xx(5)  =  rho_xups   ; % ρxΥ (in Working Paper 2005 è il 10th parameter)
xx(6)  =  c_ups      ; % Cups (8th Stochastic Vector --> 11th in te WP)
xx(7)  =  rho_muups  ; % ρµΥ (5th Stochastic Vector)
xx(8)  =  sig_M      ; % σM  (2dt Stochastic Vector)
xx(9)  =  sig_muz    ; % σµz (4th Stochastic Vector)
xx(10)  =  sig_muups  ; % σµΥ (in Working Paper 2005 è il 10th parameter)

xx(11)  =  epsilon    ; % ϵ Interest semi-elasticity of money demand (7th (last) Non-stochastic Vector)
xx(12)  =  kappa      ; % S'' (6th Non-stochastic Vector) : Kappa --> S'' Investment Adjustment Cost 
xx(13)  =  xi_w       ; % ξw  (2nd Non-stochastic Vector) :Wage Calvo parameter --> Wage Stickiness
xx(14)  =  b          ; % b   (5th Non-stochastic Vector) :Habit Formation
xx(15)  =  sigma_a    ; % σa  (4th Non-stochastic Vector)  :Capacity utilization cost --> 1/sigma_a is elasticity of capital utilization with respect to the rental rate of capital
xx(16)  =  cp_z       ; % cpz (7th Stochastic Vector) 
xx(17)  =  cp_ups     ; % cyp (9th Stochastic Vector --> 12th in te WP)
xx(18)  =  gam        ; % gamma (3rd Non-stochastic Vector) : Gamma --> Phillips Curve Slope
par(1)  =  psi_L      ; %%%%%%%%% PROBLEMA, ci sono due psi_L
par(2)  =  bet        ; % β (1st First Vector) : Discount Factor 
par(3)  =  mu_ups     ; % µY (7th First Vector)
par(4)  =  mu_z       ; % µz (8th First Vector)
par(5)  =  delta      ; % δ (3th First Vector)
par(6)  =  alph       ; % α (2th First Vector)
par(7)  =  nu         ; %%%%%%%%%%%%%%% Che parametro è ????
par(8)  =  psi_L      ; % PROBLEMA, ci sono due psi_L
par(9)  =  x          ; % x 9th First Vector)
par(10)  =  V          ; % V (10th First Vector) (Nel working Paper)
par(11)  =  sigma_L    ; %%%%%%%%%%%%%%% Che parametro è ????
par(12)  =  lambda_f   ; % λw (1st Non-stochastic Vector) : Wage Markup
par(13)  =  lambda_w   ; % λf (6th First Vector)
par(14)  =  squig      ; %%%%%%%%%%%%%%%% Che parametro è ????
par(15)  =  vartheta   ;
par(16)  =  eta        ; % η (6th First Vector)
par(17)  =  theta_M    ; % 
par(18)  =  theta_muz  ;
par(19)  =  theta_muups;


% Calvo Price Parameter  da cercare nel Workspace dopo aver ristimato il VAR e DSGE
% --> ksip  = Firm-Specific Capital Calvo Price Parameter
% --> ksiph = Homogeneous Capital Calvo Price Parameter