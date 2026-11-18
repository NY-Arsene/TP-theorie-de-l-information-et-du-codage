function r = reste_poly(a, g)
%RESTE_POLY  Reste de la division polynomiale a(x) / g(x) modulo 2.
%   r = reste_poly(a, g)
%     a, g : coefficients par puissances CROISSANTES de x
%            (ex. g(x) = 1 + x + x^3  ->  g = [1 1 0 1])
%     r    : reste, de degré < deg(g), sur deg(g) coefficients
%   Division "à la main" : tant que le degré de a est >= deg(g), on
%   retranche (XOR) g(x) décalé sous le terme de plus haut degré.

    a  = mod(double(a(:).'), 2);
    g  = double(g(:).');
    dg = numel(g) - 1;
    for i = numel(a):-1:dg+1
        if a(i)
            a(i-dg:i) = xor(a(i-dg:i), g);    % g(end) aligné sur x^(i-1)
        end
    end
    r = double(a(1:dg));
end