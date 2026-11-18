%% partie4_2.m — Codeur et décodeur C(7,4) sous Simulink (questions 4 à 6)
clear; close all; clc;
[G, H] = hamming74();
Tc = 1;                                     % une période d'horloge par bit codé

msgs  = dec2bin(0:15, 4) - '0';             % 16 messages, colonnes [m0 m1 m2 m3]
Cref  = mod(msgs * G, 2);                   % référence matricielle [m0..m3 r0 r1 r2]
ordre = [4 3 2 1 7 6 5];                    % ordre série : m3 m2 m1 m0 r2 r1 r0

%% Q5 (a) : table des états du registre pour m = [1, 0, 1, 1]
m = [1 0 1 1];                              % m0 m1 m2 m3
u = [m([4 3 2 1]) 0 0 0].';
Nw = 1;
u_ws = [(0:numel(u)-1).' * Tc, u];
mdlC = construire_modele_codeur_registre();
out  = sim(mdlC);
s = double([out.s0(:) out.s1(:) out.s2(:)]);    % état AVANT chaque coup d'horloge
fprintf('=== Q5 : table des états pour m = [m0 m1 m2 m3] = [1 0 1 1] ===\n');
fprintf(' coup | ctrl | entrée |  f | s0 s1 s2 (après) | sortie\n');
fprintf(' init |      |        |    |  %d  %d  %d          |\n', s(1, :));
for n = 0:6
    fprintf('  %d   |  %d   |   %d    |  %d |  %d  %d  %d          |   %d\n', n, ...
        out.ctrl(n+1), u(n+1), double(out.f(n+1)), s(n+2, :), out.c(n+1));
end
cS = out.c(1:7).';
fprintf('Mot émis (ordre série m3 m2 m1 m0 r2 r1 r0) : %s\n', mat2str(cS));
cRef = mod(m * G, 2);
fprintf('Référence matricielle (même ordre)          : %s\n', mat2str(cRef(ordre)));

%% Q5 (b) : les 16 messages
u  = reshape([msgs(:, [4 3 2 1]) zeros(16, 3)].', [], 1);
Nw = 16;
u_ws = [(0:numel(u)-1).' * Tc, u];
out  = sim(mdlC);
Cs   = reshape(out.c(1:7*Nw), 7, []).';
fprintf('\nCodeur à registre = codeur matriciel pour les 16 messages : %d\n', ...
        isequal(Cs, Cref(:, ordre)));

%% Q6 : décodeur, sans erreur puis avec une erreur à chacune des 7 positions
Y = [];
for e = 0:7                                  % e = 0 : pas d'erreur
    Ye = Cref(:, ordre);
    if e > 0, Ye(:, e) = 1 - Ye(:, e); end   % erreur en position série e
    Y = [Y; Ye];                             %#ok<AGROW>
end
y  = reshape(Y.', [], 1);
Nw = size(Y, 1);
y_ws = [(0:numel(y)-1).' * Tc, y];
mdlD = construire_modele_decodeur_hamming();
out  = sim(mdlD);

mdec = out.mdec(8:7:end, :);                 % instants n = 7(k+1)
synd = out.synd(8:7:end, :);
attendu = msgs(:, [4 3 2 1]);                % m3 m2 m1 m0
nomsPos = {'m3', 'm2', 'm1', 'm0', 'r2', 'r1', 'r0'};
fprintf('\n=== Q6 : décodeur Simulink ===\n');
for e = 0:7
    lignes = 16*e + (1:16);
    ok = isequal(mdec(lignes, :), attendu);
    if e == 0
        fprintf('Sans erreur            : 16/16 messages corrects = %d, syndrome nul = %d\n', ...
                ok, all(all(synd(lignes, :) == 0)));
    else
        fprintf('Erreur sur %-2s (pos. %d) : 16/16 messages corrects = %d, syndrome = %s\n', ...
                nomsPos{e}, e, ok, mat2str(synd(lignes(1), :)));
    end
end

% Comparaison avec le décodeur de référence (fonction MATLAB)
Yref = Y(:, [4 3 2 1 7 6 5]);                % retour à l'ordre [m0..m3 r0 r1 r2]
mRef = reshape(hamming_decoder(reshape(Yref.', 1, []), H), 4, []).';
fprintf('Décodeur Simulink = décodeur MATLAB de référence : %d\n', ...
        isequal(mdec, mRef(:, [4 3 2 1])));