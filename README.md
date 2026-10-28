# FPGA-based TRNG & Toeplitz Entropy Extractor

## Ogólne założenia

Projekt realizowany w środowisku **Xilinx ISE 14.7**, którego celem jest implementacja i weryfikacja sprzętowa generatora prawdziwie losowych ciągów liczb (TRNG) opartego na pierścieniach oscylacyjnych (Ring Oscillators) oraz ekstraktora entropii Toeplitza na płytce rozwojowej **Digilent Atlys** (układ Spartan-6 XC6SLX45).

## Wymagania systemowe i sprzętowe

Środowisko programistyczne: **Xilinx ISE Design Suite 14.7** (wraz z symulatorem ISim).

Płytka docelowa:** Digilent Atlys** (FPGA Xilinx Spartan-6 XC6SLX45).

Oprogramowanie pomocnicze: **Terminal szeregowy** (Terminal.exe) do odbioru danych przez USB.

## Cel projektu

Projekt wykonany w ramach pracy magisterskiej pt. *"Badanie zależności między strukturą sprzętową a efektywnością ekstraktorów entropii implementowanych w układach FPGA"* na Politechnice Wrocławskiej w roku akademickim 2026/2027 na kierunku Informatyka Techniczna specjalność Systemy i Sieci Komputerowe