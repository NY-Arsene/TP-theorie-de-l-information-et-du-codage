function [h, t] = rrc_coeffs(alpha, L, span)
%RRC_COEFFS  Coefficients du filtre en racine de cosinus surélevé.
%   [h, t] = rrc_coeffs(alpha, L, span)
%     alpha : facteur de retombée (roll-off), 0 < alpha <= 1
%     L     : nombre d'échantillons par symbole
%     span  : longueur en symboles (N = span*L + 1 coefficients)
%     h     : coefficients, normalisés à énergie unité (sum(h.^2) = 1)
%     t     : instants correspondants, en durées symbole (t/T)
%
%   h(t) = [ 4a/pi cos(pi(1+a)t/T) + (1-a) sinc((1-a)t/T) ] / [ 1 - (4a t/T)^2 ]
%   (le facteur 1/sqrt(T) disparaît dans la normalisation).
%   Valeurs limites :
%     t = 0          : h = 1 - a + 4a/pi
%     t = +-T/(4a)   : h = a/sqrt(2) [ (1 + 2/pi) sin(pi/(4a)) + (1 - 2/pi) cos(pi/(4a)) ]

    t = (-span*L/2 : span*L/2) / L;
    h = zeros(size(t));
    for i = 1:numel(t)
        x = t(i);
        if abs(x) < 1e-12
            h(i) = 1 - alpha + 4*alpha/pi;
        elseif abs(abs(x) - 1/(4*alpha)) < 1e-9
            h(i) = alpha/sqrt(2) * ((1 + 2/pi)*sin(pi/(4*alpha)) + (1 - 2/pi)*cos(pi/(4*alpha)));
        else
            h(i) = (4*alpha/pi*cos(pi*(1 + alpha)*x) + (1 - alpha)*sinc_((1 - alpha)*x)) ...
                   / (1 - (4*alpha*x)^2);
        end
    end
    h = h / sqrt(sum(h.^2));
end

function s = sinc_(x)
    if x == 0, s = 1; else, s = sin(pi*x) / (pi*x); end
end