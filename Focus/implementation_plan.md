# Redesign StatsView in stile FocusPomo

Ridisegnare la schermata Statistics per allinearla allo stile dello screenshot fornito (FocusPomo). Dark UI con glass cards, header con scroll edge effect, layout a due colonne, stacked bar chart con trend.

## Proposed Changes

### StatsViewModel — nuovi computed per il nuovo layout

#### [MODIFY] [StatsViewModel.swift](file:///home/marcodignoti/Progetti-iphone/focus-ios/Focus/Focus/ViewModels/StatsViewModel.swift)

Aggiungere nuovi computed:
- `todayMinutes` / `weekMinutes` — per la sezione "Today's Focus" / "This Week"
- `todayDelta` / `weekDelta` — variazione % vs periodo precedente (▲/▼)
- `dailyAverage` — media giornaliera nella settimana corrente
- `modeBreakdown(from:)` → `[(modeTitle, color, minutes, percentage)]` — per il grid dei modi
- `weeklyStackedData(from:)` → dati per il grafico a barre impilate per giorno

---

### StatsView — layout completo ridisegnato

#### [MODIFY] [StatsView.swift](file:///home/marcodignoti/Progetti-iphone/focus-ios/Focus/Focus/Views/Stats/StatsView.swift)

Layout completo ridisegnato con queste sezioni:

1. **Scroll edge effect header** — usa `applyNativeCalendarHeader` per iOS 26+, overlay con material per < iOS 26 (pattern identico a `FocusCalendarView`)
2. **Header** — "Summary" (bold) + data corrente ("Mar 7, Today")
3. **Summary card** — due colonne: "Total Sessions" + numero, "Total Focus" + ore formattate
4. **Mode Breakdown grid** — 2×2 grid con icona+colore, nome, durata, %
5. **Focus Trend card** — "Today's Focus" e "This Week" con durata e delta %, stacked bar chart settimanale con daily avg
6. **Swipe-down hint** — mantenuto

---

### StatsChartView — stacked bars

#### [MODIFY] [StatsChartView.swift](file:///home/marcodignoti/Progetti-iphone/focus-ios/Focus/Focus/Views/Stats/StatsChartView.swift)

Convertire il chart a barre impilate (stacked) con colori per modo, con day labels S M T W T F S, evidenziando il giorno corrente in bold.

---

### StatsSummaryCard — nuova card a due colonne

#### [MODIFY] [StatsSummaryCard.swift](file:///home/marcodignoti/Progetti-iphone/focus-ios/Focus/Focus/Views/Stats/StatsSummaryCard.swift)

Ridisegnata come card a due colonne:
- Colonna sinistra: "Total Sessions" + valore grande
- Colonna destra: "Total Focus" + ore formattate con unità piccole (h/m)

---

### Nuovi file

#### [NEW] [ModeBreakdownView.swift](file:///home/marcodignoti/Progetti-iphone/focus-ios/Focus/Focus/Views/Stats/ModeBreakdownView.swift)

Grid 2×2 con ogni modo che mostra: barra colorata, nome, durata, percentuale. Bottone "Show All" se ci sono > 4 modi.

#### [NEW] [FocusTrendCard.swift](file:///home/marcodignoti/Progetti-iphone/focus-ios/Focus/Focus/Views/Stats/FocusTrendCard.swift)

Card completa con:
- Header row: "Today's Focus" (left) / "This Week" (right) con valori grandi e delta % colorato
- Stacked bar chart settimanale
- "Daily Avg" label

## Verification Plan

### Manual Verification
- Build in Xcode
- Verificare scroll edge effect su iOS 26 simulator
- Confermare header blur su iOS < 26
