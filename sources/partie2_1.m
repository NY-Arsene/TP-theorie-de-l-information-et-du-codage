%% partie2_1.m — Source binaire et entropie (questions 1 et 2)
clear; close all; clc;
Parametres;                                  % charge Tb, p1, graine, ...

%% Q1-Q2 : source MATLAB, vérification sur 1e5 bits
N = 1e5;
rng(graine);
b = source(N, p1);

p1_hat = mean(b);                            % fréquence empirique des 1
IC     = 1.96*sqrt(p1_hat*(1-p1_hat)/N);     % demi-largeur de l'IC à 95 %
fprintf('--- Source MATLAB (N = %d bits) ---\n', N);
fprintf('p1 théorique  = %.4f\n', p1);
fprintf('p1 empirique  = %.4f   IC 95%% = [%.4f ; %.4f]\n', ...
        p1_hat, p1_hat-IC, p1_hat+IC);
if abs(p1_hat - p1) <= IC
    fprintf('=> p1 est dans l''intervalle de confiance : compatible.\n');
else
    fprintf('=> p1 hors de l''intervalle de confiance (à commenter).\n');
end

%% Entropie de la source et débit d'information
H  = entropie_binaire(p1);
Di = H*Db;                                   % débit d'information (bit/s)
fprintf('\nEntropie H(p1) = %.4f bit/symbole\n', H);
fprintf('Débit binaire  = %.0f bit/s  ->  débit d''information = %.4f bit/s\n', Db, Di);

%% Courbe H(p) pour p dans [0,1]
p = linspace(0, 1, 1001);
figure('Name', 'Entropie binaire');
plot(p, entropie_binaire(p), 'LineWidth', 1.5); hold on;
plot(p1, H, 'ro', 'MarkerFaceColor', 'r');
grid on;
xlabel('Probabilité p d''émettre un 1');
ylabel('H(p) (bit/symbole)');
title({'Entropie d''une source binaire', 'sans mémoire'});
legend('H(p)', sprintf('Notre source : p_1 = %.2f, H = %.3f', p1, H), ...
       'Location', 'south');

%% Version Simulink : construction du modèle puis simulation
Nsim = N;                                    % utilisé par le StopTime du modèle
construire_modele_source('modele_source');
out = sim('modele_source');
bS  = out.bits(:);

p1_hat_S = mean(bS);
IC_S     = 1.96*sqrt(p1_hat_S*(1-p1_hat_S)/numel(bS));
fprintf('\n--- Source Simulink (%d bits) ---\n', numel(bS));
fprintf('p1 empirique  = %.4f   IC 95%% = [%.4f ; %.4f]\n', ...
        p1_hat_S, p1_hat_S-IC_S, p1_hat_S+IC_S);