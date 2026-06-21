function [J] = fdjacv(func,arg,param)
%Calculates a forward difference approximation of Jacobian matrix.
%t1 = clock;
sqrteta = 1e-5;
ja = size(arg,2);
if size(arg,1) ~= 1,
  error('fatal (fdjacv) arg must be a column vector');
end;
argm = arg(ones(ja,1),:);
if nargin == 2, fc = feval(func,argm);
elseif nargin == 3, fc = feval(func,argm,param);
else error('fatal (fdjacv) Wrong number of inputs.'); end;
ia = size(fc,1);
J = zeros(ia,ja);
stepsize = zeros(1,ja);
[jz1] = find(abs(arg) > 1e-12);
[jz2] = find(abs(arg) <= 1e-12);
stepsize([jz1]) = sqrteta*arg([jz1]);
stepsize([jz2]) = sqrteta*ones(1,length(jz2));
stepsizem = diag(stepsize);
argm = argm+stepsizem;
if nargin == 2, fj = feval(func,argm);
elseif nargin == 3, fj = feval(func,argm,param);
else error('fatal (fdjacv) Wrong number of inputs.'); end;
stepsizem = stepsize(ones(ia,1),:);
J = (fj-fc)./stepsizem;
%t2 = clock;
%fprintf('%5.2f seconds used to linearize equations\n',etime(t2,t1))

