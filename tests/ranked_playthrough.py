"""All seven scenes at all six bounded difficulty ranks, using normal input."""
from playthrough import run
from cpu import ROOT
import json
reports=[run(a,rank) for rank in range(6) for a in range(7)]
(ROOT/'build/ranked-playthrough.json').write_text(json.dumps(reports,indent=2))
(ROOT/'build/playthrough.json').write_text(json.dumps(reports[:7],indent=2))
assert all(r['result']=='clear' and r['fault']==0 for r in reports)
