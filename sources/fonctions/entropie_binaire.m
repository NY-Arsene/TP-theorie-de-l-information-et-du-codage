function H = entropie_binaire(p)
%ENTROPIE_BINAIRE  Entropie (en bits) d'une source binaire de probabilité p.
%   H = entropie_binaire(p) = -p*log2(p) - (1-p)*log2(1-p)
%   Accepte un scalaire ou un vecteur. Convention : 0*log2(0) = 0.

    H   = zeros(size(p));
    idx = (p > 0) & (p < 1);           % hors de ]0,1[, H = 0
    q   = p(idx);
    H(idx) = -q.*log2(q) - (1-q).*log2(1-q);
end