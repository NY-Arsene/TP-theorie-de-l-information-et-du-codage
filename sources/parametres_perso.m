function P = parametres_perso(nom)
%PARAMETRES_PERSO Paramètres personnels du TP « chaîne de transmission ».

n = upper(strtrim(nom));
% c = rand(1);   % <- version reçue : rend les valeurs aléatoires 
c = double(n);   % codes des caractères du nom -> valeurs déterminées par le nom
graine = mod(sum(c .* (1:numel(c)) * 31) + 7 * numel(c), 2^31 - 1);
s = RandStream('mt19937ar', 'Seed', graine);
u = @(a, b) a + (b - a) * rand(s);
P.nom = n;
P.p1 = round(u(0.15, 0.40) * 100) / 100; % P(bit = 1), parties 2 et 3
P.pe_cbs = round(u(0.02, 0.15) * 1000) / 1000; % canal binaire symétrique
P.A = 1; % amplitude
P.a_unif = round(u(1.2, 2.0) * 100) / 100; % bruit uniforme sur [-a, a]
P.sigma = round(u(0.5, 0.9) * 100) / 100; % bruit gaussien (partie 3)
Ls = [4 8 16];
P.L = Ls(randi(s, 3)); % échantillons par bit
alphas = [0.22 0.25 0.35];
P.alpha = alphas(randi(s, 3)); % roll-off du filtre RRC
P.beta = round(u(0.2, 0.5) * 100) / 100; % amplitude de l'écho
P.retard_trajet = randi(s, 2); % retard de l'écho (symboles)
P.graine = mod(graine, 1e6);
P.p1_ext = round(u(0.05, 0.15) * 100) / 100; % source très déséquilibrée
end