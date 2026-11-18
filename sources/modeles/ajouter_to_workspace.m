function blk = ajouter_to_workspace(sys, nomVariable, pos)
%AJOUTER_TO_WORKSPACE  Ajoute un bloc To Workspace (format Array) qui
%   enregistre son entrée dans out.<nomVariable>.
    blk = [sys '/' nomVariable];
    add_block('simulink/Sinks/To Workspace', blk, ...
        'VariableName', nomVariable, 'SaveFormat', 'Array', 'Position', pos);
end