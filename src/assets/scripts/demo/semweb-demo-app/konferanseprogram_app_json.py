"""App 2: convert the example data to JSON, then read it back as JSON."""
import sys

from linkml_runtime.dumpers import json_dumper
from linkml_runtime.loaders import json_loader, yaml_loader
from konferanseprogram_model import KonferanseprogramContainer

# YAML -> JSON
program = yaml_loader.load(sys.argv[1], target_class=KonferanseprogramContainer)
json_dumper.dump(program, "konferanseprogram.json")
print("Wrote konferanseprogram.json")

# ...and read the JSON file with the same generated classes
program = json_loader.load("konferanseprogram.json", target_class=KonferanseprogramContainer)

speakers = {str(h.id): h.navn for h in program.foredragsholdere}
conferences = {str(k.id): k.tittel for k in program.konferansar}

for talk in program.foredragsliste:
    who = ", ".join(speakers[str(s)] for s in talk.har_foredragsholder)
    where = conferences[str(talk.del_av_konferanse)]
    print(f"{talk.tittel} ({talk.varighet} min) - {who} @ {where}")
