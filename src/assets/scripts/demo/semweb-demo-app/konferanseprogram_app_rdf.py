"""App 3: convert the example data to RDF (Turtle), then read it back as RDF."""
import sys

from linkml_runtime.dumpers import rdflib_dumper
from linkml_runtime.loaders import rdflib_loader, yaml_loader
from linkml_runtime.utils.schemaview import SchemaView
from konferanseprogram_model import KonferanseprogramContainer

schema = SchemaView(sys.argv[2])        # the LinkML model: maps slots to dct:title etc.

# YAML -> RDF
program = yaml_loader.load(sys.argv[1], target_class=KonferanseprogramContainer)
rdflib_dumper.dump(program, "konferanseprogram.ttl", schemaview=schema)
print("Wrote konferanseprogram.ttl")

# ...and read the Turtle file back into the generated classes
program = rdflib_loader.load("konferanseprogram.ttl", target_class=KonferanseprogramContainer, schemaview=schema)

speakers = {str(h.id): h.navn for h in program.foredragsholdere}
conferences = {str(k.id): k.tittel for k in program.konferansar}

for talk in program.foredragsliste:
    who = ", ".join(speakers[str(s)] for s in talk.har_foredragsholder)
    where = conferences[str(talk.del_av_konferanse)]
    print(f"{talk.tittel} ({talk.varighet} min) - {who} @ {where}")
