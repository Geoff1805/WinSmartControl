# WinSmartControl 🛡️

[![CI / CD Quality & Tests](https://github.com/Geoff1805/WinSmartControl/actions/workflows/ci.yml/badge.svg)](https://github.com/Geoff1805/WinSmartControl/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Platform Windows 11](https://img.shields.io/badge/platform-Windows%2011-0078D6.svg)](https://microsoft.com)

**WinSmartControl** est un outil open source développé pour gérer, auditer et basculer **Smart App Control (SAC)** sous Windows 11 en **mode évaluation / apprentissage** (`Evaluation mode`). Il permet aux développeurs et aux assistants d'ingénierie logicielle (agents IA, environnements de build, CLI) d'enseigner leurs workflows et exécutables au sous-système de réputation Windows (ISG) sans risquer de blocages intempestifs.

---

## 📌 Pourquoi WinSmartControl ?

### Le problème avec Smart App Control (SAC)
Sous Windows 11, Smart App Control s'appuie sur la technologie **Windows Defender Application Control (WDAC)** et le graphe de sécurité cloud Microsoft (**Intelligent Security Graph - ISG**).

SAC possède trois états fondamentaux définis dans le registre :
- **`0` — Off (Désactivé)** : SAC est éteint. Aucun blocage ni audit.
- **`1` — Enforce (Activé / Bloquant)** : SAC bloque impitoyablement toute application ou script binaire non signé ou dont la réputation cloud n'est pas établie. Dans ce mode, de nombreux outils développeurs (`ripgrep`, `jq`, `adb`, scripts PowerShell, compilatéurs KMP/Gradle/Rust) peuvent être bloqués.
- **`2` — Evaluation (Mode Évaluation / Apprentissage)** : SAC fonctionne en **arrière-plan silencieux**. Il **n'interrompt ni ne bloque aucun outil**, mais observe les exécutions et transmet la télémétrie à l'ISG pour construire la réputation des flux légitimes.

### Le verrouillage de l'interface graphique Windows
Lorsque Smart App Control passe en mode Activé (`1`) ou Désactivé (`0`), l'application Sécurité Windows **verrouille et grise l'option de retour en mode Évaluation**.
**WinSmartControl** lève ce verrou en modifiant directement la clé de stratégie Code Integrity au niveau du noyau :
`HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy` ➔ `VerifiedAndReputablePolicyState = 2`
puis en rafraîchissant les politiques Code Integrity via `citool.exe -r`.

---

## 🚀 Fonctionnalités Clés

1. **Bascule en Mode Apprentissage (Evaluation = 2)** :
   Restaure le mode apprentissage sans nécessiter de réinstallation ou réinitialisation de Windows.
2. **Entraînement Automatique des Outils Développeur (`train`)** :
   Exécute une routine d'exercices sur vos outils usuels (`rg`, `jq`, `git`, `python`, `adb`, `biome`, etc.) pendant que le système audite, favorisant la création de réputation positive dans l'ISG.
3. **Audit en Temps Réel des Événements Code Integrity (`logs`)** :
   Lit les événements de l'observateur d'événements :
   - **ID 3076** : Événement d'audit (exécuté avec succès, aurait été bloqué en mode Enforce).
   - **ID 3077** : Événement de blocage strict (en mode Enforce).
4. **Configuration de la Confiance Développeur** :
   Ajoute les répertoires de développement (`G:\Mon Drive\05_Dev`, toolchains locales) aux exclusions de surveillance et active le Mode Développeur Windows.
5. **Double Interface** :
   - Lanceur 1-clic autonome avec élévation automatique (`Run-SetLearningMode.bat` / PowerShell).
   - Package et CLI Python typés (`winsmartcontrol status`, `winsmartcontrol set eval`, etc.).

---

## 🛠️ Utilisation Rapide

### Méthode 1 : Lanceur 1-Clic Administrateur (Recommandé)
1. Rendez-vous dans le dossier `scripts/` du dépôt :
   `G:\Mon Drive\05_Dev\WinSmartControl\scripts`
2. Faites un clic droit sur **`Run-SetLearningMode.bat`** ➔ **Exécuter en tant qu'administrateur**.
3. Le script :
   - Bascule le registre `VerifiedAndReputablePolicyState` à `2`.
   - Rafraîchit Code Integrity via `citool.exe -r`.
   - Enregistre les exclusions développeur.
   - Lance la boucle d'apprentissage télémétrique des outils.

### Méthode 2 : En Ligne de Commande PowerShell (Elevé)
```powershell
# Afficher l'état actuel (sans élévation)
.\scripts\Set-SmartAppControl.ps1 -Mode Status

# Basculer en mode évaluation avec entraînement des outils (nécessite terminal Admin)
.\scripts\Set-SmartAppControl.ps1 -Mode Evaluation -TrainTools -ConfigureDevTrust

# Auditer les événements récents de blocage / audit
.\scripts\Audit-SACLogs.ps1 -Limit 20
```

### Méthode 3 : CLI Python
```bash
# Vérifier le statut
python -m winsmartcontrol.cli status

# Lancer la boucle d'entraînement
python -m winsmartcontrol.cli train

# Voir les derniers logs Code Integrity
python -m winsmartcontrol.cli logs --limit 10
```

---

## 🔒 Protection des Configurations & Standards

Conformément à nos règles d'architecture et de sécurité :
- Le fichier `.env.example` contient le modèle des variables de configuration.
- Les fichiers réels de configuration locale (`.env`, `credentials/`, logs locaux, caches d'audit) sont **strictement protégés et ignorés par Git** via `.gitignore`.
- Fichier `.github/dependabot.yml` actif pour la surveillance continue des dépendances (`pip`, `github-actions`).
- Workflows GitHub Actions exécutés sur runner LTS `ubuntu-24.04` avec zéro avertissement.

---

## 🧪 Tests Fonctionnels

La suite de tests unitaires et fonctionnels valide le respect des cas nominaux et des cas limites :
```bash
py -m pytest tests -v
```

---

## 📄 Licence

Ce projet est distribué sous licence open source **MIT**. Consultez le fichier [LICENSE](LICENSE) pour plus de détails.
