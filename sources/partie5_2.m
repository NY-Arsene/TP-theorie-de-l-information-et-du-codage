%% partie5_2.m — QPSK avec code de Hamming C(7,4) (question 6)
clear; close all; clc;
Parametres;
Q = @(x) 0.5 * erfc(x / sqrt(2));

% Unité de temps : Tb = 7 -> Tc = 4 (bit codé), Tsym = 2Tc = 8 (symbole QPSK)
Tb = 7;  Tc = 4*Tb/7;  Tsym = 2*Tc;  Tpas = 1;
Es = 1;                  % énergie par symbole
Eb = 7/8 * Es;           % 2 bits codés par symbole, 4/7 bit d'information par bit codé
mappingGray = 1;
Nmax = 2e6;

mdl = construire_modele_qpsk_codee();

%% Étalonnage sans bruit
Nsim = 400;  N0 = 0;
trouve = false;
for phaseC = 0:6
    for dAlign = 1:7
        out = sim(mdl);
        try
            D = trouver_retard(out.tx, out.rx, 80);
            trouve = true;
        catch
        end
        if trouve, break; end
    end
    if trouve, break; end
end
if ~trouve, error('Étalonnage impossible.'); end
Dc = trouver_retard(out.cTx, out.cRx, 40);
fprintf('=== Étalonnage ===\nphaseC = %d, dAlign = %d, retard bits codés = %d, retard total = %d Tb\n', ...
        phaseC, dAlign, Dc, D);

%% TEB en fonction de Eb/N0
EbN0dB_v = 0:9;
e   = 10.^(EbN0dB_v/10);
pth = Q(sqrt(2*4/7*e));
Pb_approx = zeros(size(e));
for j = 2:7
    Pb_approx = Pb_approx + (j/7)*nchoosek(7, j)*pth.^j.*(1 - pth).^(7 - j);
end
tebQ = zeros(size(e));  nErr = tebQ;  pRaw = tebQ;
fprintf('\n Eb/N0 |  N bits  | erreurs | TEB QPSK codé | p brut simulé | p théorique\n');
for i = 1:numel(e)
    N0     = Eb / e(i);
    graine = P.graine + 100*i;
    Nsim   = 4 * ceil(min(Nmax, max(1e5, 200/(1.5*Pb_approx(i)))) / 4);
    tic; out = sim(mdl); ts = toc;
    tx = out.tx(:);  rx = out.rx(:);
    er = tx(10:end-D) ~= rx(10+D:end);
    tebQ(i) = mean(er);  nErr(i) = sum(er);
    cT = out.cTx(:);  cR = out.cRx(:);
    pRaw(i) = mean(cT(10:end-Dc) ~= cR(10+Dc:end));
    fprintf('%4d dB | %8d | %7d |   %9.3e   |   %9.3e   | %9.3e   [%.0f s]\n', ...
            EbN0dB_v(i), numel(er), nErr(i), tebQ(i), pRaw(i), pth(i), ts);
end

%% Comparaison avec la partie 4 (codage + modulation binaire)
tebP4 = [];
if isfile('resultats_partie4.mat'), R4 = load('resultats_partie4.mat'); tebP4 = R4.tebC; end
xf = linspace(0, 9, 200);
figure('Name', 'QPSK codée');
semilogy(xf, Q(sqrt(2*10.^(xf/10))), 'b-', 'LineWidth', 1.5); hold on;
leg = {'Sans codage : théorie'};
if ~isempty(tebP4)
    semilogy(EbN0dB_v, tebP4, 'ks--', 'LineWidth', 1.2);
    leg{end+1} = 'Codage + modulation binaire (partie 4)';
end
semilogy(EbN0dB_v, tebQ, 'ro-', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
semilogy(EbN0dB_v, Pb_approx, 'r:', 'LineWidth', 1.2);
leg = [leg, {'Codage + QPSK Gray (simulation)', 'Codage : approximation'}];
grid on;  ylim([1e-6 1]);
xlabel('E_b/N_0 (dB)');  ylabel('Taux d''erreur binaire');
title('Code C(7,4) avec modulation QPSK');
legend(leg, 'Location', 'southwest');

fprintf('\nCadence des symboles : %.3f symbole par Tb (contre 7/4 = 1,75 bit codé par Tb en binaire)\n', Tb/Tsym);
save('resultats_partie5_codee.mat', 'EbN0dB_v', 'tebQ', 'nErr', 'pRaw', 'D');