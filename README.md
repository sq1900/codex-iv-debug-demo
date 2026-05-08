# Codex I-V Data Debug Demo

This repository is prepared for a Codex-based code debugging demo.

## Project Goal

Use Codex to debug MATLAB scripts for semiconductor I-V measurement data processing.

## Data

The `data/` folder contains raw I-V measurement data of three power semiconductor devices:

- IRF3710
- IRF2804
- BD241C

## Tasks for Codex

Codex should help debug and improve the MATLAB script to:

1. Read raw `.txt` data files.
2. Clean invalid values.
3. Normalize current data.
4. Plot I-V curves.
5. Fit IRF3710 data using a logarithmic model.
6. Compare I-V characteristics of different devices.
7. Export publication-style figures.

## Expected Output

- IRF3710 logarithmic fitting figure
- I-V characteristics comparison figure
