"""One app, three data formats: read the same program from YAML, JSON and RDF."""
import sys

from linkml_runtime.dumpers import json_dumper, rdflib_dumper
from linkml_runtime.loaders import json_loader, rdflib_loader, yaml_loader
from linkml_runtime.utils.schemaview import SchemaView
from konferanseprogram_model import KonferanseprogramContainer

schema = SchemaView(sys.argv[2])        # the LinkML model: maps slots to dct:title etc.


def show(program):
    speakers = {str(h.id): h.navn for h in program.foredragsholdere}
    conferences = {str(k.id): k.tittel for k in program.konferansar}
    for talk in program.foredragsliste:
        who = ", ".join(speakers[str(s)] for s in talk.har_foredragsholder)
        where = conferences[str(talk.del_av_konferanse)]
        print(f"{talk.tittel} ({talk.varighet} min) - {who} @ {where}")


# YAML: the example data as written
yaml_program = yaml_loader.load(sys.argv[1], target_class=KonferanseprogramContainer)
print("yaml_loader load yaml file:")
show(yaml_program)

# JSON: write the data as JSON and read it back with the same generated classes
print("json_dumper write json file:")
json_dumper.dump(yaml_program, "konferanseprogram.json")
print("json_loader load json file:")
show(json_loader.load("konferanseprogram.json", target_class=KonferanseprogramContainer))

# RDF: write the data as Turtle and read it back with the same generated classes
print("rdflib_loader write turtle file:")
rdflib_dumper.dump(yaml_program, "konferanseprogram.ttl", schemaview=schema)
print("rdflib_loader load turtle file:")
show(rdflib_loader.load("konferanseprogram.ttl", target_class=KonferanseprogramContainer, schemaview=schema))
