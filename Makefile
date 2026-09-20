.DEFAULT_GOAL := help

MAC_PYTHON ?= python3
MAC_VENV_PYTHON ?= .venv/bin/python
WIN_VENV_PYTHON ?= .venv/Scripts/python.exe
PLAN ?=
QUERY ?= blues
CATEGORY ?= DRV

.PHONY: help \
	mac-setup mac-build mac-test mac-install-skill mac-doctor mac-snapshot \
	mac-routing mac-catalog-search mac-plan-validate mac-plan-preview \
	win-setup win-build win-test win-install-skill win-doctor win-snapshot \
	win-routing win-catalog-search win-plan-validate win-plan-preview

help:
	@printf '%s\n' 'macOS:'
	@printf '%s\n' '  make mac-setup'
	@printf '%s\n' '  make mac-build'
	@printf '%s\n' '  make mac-test'
	@printf '%s\n' '  make mac-install-skill'
	@printf '%s\n' '  make mac-doctor'
	@printf '%s\n' '  make mac-snapshot'
	@printf '%s\n' '  make mac-routing'
	@printf '%s\n' '  make mac-catalog-search QUERY=blues CATEGORY=DRV'
	@printf '%s\n' '  make mac-plan-validate PLAN=path/to/plan.json'
	@printf '%s\n' '  make mac-plan-preview PLAN=path/to/plan.json'
	@printf '%s\n' 'Windows:'
	@printf '%s\n' '  make win-setup'
	@printf '%s\n' '  make win-build'
	@printf '%s\n' '  make win-test'
	@printf '%s\n' '  make win-install-skill'
	@printf '%s\n' '  make win-doctor'
	@printf '%s\n' '  make win-snapshot'
	@printf '%s\n' '  make win-routing'
	@printf '%s\n' '  make win-catalog-search QUERY=blues CATEGORY=DRV'
	@printf '%s\n' '  make win-plan-validate PLAN=path/to/plan.json'
	@printf '%s\n' '  make win-plan-preview PLAN=path/to/plan.json'
	@printf '%s\n' ''
	@printf '%s\n' 'Hardware writes remain explicit CLI commands. They are not Make targets.'

mac-setup:
	$(MAC_PYTHON) -m venv .venv
	$(MAC_VENV_PYTHON) -m pip install --upgrade pip
	$(MAC_VENV_PYTHON) -m pip install -e .

mac-build:
	./scripts/macos/build-bridge.sh

mac-test:
	./scripts/macos/test.sh

mac-install-skill:
	./scripts/macos/install-skill.sh --force

mac-doctor:
	$(MAC_VENV_PYTHON) skills/ampero-tone/scripts/ampero.py --json doctor --scan

mac-snapshot:
	$(MAC_VENV_PYTHON) skills/ampero-tone/scripts/ampero.py --json device snapshot --include-parameters

mac-routing:
	$(MAC_VENV_PYTHON) skills/ampero-tone/scripts/ampero.py --json device routing --timeout 5

mac-catalog-search:
	$(MAC_VENV_PYTHON) skills/ampero-tone/scripts/ampero.py --json catalog search "$(QUERY)" --category "$(CATEGORY)"

mac-plan-validate:
	$(if $(PLAN),,$(error PLAN is required, for example: make mac-plan-validate PLAN=examples/clear-rhythm.plan.json))
	$(MAC_VENV_PYTHON) skills/ampero-tone/scripts/ampero.py --json plan validate "$(PLAN)"

mac-plan-preview:
	$(if $(PLAN),,$(error PLAN is required, for example: make mac-plan-preview PLAN=examples/clear-rhythm.plan.json))
	$(MAC_VENV_PYTHON) skills/ampero-tone/scripts/ampero.py --json plan preview "$(PLAN)"

win-setup:
	powershell -NoProfile -ExecutionPolicy Bypass -Command "py -3.9 -m venv .venv; .\.venv\Scripts\python.exe -m pip install --upgrade pip; .\.venv\Scripts\python.exe -m pip install -e ."

win-build:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/windows/build-bridge.ps1

win-test:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/windows/test.ps1

win-install-skill:
	powershell -NoProfile -ExecutionPolicy Bypass -File scripts/windows/install-skill.ps1 -Force

win-doctor:
	$(WIN_VENV_PYTHON) skills/ampero-tone/scripts/ampero.py --json doctor --scan

win-snapshot:
	$(WIN_VENV_PYTHON) skills/ampero-tone/scripts/ampero.py --json device snapshot --include-parameters

win-routing:
	$(WIN_VENV_PYTHON) skills/ampero-tone/scripts/ampero.py --json device routing --timeout 5

win-catalog-search:
	$(WIN_VENV_PYTHON) skills/ampero-tone/scripts/ampero.py --json catalog search "$(QUERY)" --category "$(CATEGORY)"

win-plan-validate:
	$(if $(PLAN),,$(error PLAN is required, for example: make win-plan-validate PLAN=examples/clear-rhythm.plan.json))
	$(WIN_VENV_PYTHON) skills/ampero-tone/scripts/ampero.py --json plan validate "$(PLAN)"

win-plan-preview:
	$(if $(PLAN),,$(error PLAN is required, for example: make win-plan-preview PLAN=examples/clear-rhythm.plan.json))
	$(WIN_VENV_PYTHON) skills/ampero-tone/scripts/ampero.py --json plan preview "$(PLAN)"
