function bits = source(N, p1)
%SOURCE  Source binaire sans mémoire et stationnaire.
%   bits = source(N, p1) renvoie un vecteur colonne de N bits indépendants,
%   avec P(1) = p1 et P(0) = 1 - p1.
%
%   Principe : on tire U uniforme sur [0,1[ ; P(U < p1) = p1,
%   donc le bit vaut 1 si U < p1 et 0 sinon.
%
%   La graine se fixe AVANT l'appel, avec rng(graine).

    if nargin < 2
        p1 = 0.5;                      % source équiprobable par défaut
    end
    if p1 < 0 || p1 > 1
        error('source : p1 doit être compris entre 0 et 1.');
    end

    bits = double(rand(N, 1) < p1);    % 1 avec probabilité p1
end