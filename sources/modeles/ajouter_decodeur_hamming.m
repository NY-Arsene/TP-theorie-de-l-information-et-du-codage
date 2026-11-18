function blk = ajouter_decodeur_hamming(sys, nom, pos)
%AJOUTER_DECODEUR_HAMMING  Sous-système "décodeur C(7,4)", identique au
%   modèle validé en partie 4.2 (modele_decodeur_hamming) : ligne de 7
%   bascules D, syndrome par XOR, décodage du syndrome par NOT/AND,
%   correction par XOR. Entrée y (bits codés en série, cadence Tc), sortie m
%   (vecteur [m3 m2 m1 m0] corrigé, valable quand les 7 bascules contiennent
%   un mot entier).

    blk = [sys '/' nom];
    add_block('simulink/Ports & Subsystems/Subsystem', blk, 'Position', pos);
    delete_line(blk, 'In1/1', 'Out1/1');
    set_param([blk '/In1'],  'Name', 'y', 'Position', [20 48 50 62]);
    set_param([blk '/Out1'], 'Name', 'm', 'Position', [900 273 930 287]);
    L = @(a, b) add_line(blk, a, b, 'autorouting', 'on');

    for i = 1:7
        add_block('simulink/Discrete/Unit Delay', sprintf('%s/D%d', blk, i), ...
            'InitialCondition', '0', 'SampleTime', 'Tc', ...
            'Position', [130 + 90*(i-1), 40, 170 + 90*(i-1), 70]);
    end
    L('y/1', 'D1/1');
    for i = 1:6
        L(sprintf('D%d/1', i), sprintf('D%d/1', i + 1));
    end
    m3 = 'D7/1';  m2 = 'D6/1';  m1 = 'D5/1';  m0 = 'D4/1';
    r2 = 'D3/1';  r1 = 'D2/1';  r0 = 'D1/1';

    entrees = {{m0, m2, m3, r0}, {m0, m1, m2, r1}, {m1, m2, m3, r2}};
    for i = 1:3
        nomS = sprintf('S%d', i);
        add_block('simulink/Logic and Bit Operations/Logical Operator', [blk '/' nomS], ...
            'Operator', 'XOR', 'Inputs', '4', 'Position', [300, 120 + 80*(i-1), 340, 180 + 80*(i-1)]);
        for j = 1:4
            L(entrees{i}{j}, sprintf('%s/%d', nomS, j));
        end
        add_block('simulink/Logic and Bit Operations/Logical Operator', ...
            sprintf('%s/NON S%d', blk, i), 'Operator', 'NOT', ...
            'Position', [400, 135 + 80*(i-1), 430, 165 + 80*(i-1)]);
        L(sprintf('S%d/1', i), sprintf('NON S%d/1', i));
    end

    nomsBits  = {'m3', 'm2', 'm1', 'm0'};
    bitsRecus = {m3, m2, m1, m0};
    colonnes  = [1 0 1; 1 1 1; 0 1 1; 1 1 0];
    for b = 1:4
        porte = sprintf('Erreur %s', nomsBits{b});
        add_block('simulink/Logic and Bit Operations/Logical Operator', [blk '/' porte], ...
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
        add_block('simulink/Logic and Bit Operations/Logical Operator', [blk '/' corr], ...
            'Operator', 'XOR', 'Inputs', '2', ...
            'Position', [620, 120 + 90*(b-1), 660, 160 + 90*(b-1)]);
        L(bitsRecus{b},           [corr '/1']);
        L(sprintf('%s/1', porte), [corr '/2']);
    end

    add_block('simulink/Signal Routing/Mux', [blk '/Mux message'], ...
        'Inputs', '4', 'Position', [720 130 725 430]);
    for b = 1:4
        L(sprintf('Correction %s/1', nomsBits{b}), sprintf('Mux message/%d', b));
    end
    add_block('simulink/Signal Attributes/Data Type Conversion', [blk '/VersDouble'], ...
        'OutDataTypeStr', 'double', 'Position', [770 265 840 295]);
    L('Mux message/1', 'VersDouble/1');
    L('VersDouble/1',  'm/1');
end