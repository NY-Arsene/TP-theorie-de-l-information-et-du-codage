function blk = ajouter_modem_qpsk_filtre(sys, nom, pos)
%AJOUTER_MODEM_QPSK_FILTRE  Sous-système "modem QPSK filtré + canal" (parties 6 et 7).
%   Entrée : bits en série.  Sortie : bits décidés en série (même cadence).
%   Buffer 2 -> mapping de Gray -> un symbole tous les L échantillons
%     -> filtre de mise en forme hE -> canal à écho hc -> + bruit complexe
%     -> filtre adapté hE(-t) -> retard dPhase -> échantillonnage (Tsym)
%     -> décision sur le signe de I et Q -> Unbuffer.
%   Variables : Te, Tsym, L, hE, hc, N0, graine, dPhase, Nlog.
%   Enregistre out.ye (sortie du filtre adapté, Nlog derniers points) et
%   out.zsym (échantillons de décision).

    blk = [sys '/' nom];
    add_block('simulink/Ports & Subsystems/Subsystem', blk, 'Position', pos);
    delete_line(blk, 'In1/1', 'Out1/1');
    set_param([blk '/In1'],  'Name', 'bits',    'Position', [20 98 50 112]);
    set_param([blk '/Out1'], 'Name', 'bitsDec', 'Position', [1700 118 1730 132]);
    L = @(a, b) add_line(blk, a, b, 'autorouting', 'on');
    RO = 'simulink/Logic and Bit Operations/Relational Operator';
    DT = 'simulink/Signal Attributes/Data Type Conversion';

    % --- Mapping de Gray ------------------------------------------------------------
    add_block('dspbuff3/Buffer', [blk '/Buffer 2'], 'N', '2', 'Position', [80 85 130 125]);
    add_block('simulink/Math Operations/Reshape', [blk '/Vecteur'], ...
        'OutputDimensionality', '1-D array', 'Position', [160 85 200 125]);
    add_block('simulink/Signal Routing/Demux', [blk '/b1 b2'], 'Outputs', '2', 'Position', [230 75 235 135]);
    add_block('simulink/Math Operations/Gain', [blk '/Gain I'], 'Gain', '2/sqrt(2)', 'Position', [270 65 310 95]);
    add_block('simulink/Math Operations/Bias', [blk '/Biais I'], 'Bias', '-1/sqrt(2)', 'Position', [330 65 370 95]);
    add_block('simulink/Math Operations/Gain', [blk '/Gain Q'], 'Gain', '2/sqrt(2)', 'Position', [270 115 310 145]);
    add_block('simulink/Math Operations/Bias', [blk '/Biais Q'], 'Bias', '-1/sqrt(2)', 'Position', [330 115 370 145]);
    add_block('simulink/Math Operations/Real-Imag to Complex', [blk '/Symbole'], 'Position', [400 85 440 125]);
    L('bits/1', 'Buffer 2/1');  L('Buffer 2/1', 'Vecteur/1');  L('Vecteur/1', 'b1 b2/1');
    L('b1 b2/1', 'Gain I/1');  L('Gain I/1', 'Biais I/1');  L('Biais I/1', 'Symbole/1');
    L('b1 b2/2', 'Gain Q/1');  L('Gain Q/1', 'Biais Q/1');  L('Biais Q/1', 'Symbole/2');

    % --- Suréchantillonnage, mise en forme, écho -------------------------------------
    add_block('simulink/Signal Attributes/Rate Transition', [blk '/Vers Te'], ...
        'OutPortSampleTime', 'Te', 'Position', [470 88 520 122]);
    add_block('simulink/Sources/Pulse Generator', [blk '/Peigne'], ...
        'PulseType', 'Sample based', 'Amplitude', '1', 'Period', 'L', ...
        'PulseWidth', '1', 'PhaseDelay', '0', 'SampleTime', 'Te', 'Position', [470 150 520 180]);
    add_block('simulink/Math Operations/Product', [blk '/Insertion zeros'], ...
        'Inputs', '**', 'Position', [550 95 580 145]);
    add_block('simulink/Discrete/Discrete FIR Filter', [blk '/Mise en forme'], ...
        'Coefficients', 'hE', 'Position', [610 100 690 140]);
    add_block('simulink/Discrete/Discrete FIR Filter', [blk '/Echo'], ...
        'Coefficients', 'hc', 'Position', [720 100 800 140]);
    L('Symbole/1', 'Vers Te/1');  L('Vers Te/1', 'Insertion zeros/1');
    L('Peigne/1', 'Insertion zeros/2');  L('Insertion zeros/1', 'Mise en forme/1');
    L('Mise en forme/1', 'Echo/1');

    % --- Bruit complexe -------------------------------------------------------------
    add_block('simulink/Sources/Random Number', [blk '/Bruit I'], 'Mean', '0', 'Variance', 'N0/2', ...
        'Seed', 'graine+1', 'SampleTime', 'Te', 'Position', [720 180 770 210]);
    add_block('simulink/Sources/Random Number', [blk '/Bruit Q'], 'Mean', '0', 'Variance', 'N0/2', ...
        'Seed', 'graine+2', 'SampleTime', 'Te', 'Position', [720 230 770 260]);
    add_block('simulink/Math Operations/Real-Imag to Complex', [blk '/Bruit complexe'], 'Position', [800 195 840 245]);
    add_block('simulink/Math Operations/Sum', [blk '/Canal'], 'Inputs', '++', 'Position', [870 105 900 135]);
    L('Bruit I/1', 'Bruit complexe/1');  L('Bruit Q/1', 'Bruit complexe/2');
    L('Echo/1', 'Canal/1');  L('Bruit complexe/1', 'Canal/2');

    % --- Filtre adapté et échantillonnage --------------------------------------------
    add_block('simulink/Discrete/Discrete FIR Filter', [blk '/Filtre adapte'], ...
        'Coefficients', 'fliplr(hE)', 'Position', [930 100 1010 140]);
    add_block('simulink/Sinks/To Workspace', [blk '/ye'], 'VariableName', 'ye', ...
        'SaveFormat', 'Array', 'MaxDataPoints', 'Nlog', 'Position', [1040 20 1100 50]);
    add_block('simulink/Discrete/Delay', [blk '/Phase'], 'DelayLength', 'dPhase', ...
        'Position', [1040 103 1090 137]);
    add_block('simulink/Signal Attributes/Rate Transition', [blk '/Echantillonneur'], ...
        'OutPortSampleTime', 'Tsym', 'Position', [1120 103 1170 137]);
    ajouter_to_workspace(blk, 'zsym', [1200 20 1260 50]);
    L('Canal/1', 'Filtre adapte/1');  L('Filtre adapte/1', 'ye/1');
    L('Filtre adapte/1', 'Phase/1');  L('Phase/1', 'Echantillonneur/1');
    L('Echantillonneur/1', 'zsym/1');

    % --- Décision et remise en série ------------------------------------------------
    add_block('simulink/Math Operations/Complex to Real-Imag', [blk '/Voies'], 'Position', [1200 95 1240 145]);
    add_block('simulink/Sources/Constant', [blk '/Zero'], 'Value', '0', 'SampleTime', 'inf', ...
        'Position', [1200 180 1230 200]);
    add_block(RO, [blk '/Decision I'], 'Operator', '>', 'Position', [1270 80 1300 110]);
    add_block(RO, [blk '/Decision Q'], 'Operator', '>', 'Position', [1270 140 1300 170]);
    add_block(DT, [blk '/d1'], 'OutDataTypeStr', 'double', 'Position', [1320 80 1360 110]);
    add_block(DT, [blk '/d2'], 'OutDataTypeStr', 'double', 'Position', [1320 140 1360 170]);
    add_block('simulink/Signal Routing/Mux', [blk '/Paire'], 'Inputs', '2', 'Position', [1390 80 1395 170]);
    add_block('simulink/Math Operations/Reshape', [blk '/Colonne'], ...
        'OutputDimensionality', 'Column vector (2-D)', 'Position', [1420 105 1460 145]);
    add_block('dspbuff3/Unbuffer', [blk '/Unbuffer 2'], 'Position', [1490 105 1540 145]);
    L('Echantillonneur/1', 'Voies/1');
    L('Voies/1', 'Decision I/1');  L('Zero/1', 'Decision I/2');
    L('Voies/2', 'Decision Q/1');  L('Zero/1', 'Decision Q/2');
    L('Decision I/1', 'd1/1');  L('Decision Q/1', 'd2/1');
    L('d1/1', 'Paire/1');  L('d2/1', 'Paire/2');
    L('Paire/1', 'Colonne/1');  L('Colonne/1', 'Unbuffer 2/1');  L('Unbuffer 2/1', 'bitsDec/1');
end