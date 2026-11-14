import serial
import sys
import os

# --- KONFIGURACJA ---
SERIAL_PORT = 'COM3'
BAUD_RATE = 115200       
TIMEOUT = 1              

# --- PARAMETRY PODZIAŁU ---
BYTES_PER_FILE = 625000  
MAX_FILES = 10           
# --------------------

def capture_serial_split_files():
    print(f"Start nasłuchu na porcie {SERIAL_PORT} (Baudrate: {BAUD_RATE})")
    print(f"Plan: Zapis do {MAX_FILES} plików po {BYTES_PER_FILE} bajtów każdy.\n")
    
    current_file_index = 1
    bytes_in_current_file = 0
    
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=TIMEOUT)
        print("Połączono pomyślnie! Oczekiwanie na dane...\n")
        
        while current_file_index <= MAX_FILES:
            if ser.in_waiting > 0:
                space_left = BYTES_PER_FILE - bytes_in_current_file
                to_read = min(ser.in_waiting, space_left)
                raw_data = ser.read(to_read)
                
                if not raw_data:
                    continue

                filename = f"dane_{current_file_index}.bin"

                with open(filename, 'ab') as f:
                    f.write(raw_data)
                
                bytes_in_current_file += len(raw_data)

                sys.stdout.write(f"\r[Plik {current_file_index}/{MAX_FILES}] Zapisano: {bytes_in_current_file}/{BYTES_PER_FILE} bajtów")
                sys.stdout.flush()
                
                # Sprawdzenie czy obecny plik został w pełni zapełniony
                if bytes_in_current_file >= BYTES_PER_FILE:
                    print(f"\n -> Plik '{filename}' został w pełni zapełniony.")
                    current_file_index += 1
                    bytes_in_current_file = 0 # Reset licznika dla kolejnego pliku
                    
        print("\n[Sukces] Wszystkie 10 plików zostało pomyślnie zapełnionych. Pobieranie zakończone.")
        
    except serial.SerialException as e:
        print(f"\n[Błąd portu szeregowego]: {e}")
    except KeyboardInterrupt:
        print("\n[Przerwano] Program został zatrzymany ręcznie przez użytkownika.")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("Port szeregowy został zamknięty.")

if __name__ == "__main__":
    capture_serial_split_files()