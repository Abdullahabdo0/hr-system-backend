import sys
import os

# Add the root directory to the python path so it can import from main
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app
