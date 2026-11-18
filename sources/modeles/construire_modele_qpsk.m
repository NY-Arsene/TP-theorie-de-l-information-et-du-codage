function mdl = construire_modele_qpsk()
%CONSTRUIRE_MODELE_QPSK  Chaîne QPSK sans codage (partie 5, questions 2 à 5) :
%   Source (Tb) -> modem QPSK + canal gaussien complexe -> bits décidés (Tb).
%   Variables : Tb, Tpas, Tsym, Nsim, N0, graine, mappingGray.
%   Sorties : out.tx, out.rx, out.ssym, out.rsym.

    try
        load_system('dspbuff3');
    catch
        error('Bibliothèque "dspbuff3" (Buffer / Unbuffer) introuvable.');
    end
    mdl = 'modele_qpsk';
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
    new_system(mdl);  open_system(mdl);
    set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
        'FixedStep', 'Tpas', 'StopTime', '(Nsim-1)*Tb', 'ReturnWorkspaceOutputs', 'on');

    ajouter_source_binaire(mdl, 'Source', [30 80 150 130], '0.5', 'graine');
    ajouter_to_workspace(mdl, 'tx', [220 10 280 40]);
    ajouter_modem_qpsk(mdl, 'Modem QPSK et canal', [220 80 380 130]);
    ajouter_to_workspace(mdl, 'rx', [440 90 500 120]);
    add_line(mdl, 'Source/1', 'tx/1', 'autorouting', 'on');
    add_line(mdl, 'Source/1', 'Modem QPSK et canal/1', 'autorouting', 'on');
    add_line(mdl, 'Modem QPSK et canal/1', 'rx/1', 'autorouting', 'on');

    save_system(mdl);
    fprintf('Modèle "%s.slx" construit.\n', mdl);
end