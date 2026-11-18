function mdl = construire_modele_codeur_registre()
%CONSTRUIRE_MODELE_CODEUR_REGISTRE  Codeur C(7,4) à registre à décalage
%   (partie 4, questions 4 et 5) : bascules D (Unit Delay), portes XOR/AND
%   et un interrupteur message/redondance (Switch). Ni produit matriciel,
%   ni division de polynômes.
%
%   Fonctionnement, sur un mot de 7 coups d'horloge (période Tc) :
%   - coups 0 à 3 (ctrl = 1) : les bits du message entrent poids fort
%     d'abord (m3, m2, m1, m0) ; ils sortent directement (code systématique)
%     et alimentent le registre : f = m XOR s2 ;
%        s2 <- s1,  s1 <- s0 XOR f,  s0 <- f
%   - coups 4 à 6 (ctrl = 0) : la rétroaction est coupée (f = 0), le
%     registre se décale et la sortie prend s2 : on émet r2, r1, r0.
%   Le registre se retrouve à zéro au début du mot suivant.
%
%   Ordre des bits émis : m3 m2 m1 m0 r2 r1 r0.
%   Variables du workspace : Tc, Nw (nombre de mots), u_ws = [t, u] (entrée :
%   pour chaque mot, m3 m2 m1 m0 suivis de 3 zéros).
%   Sorties : out.c (bits codés), out.ctrl, out.f, out.s0, out.s1, out.s2.

    mdl = 'modele_codeur_registre';
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
    new_system(mdl);  open_system(mdl);
    set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
        'FixedStep', 'Tc', 'StopTime', '7*Nw*Tc', 'ReturnWorkspaceOutputs', 'on');

    % --- Entrée et horloge message/redondance --------------------------------
    add_block('simulink/Sources/From Workspace', [mdl '/Message'], ...
        'VariableName', 'u_ws', 'SampleTime', 'Tc', 'Interpolate', 'off', ...
        'OutputAfterFinalValue', 'Setting to zero', 'Position', [30 100 110 130]);
    add_block('simulink/Sources/Pulse Generator', [mdl '/Horloge mot'], ...
        'PulseType', 'Sample based', 'Amplitude', '1', 'Period', '7', ...
        'PulseWidth', '4', 'PhaseDelay', '0', 'SampleTime', 'Tc', ...
        'Position', [30 220 90 250]);

    % --- Registre à rétroaction -----------------------------------------------
    add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl '/XOR entree'], ...
        'Operator', 'XOR', 'Inputs', '2', 'Position', [180 100 220 140]);
    add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl '/Porte'], ...
        'Operator', 'AND', 'Inputs', '2', 'Position', [260 110 300 150]);
    add_block('simulink/Discrete/Unit Delay', [mdl '/D0'], ...
        'InitialCondition', '0', 'SampleTime', 'Tc', 'Position', [360 115 400 145]);
    add_block('simulink/Logic and Bit Operations/Logical Operator', [mdl '/XOR s1'], ...
        'Operator', 'XOR', 'Inputs', '2', 'Position', [450 110 490 150]);
    add_block('simulink/Discrete/Unit Delay', [mdl '/D1'], ...
        'InitialCondition', '0', 'SampleTime', 'Tc', 'Position', [540 115 580 145]);
    add_block('simulink/Discrete/Unit Delay', [mdl '/D2'], ...
        'InitialCondition', '0', 'SampleTime', 'Tc', 'Position', [630 115 670 145]);

    % --- Interrupteur message / redondance ------------------------------------
    add_block('simulink/Signal Attributes/Data Type Conversion', [mdl '/s2 double'], ...
        'OutDataTypeStr', 'double', 'Position', [720 115 790 145]);
    add_block('simulink/Signal Routing/Switch', [mdl '/Interrupteur'], ...
        'Criteria', 'u2 > Threshold', 'Threshold', '0.5', 'Position', [850 60 890 140]);

    % --- Enregistrements --------------------------------------------------------
    ajouter_to_workspace(mdl, 'c',    [950 85 1010 115]);
    ajouter_to_workspace(mdl, 'ctrl', [180 260 240 290]);
    ajouter_to_workspace(mdl, 'f',    [360 200 420 230]);
    ajouter_to_workspace(mdl, 's0',   [450 200 510 230]);
    ajouter_to_workspace(mdl, 's1',   [600 200 660 230]);
    ajouter_to_workspace(mdl, 's2',   [720 200 780 230]);

    % --- Connexions -------------------------------------------------------------
    L = @(a, b) add_line(mdl, a, b, 'autorouting', 'on');
    L('Message/1',      'XOR entree/1');
    L('D2/1',           'XOR entree/2');          % rétroaction : f = m XOR s2
    L('XOR entree/1',   'Porte/1');
    L('Horloge mot/1',  'Porte/2');               % coupée pendant la redondance
    L('Porte/1',        'D0/1');                  % s0 <- f
    L('D0/1',           'XOR s1/1');
    L('Porte/1',        'XOR s1/2');
    L('XOR s1/1',       'D1/1');                  % s1 <- s0 XOR f
    L('D1/1',           'D2/1');                  % s2 <- s1
    L('D2/1',           's2 double/1');
    L('Message/1',      'Interrupteur/1');        % ctrl = 1 : message
    L('Horloge mot/1',  'Interrupteur/2');
    L('s2 double/1',    'Interrupteur/3');        % ctrl = 0 : redondance
    L('Interrupteur/1', 'c/1');
    L('Horloge mot/1',  'ctrl/1');
    L('Porte/1',        'f/1');
    L('D0/1',           's0/1');
    L('D1/1',           's1/1');
    L('D2/1',           's2/1');

    save_system(mdl);
    fprintf('Modèle "%s.slx" construit.\n', mdl);
end