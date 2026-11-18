%% partie6_2.m — Chaîne QPSK avec filtres de mise en forme et filtre adapté (Q1, Q5, Q6)
clear; close all; clc;
Parametres;
Q = @(x) 0.5 * erfc(x / sqrt(2));

% Unité de temps : un échantillon = 1  ->  Ts = L (symbole), Tb = L/2 (bit)
Te = 1;  Ts = L;  Tb = L/2;
Es = 1;  Eb = Es/2;
span = 10;
Nmax = 1e6;
Nlog = 400*L;                              % points gardés pour le diagramme de l'œil

mdl = construire_modele_qpsk_filtre();

%% Configurations étudiées
configs = struct('nom', {}, 'h', {}, 'decal', {});
configs(end+1) = struct('nom', 'Porte', 'h', ones(1, L)/sqrt(L), 'decal', 0);
configs(end+1) = struct('nom', sprintf('RRC a = %.2f', alpha), 'h', rrc_coeffs(alpha, L, span), 'decal', 0);
if alpha ~= 0.22
    configs(end+1) = struct('nom', 'RRC a = 0.22', 'h', rrc_coeffs(0.22, L, span), 'decal', 0);
end
configs(end+1) = struct('nom', 'RRC a = 1', 'h', rrc_coeffs(1, L, span), 'decal', 0);
configs(end+1) = struct('nom', 'RRC a = 0.22, décalage T/4', 'h', rrc_coeffs(0.22, L, span), 'decal', L/4);
configs(end+1) = struct('nom', 'RRC a = 1, décalage T/4',    'h', rrc_coeffs(1, L, span),    'decal', L/4);
nc = numel(configs);

EbN0dB_v = 0:9;
e  = 10.^(EbN0dB_v/10);
q  = Q(sqrt(2*e));
teb = nan(nc, numel(e));  nErr = teb;
ouv = zeros(1, nc);  Dc = zeros(1, nc);  dOpt = zeros(1, nc);

figOeil = figure('Name', 'Diagrammes de l''oeil (sans bruit)');
figCons = figure('Name', 'Constellations à Eb/N0 = 10 dB');
nl = 2;  ncol = ceil(nc/2);

for c = 1:nc
    hE = configs(c).h;
    graine = P.graine;

    % --- Étalonnage sans bruit : phase d'échantillonnage optimale -----------
    N0 = 0;  Nsim = 2000;
    meilleur = -inf;
    for d = 1:L
        dPhase = d;
        out = sim(mdl);
        z = out.zsym(:);  z = z(30:end);
        o = min(abs([real(z); imag(z)]));
        if o > meilleur, meilleur = o; dOpt(c) = d; end
    end
    dPhase = dOpt(c);
    out0 = sim(mdl);
    Dc(c) = trouver_retard(out0.tx, out0.rx, 80);
    ye0 = real(out0.ye(:));
    m = arrayfun(@(p) mean(abs(ye0(p:L:end))), 1:L);
    [~, pOpt] = max(m);                    % instant optimal dans la sortie du filtre adapté

    % --- Diagramme de l'œil (sans bruit), avec le décalage éventuel ----------
    dPhase = dOpt(c) + configs(c).decal;
    out = sim(mdl);
    z = out.zsym(:);  z = z(30:end);
    ouv(c) = min(abs([real(z); imag(z)])); % ouverture verticale minimale (idéal : 1/sqrt(2))
    centres = (pOpt + 2*L) : L : (numel(ye0) - L);
    figure(figOeil);  subplot(nl, ncol, c);
    for ci = centres(1:min(200, end))
        plot((-L:L)/L, ye0(ci-L:ci+L), 'b-');  hold on;
    end
    xline(-configs(c).decal/L, 'r-', 'LineWidth', 1.5);
    yline([-1 1]/sqrt(2), 'k:');
    grid on;  xlabel('t / T');  ylabel('voie I');
    title({configs(c).nom, sprintf('ouverture min = %.3f', ouv(c))});

    % --- Constellation à 10 dB ----------------------------------------------
    N0 = Eb / 10;  Nsim = 4000;
    out = sim(mdl);
    z = out.zsym(:);  z = z(30:end);
    figure(figCons);  subplot(nl, ncol, c);
    plot(real(z), imag(z), '.', 'MarkerSize', 4);  hold on;
    plot([1 -1 -1 1]/sqrt(2), [1 1 -1 -1]/sqrt(2), 'r+', 'MarkerSize', 12, 'LineWidth', 2);
    xline(0, 'k-');  yline(0, 'k-');
    axis equal;  axis([-1.6 1.6 -1.6 1.6]);  grid on;
    title(configs(c).nom);

    % --- TEB ------------------------------------------------------------------
    for i = 1:numel(e)
        N0 = Eb / e(i);
        graine = P.graine + 100*i;
        Nsim = 2 * ceil(min(Nmax, max(1e5, 200/q(i))) / 2);
        out = sim(mdl);
        tx = out.tx(:);  rx = out.rx(:);
        er = tx(10:end-Dc(c)) ~= rx(10+Dc(c):end);
        teb(c, i) = mean(er);  nErr(c, i) = sum(er);
    end
    fprintf('%-28s : dPhase = %d, retard = %d bits, ouverture = %.3f, TEB(6 dB) = %.3e, TEB(9 dB) = %.3e\n', ...
            configs(c).nom, dOpt(c), Dc(c), ouv(c), teb(c, 7), teb(c, 10));
end
% L'œil est tracé avec la phase optimale ; le trait rouge marque l'instant réellement utilisé.

%% Tableau et figure des TEB
fprintf('\n Eb/N0 | théorie   ');
fprintf('| %-12s', configs.nom);  fprintf('\n');
for i = 1:numel(e)
    fprintf('%4d dB | %9.3e ', EbN0dB_v(i), q(i));
    fprintf('| %-12.3e', teb(:, i));  fprintf('\n');
end

tebP5 = [];
if isfile('resultats_partie5.mat'), R5 = load('resultats_partie5.mat'); tebP5 = R5.teb(1, :); end
xf = linspace(0, 9, 200);
figure('Name', 'TEB avec filtres');
semilogy(xf, Q(sqrt(2*10.^(xf/10))), 'k-', 'LineWidth', 1.5);  hold on;
leg = {'Théorie Q(\surd(2E_b/N_0))'};
if ~isempty(tebP5)
    semilogy(EbN0dB_v, tebP5, 'kx', 'MarkerSize', 9, 'LineWidth', 1.2);
    leg{end+1} = 'QPSK sans filtre (partie 5)';
end
marq = {'o-', 's-', 'd-', '^-', 'v--', 'p--'};
for c = 1:nc
    semilogy(EbN0dB_v, teb(c, :), marq{c}, 'LineWidth', 1.2);
    leg{end+1} = configs(c).nom; %#ok<SAGROW>
end
grid on;  ylim([1e-6 1]);
xlabel('E_b/N_0 (dB)');  ylabel('Taux d''erreur binaire');
title(sprintf('QPSK avec filtres de mise en forme (L = %d, span = %d)', L, span));
legend(leg, 'Location', 'southwest');

save('resultats_partie6.mat', 'EbN0dB_v', 'teb', 'nErr', 'ouv', 'configs');