"""Module de gestion du Contrôle Intelligent des Applications (Smart App Control)."""

from __future__ import annotations

import ctypes
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

try:
    import winreg
except ImportError:
    winreg = None  # Compatibilité tests hors-Windows


CI_POLICY_KEY = r"SYSTEM\CurrentControlSet\Control\CI\Policy"
SAC_VALUE_NAME = "VerifiedAndReputablePolicyState"
SAC_PREV_NAME = "SAC_PreviousState"


@dataclass
class SACStatus:
    code: int
    name: str
    description: str
    is_learning: bool


SAC_MODES: Dict[int, SACStatus] = {
    0: SACStatus(
        code=0,
        name="Off (Désactivé)",
        description="Smart App Control est désactivé. Aucune restriction de réputation n'est appliquée.",
        is_learning=False,
    ),
    1: SACStatus(
        code=1,
        name="Enforce (Activé/Bloquant)",
        description="Smart App Control bloque automatiquement les fichiers binaires ou scripts non vérifiés.",
        is_learning=False,
    ),
    2: SACStatus(
        code=2,
        name="Evaluation (Apprentissage)",
        description="Smart App Control est en mode apprentissage : il audite et observe les exécutions sans rien bloquer.",
        is_learning=True,
    ),
}


class SmartControlManager:
    """Gestionnaire centralisé pour Smart App Control et l'environnement de développement."""

    @staticmethod
    def is_admin() -> bool:
        """Vérifie si le processus en cours dispose des privilèges Administrateur."""
        if os.name != "nt":
            return False
        try:
            return ctypes.windll.shell32.IsUserAnAdmin() != 0
        except Exception:
            return False

    @staticmethod
    def get_status() -> SACStatus:
        """Récupère l'état actuel de Smart App Control depuis le registre Windows."""
        if winreg is None:
            return SACStatus(-1, "Non-Windows", "Environnement non Windows.", False)

        try:
            with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, CI_POLICY_KEY, 0, winreg.KEY_READ) as key:
                val, _ = winreg.QueryValueEx(key, SAC_VALUE_NAME)
                return SAC_MODES.get(
                    val,
                    SACStatus(val, f"Inconnu ({val})", "Valeur de registre non répertoriée.", False),
                )
        except FileNotFoundError:
            return SACStatus(-1, "Clé absente", "La clé de politique CI n'existe pas.", False)
        except PermissionError:
            return SACStatus(-1, "Accès refusé", "Droits de lecture insuffisants.", False)
        except Exception as e:
            return SACStatus(-1, "Erreur", str(e), False)

    @staticmethod
    def set_mode(mode_code: int) -> bool:
        """Définit le mode de Smart App Control (0=Off, 1=Enforce, 2=Evaluation).
        
        Nécessite des privilèges Administrateur.
        """
        if winreg is None or not SmartControlManager.is_admin():
            return False

        try:
            with winreg.OpenKey(
                winreg.HKEY_LOCAL_MACHINE, CI_POLICY_KEY, 0, winreg.KEY_SET_VALUE
            ) as key:
                # Sauvegarde de l'état précédent
                current = SmartControlManager.get_status()
                if current.code in (0, 1, 2):
                    winreg.SetValueEx(key, SAC_PREV_NAME, 0, winreg.REG_DWORD, current.code)
                winreg.SetValueEx(key, SAC_VALUE_NAME, 0, winreg.REG_DWORD, mode_code)

            # Rafraîchissement de la politique CI via citool si présent
            citool = shutil.which("citool.exe")
            if citool:
                subprocess.run([citool, "-r"], capture_output=True, text=True, check=False)
            return True
        except Exception:
            return False

    @staticmethod
    def get_default_tools() -> List[str]:
        """Retourne la liste complète des outils de développement Antigravity et du système à entraîner."""
        return [
            "git --version",
            "gh --version",
            "py --version",
            "py -m pip --version",
            "py -m pytest --version",
            "rg --version",
            "jq --version",
            "adb version",
            "cmd.exe /c biome --version",
            "act --version",
            "gitleaks version",
            "node --version",
            "cmd.exe /c npm --version",
            "cmd.exe /c java -version",
            "cmd.exe /c javac -version",
            "cmd.exe /c wrangler --version",
        ]

    @staticmethod
    def train_tools(custom_tools: Optional[List[str]] = None) -> List[Dict[str, Any]]:
        """Exécute une série d'outils de développement pour enseigner leur légitimité au graphe de réputation (ISG)."""
        tools = custom_tools or SmartControlManager.get_default_tools()

        results = []
        for cmd in tools:
            binary = cmd.split()[0].strip('"')
            binary_path = shutil.which(binary) if not os.path.isabs(binary) else binary
            try:
                proc = subprocess.run(
                    cmd,
                    shell=True,
                    stdin=subprocess.DEVNULL,
                    capture_output=True,
                    text=True,
                    errors="replace",
                    timeout=5,
                )
                output_raw = (proc.stdout or proc.stderr or "").strip()
                first_line = output_raw.splitlines()[0] if output_raw else "OK (Code 0)"
                results.append({
                    "command": cmd,
                    "binary_path": binary_path,
                    "success": proc.returncode == 0,
                    "output": first_line[:120],
                })
            except Exception as e:
                results.append({
                    "command": cmd,
                    "binary_path": binary_path,
                    "success": False,
                    "output": str(e),
                })
        return results

    @staticmethod
    def get_audit_logs(limit: int = 20) -> List[Dict[str, str]]:
        """Interroge les logs d'événements Windows Code Integrity (ID 3076=Audit, 3077=Bloqué)."""
        if os.name != "nt":
            return []

        ps_cmd = (
            f"Get-WinEvent -FilterHashtable @{{LogName='Microsoft-Windows-CodeIntegrity/Operational'; Id=3076,3077}} "
            f"-MaxEvents {limit} -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, Message | ConvertTo-Json -Depth 2"
        )
        try:
            res = subprocess.run(["powershell", "-NoProfile", "-Command", ps_cmd], capture_output=True, text=True)
            if res.returncode == 0 and res.stdout.strip():
                import json
                parsed = json.loads(res.stdout)
                if isinstance(parsed, dict):
                    parsed = [parsed]
                return parsed
        except Exception:
            pass
        return []
