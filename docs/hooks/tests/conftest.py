"""Make the hook modules importable without turning docs/hooks into a package."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
