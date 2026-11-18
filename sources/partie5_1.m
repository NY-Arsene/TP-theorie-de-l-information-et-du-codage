%% partie5_1.m — Modulation QPSK sans codage (questions 1 à 5)
clear; close all; clc;
Parametres;
Q = @(x) 0.5 * erfc(x / sqrt(2));

% Un symbole toutes les 2Tb, un échantillon complexe par symbole, Es = 1
Tb = 1;  Tsym = 2*Tb;  Tpas = Tb;
Es = 1;  Eb = Es/2;
Nmax = 2e6;

%% Q1 : mappings de Gray et naturel
k     = [1 3 5 7];
sym   = exp(1j*k*pi/4);
gray  = {'11', '01', '00', '10'};             % k = 1, 3, 5, 7
nat   = {'00', '01', '10', '11'};
fprintf('=== Q1 : mapping (symbole e^{jk pi/4}) ===\n');
fprintf('  k |   I     Q   | Gray | naturel\n');
for i = 1:4
    fprintf('  %d | %+.3f %+.3f |  %s  |  %s\n', k(i), real(sym(i)), imag(sym(i)), gray{i}, nat{i});
end
dist = @(a, b) sum(a ~= b);
fprintf('Bits différents entre symboles voisins (k, k+2) :\n');
fprintf('  Gray    : %s\n', mat2str(arrayfun(@(i) dist(gray{i}, gray{mod(i,4)+1}), 1:4)));
fprintf('  naturel : %s\n', mat2str(arrayfun(@(i) dist(nat{i},  nat{mod(i,4)+1}),  1:4)));
fprintf('Es = %g  ->  Eb = Es/2 = %g\n', Es, Eb);

figure('Name', 'Constellations');
for f = 1:2
    subplot(1, 2, f);
    plot(real(sym), imag(sym), 'ko', 'MarkerFaceColor', 'k'); hold on;
    lab = gray;  if f == 2, lab = nat; end
    for i = 1:4
        text(real(sym(i))*1.18, imag(sym(i))*1.18, lab{i}, 'FontSize', 13, ...
             'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    end
    xline(0, 'k:');  yline(0, 'k:');
    axis equal;  axis([-1.4 1.4 -1.4 1.4]);  grid on;
    xlabel('I');  ylabel('Q');
    if f == 1, title('Mapping de Gray'); else, title('Mapping naturel'); end
end

%% Q2 : modèle Simulink et validation sans bruit
mdl = construire_modele_qpsk();
Nsim = 2000;  N0 = 0;
fprintf('\n=== Q2 : validation sans bruit ===\n');
for mappingGray = [1 0]
    out = sim(mdl);
    D = trouver_retard(out.tx, out.rx, 20);
    s = out.ssym(:);
    fprintf('Mapping %-7s : retard = %d bits, bits restitués sans erreur, %d symboles distincts émis\n', ...
            ternaire(mappingGray, 'Gray', 'naturel'), D, numel(unique(round(s*1e6))));
end

%% Q3 : constellations reçues
mappingGray = 1;  Nsim = 4000;
figure('Name', 'Constellations reçues');
vals = [0 5 10];
for i = 1:3
    N0  = Eb / 10^(vals(i)/10);
    out = sim(mdl);
    r   = out.rsym(:);
    subplot(1, 3, i);
    plot(real(r), imag(r), '.', 'MarkerSize', 4); hold on;
    plot(real(sym), imag(sym), 'r+', 'MarkerSize', 14, 'LineWidth', 2);
    xline(0, 'k-');  yline(0, 'k-');
    axis equal;  axis([-2.5 2.5 -2.5 2.5]);  grid on;
    xlabel('I');  ylabel('Q');
    title({sprintf('E_b/N_0 = %d dB', vals(i)), sprintf('\\sigma = %.2f par voie', sqrt(N0/2))});
end

%% Q4-Q5 : TEB, mapping de Gray et mapping naturel
EbN0dB_v = 0:9;
e  = 10.^(EbN0dB_v/10);
q  = Q(sqrt(2*e));                         % TEB théorique Gray = BPSK
qN = 1.5*q - q.^2;                         % TEB théorique mapping naturel
teb = zeros(2, numel(e));  nErr = teb;
fprintf('\n=== Q4-Q5 : TEB ===\n');
fprintf(' Eb/N0 |  TEB Gray  | théorie Q  | TEB naturel | théorie 1,5q - q^2\n');
for i = 1:numel(e)
    N0 = Eb / e(i);
    graine = P.graine + 100*i;
    Nsim = 2 * ceil(min(Nmax, max(1e5, 200/q(i))) / 2);
    for g = 1:2
        mappingGray = 2 - g;               % g = 1 : Gray ; g = 2 : naturel
        out = sim(mdl);
        tx = out.tx(:);  rx = out.rx(:);
        er = tx(10:end-D) ~= rx(10+D:end);
        teb(g, i) = mean(er);  nErr(g, i) = sum(er);
    end
    fprintf('%4d dB | %9.3e  | %9.3e  |  %9.3e  |  %9.3e\n', EbN0dB_v(i), teb(1,i), q(i), teb(2,i), qN(i));
end
fprintf('Rapport TEB naturel / TEB Gray : %s\n', mat2str(teb(2,:)./teb(1,:), 3));

tebBPSK = [];
if isfile('resultats_partie3.mat'), R3 = load('resultats_partie3.mat'); tebBPSK = R3.tebInt; end

xf = linspace(0, 9, 200);  qf = Q(sqrt(2*10.^(xf/10)));
figure('Name', 'TEB QPSK');
semilogy(xf, qf, 'b-', 'LineWidth', 1.5); hold on;
semilogy(EbN0dB_v, teb(1,:), 'bo', 'LineWidth', 1.5);
semilogy(xf, 1.5*qf - qf.^2, 'r-', 'LineWidth', 1.2);
semilogy(EbN0dB_v, teb(2,:), 'rs', 'LineWidth', 1.5);
leg = {'Théorie Gray = BPSK : Q(\surd(2E_b/N_0))', 'QPSK Gray (simulation)', ...
       'Théorie naturel : 1,5q - q^2', 'QPSK naturel (simulation)'};
if ~isempty(tebBPSK)
    semilogy(EbN0dB_v, tebBPSK, 'kx', 'MarkerSize', 9, 'LineWidth', 1.5);
    leg{end+1} = 'Chaîne binaire, partie 3 (simulation)';
end
grid on;  ylim([1e-6 1]);
xlabel('E_b/N_0 (dB)');  ylabel('Taux d''erreur binaire');
title('Modulation QPSK : mapping de Gray et naturel');
legend(leg, 'Location', 'southwest');

save('resultats_partie5.mat', 'EbN0dB_v', 'teb', 'nErr');

%% ------------------------------------------------------------------------
function s = ternaire(c, a, b)
    if c, s = a; else, s = b; end
end