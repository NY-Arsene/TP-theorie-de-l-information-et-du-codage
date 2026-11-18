function blk = ajouter_modem_qpsk(sys, nom, pos)
%AJOUTER_MODEM_QPSK  Sous-système "modulateur QPSK + canal + démodulateur",
%   en bande de base équivalente (un échantillon complexe par symbole).
%
%   Entrée  : bits en série.   Sortie : bits décidés en série (même cadence).
%   Buffer 2 -> (b1, b2) -> [transcodage si mapping naturel]
%     -> I = (2u1 - 1)/sqrt(2),  Q = (2u2 - 1)/sqrt(2)       (Es = 1)
%     -> + bruit complexe, variance N0/2 sur chaque voie
%     -> décision sur le signe de chaque voie -> [transcodage inverse]
%     -> Unbuffer.
%
%   Mapping de Gray (mappingGray = 1) :
%       11 -> k = 1,  01 -> k = 3,  00 -> k = 5,  10 -> k = 7   (symbole e^{jk pi/4})
%       c'est-à-dire  I > 0 <=> b1 = 1,  Q > 0 <=> b2 = 1.
%   Mapping naturel (mappingGray = 0) :
%       00 -> k = 1,  01 -> k = 3,  10 -> k = 5,  11 -> k = 7
%       obtenu en transcodant u1 = NON(b1 XOR b2), u2 = NON b1 avant le
%       modulateur de Gray, et  b1 = NON d2,  b2 = d1 XOR d2  après décision.
%
%   Variables du workspace : N0, Tsym, graine, mappingGray.
%   Enregistre out.ssym (symboles émis) et out.rsym (symboles reçus).

    blk = [sys '/' nom];
    add_block('simulink/Ports & Subsystems/Subsystem', blk, 'Position', pos);
    delete_line(blk, 'In1/1', 'Out1/1');
    set_param([blk '/In1'],  'Name', 'bits',    'Position', [20 148 50 162]);
    set_param([blk '/Out1'], 'Name', 'bitsDec', 'Position', [1900 148 1930 162]);
    L = @(a, b) add_line(blk, a, b, 'autorouting', 'on');
    LO = 'simulink/Logic and Bit Operations/Logical Operator';
    DT = 'simulink/Signal Attributes/Data Type Conversion';
    SW = 'simulink/Signal Routing/Switch';

    % --- Regroupement des bits par deux -----------------------------------------
    add_block('dspbuff3/Buffer', [blk '/Buffer 2'], 'N', '2', 'Position', [90 135 140 175]);
    add_block('simulink/Math Operations/Reshape', [blk '/Vecteur'], ...
        'OutputDimensionality', '1-D array', 'Position', [170 135 210 175]);
    add_block('simulink/Signal Routing/Demux', [blk '/b1 b2'], ...
        'Outputs', '2', 'Position', [240 120 245 190]);
    L('bits/1', 'Buffer 2/1');  L('Buffer 2/1', 'Vecteur/1');  L('Vecteur/1', 'b1 b2/1');

    add_block('simulink/Sources/Constant', [blk '/Gray'], ...
        'Value', 'mappingGray', 'SampleTime', 'inf', 'Position', [280 300 340 330]);

    % --- Transcodage pour le mapping naturel ------------------------------------
    add_block(LO, [blk '/XOR b1 b2'], 'Operator', 'XOR', 'Inputs', '2', 'Position', [290 180 320 210]);
    add_block(LO, [blk '/NON xor'],   'Operator', 'NOT', 'Position', [350 180 380 210]);
    add_block(DT, [blk '/n1'], 'OutDataTypeStr', 'double', 'Position', [400 180 440 210]);
    add_block(LO, [blk '/NON b1'],    'Operator', 'NOT', 'Position', [350 230 380 260]);
    add_block(DT, [blk '/n2'], 'OutDataTypeStr', 'double', 'Position', [400 230 440 260]);
    L('b1 b2/1', 'XOR b1 b2/1');  L('b1 b2/2', 'XOR b1 b2/2');
    L('XOR b1 b2/1', 'NON xor/1');  L('NON xor/1', 'n1/1');
    L('b1 b2/1', 'NON b1/1');       L('NON b1/1', 'n2/1');

    add_block(SW, [blk '/u1'], 'Criteria', 'u2 > Threshold', 'Threshold', '0.5', 'Position', [480 100 510 160]);
    add_block(SW, [blk '/u2'], 'Criteria', 'u2 > Threshold', 'Threshold', '0.5', 'Position', [480 200 510 260]);
    L('b1 b2/1', 'u1/1');  L('Gray/1', 'u1/2');  L('n1/1', 'u1/3');
    L('b1 b2/2', 'u2/1');  L('Gray/1', 'u2/2');  L('n2/1', 'u2/3');

    % --- Modulateur : voies I et Q -----------------------------------------------
    add_block('simulink/Math Operations/Gain', [blk '/Gain I'], 'Gain', '2/sqrt(2)', 'Position', [550 115 590 145]);
    add_block('simulink/Math Operations/Bias', [blk '/Biais I'], 'Bias', '-1/sqrt(2)', 'Position', [610 115 650 145]);
    add_block('simulink/Math Operations/Gain', [blk '/Gain Q'], 'Gain', '2/sqrt(2)', 'Position', [550 215 590 245]);
    add_block('simulink/Math Operations/Bias', [blk '/Biais Q'], 'Bias', '-1/sqrt(2)', 'Position', [610 215 650 245]);
    add_block('simulink/Math Operations/Real-Imag to Complex', [blk '/Symbole'], 'Position', [690 150 730 200]);
    L('u1/1', 'Gain I/1');  L('Gain I/1', 'Biais I/1');  L('Biais I/1', 'Symbole/1');
    L('u2/1', 'Gain Q/1');  L('Gain Q/1', 'Biais Q/1');  L('Biais Q/1', 'Symbole/2');

    % --- Canal : bruit complexe -------------------------------------------------
    add_block('simulink/Sources/Random Number', [blk '/Bruit I'], 'Mean', '0', 'Variance', 'N0/2', ...
        'Seed', 'graine+1', 'SampleTime', 'Tsym', 'Position', [690 260 740 290]);
    add_block('simulink/Sources/Random Number', [blk '/Bruit Q'], 'Mean', '0', 'Variance', 'N0/2', ...
        'Seed', 'graine+2', 'SampleTime', 'Tsym', 'Position', [690 310 740 340]);
    add_block('simulink/Math Operations/Real-Imag to Complex', [blk '/Bruit complexe'], 'Position', [770 280 810 330]);
    add_block('simulink/Math Operations/Sum', [blk '/Canal'], 'Inputs', '++', 'Position', [850 160 880 190]);
    L('Bruit I/1', 'Bruit complexe/1');  L('Bruit Q/1', 'Bruit complexe/2');
    L('Symbole/1', 'Canal/1');  L('Bruit complexe/1', 'Canal/2');
    ajouter_to_workspace(blk, 'ssym', [770 60 830 90]);
    ajouter_to_workspace(blk, 'rsym', [920 60 980 90]);
    L('Symbole/1', 'ssym/1');  L('Canal/1', 'rsym/1');

    % --- Démodulateur : signe de chaque voie ------------------------------------
    add_block('simulink/Math Operations/Complex to Real-Imag', [blk '/Voies'], 'Position', [920 150 960 200]);
    add_block('simulink/Sources/Constant', [blk '/Zero'], 'Value', '0', 'SampleTime', 'inf', ...
        'Position', [920 240 950 260]);
    add_block('simulink/Logic and Bit Operations/Relational Operator', [blk '/Decision I'], ...
        'Operator', '>', 'Position', [1000 130 1030 160]);
    add_block('simulink/Logic and Bit Operations/Relational Operator', [blk '/Decision Q'], ...
        'Operator', '>', 'Position', [1000 200 1030 230]);
    add_block(DT, [blk '/d1'], 'OutDataTypeStr', 'double', 'Position', [1060 130 1100 160]);
    add_block(DT, [blk '/d2'], 'OutDataTypeStr', 'double', 'Position', [1060 200 1100 230]);
    L('Canal/1', 'Voies/1');
    L('Voies/1', 'Decision I/1');  L('Zero/1', 'Decision I/2');
    L('Voies/2', 'Decision Q/1');  L('Zero/1', 'Decision Q/2');
    L('Decision I/1', 'd1/1');  L('Decision Q/1', 'd2/1');

    % --- Transcodage inverse (mapping naturel) ----------------------------------
    add_block(LO, [blk '/NON d2'],  'Operator', 'NOT', 'Position', [1140 260 1170 290]);
    add_block(DT, [blk '/nb1'], 'OutDataTypeStr', 'double', 'Position', [1190 260 1230 290]);
    add_block(LO, [blk '/XOR d1 d2'], 'Operator', 'XOR', 'Inputs', '2', 'Position', [1140 310 1170 340]);
    add_block(DT, [blk '/nb2'], 'OutDataTypeStr', 'double', 'Position', [1190 310 1230 340]);
    L('d2/1', 'NON d2/1');  L('NON d2/1', 'nb1/1');
    L('d1/1', 'XOR d1 d2/1');  L('d2/1', 'XOR d1 d2/2');  L('XOR d1 d2/1', 'nb2/1');

    add_block(SW, [blk '/b1 decide'], 'Criteria', 'u2 > Threshold', 'Threshold', '0.5', 'Position', [1280 120 1310 180]);
    add_block(SW, [blk '/b2 decide'], 'Criteria', 'u2 > Threshold', 'Threshold', '0.5', 'Position', [1280 220 1310 280]);
    L('d1/1', 'b1 decide/1');  L('Gray/1', 'b1 decide/2');  L('nb1/1', 'b1 decide/3');
    L('d2/1', 'b2 decide/1');  L('Gray/1', 'b2 decide/2');  L('nb2/1', 'b2 decide/3');

    % --- Remise en série --------------------------------------------------------
    add_block('simulink/Signal Routing/Mux', [blk '/Paire'], 'Inputs', '2', 'Position', [1360 140 1365 260]);
    add_block('simulink/Math Operations/Reshape', [blk '/Colonne'], ...
        'OutputDimensionality', 'Column vector (2-D)', 'Position', [1400 180 1440 220]);
    add_block('dspbuff3/Unbuffer', [blk '/Unbuffer 2'], 'Position', [1480 180 1530 220]);
    L('b1 decide/1', 'Paire/1');  L('b2 decide/1', 'Paire/2');
    L('Paire/1', 'Colonne/1');  L('Colonne/1', 'Unbuffer 2/1');  L('Unbuffer 2/1', 'bitsDec/1');
end