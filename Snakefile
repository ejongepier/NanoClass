import re
import os
import yaml
from typing import List
from pathlib import Path
import pandas as pd
from snakemake.utils import min_version, validate

min_version("5.1.0")
report: "report/workflow.rst"

# ======================================================
# Config files
# ======================================================

configfile: "config.yaml"
validate(config, "schemas/config.schema.yaml")

smpls = pd.read_csv(config["samples"]).set_index(["run", "sample"], drop=False)
validate(smpls, "schemas/samples.schema.yaml")

wildcard_constraints:
    sample = '\w+',
    run = '\w+'

# ======================================================
# Rules
# ======================================================

optrules = [] 
optrules.extend(["plots/precision.pdf"] if len(config["methods"]) > 2 else [])

rule all:
    input:
        expand("classifications/{samples.run}/{method}/{samples.sample}.{method}.taxmat",
            samples=smpls.itertuples(), method=config["methods"]
        ),
        expand("plots/{samples.run}/nanofilt/{samples.sample}.filtered.pdf",
            samples=smpls.itertuples(), method=config["methods"]
        ),
        expand("stats/{samples.run}/nanofilt/{samples.sample}.filtered.txt",
            samples=smpls.itertuples(), method=config["methods"]
        ),
        "plots/Genus.pdf",
        "plots/runtime.pdf",
        optrules

# ======================================================
# Functions and Classes
# ======================================================

#for samples in smpls.itertuples():
#    file = Path('data/{samples.run}/basecalled/{samples.sample}.passed.fastq.gz'.format(samples=samples))
#    try:
#        abs_path = file.resolve(strict=True)
#    except FileNotFoundError:
#        print('There is no file called "{file}".'.format(file = file))
#        if not os.path.exists('data/{samples.run}/basecalled/'.format(samples=samples)):
#            os.makedirs('data/{samples.run}/basecalled/'.format(samples=samples))
#            print('Created directory "data/{samples.run}/basecalled/".'.format(samples=samples))
#        print('Please copy your basecalled fastq files into the "data/{samples.run}/basecalled/" directory.'.format(samples=samples))
#        print('Make sure it is named "{samples.sample}.passed.fastq" (or "{samples.sample}.passed.fastq.gz" if zipped)"'.format(samples=samples))

#def plot-precision():
#    if len(config[method]) > 2:
#        return

onsuccess:
    print("NanoClass finished!")
    print("Tho generate a report run: snakemake --report report/NanoClass.zip")


onerror:
    print("Note the path to the log file for debugging.")
    print("Documentation is available at: https://nanoclass.readthedocs.io")
    print("Issues can be raised at: https://github.com/ejongepier/NanoClass/issues")


# ======================================================
# Global variables
# ======================================================

#======================================================
# Include
#======================================================

include: "rules/preprocess.smk"
include: "rules/common.smk"
include: "rules/blastn.smk"
include: "rules/centrifuge.smk"
include: "rules/idtaxa.smk"
include: "rules/kraken.smk"
include: "rules/mapseq.smk"
include: "rules/megablast.smk"
include: "rules/minimap.smk"
include: "rules/mothur.smk"
include: "rules/qiime.smk"
include: "rules/rdp.smk"
include: "rules/spingo.smk"
