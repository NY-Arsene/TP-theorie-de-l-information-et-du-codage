%% partie4_4.m — Insertion du code C(7,4) dans la chaîne (questions 10 à 12)
clear; close all; clc;
Parametres;
Q = @(x) 0.5 * erfc(x / sqrt(2));

% Unité de temps choisie pour que toutes les cadences soient entières :
% Tb = 7L  ->  Tc = 4Tb/7 = 4L (bit codé),  Tec = Tc/L = 4 (échantillon).
% Le TEB ne dépend que de Eb/N0 : ce choix ne change aucun résultat.
Tb  = 7 * L;
Eb  = A^2 * Tb;
Tc  = 4 * Tb / 7;
Tec = Tc / L;
Ac  = A * sqrt(4/7);                      % amplitude d'un bit codé (Eb conservée)
Nmax = 2e6;                               % nombre maximal de bits d'information par point

mdl = construire_modele_chaine_codee();

%% Étalonnage sans bruit
Nsim = 400;  sigma2e = 0;  phaseC = 0;  dAlign = 1;
% 1) instant d'échantillonnage : z doit valoir exactement ±Ac
trouve = false;
for d = 1:L
    dPhase = d;
    out = sim(mdl);
    z = out.z(:);
    if max(abs(abs(z(20:end)) - Ac)) < 1e-9, trouve = true; break; end
end
if ~trouve, error('Étalonnage de la phase d''échantillonnage impossible.'); end
Dc = trouver_retard(out.cTx, out.cRx, 20);            % retard du canal (bits codés)

% 2) horloge de mot du codeur et alignement des mots au décodeur
trouve = false;
for phaseC = 0:6
    for dAlign = 1:7
        out = sim(mdl);
        try
            D = trouver_retard(out.tx, out.rx, 80);   % retard total (bits d'information)
            trouve = true;
        catch
        end
        if trouve, break; end
    end
    if trouve, break; end
end
if ~trouve, error('Étalonnage impossible : aucun réglage ne restitue les bits émis.'); end
fprintf('=== Étalonnage (sans bruit), L = %d ===\n', L);
fprintf('dPhase = %d échantillon(s), phaseC = %d, dAlign = %d\n', dPhase, phaseC, dAlign);
fprintf('Retard du canal : %d bit(s) codé(s)\n', Dc);
fprintf('Retard total source -> sortie du décodeur : %d bits d''information = %.1f Tb\n', D, D);

%% Q10 : TEB en fonction de Eb/N0
EbN0dB_v = 0:9;
e    = 10.^(EbN0dB_v / 10);
pu   = Q(sqrt(2 * e));                    % sans codage (théorie)
pth  = Q(sqrt(2 * 4/7 * e));              % bit codé avant correction (théorie)
Pb_approx = zeros(size(e));
for j = 2:7
    Pb_approx = Pb_approx + (j/7) * nchoosek(7, j) * pth.^j .* (1 - pth).^(7 - j);
end

tebC = zeros(size(e));  nErr = tebC;  nBits = tebC;  pRaw = tebC;
fprintf('\n Eb/N0 |  N bits  | erreurs |  TEB codé  | approx. | p brut simulé | p théorique\n');
for i = 1:numel(e)
    N0      = Eb / e(i);
    sigma2e = N0 * L / (2 * Tb);          % même variance par échantillon que sans codage
    Nsim    = 4 * ceil(min(Nmax, max(1e5, 200 / (1.5 * Pb_approx(i)))) / 4);
    graine  = P.graine + 100*i;           % réalisation indépendante pour chaque point
    tic; out = sim(mdl); ts = toc;

    tx = out.tx(:);  rx = out.rx(:);
    eI = tx(10:end-D) ~= rx(10+D:end);
    tebC(i) = mean(eI);  nErr(i) = sum(eI);  nBits(i) = numel(eI);
    cT = out.cTx(:);  cR = out.cRx(:);
    pRaw(i) = mean(cT(10:end-Dc) ~= cR(10+Dc:end));
    fprintf('%4d dB | %8d | %7d | %9.3e | %7.1e |   %9.3e   | %9.3e   [%.0f s]\n', ...
            EbN0dB_v(i), nBits(i), nErr(i), tebC(i), Pb_approx(i), pRaw(i), pth(i), ts);
end

%% Chaîne sans codage (résultats de la partie 3)
tebNC = [];
if isfile('resultats_partie3.mat')
    R3 = load('resultats_partie3.mat');
    tebNC = R3.tebInt;
end

%% Q11 : gain de codage et point de croisement
lc = log10(tebC);  lu = log10(pu);
d  = lc - lu;
k  = find(d(1:end-1) > 0 & d(2:end) <= 0, 1);
if ~isempty(k)
    xCross = EbN0dB_v(k) + d(k) / (d(k) - d(k+1));
    fprintf('\nLe codage devient avantageux au-delà de Eb/N0 = %.2f dB\n', xCross);
end
ok = tebC > 0;
xU = interp1(lu, EbN0dB_v, -4);
xC = interp1(lc(ok), EbN0dB_v(ok), -4);
fprintf('TEB = 1e-4 : %.2f dB sans codage, %.2f dB avec codage  ->  gain de codage = %.2f dB\n', ...
        xU, xC, xU - xC);
R = 4/7;
limR = (2^(2*R) - 1) / (2*R);
fprintf('Limite de Shannon pour R = 4/7 : %.2f dB  |  limite absolue ln 2 : %.2f dB\n', ...
        10*log10(limR), 10*log10(log(2)));
fprintf('Écart à la limite de Shannon (R = 4/7) à 1e-4 : %.1f dB\n', xC - 10*log10(limR));

%% Q12 : latence et débit
fprintf('\n=== Q12 ===\n');
fprintf('Retard mesuré : %d Tb avec codage (contre 2 Tb sans codage en partie 3)\n', D);
fprintf('Débit binaire sur le canal : 7/4 = %.2f fois le débit utile\n', 7/4);

%% Figure
xf = linspace(-2, 10, 300);  ef = 10.^(xf / 10);
figure('Name', 'TEB avec et sans codage');
semilogy(xf, Q(sqrt(2 * ef)), 'b-', 'LineWidth', 1.5); hold on;
if ~isempty(tebNC)
    semilogy(EbN0dB_v, tebNC, 'bo', 'LineWidth', 1.5);
end
semilogy(EbN0dB_v, Pb_approx, 'r--', 'LineWidth', 1.2);
semilogy(EbN0dB_v, tebC, 'rs-', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
semilogy(EbN0dB_v, pRaw, 'k:', 'LineWidth', 1.2);
xline(10*log10(limR), 'g-', 'Shannon R = 4/7', 'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom');
xline(10*log10(log(2)), 'g--', 'ln 2', 'LineWidth', 1.2, 'LabelVerticalAlignment', 'bottom');
grid on;  ylim([1e-6 1]);  xlim([-2 10]);
xlabel('E_b/N_0 (dB)');  ylabel('Taux d''erreur binaire');
title(sprintf('Chaîne avec code de Hamming C(7,4), L = %d', L));
leg = {'Sans codage : théorie'};
if ~isempty(tebNC), leg{end+1} = 'Sans codage : simulation (partie 3)'; end
leg = [leg, {'Avec codage : approximation', 'Avec codage : simulation Simulink', ...
             'Bits codés avant correction (simulés)'}];
legend(leg, 'Location', 'southwest');

save('resultats_partie4.mat', 'EbN0dB_v', 'tebC', 'nErr', 'nBits', 'pRaw', 'D');