function [J] = fdjaca(func,arg,param,stepsize)
%Calculates a forward difference approximation of Jacobian matrix.
%t1 = clock;

if nargin == 4
   test = length(arg)-length(stepsize);
   if test ~= 0, error('fatal (fdjaca) arg and stepsize not same length'); end;
end;

sqrteta = 1e-4;
jend = length(arg);
if isempty(param) == 1, fc = feval(func,arg);
else  fc = feval(func,arg,param);  end;   

J = zeros(length(fc),jend);

for j = 1:jend
  if nargin == 3
    if abs(arg(j)) > 1e-12, stepsizej = sqrteta*arg(j);
    else stepsizej = sqrteta; end;
  else
     stepsizej = stepsize(j);
  end;
  tempj = arg(j);
  arg(j) = arg(j)-stepsizej;
  stepsizej = arg(j)-tempj;
  if isempty(param) == 1, fj = feval(func,arg);
  else fj = feval(func,arg,param); end;
  J(:,j) = (fj-fc)/stepsizej;
  arg(j) = tempj;
end;

%t2 = clock;
%fprintf('%5.2f seconds used to linearize equations\n',etime(t2,t1));

