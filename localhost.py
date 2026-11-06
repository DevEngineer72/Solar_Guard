import subprocess
from pathlib import Path

build = Path(__file__).resolve().parent / "build" / "web"

subprocess.run(
	["python3", "-m", "http.server", "8080"],
	cwd=build
)
