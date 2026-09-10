<div align="center">
  <h1>🚨 PT_MDT - Police Mobile Data Terminal</h1>
  <p><strong>Moderní, rychlý a plně vybavený policejní terminál pro FiveM (ESX Legacy & ox_inventory)</strong></p>

  [![FiveM](https://img.shields.io/badge/FiveM-Ready-blue.svg?style=for-the-badge&logo=fivem)](https://fivem.net/)
  [![ESX Legacy](https://img.shields.io/badge/ESX-Legacy-darkgreen.svg?style=for-the-badge)](https://esx-framework.org/)
  [![ox_inventory](https://img.shields.io/badge/ox__inventory-Integrated-purple.svg?style=for-the-badge)](https://github.com/overextended/ox_inventory)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
</div>

---

## 📖 Přehled / Overview

**pt_mdt** je pokročilý policejní systém (MDT / CAD) navržený s důrazem na čistý moderní design, rychlost a snadnou konfiguraci. Nevyžaduje žádné složité kompilování NodeJS balíčků – po stažení z GitHubu funguje okamžitě!

---

## ✨ Klíčové funkce / Features

- 🖥️ **Přehledný Dashboard**:
  - Hlídky ve službě (aktivní policisté a šerifové).
  - Oddělení nástěnky s hlášeními velení (možnost připnout zprávy).
  - Rychlé statistiky aktivních zatykačů, BOLO a incidentů za posledních 24 hodin.
- 👤 **Evidence občanů (Citizens)**:
  - Vyhledávání osob dle jména, příjmení, telefonního čísla nebo rodného čísla / ID.
  - Vlastněné licence (řidičský průkaz, zbrojní průkaz z `user_licenses`).
  - Kompletní trestní rejstřík a záznamy o trestech.
  - Záznamy o vlastněných vozidlech a aktivních zatykačích na osobu.
  - Možnost nahrání policejní fotografie (Mugshot) a interních poznámek.
- 🚔 **Evidence vozidel (Vehicles)**:
  - Vyhledávání podle SPZ (Plate).
  - Přímé zjištění majitele vozidla s možností jedním klikem otevřít jeho kartu.
  - Označení vozidla jako **Odcizené** (Stolen) a interní policejní záznamy k vozidlu.
- 📋 **Incidenty a spisy (Incidents & Reports)**:
  - Tvorba protokolů s přiřazením zasahujících důstojníků, podezřelých a svědků.
  - Interaktivní výběr trestů z **Trestního sazebníku (Penal Code)**.
  - Automatický součet celkové pokuty a délky vězení.
  - **Plná automatizace**: vystavení pokuty přímo na účet podezřelého (`esx_billing` / society) a odeslání do vězení.
- 📜 **Zatykače (Warrants)**:
  - Vydávání zatykačů na hledané osoby.
  - Upozornění do chatu/notifikace všem hlídkám ve službě.
  - Možnost zatykač uzavřít po zadržení pachatele.
- 🚨 **BOLO Pátrání (Be On the Lookout)**:
  - Vyhlášení urgentního pátrání po nebezpečných osobách nebo vozidlech.
- ⚖️ **Trestní sazebník (Penal Code)**:
  - Plně kategorizovaný sazebník (Dopravní přestupky, Veřejný pořádek, Majetek, Násilí, Drogy a zbraně) přehledně editovatelný v `shared/penal_code.lua`.
- 📻 **Dispečink a 911 hovory (Dispatch)**:
  - Záznam příchozích tísňových volání.
  - Možnost jedním kliknutím nastavit GPS cíl (waypoint) na mapě.
- 🌐 **Vícejazyčnost (Multi-language / i18n)**:
  - Předpřipravené jazyky: **Čeština (`cs`)**, **Angličtina (`en`)**, **Němčina (`de`)**.
  - Výběr jediným nastavením v `shared/config.lua`.
- 🎒 **Integrace s `ox_inventory`**:
  - Unikátní item `mdt_tablet` s 3D propem a animací držení v ruce.
  - Možnost otevření MDT odkudkoliv s itemem, nebo v policejním voze přes klávesu/příkaz (`/mdt`).

---

## 📦 Požadavky / Requirements

- [es_extended](https://github.com/esx-framework/esx_core) (ESX Legacy)
- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)

---

## 🚀 Instalace / Installation

1. **Stáhněte** nebo naklonujte repozitář do složky `resources/[pt_scripts]/pt_mdt`:
   ```bash
   cd resources/[pt_scripts]
   git clone https://github.com/it-petrfila/pt_mdt.git
   ```

2. **Importujte databázové schéma**:
   Spusťte soubor `install.sql` ve vašem databázovém nástroji (např. HeidiSQL nebo phpMyAdmin) v databázi FiveM serveru.

3. **Přidejte položku do `ox_inventory/data/items.lua`**:
   ```lua
   ['mdt_tablet'] = {
       label = 'Police MDT Tablet',
       weight = 1000,
       stack = false,
       close = true,
       description = 'Mobilní policejní terminál pro přístup k evidenci občanů, vozidel a zatykačů.'
   },
   ```

4. **Zkopírujte ikonu položky**:
   Zkopírujte soubor `web/img/mdt_tablet.png` do `resources/ox_inventory/web/images/mdt_tablet.png`.

5. **Spusťte skript v `server.cfg`**:
   ```cfg
   ensure ox_lib
   ensure oxmysql
   ensure ox_inventory
   ensure pt_mdt
   ```

---

## ⚙️ Konfigurace / Configuration

Veškeré nastavení se provádí v souboru `shared/config.lua`:

```lua
Config.Locale = 'cs' -- Volby: 'cs', 'en', 'de'

-- Povolení zaměstnání
Config.AllowedJobs = {
    ['police'] = { label = 'Police Department', badge = 'LSPD', canIssueWarrant = true, canSendToJail = true },
    ['sheriff'] = { label = 'Sheriff Office', badge = 'LSSD', canIssueWarrant = true, canSendToJail = true }
}

-- Nastavení otevírání
Config.OpenOptions = {
    Command = 'mdt',
    Keybind = 'F5',
    RequireItem = true,
    AllowInPoliceVehicleWithoutItem = true,
}
```

---

## 📡 API a Exporty pro vývojáře

Pro odeslání nového hlášení na dispečink z jiného skriptu (např. systém loupeží):

```lua
-- Na straně serveru:
exports['pt_mdt']:SendDispatch({
    code = '10-31',
    title = 'Přepadení klenotnictví',
    message = 'Spuštěn tichý alarm, podezřelí ozbrojeni',
    caller = 'Bezpečnostní systém',
    coords = vector3(-631.5, -237.4, 38.0)
})
```

---

## 📜 Licence

Tento projekt je licencován pod licencí MIT - viz soubor [LICENSE](LICENSE).

Vyvinuto od **pt_scripts (it-petrfila)**.
