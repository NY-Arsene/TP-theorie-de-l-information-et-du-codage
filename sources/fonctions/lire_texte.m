function texte = lire_texte(fichier)
%LIRE_TEXTE  Lit un fichier texte UTF-8 et le nettoie.
%   texte = lire_texte('roman.txt') renvoie une ligne de caracteres.
%   - fins de ligne Windows (CR LF) ramenees a LF
%   - suppression du BOM UTF-8 eventuel
%   - si le fichier vient du Projet Gutenberg, suppression de l'en-tete
%     ("*** START OF ...") et de la licence finale ("*** END OF ...")

    fid = fopen(fichier, 'r', 'n', 'UTF-8');
    if fid < 0
        error('lire_texte : impossible d''ouvrir le fichier %s', fichier);
    end
    texte = fread(fid, '*char').';
    fclose(fid);

    texte = strrep(texte, sprintf('\r\n'), newline);
    texte = strrep(texte, char(65279), '');            % BOM

    d = strfind(texte, '*** START OF');
    if ~isempty(d)
        nl    = find(texte(d(1):end) == newline, 1);   % fin de la ligne du marqueur
        texte = texte(d(1)+nl:end);
    end
    f = strfind(texte, '*** END OF');
    if ~isempty(f)
        texte = texte(1:f(1)-1);
    end

    texte = strtrim(texte);
    texte = texte(:).';                                % vecteur ligne
end