%%% LORENZO 

function y = nozero(x)
    % Removes zero elements from a vector
    y = x(x ~= 0);
end