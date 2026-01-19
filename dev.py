import time
import os
import sys
import subprocess
from watchfiles import watch

# This File is meant to auto restart the app on change

def run_once():
    return subprocess.Popen([sys.executable, "main.py"], env=os.environ.copy())

def main():
    p = run_once()
    try:
        for _changes in watch("qml", "main.py", "widgets"):
            # Restart on any change
            p.terminate()
            try:
                p.wait(timeout=2)
            except subprocess.TimeoutExpired:
                p.kill()
                p.wait()
            time.sleep(0.1)
            p = run_once()
    finally:
        p.terminate()
        try:
            p.wait(timeout=2)
        except Exception:
            p.kill()

if __name__ == "__main__":
    main()

