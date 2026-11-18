%% partie3_1.m — Canal binaire symétrique (questions 1 à 3)
clear; close all; clc;
Parametres;
Nsim = 1e5;

%% Q1-Q2 : modèle Simulink du CBS et TEB simulé
mdl = construire_modele_canal('cbs');
out = sim(mdl);
tx = out.tx(:);  rx = out.rx(:);

nErr = sum(tx ~= rx);
teb  = nErr / numel(tx);
IC   = 1.96 * sqrt(teb*(1-teb) / numel(tx));
fprintf('=== Q2 : canal binaire symétrique ===\n');
fprintf('pe (paramètre)  = %.4f\n', pe);
fprintf('TEB simulé      = %.4f  (%d erreurs sur %d bits)\n', teb, nErr, numel(tx));
fprintf('IC à 95 %%       = [%.4f ; %.4f]  ->  pe dans l''IC : %d\n', ...
        teb-IC, teb+IC, abs(teb-pe) <= IC);

%% Q3 : capacité du CBS
R = 4/7;                                          % rendement du code de Hamming
C = 1 - entropie_binaire(pe);
pe_lim = fzero(@(x) 1 - entropie_binaire(x) - R, [1e-9, 0.5]);
fprintf('\n=== Q3 : capacité ===\n');
fprintf('C = 1 - H(pe) = %.4f bit/utilisation du canal\n', C);
fprintf('R = 4/7 = %.4f  ->  R < C : %d\n', R, R < C);
fprintf('Transmission fiable à R = 4/7 possible tant que pe < %.4f (ou pe > %.4f)\n', ...
        pe_lim, 1 - pe_lim);

x = linspace(0, 1, 1001);
figure('Name', 'Capacité du CBS');
plot(x, 1 - entropie_binaire(x), 'LineWidth', 1.5); hold on;
yline(R, 'r--', 'R = 4/7', 'LineWidth', 1.2);
plot(pe, C, 'ko', 'MarkerFaceColor', 'k');
xline(pe_lim, 'k:'); xline(1 - pe_lim, 'k:');
grid on;
xlabel('Probabilité d''erreur p_e');
ylabel('Capacité C (bit/utilisation)');
title('Capacité du canal binaire symétrique');
legend('C(p_e) = 1 - H(p_e)', 'Rendement R = 4/7', ...
       sprintf('Notre canal : p_e = %.3f, C = %.3f', pe, C), 'Location', 'north');