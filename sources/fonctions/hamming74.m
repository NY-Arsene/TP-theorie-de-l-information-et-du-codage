function [G, H, P] = hamming74()
%HAMMING74  Matrices du code cyclique C(7,4) de polynôme générateur
%   g(x) = 1 + x + x^3, sous forme systématique c = [m0 m1 m2 m3 | r0 r1 r2]
%   avec r(x) = x^3 m(x) mod g(x).
%   [G, H, P] = hamming74()  ->  G = [I4 | P], H = [P' | I3]

    g = [1 1 0 1];
    P = zeros(4, 3);
    for k = 0:3
        a = zeros(1, 7);
        a(k + 4) = 1;                  % x^3 * x^k
        P(k + 1, :) = reste_poly(a, g);
    end
    G = [eye(4) P];
    H = [P.' eye(3)];
end