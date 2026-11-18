function blk = ajouter_codeur_registre(sys, nom, pos)
%AJOUTER_CODEUR_REGISTRE  Sous-système "codeur C(7,4) à registre", identique
%   au modèle validé en partie 4.2 (modele_codeur_registre), avec un port
%   d'entrée u (m3 m2 m1 m0 0 0 0 par mot, cadence Tc) et un port de sortie c.
%   L'horloge de mot (Pulse Generator, période 7, largeur 4) est décalée de
%   phaseC coups d'horloge (variable du workspace, étalonnée par le script).

    blk = [sys '/' nom];
    add_block('simulink/Ports & Subsystems/Subsystem', blk, 'Position', pos);
    delete_line(blk, 'In1/1', 'Out1/1');
    set_param([blk '/In1'],  'Name', 'u', 'Position', [20 100 50 114]);
    set_param([blk '/Out1'], 'Name', 'c', 'Position', [960 93 990 107]);
    L = @(a, b) add_line(blk, a, b, 'autorouting', 'on');

    add_block('simulink/Sources/Pulse Generator', [blk '/Horloge mot'], ...
        'PulseType', 'Sample based', 'Amplitude', '1', 'Period', '7', ...
        'PulseWidth', '4', 'PhaseDelay', 'phaseC', 'SampleTime', 'Tc', ...
        'Position', [30 220 90 250]);
    add_block('simulink/Logic and Bit Operations/Logical Operator', [blk '/XOR entree'], ...
        'Operator', 'XOR', 'Inputs', '2', 'Position', [180 100 220 140]);
    add_block('simulink/Logic and Bit Operations/Logical Operator', [blk '/Porte'], ...
        'Operator', 'AND', 'Inputs', '2', 'Position', [260 110 300 150]);
    add_block('simulink/Discrete/Unit Delay', [blk '/D0'], ...
        'InitialCondition', '0', 'SampleTime', 'Tc', 'Position', [360 115 400 145]);
    add_block('simulink/Logic and Bit Operations/Logical Operator', [blk '/XOR s1'], ...
        'Operator', 'XOR', 'Inputs', '2', 'Position', [450 110 490 150]);
    add_block('simulink/Discrete/Unit Delay', [blk '/D1'], ...
        'InitialCondition', '0', 'SampleTime', 'Tc', 'Position', [540 115 580 145]);
    add_block('simulink/Discrete/Unit Delay', [blk '/D2'], ...
        'InitialCondition', '0', 'SampleTime', 'Tc', 'Position', [630 115 670 145]);
    add_block('simulink/Signal Attributes/Data Type Conversion', [blk '/s2 double'], ...
        'OutDataTypeStr', 'double', 'Position', [720 115 790 145]);
    add_block('simulink/Signal Routing/Switch', [blk '/Interrupteur'], ...
        'Criteria', 'u2 > Threshold', 'Threshold', '0.5', 'Position', [850 60 890 140]);

    L('u/1',            'XOR entree/1');
    L('D2/1',           'XOR entree/2');
    L('XOR entree/1',   'Porte/1');
    L('Horloge mot/1',  'Porte/2');
    L('Porte/1',        'D0/1');
    L('D0/1',           'XOR s1/1');
    L('Porte/1',        'XOR s1/2');
    L('XOR s1/1',       'D1/1');
    L('D1/1',           'D2/1');
    L('D2/1',           's2 double/1');
    L('u/1',            'Interrupteur/1');
    L('Horloge mot/1',  'Interrupteur/2');
    L('s2 double/1',    'Interrupteur/3');
    L('Interrupteur/1', 'c/1');
end