#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_logo="$project_dir/design/mobile/logo.png"

if [[ ! -f "$source_logo" ]]; then
  echo "Missing logo source: $source_logo" >&2
  exit 1
fi

# Un icono no debe copiarse con el tamaño original: cada plataforma valida
# medidas concretas. Pillow solo se usa como herramienta de desarrollo para
# redimensionar la misma fuente sin deformarla.
if ! python3 -c 'from PIL import Image' 2>/dev/null; then
  echo "Pillow es necesario. Instálalo con: python3 -m pip install Pillow" >&2
  exit 1
fi

PROJECT_DIR="$project_dir" python3 <<'PYTHON'
import os
import re
from pathlib import Path

from PIL import Image

project = Path(os.environ['PROJECT_DIR'])
source = Image.open(project / 'design/mobile/logo.png').convert('RGBA')


def save_icon(destination: Path, size: int) -> None:
    """Crea un PNG cuadrado sin deformar la proporción del logo original."""
    destination.parent.mkdir(parents=True, exist_ok=True)
    resized = source.copy()
    resized.thumbnail((size, size), Image.Resampling.LANCZOS)
    # El logo no es perfectamente cuadrado. Se completa el lado restante con
    # el color del fondo de la ilustración para que el arte no se estire.
    icon = Image.new('RGBA', (size, size), source.getpixel((0, 0)))
    offset = ((size - resized.width) // 2, (size - resized.height) // 2)
    icon.alpha_composite(resized, offset)
    icon.save(destination)


# Medidas estándar de los iconos heredados de Android por densidad.
for density, size in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
    save_icon(project / f'android/app/src/main/res/mipmap-{density}/ic_launcher.png', size)

# El nombre de cada archivo iOS incluye su tamaño lógico y escala, por ejemplo
# 60x60@3x = 180 píxeles. Así el script se mantiene sincronizado con Xcode.
ios_dir = project / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for icon in ios_dir.glob('Icon-App-*.png'):
    match = re.search(r'Icon-App-([0-9.]+)x[0-9.]+@([0-9]+)x', icon.name)
    if not match:
        raise ValueError(f'No se pudo obtener el tamaño de {icon.name}')
    save_icon(icon, round(float(match.group(1)) * int(match.group(2))))

save_icon(project / 'web/favicon.png', 32)
for size in (192, 512):
    save_icon(project / f'web/icons/Icon-{size}.png', size)
    save_icon(project / f'web/icons/Icon-maskable-{size}.png', size)
PYTHON

echo "Iconos de plataforma sincronizados desde design/mobile/logo.png"
