%% partie3_4.m — Chaîne de base à L échantillons par bit (questions 10 à 13)
clear; close all; clc;
Parametres;
Q = @(x) 0.5 * erfc(x / sqrt(2));

mdl = construire_modele_chaine_base();

%% Étalonnage sans bruit : instant d'échantillonnage et retard
% Sans bruit, z_k doit valoir exactement ±A si l'intégration porte sur un
% bit entier : on cherche le retard dPhase (en échantillons) qui le garantit.
Nsim = 500;  sigma2e = 0;
trouve = false;
for d = 1:L
    dPhase = d;
    dMid   = d + floor((L-1)/2);          % milieu du même bit
    out = sim(mdl);
    z = out.z(:);
    if max(abs(abs(z(5:end)) - A)) < 1e-9
        trouve = true;  break;
    end
end
if ~trouve, error('Étalonnage impossible : vérifier le modèle.'); end
D  = trouver_retard(out.tx, out.rxInt);   % retard de la voie intégrateur (bits)
DM = trouver_retard(out.tx, out.rxMid);   % retard de la voie milieu (bits)
fprintf('=== Étalonnage (sans bruit), L = %d ===\n', L);
fprintf('Phase d''échantillonnage : dPhase = %d échantillons, dMid = %d\n', dPhase, dMid);
fprintf('Retard entre bits émis et reçus : %d bit(s) (intégrateur), %d bit(s) (milieu)\n', D, DM);

%% Q10-Q11 : visualisation et variance du bruit après intégration (Eb/N0 = 5 dB)
EbN0dB  = 5;
N0      = Eb / 10^(EbN0dB/10);
sigma2e = N0 * L / (2*Tb);                % variance du bruit par échantillon
Nsim    = 2e4;
out = sim(mdl);

tx = out.tx(:);  z = out.z(:);
xk = 2*A*tx(5:end-D) - A;                 % niveaux émis, alignés
nz = z(5+D:end) - xk;                     % bruit en sortie d'intégrateur
fprintf('\n=== Q11 : Eb/N0 = %d dB ===\n', EbN0dB);
fprintf('Variance par échantillon sigma^2 = N0 L/(2Tb) = %.4f\n', sigma2e);
fprintf('Variance après intégration : mesurée %.4f, théorique sigma^2/L = N0/(2Tb) = %.4f\n', ...
        var(nz), N0/(2*Tb));

t = (0:20*L-1) * Te;
figure('Name', 'Signaux');
plot(t, out.x(:), 'LineWidth', 1.5); hold on;
plot(t, out.r(:), '.-');
grid on; xlabel('t / T_b'); ylabel('Amplitude');
title(sprintf('Signal émis et signal reçu (20 bits, L = %d, E_b/N_0 = %d dB)', L, EbN0dB));
legend('x(t) émis', 'r(t) reçu');

%% Q12 : courbe de TEB pilotée par script
EbN0dB_v = 0:9;
tebInt = zeros(size(EbN0dB_v));  tebMid = tebInt;  nErrInt = tebInt;  nBits = tebInt;
fprintf('\n=== Q12 : TEB en fonction de Eb/N0 ===\n');
fprintf(' Eb/N0   N bits    erreurs   TEB intégr.   théorie     TEB milieu   théorie milieu\n');
for i = 1:numel(EbN0dB_v)
    N0      = Eb / 10^(EbN0dB_v(i)/10);
    sigma2e = N0 * L / (2*Tb);
    Pth     = Q(sqrt(2*Eb/N0));
    Nsim    = min(1e6, max(1e5, ceil(200 / Pth)));   % viser ~200 erreurs
    tic; out = sim(mdl); ts = toc;

    tx = out.tx(:);
    eI = tx(5:end-D)  ~= out.rxInt(5+D:end);
    eM = tx(5:end-DM) ~= out.rxMid(5+DM:end);
    tebInt(i) = mean(eI);  nErrInt(i) = sum(eI);  nBits(i) = numel(eI);
    tebMid(i) = mean(eM);
    fprintf('%4d dB  %8d  %8d   %10.3e  %10.3e   %10.3e   %10.3e   [%.0f s]\n', ...
            EbN0dB_v(i), nBits(i), nErrInt(i), tebInt(i), Pth, tebMid(i), ...
            Q(sqrt(2*Eb/(N0*L))), ts);
end

xf = linspace(0, 9, 200);
figure('Name', 'TEB chaîne de base');
semilogy(xf, Q(sqrt(2*10.^(xf/10))), 'b-', 'LineWidth', 1.5); hold on;
semilogy(EbN0dB_v, tebInt, 'bo', 'LineWidth', 1.5);
semilogy(xf, Q(sqrt(2*10.^(xf/10)/L)), 'r-', 'LineWidth', 1.2);
semilogy(EbN0dB_v, tebMid, 'rs', 'LineWidth', 1.5);
if exist('berawgn', 'file')
    semilogy(EbN0dB_v, berawgn(EbN0dB_v, 'psk', 2, 'nondiff'), 'k+', 'MarkerSize', 8);
end
grid on; ylim([1e-6 1]);
xlabel('E_b/N_0 (dB)'); ylabel('Taux d''erreur binaire');
title(sprintf('Chaîne de base, L = %d échantillons par bit', L));
legend('Théorie Q(\surd(2E_b/N_0))', 'Simulation : intégrateur', ...
       'Théorie : 1 échantillon', 'Simulation : 1 échantillon au milieu', ...
       'berawgn (Toolbox)', 'Location', 'southwest');

save('resultats_partie3.mat', 'EbN0dB_v', 'tebInt', 'tebMid', 'nErrInt', 'nBits');

%% Q13 (complément) : loi du bruit uniforme après intégration
Nq = 1e5;
nU = a * (2*rand(L, Nq) - 1);             % L échantillons uniformes sur [-a, a] par bit
mU = mean(nU, 1);                          % sortie de l'intégrateur
vU = a^2 / (3*L);                          % variance théorique
uu = linspace(-a, a, 500);
figure('Name', 'Bruit uniforme intégré');
histogram(mU, 100, 'Normalization', 'pdf'); hold on;
plot(uu, exp(-uu.^2/(2*vU)) / sqrt(2*pi*vU), 'r', 'LineWidth', 1.5);
plot(uu, ones(size(uu)) / (2*a), 'k--', 'LineWidth', 1.2);
grid on; xlabel('Bruit après intégration'); ylabel('Densité');
title(sprintf('Moyenne de L = %d bruits uniformes sur [-a, a], a = %.2f', L, a));
legend('Histogramme', sprintf('Gaussienne, variance a^2/(3L) = %.3f', vU), ...
       'Uniforme d''origine', 'Location', 'northeast');