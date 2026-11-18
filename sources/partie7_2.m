%% partie7_2.m — Transmission d'un texte (question 3)
% Chaîne complète : QPSK + filtres RRC + canal gaussien (sans écho),
% sans puis avec le code de Hamming, pour Eb/N0 = 3 dB et 6 dB.
clear; close all; clc;
Parametres;
Nc = 3000;                                    % nombre de caractères transmis

if ~exist('fichierTexte', 'var'), fichierTexte = 'The_Project_Gutenberg_eBook_of_The.txt'; end
texte  = lire_texte(fichierTexte);
texte  = texte(1:min(Nc, end));
octets = unicode2native(texte, 'UTF-8');      % caractères -> octets
bitsTxt = double(reshape((dec2bin(octets, 8) == '1').', [], 1));   % octets -> bits
nb = numel(bitsTxt);
fprintf('Texte : %d caractères -> %d octets -> %d bits\n', numel(texte), numel(octets), nb);

span = 10;  Nlog = 100;  hc = 1;  graine = P.graine;
hE = rrc_coeffs(alpha, L, span);
vals = [3 6];
res = struct('codage', {}, 'EbN0', {}, 'teb', {}, 'tauxOctets', {}, 'texte', {});

for avecCodage = [false true]
    mdl = construire_modele_chaine_complete(avecCodage);
    if ~avecCodage
        Te = 1;  Tsym = L;  Tb = L/2;  Tpas = 1;  Eb = 1/2;
    else
        Te = 2;  Tsym = 2*L;  Tc = L;  Tb = 7*L/4;  Tpas = 1;  Eb = 7/8;
    end

    % --- Étalonnage sans bruit sur des bits aléatoires ------------------------
    rng(P.graine);
    Nsim = 800;  bits = double(rand(Nsim, 1) < 0.5);
    bits_ws = [(0:Nsim-1).' * Tb, bits];
    N0 = 0;  phaseC = 0;  dAlign = 1;
    meilleur = -inf;
    for d = 1:L
        dPhase = d;
        out = sim(mdl);
        z = out.zsym(:);  z = z(60:end);
        o = min(abs([real(z); imag(z)]));
        if o > meilleur, meilleur = o; dOpt = d; end
    end
    dPhase = dOpt;
    trouve = false;
    phasesC = 0;  alignements = 1;
    if avecCodage, phasesC = 0:6;  alignements = 1:7; end
    for phaseC = phasesC
        for dAlign = alignements
            out = sim(mdl);
            try
                D = trouver_retard(bits, out.rx, 150);
                trouve = true;
            catch
            end
            if trouve, break; end
        end
        if trouve, break; end
    end
    if ~trouve, error('Étalonnage impossible (codage = %d).', avecCodage); end
    fprintf('\nCodage = %d : dPhase = %d, phaseC = %d, dAlign = %d, retard = %d bits\n', ...
            avecCodage, dPhase, phaseC, dAlign, D);

    % --- Transmission du texte ----------------------------------------------------
    pad  = mod(-nb, 4);                       % longueur multiple de 4 pour le codeur
    bits = [bitsTxt; zeros(pad + 4*ceil((D + 20)/4), 1)];
    Nsim = numel(bits);
    bits_ws = [(0:Nsim-1).' * Tb, bits];
    for v = vals
        N0 = Eb / 10^(v/10);
        out = sim(mdl);
        rx  = out.rx(:);
        bRx = rx(1+D : D+nb);
        teb = mean(bRx ~= bitsTxt);
        oRx = uint8((2.^(7:-1:0)) * reshape(bRx, 8, []));
        tauxO = mean(oRx ~= octets);
        tRx = native2unicode(oRx, 'UTF-8');
        res(end+1) = struct('codage', avecCodage, 'EbN0', v, 'teb', teb, ...
                            'tauxOctets', tauxO, 'texte', tRx); %#ok<SAGROW>
        nomFichier = sprintf('texte_recu_%ddB_%s.txt', v, ternaire(avecCodage, 'avec_Hamming', 'sans_codage'));
        fid = fopen(nomFichier, 'w', 'n', 'UTF-8');  fwrite(fid, tRx, 'char');  fclose(fid);
    end
end

%% Résultats
fprintf('\n=== Texte original (début) ===\n%s\n', texte(1:min(300, end)));
for r = res
    fprintf('\n=== Eb/N0 = %d dB, %s : TEB = %.2e, octets faux = %.2f %% ===\n', r.EbN0, ...
            ternaire(r.codage, 'AVEC code de Hamming', 'SANS codage'), r.teb, 100*r.tauxOctets);
    fprintf('%s\n', r.texte(1:min(300, end)));
end
fprintf('\nTextes complets enregistrés dans texte_recu_*.txt\n');

%% ------------------------------------------------------------------------
function s = ternaire(c, a, b)
    if c, s = a; else, s = b; end
end