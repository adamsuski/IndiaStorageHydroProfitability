# Online Companion — “Evaluating storage profitability: A market-based comparison of hydro and battery options in India”

This repository provides a lightweight, fully reproducible companion to the article:

> **Evaluating storage profitability: A market-based comparison of hydro and battery options in India**  
> Adam Suski, Ilka Deleque Curiel, Debabrata Chattopadhyay, Sushanta Chatterjee, Dzenan Malovic (2025)

The companion contains just **two files**:
1. `storage_profitability_model.py` — a compact MILP-based model for evaluating storage/hydro profitability under multiple business cases.
2. `inputs_india_companion.xlsx` — minimal input workbook (prices, inflows, techno-economics, and scenario settings).

---

## What this code does (in one minute)

- Implements a **price-taker** mixed-integer linear program that optimizes hourly dispatch and monthly contract volumes.  
- Evaluates **three business cases** consistently across technologies:
  - **SPOT** — energy arbitrage only (day-ahead prices).
  - **SPOT+FCAS** — arbitrage + frequency control ancillary services (FCAS) revenue.
  - **SPOT+FCAS+CONTRACT** — stacked revenues with a fixed-price monthly contract (model chooses the optimal monthly volume).
- Computes **net revenue** and **IRR** using historical Indian Energy Exchange (IEX) prices (2015–2023) and state-level hydrology proxies.

Technologies included: **BESS**, **PSP**, **ROR**, **ROR with pondage**.

---
