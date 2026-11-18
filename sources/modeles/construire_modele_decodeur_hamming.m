function mdl = construire_modele_decodeur_hamming()
%CONSTRUIRE_MODELE_DECODEUR_HAMMING  Décodeur C(7,4) en logique
%   (partie 4, question 6) : conversion série-parallèle par une ligne de 7
%   bascules D, calcul du syndrome par portes XOR, décodage du syndrome par
%   portes NOT/AND, correction par XOR.
%
%   Les mots arrivent en série dans l'ordre du codeur :
%       w1..w7 = m3 m2 m1 m0 r2 r1 r0
%   À l'instant n = 7(k+1), les bascules D7..D1 contiennent le mot k entier.
%
%   Syndrome s = r H' :
%       s1 = m0 + m2 + m3 + r0     (mod 2)
%       s2 = m0 + m1 + m2 + r1
%       s3 = m1 + m2 + m3 + r2
%   Erreur sur un bit de message si s est égal à sa colonne de H :
%       m0 : s = (1,1,0)   m1 : (0,1,1)   m2 : (1,1,1)   m3 : (1,0,1)
%   (une erreur sur un bit de parité ne change pas le message décodé).
%
%   Variables du workspace : Tc, Nw, y_ws = [t, y].
%   Sorties : out.mdec (N x 4 : m3 m2 m1 m0 corrigés), out.synd (N x 3),
%   valables aux instants n = 7(k+1).

    mdl = 'modele_decodeur_hamming';
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
    new_system(mdl);  open_system(mdl);
    set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
        'FixedStep', 'Tc', 'StopTime', '7*Nw*Tc', 'ReturnWorkspaceOutputs', 'on');
    L = @(a, b) add_line(mdl, a, b, 'autorouting', 'on');

    add_block('simulink/Sources/From Workspace', [mdl '/Recu'], ...
        'VariableName', 'y_ws', 'SampleTime', 'Tc', 'Interpolate', 'off', ...
        'OutputAfterFinalValue', 'Setting to zero', 'Position', [20 40 100 70]);

    % --- Conversion série-parallèle : 7 bascules D -----------------------------
    for i = 1:7
        add_block('simulink/Discrete/Unit Delay', sprintf('%s/D%d', mdl, i), ...
            'InitialCondition', '0', 'SampleTime', 'Tc', ...
            'Position', [130 + 90*(i-1), 40, 170 + 90*(i-1), 70]);
    end
    L('Recu/1', 'D1/1');
    for i = 1:6
        L(sprintf('D%d/1', i), sprintf('D%d/1', i + 1));
    end
    % w_p = sortie de D(8-p) : m3 = D7, m2 = D6, m1 = D5, m0 = D4, r2 = D3, r1 = D2, r0 = D1
    m3 = 'D7/1';  m2 = 'D6/1';  m1 = 'D5/1';  m0 = 'D4/1';
    r2 = 'D3/1';  r1 = 'D2/1';  r0 = 'D1/1';

    % --- Syndrome : portes XOR à 4 entrées -------------------------------------
    entrees = {{m0, m2, m3, r0}, {m0, m1, m2, r1}, {m1, m2, m3, r2}};
    for i = 1:3
        nom = sprintf('S%d', i);
        add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl '/' nom], ...
            'Operator', 'XOR', 'Inputs', '4', 'Position', [300, 120 + 80*(i-1), 340, 180 + 80*(i-1)]);
        for j = 1:4
            L(entrees{i}{j}, sprintf('%s/%d', nom, j));
        end
        add_block('simulink/Logic and Bit Operations/Logical Operator', ...
            sprintf('%s/NON S%d', mdl, i), 'Operator', 'NOT', ...
            'Position', [400, 135 + 80*(i-1), 430, 165 + 80*(i-1)]);
        L(sprintf('S%d/1', i), sprintf('NON S%d/1', i));
    end

    % --- Décodage du syndrome (AND) et correction (XOR) -------------------------
    % colonne de H de chaque bit de message, dans l'ordre m3 m2 m1 m0
    nomsBits = {'m3', 'm2', 'm1', 'm0'};
    bitsRecus = {m3, m2, m1, m0};
    colonnes = [1 0 1; 1 1 1; 0 1 1; 1 1 0];
    for b = 1:4
        porte = sprintf('Erreur %s', nomsBits{b});
        add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl '/' porte], ...
            'Operator', 'AND', 'Inputs', '3', ...
            'Position', [520, 120 + 90*(b-1), 560, 180 + 90*(b-1)]);
        for i = 1:3
            if colonnes(b, i)
                L(sprintf('S%d/1', i), sprintf('%s/%d', porte, i));
            else
                L(sprintf('NON S%d/1', i), sprintf('%s/%d', porte, i));
            end
        end
        corr = sprintf('Correction %s', nomsBits{b});
        add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl '/' corr], ...
            'Operator', 'XOR', 'Inputs', '2', ...
            'Position', [620, 120 + 90*(b-1), 660, 160 + 90*(b-1)]);
        L(bitsRecus{b},             [corr '/1']);
        L(sprintf('%s/1', porte),   [corr '/2']);
    end

    % --- Sorties ------------------------------------------------------------------
    add_block('simulink/Signal Routing/Mux', [mdl '/Mux message'], ...
        'Inputs', '4', 'Position', [720 130 725 430]);
    for b = 1:4
        L(sprintf('Correction %s/1', nomsBits{b}), sprintf('Mux message/%d', b));
    end
    add_block('simulink/Signal Attributes/Data Type Conversion', [mdl '/VersDouble'], ...
        'OutDataTypeStr', 'double', 'Position', [770 265 840 295]);
    ajouter_to_workspace(mdl, 'mdec', [890 265 950 295]);
    L('Mux message/1', 'VersDouble/1');
    L('VersDouble/1',  'mdec/1');

    add_block('simulink/Signal Routing/Mux', [mdl '/Mux syndrome'], ...
        'Inputs', '3', 'Position', [460 380 465 460]);
    for i = 1:3
        L(sprintf('S%d/1', i), sprintf('Mux syndrome/%d', i));
    end
    add_block('simulink/Signal Attributes/Data Type Conversion', [mdl '/SyndDouble'], ...
        'OutDataTypeStr', 'double', 'Position', [520 405 590 435]);
    ajouter_to_workspace(mdl, 'synd', [640 405 700 435]);
    L('Mux syndrome/1', 'SyndDouble/1');
    L('SyndDouble/1',   'synd/1');

    save_system(mdl);
    fprintf('Modèle "%s.slx" construit.\n', mdl);
end