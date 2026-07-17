function allz = numericRightMostAllZeroQ(dim,x)
zeroTol=10^(-10);
allz=(norm(x(length(x)-dim+1:length(x))) < zeroTol);
