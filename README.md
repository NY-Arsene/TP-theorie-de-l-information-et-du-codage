# Chaîne de transmission numérique en bande de base — MATLAB / Simulink

ENSIM 5A ASTRE — Théorie de l'information et du codage — TP 2026-2027

Auteur : **NOM Prénom** *(à compléter)*

Ce dépôt contient le rapport, les sources MATLAB et Simulink, ce guide d'utilisation,
le lien vers la présentation et la déclaration sur l'usage de l'IA.

```
TP_chaine_transmission/
├── README.md                 ce guide d'utilisation
├── DECLARATION_IA.md         déclaration sur l'usage de l'IA
├── rapport/                  rapport (PDF)
├── presentation/             lien vers la présentation vidéo
├── figures/                  figures produites par lancer_tout (créé à l'exécution)
└── sources/
    ├── Parametres.m          paramètres communs (appelé par tous les scripts)
    ├── parametres_perso.m    paramètres personnels (fonction fournie)
    ├── lancer_tout.m         exécute tout le TP et enregistre les figures
    ├── partie2_1.m … partie7_2.m   un script par groupe de questions
    ├── fonctions/            fonctions MATLAB (Huffman, LZ78, Hamming, RRC…)
    ├── modeles/              fonctions qui construisent les modèles Simulink
    └── *.slx                 modèles Simulink (générés par les scripts)
```

## 1. Prérequis

| Logiciel | Utilisation | Obligatoire |
|---|---|---|
| MATLAB R2024b (testé) + Simulink | tout le TP | oui |
| DSP System Toolbox | blocs Buffer / Unbuffer (parties 4.4 à 7) | oui |
| Communications Toolbox | `huffmandict`, `cyclgen`, `berawgn` (comparaisons) | non |
| Signal Processing Toolbox | `pwelch`, `hann`, `rcosdesign` (partie 6.1) | oui pour 6.1 |
| 7-Zip (`C:\Program Files\7-Zip\7z.exe`) | tailles bzip2 / 7z (partie 2.4) | non |

## 2. Mise en place

1. Ouvrir MATLAB et se placer dans le dossier `sources/` (Current Folder).
2. Dans `Parametres.m` :
   - `nomEtudiant` : nom exactement comme sur la liste d'appel ; il détermine les
     paramètres personnels (p1, pe, a, σ, L, α, β, τ, graine) ;
   - `fichierTexte` : nom du texte long (≥ 100 000 caractères, UTF-8) copié dans
     `sources/`. Nous avons utilisé *The Prince* (Projet Gutenberg) ; l'en-tête et la
     licence Gutenberg sont retirés automatiquement par `lire_texte`.
3. Pour la partie 2.2 de test, le fichier `texte_fr.txt` fourni peut aussi être utilisé.

## 3. Exécution

**Tout le TP** (≈ 30 à 40 min) : `lancer_tout` — les figures sont enregistrées dans `figures/`.

**Une partie** : lancer le script correspondant, par exemple `partie3_4`, ou
`lancer_tout({'partie3_4'})` pour enregistrer aussi ses figures.
Les scripts doivent être lancés **dans l'ordre** la première fois : certains
réutilisent les résultats sauvegardés (`resultats_partie*.mat`) des précédents
pour les comparaisons.

| Script | Questions | Contenu | Durée |
|---|---|---|---|
| `partie2_1` | 2.1 (Q1-2) | source binaire (MATLAB et Simulink), entropie H(p) | < 1 min |
| `partie2_2` | 2.2 (Q3-6) | entropie d'un texte, code de Huffman, coût de la table | < 1 min |
| `partie2_3` | 2.3 (Q7) | extension de la source (blocs de k bits) | < 1 min |
| `partie2_4` | 2.4 (Q8-9) | paires de caractères, gzip/bzip2/7z, bits en sortie de Huffman | ≈ 1 min |
| `partie2_5` | 2.5 (Q10-11) | codage de Lempel-Ziv 78 | ≈ 1 min |
| `partie3_1` | 3 (Q1-3) | canal binaire symétrique, capacité | < 1 min |
| `partie3_2` | 3 (Q4-6) | bruit uniforme, seuil optimal | < 1 min |
| `partie3_3` | 3 (Q7-9) | bruit gaussien, seuil MAP | < 1 min |
| `partie3_4` | 3 (Q10-13) | L échantillons par bit, détecteur optimal, TEB(Eb/N0) | ≈ 1 min |
| `partie4_1` | 4 (Q1-3) | matrices G, H, distance minimale, codeur/décodeur MATLAB | < 1 min |
| `partie4_2` | 4 (Q4-6) | codeur à registre et décodeur en logique (Simulink) | < 1 min |
| `partie4_3` | 4 (Q7-9) | performances théoriques, Monte-Carlo | ≈ 1 min |
| `partie4_4` | 4 (Q10-12) | code inséré dans la chaîne, gain de codage, latence | ≈ 5 min |
| `partie5_1` | 5 (Q1-5) | QPSK, mapping de Gray et naturel, constellations | ≈ 1 min |
| `partie5_2` | 5 (Q6) | QPSK avec code de Hamming | ≈ 5 min |
| `partie6_1` | 6 (Q2-4) | filtre RRC, h et h*h, densités spectrales | < 1 min |
| `partie6_2` | 6 (Q1, Q5-6) | chaîne filtrée, diagrammes de l'œil, décalage T/4 | ≈ 6 min |
| `partie7_1` | 7 (Q1-2) | canal à écho, égaliseurs ZF et à retour de décision | ≈ 3 min |
| `partie7_2` | 7 (Q3) | transmission d'un texte, avec et sans Hamming | ≈ 2 min |

## 4. Modèles Simulink

Chaque modèle est **construit par un script** (`modeles/construire_modele_*.m`) avec
`add_block` / `add_line`, puis enregistré en `.slx` dans `sources/` : il peut ensuite
être ouvert et simulé à la main, à condition d'avoir lancé le script correspondant
(qui crée les variables du workspace).

| Modèle | Script | Description |
|---|---|---|
| `modele_source` | partie2_1 | source binaire (sous-système masqué) |
| `modele_canal_cbs`, `_unif`, `_gauss` | partie3_1 à 3_3 | chaîne à 1 échantillon par bit |
| `modele_chaine_base` | partie3_4 | L échantillons par bit, détecteur optimal (intégrateur) |
| `modele_codeur_registre` | partie4_2 | codeur C(7,4) : bascules D, XOR, AND, Switch |
| `modele_decodeur_hamming` | partie4_2 | décodeur C(7,4) : syndrome et correction en logique |
| `modele_chaine_codee` | partie4_4 | chaîne binaire avec codage de canal |
| `modele_qpsk`, `modele_qpsk_codee` | partie5_1, 5_2 | modulation QPSK sans et avec codage |
| `modele_qpsk_filtre` | partie6_2 | QPSK + filtre de mise en forme et filtre adapté |
| `modele_chaine_complete`, `_codee` | partie7_1, 7_2 | chaîne complète avec canal à écho |

Conventions communes :

- les sous-systèmes réutilisables (source, codeur, décodeur, modem QPSK) sont créés
  par les fonctions `modeles/ajouter_*.m` ;
- les signaux sont récupérés par des blocs *To Workspace* dans la sortie `out` de `sim` ;
- la **synchronisation** (instant d'échantillonnage `dPhase`, phase de l'horloge de mot
  `phaseC`, alignement des mots `dAlign`) et le **retard** total sont déterminés
  automatiquement par une simulation sans bruit en début de script ;
- chaque point de TEB utilise sa propre graine (`P.graine + 100*i`), dérivée de la
  graine personnelle : les résultats sont reproductibles.

## 5. Problèmes connus

| Message | Cause | Solution |
|---|---|---|
| `Bibliothèque "dspbuff3" introuvable` | DSP System Toolbox absente | l'installer (blocs Buffer / Unbuffer) |
| `Le texte ne fait que … caractères` | `fichierTexte` pointe vers un texte court | indiquer le roman dans `Parametres.m` |
| `Étalonnage impossible` | modèle modifié à la main | relancer le script : il reconstruit le modèle |
| colonnes bzip2 / 7z à `NaN` | 7-Zip absent | facultatif ; installer 7-Zip ou compresser à la main |
