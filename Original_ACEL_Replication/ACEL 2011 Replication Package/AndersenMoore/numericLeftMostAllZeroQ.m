function allz = numericLeftMostAllZeroQ(dim,x)
zeroTol=10^(-10);
allz=(norm(x(1:dim)) < zeroTol);
