"""App 1: load the YAML example data with the generated Python classes."""
import sys

from linkml_runtime.loaders import yaml_loader
from konferanseprogram_model import KonferanseprogramContainer

program = yaml_loader.load(sys.argv[1], target_class=KonferanseprogramContainer)

speakers = {str(h.id): h.navn for h in program.foredragsholdere}
conferences = {str(k.id): k.tittel for k in program.konferansar}

for talk in program.foredragsliste:
    who = ", ".join(speakers[str(s)] for s in talk.har_foredragsholder)
    where = conferences[str(talk.del_av_konferanse)]
    print(f"{talk.tittel} ({talk.varighet} min) - {who} @ {where}")
