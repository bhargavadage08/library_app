import os
import sys

# Ensure the 'app' directory is in sys.path so submodules (core, models, routes, schemas, services, utils)
# can be imported directly without ModuleNotFoundError
_app_dir = os.path.dirname(os.path.abspath(__file__))
if _app_dir not in sys.path:
    sys.path.insert(0, _app_dir)

from .main import app

__all__ = ["app"]
