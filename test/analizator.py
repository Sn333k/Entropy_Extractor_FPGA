import sys

# Słownik zamieniający kody sterujące ASCII na ich czytelne reprezentacje
SPECIAL_CHARS = {

    '\x1b': '\\e (Escape / ESC)'
}

def analyze_ascii_file(filename='dane.txt'):
    print(f"Analizuję plik: '{filename}'...\n")
    print("-" * 60)
    print(f"{'ZNAK / KOD':<25} | {'OPIS / WIZUALIZACJA':<30}")
    print("-" * 60)

    try:
        with open(filename, 'r', encoding='utf-8', errors='replace') as file:
            while True:
                # Czytamy plik znak po znaku (lub małymi paczkami)
                chunk = file.read(1024)
                if not chunk:
                    break
                
                for char in chunk:
                    if char in SPECIAL_CHARS:
                        print(f"{SPECIAL_CHARS[char]:<25} | [Znak specjalny]")
                    elif ord(char) < 32 or ord(char) == 127:
                        # Inne nietrywialne znaki sterujące ASCII
                        print(f"ASCII {ord(char):<18} | [Znak sterujący]")
                        
    except FileNotFoundError:
        print(f"[Błąd]: Nie znaleziono pliku '{filename}'. Najpierw uruchom program zbierający dane.")
    except Exception as e:
        print(f"[Błąd]: Wystąpił problem podczas odczytu pliku: {e}")
    
    print("-" * 60)

if __name__ == "__main__":
    analyze_ascii_file()