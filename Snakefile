import re
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

# ======================================================
# Rules
# ======================================================

wildcard_constraints:
    sample = '\w+',
    run = '\w+'

rule all:
    input:
        expand("classifications/{samples.run}/{method}/{samples.sample}.{method}.taxmat",
            samples=smpls.itertuples(), method=config["methods"]
        ),
        expand("plots/Genus.pdf"),
        expand("plots/accuracy.pdf"),
        expand("plots/runtime.pdf")

# ======================================================
# Functions and Classes
# ======================================================

# ======================================================
# Global variables
# ======================================================

#======================================================
# Include
#======================================================

include: "rules/porechop.smk"
include: "rules/nanofilt.smk"
include: "rules/reports.smk"
include: "rules/db.smk"
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
include: "rules/plot.smk"
