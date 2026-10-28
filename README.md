# Arco - Traduction française (non officielle) -

Traduction française amateur complète du jeu **Arco** (édité par Panic), version Steam.

## Contenu

| Partie | État |
|---|---|
| Menus, options, interface de combat | ✅ |
| Objets, compétences, missions | ✅ |
| Acte I — Pèlerinage (tutoriel) | ✅ |
| Acte II — Iyo | ✅ |
| Acte III — Kanek | ✅ |
| Acte IV — Tuag | ✅ |
| Acte V — Fin et épilogues | ✅ |
| Chansons de fin (sous-titres) | ✅ |
| Bandeau de début de combat (« SURPRISE » / « SURPRIS ») | ✅ |

################################################################

Version du jeu testée : `2025.08.11-01-PC` (Steam, Windows).

################################################################

La traduction n'a pas encore été relue en jouant l'intégralité du jeu : des coquilles ou des textes qui débordent de leur cadre peuvent subsister. N'hésite pas à les signaler (voir plus bas).

## Installation (Windows)

1. Télécharge ce dépôt : bouton vert **Code** → **Download ZIP**, puis décompresse-le.
2. Double-clique sur **`installer.bat`**.
   - Windows peut afficher un avertissement de sécurité, car le fichier vient d'Internet : clique sur **Informations complémentaires** puis **Exécuter quand même** (ou **Exécuter**).
   - Le script trouve le jeu tout seul via Steam. Sinon, il te demande le chemin de `arco.exe`.
3. Lance le jeu, va dans **Options** → **Locale** et choisis **French / Français**.

### Ce que fait l'installeur

Ce dépôt ne contient aucun texte original du jeu, seulement la traduction. L'installeur `installer.ps1` (script PowerShell lisible dans n'importe quel éditeur de texte) :

1. lit le fichier de textes du jeu directement dans ton `arco.exe`, sans le modifier ;
2. y ajoute le français ;
3. copie le résultat dans `%APPDATA%\arco\locale` (et le bandeau dans `%APPDATA%\arco\assets`), un dossier que le jeu lit avant ses propres fichiers.

Le jeu lui-même n'est jamais modifié.

## Mise à jour

Télécharge la nouvelle version du dépôt et relance `installer.bat`.

## Désinstallation

Double-clique sur **`desinstaller.bat`**. Tes sauvegardes (dossier `save`) ne sont pas touchées.

## Bon à savoir

- Si le jeu reçoit une mise à jour, relance `installer.bat` : les textes inchangés restent traduits, les nouveaux s'afficheront en anglais en attendant une mise à jour de la traduction. En cas de problème, utilise `desinstaller.bat`.
- Le bandeau de début de combat redessiné s'affiche en français quelle que soit la langue choisie dans le jeu (le jeu n'a qu'une image pour toutes les langues).

## Signaler une erreur

Ouvre une *issue* en indiquant le texte fautif (une capture d'écran aide beaucoup) et, si possible, l'endroit du jeu où il apparaît.

## Mentions

Arco et ses textes originaux appartiennent à leurs auteurs. Ce projet est une traduction de fans, sans lien avec les développeurs ni l'éditeur. Il ne redistribue aucun fichier du jeu.
