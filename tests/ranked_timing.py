"""Compatibility entry point for representative hardware rank checks."""
import sys,runpy
from pathlib import Path
if len(sys.argv)<2:sys.argv.append('ntsc')
if len(sys.argv)<3:sys.argv.append('0:3,1:3,3:3,4:2,5:2,5:3')
runpy.run_path(str(Path(__file__).with_name('mechanics_hardware.py')),run_name='__main__')
