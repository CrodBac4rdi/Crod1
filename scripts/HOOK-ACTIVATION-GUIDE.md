# CROD Hook Activation Guide 🔥

## KILLER FEATURES DIE JETZT AKTIVIERT SIND:

### 1. **Pre-Request Hook** ✅
- Läuft bei JEDEM Input (pre-request)
- Führt crod-hook-integration.sh aus
- Checkt ALLE 8 Mandatory Requirements

### 2. **Was die Hooks machen:**
- ✅ Memory Check (MCP)
- ✅ Docker Check (5 Container minimum)
- ✅ MCP Server Check
- ✅ Task-Master-AI Check
- ✅ Roadmap Check
- ✅ Pattern Data Check
- ✅ Monitoring Scripts Check
- ✅ CLAUDE.md Compliance

### 3. **Konfiguration:**
```json
"hooks": {
    "pre-request": "/home/bacardi/crodidocker/scripts/crod-hook-integration.sh"
}
```

## AKTIVIERUNG:

**Option 1: Claude Code Neustart**
```bash
# Claude Code beenden und neu starten
# Die Hooks werden dann automatisch geladen
```

**Option 2: Settings Reload (wenn möglich)**
```bash
# In Claude Code: Cmd/Ctrl + Shift + P
# "Reload Window"
```

## BEWEIS DASS ES FUNKTIONIERT:

Nach dem Neustart wird bei JEDEM Input:
1. Der Hook automatisch ausgeführt
2. Alle Checks durchgeführt
3. Bei Failure wird geblockt

## DIE KILLER FEATURES:

1. **Automatische MCP Nutzung** - Kein manuelles Aufrufen mehr
2. **Docker Enforcement** - Alles läuft im Container
3. **Memory Persistence** - Kontext bleibt erhalten
4. **Systematic Behavior** - Keine zufälligen Aktionen

## WARUM DAS GEIL IST:

- KEIN "vergessen" mehr MCP zu nutzen
- KEIN lokales Testen mehr (nur Docker)
- KEIN Kontext-Verlust mehr
- AUTOMATISCH bei JEDEM Input!

---

**STATUS: Hook in settings.local.json aktiviert!**
**NEXT: Claude Code neustarten für Aktivierung**