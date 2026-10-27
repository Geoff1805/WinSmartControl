"""Tests unitaires et fonctionnels pour WinSmartControl (Rule 13)."""

import pytest
from unittest.mock import patch, MagicMock
from winsmartcontrol.manager import SmartControlManager, SACStatus, SAC_MODES


def test_sac_modes_definitions():
    """Vérifie la cartographie exacte des codes Smart App Control."""
    assert 0 in SAC_MODES
    assert 1 in SAC_MODES
    assert 2 in SAC_MODES

    assert SAC_MODES[0].code == 0
    assert SAC_MODES[0].is_learning is False
    assert "Désactivé" in SAC_MODES[0].name

    assert SAC_MODES[1].code == 1
    assert SAC_MODES[1].is_learning is False
    assert "Enforce" in SAC_MODES[1].name

    assert SAC_MODES[2].code == 2
    assert SAC_MODES[2].is_learning is True
    assert "Evaluation" in SAC_MODES[2].name


def test_is_admin_check():
    """Vérifie que la fonction is_admin s'exécute sans exception et retourne un booléen."""
    result = SmartControlManager.is_admin()
    assert isinstance(result, bool)


def test_get_status_live_or_mock():
    """Vérifie la récupération de statut en nominal."""
    status = SmartControlManager.get_status()
    assert isinstance(status, SACStatus)
    assert status.code in (0, 1, 2, -1)
    assert len(status.name) > 0


def test_train_tools_nominal():
    """Vérifie l'exécution nominale d'un sous-ensemble d'outils sûrs."""
    results = SmartControlManager.train_tools(custom_tools=["py --version", "git --version"])
    assert isinstance(results, list)
    assert len(results) == 2
    for r in results:
        assert "command" in r
        assert "success" in r
        assert "output" in r


def test_train_tools_nonexistent_command():
    """Cas d'erreur (Edge Case) : exécution d'une commande inconnue."""
    results = SmartControlManager.train_tools(custom_tools=["non_existent_tool_123456 --xyz"])
    assert len(results) == 1
    assert results[0]["success"] is False


def test_set_mode_non_admin_fails():
    """Vérifie le blocage de sécurité lorsqu'un utilisateur non admin tente une modification."""
    with patch.object(SmartControlManager, "is_admin", return_value=False):
        success = SmartControlManager.set_mode(2)
        assert success is False


@patch("subprocess.run")
def test_get_audit_logs_nominal(mock_subproc):
    """Vérifie le parsing des logs d'audit Code Integrity."""
    mock_res = MagicMock()
    mock_res.returncode = 0
    mock_res.stdout = '[{"TimeCreated": "2026-10-27T12:00:00", "Id": 3076, "Message": "Audit block"}]'
    mock_subproc.return_value = mock_res

    logs = SmartControlManager.get_audit_logs(limit=5)
    assert len(logs) == 1
    assert logs[0]["Id"] == 3076
