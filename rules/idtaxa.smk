rule idtaxa_download_db:
    output:
        ref_tax = "db/idtaxa/ref-taxonomy.txt",
        ref_seqs = "db/idtaxa/ref-seqs.fna"
    threads: 1
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["idtaxa"]["dbmemory"]
    params:
        url = config["idtaxa"]["url"]
    singularity:
        config["container"]
    log:
        "logs/idtaxa_download_db.log"
    benchmark:
        "benchmarks/idtaxa_download_db.txt"
    shell:
        """
        wget -O db/idtaxa/db.zip {params.url}
        unzip -p -j db/idtaxa/db.zip \
            */taxonomy/16S_only/99/majority_taxonomy_7_levels.txt \
            > {output.ref_tax}
        unzip -p -j db/idtaxa/db.zip \
            */rep_set/rep_set_16S_only/99/silva_132_99_16S.fna \
            > {output.ref_seqs}
        rm db/idtaxa/db.zip
        """

rule idtaxa_learn_taxa:
    input:
        ref_seqs = rules.idtaxa_download_db.output.ref_seqs,
        ref_tax = rules.idtaxa_download_db.output.ref_tax
    output:
        "db/idtaxa/ref-db.Rdata"
    threads: 1
    singularity:
        config["idtaxa"]["container"]
    log:
        "logs/idtaxa_learn_taxa.log"
    benchmark:
        "benchmarks/idtaxa_learn_taxa.txt"
    shell:
        """
        export PATH=/opt/conda/envs/R-4.0-conda-only/bin/:$PATH
        Rscript scripts/learntaxa.R {input.ref_seqs} {input.ref_tax} {output}
        """


rule idtaxa_classify:
    input:
        db = "db/idtaxa/ref-db.Rdata",
        query = rules.prep_fasta_query.output
    output:
        "classifications/{run}/idtaxa/{sample}.idtaxa.taxlist"
    threads:
        config["idtaxa"]["threads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["idtaxa"]["memory"]
    singularity:
        config["idtaxa"]["container"]
    log:
        "logs/idtaxa_classify_{run}_{sample}.log"
    benchmark:
        "benchmarks/idtaxa_classify_{run}_{sample}.txt"
    shell:
        """
        export PATH=/opt/conda/envs/R-4.0-conda-only/bin/:$PATH
        Rscript scripts/idtaxa.R {input.db} {input.query} {output} {threads}
        """

rule idtaxa_tomat:
    input:
        list = "classifications/{run}/idtaxa/{sample}.idtaxa.taxlist",
    output:
        taxmat = "classifications/{run}/idtaxa/{sample}.idtaxa.taxmat",
        otumat = "classifications/{run}/idtaxa/{sample}.idtaxa.otumat"
    threads: 1
    singularity:
        config["container"]
    log:
        "logs/idtaxa_tomat_{run}_{sample}.log"
    benchmark:
        "benchmarks/idtaxa_tomat_{run}_{sample}.txt"
    shell:
        """
        scripts/tomat.py -l {input.list}
        """

