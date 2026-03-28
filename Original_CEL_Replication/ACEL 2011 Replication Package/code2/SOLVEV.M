function [V] = solvev(Q,U,bet)
%solvev:  Iterates to solve for V matrix used in computing the value function.

nmax = 2000;  %Max Number of Iterations
tol = 1e-5;  %Tolerance for convergence
V = U;  %Initial guess for V

for ii = 1:nmax
  Vnew = bet*Q'*V*Q+U;  %New Guess
  vtest = max(max(abs(Vnew-V)));
  V = Vnew;
  if vtest < tol  %Check convergence
    fprintf('Successful Convergence on V\n');
    break;
  end;
end;

if ii == nmax
  fprintf('V matrix did not converge\n');
  error('fatal (solveV) Value function results inaccurate');
end;
