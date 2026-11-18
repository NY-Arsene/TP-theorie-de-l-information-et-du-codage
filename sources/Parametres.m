%% Parametres.m — Paramètres de la chaîne de transmission 
% TP : Modélisation et simulation d'une chaîne de transmission numérique en bande de base
% ENSIM 5A ASTRE — Théorie de l'information et du codage

%% Identité 
nomEtudiant = 'NGUENANG Arsene';             

%% Paramètres personnels (fonction fournie par l'enseignant)
P = parametres_perso(nomEtudiant);

p1     = P.p1;             % probabilité d'émettre un 1 (parties 2 et 3)
p1_ext = P.p1_ext;         % source très déséquilibrée (partie 2.3)
pe     = P.pe_cbs;         % probabilité d'erreur du canal binaire symétrique
A      = P.A;              % amplitude : bit 0 -> -A, bit 1 -> +A
a      = P.a_unif;         % bruit uniforme sur [-a, a] (partie 3)
sigma  = P.sigma;          % écart-type du bruit gaussien (partie 3)
L      = P.L;              % nombre d'échantillons par bit / par symbole
alpha  = P.alpha;          % facteur de retombée du filtre RRC (partie 6)
beta   = P.beta;           % amplitude de l'écho (partie 7)
tau    = P.retard_trajet;  % retard de l'écho, en durées symbole (partie 7)
graine = P.graine;         % graine des tirages aléatoires (reproductibilité)

%% Conventions générales
Tb = 1;                    % durée d'un bit (unité de référence)

%% Grandeurs dérivées
p0 = 1 - p1;               % probabilité d'émettre un 0
Db = 1/Tb;                 % débit binaire (bit/s)
Te = Tb/L;                 % période d'échantillonnage
Eb = A^2*Tb;               % énergie par bit d'information

%% Affichage
fprintf('--- Parametres de la source ---\n');
fprintf('p0 = %.2f | p1 = %.2f\n', p0, p1);