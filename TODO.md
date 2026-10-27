# WinSmartControl - Feuille de Route & Tâches (TODO)

## Phase 1 : Initialisation & Fonctions Essentielles (Terminée)
- [x] Initialisation du dépôt sous `G:\Mon Drive\05_Dev\WinSmartControl` sous licence MIT.
- [x] Fichiers standards `.gitignore` et `.env.example` pour protection des configurations locales.
- [x] Script PowerShell `scripts/Set-SmartAppControl.ps1` conforme encodage UTF-8 standard.
- [x] Script d'audit des logs Code Integrity `scripts/Audit-SACLogs.ps1`.
- [x] Lanceur 1-clic UAC `scripts/Run-SetLearningMode.bat`.
- [x] Module Python `winsmartcontrol.manager` et CLI `winsmartcontrol.cli`.
- [x] Configuration CI/CD GitHub Actions (`.github/workflows/ci.yml`) sur `ubuntu-24.04`.
- [x] Configuration Dependabot (`.github/dependabot.yml`) pour GitHub Actions et Pip.
- [x] Suite de tests unitaires et fonctionnels avec Pytest (7/7 passés).

## Phase 2 : Évolutions Futures
- [ ] Export automatique des rapports d'audit Code Integrity en format HTML/JSON.
- [ ] Interface graphique légère (Systray / notification Windows) signalant les événements d'audit en temps réel.
- [ ] Intégration d'un watcher observant en continu le journal d'événements `Microsoft-Windows-CodeIntegrity/Operational` pour alerter immédiatement si un nouvel exécutable compilé est audité.
