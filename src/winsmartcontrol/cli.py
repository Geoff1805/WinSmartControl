"""Interface en ligne de commande (CLI) pour WinSmartControl."""

from __future__ import annotations

import argparse
import sys
from winsmartcontrol.manager import SmartControlManager


def main() -> None:
    parser = argparse.ArgumentParser(
        description="WinSmartControl - Gestion et apprentissage de Smart App Control (SAC) sous Windows 11."
    )
    subparsers = parser.add_subparsers(dest="command", help="Commandes disponibles")

    # Commande status
    subparsers.add_parser("status", help="Affiche l'état actuel de Smart App Control.")

    # Commande set
    set_parser = subparsers.add_parser("set", help="Change le mode de Smart App Control (requiert Administrateur).")
    set_parser.add_argument(
        "mode",
        choices=["eval", "evaluation", "enforce", "off"],
        help="Mode cible (evaluation / enforce / off).",
    )

    # Commande train
    subparsers.add_parser("train", help="Exécute la boucle d'apprentissage pour les outils développeurs.")

    # Commande logs
    logs_parser = subparsers.add_parser("logs", help="Affiche les derniers événements Code Integrity (ID 3076/3077).")
    logs_parser.add_argument("--limit", type=int, default=15, help="Nombre d'événements à récupérer (défaut: 15).")

    args = parser.parse_args()

    if not args.command or args.command == "status":
        status = SmartControlManager.get_status()
        is_admin = SmartControlManager.is_admin()
        print("=" * 60)
        print("          WinSmartControl - Smart App Control Status          ")
        print("=" * 60)
        print(f"[*] État actuel      : {status.name}")
        print(f"[*] Code de registre : {status.code}")
        print(f"[*] Description      : {status.description}")
        print(f"[*] Mode apprentissage : {'OUI (Audit actif)' if status.is_learning else 'NON'}")
        print(f"[*] Privilège Admin  : {'OUI' if is_admin else 'NON (Lecture seule)'}")
        print("=" * 60)
        if not is_admin and status.code == 1:
            print("\n[NOTE] Pour basculer en mode apprentissage (Evaluation = 2), exécutez le script :")
            print(r"       scripts\Run-SetLearningMode.bat (Clic droit -> Exécuter en tant qu'administrateur)")
        return

    if args.command == "set":
        mode_map = {
            "eval": 2,
            "evaluation": 2,
            "enforce": 1,
            "off": 0,
        }
        target_code = mode_map[args.mode]
        if not SmartControlManager.is_admin():
            print("[ERREUR] Cette opération nécessite des privilèges Administrateur.")
            print(r"Veuillez lancer votre terminal ou 'scripts\Run-SetLearningMode.bat' en mode Administrateur.")
            sys.exit(1)

        success = SmartControlManager.set_mode(target_code)
        if success:
            updated = SmartControlManager.get_status()
            print(f"[SUCCÈS] Mode Smart App Control appliqué : {updated.name}")
        else:
            print("[ÉCHEC] Impossible de mettre à jour la valeur de registre.")
            sys.exit(1)

    elif args.command == "train":
        print("[*] Lancement de l'apprentissage des outils développeur...")
        results = SmartControlManager.train_tools()
        for r in results:
            status_icon = "✔" if r["success"] else "✖"
            print(f"  [{status_icon}] {r['command']:<20} -> {r['output']}")
        print("[OK] Entraînement terminé. Les exécutions ont été enregistrées.")

    elif args.command == "logs":
        print(f"[*] Recherche des {args.limit} derniers événements Code Integrity...")
        logs = SmartControlManager.get_audit_logs(limit=args.limit)
        if not logs:
            print("[INFO] Aucun blocage ou audit récent trouvé dans Microsoft-Windows-CodeIntegrity/Operational.")
        else:
            for ev in logs:
                print(f"- [{ev.get('TimeCreated', 'N/A')}] ID {ev.get('Id')}: {ev.get('Message', '').strip()[:120]}...")


if __name__ == "__main__":
    main()
