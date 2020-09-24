rule common_download_db:
    output:
        ref_tax = "db/common/ref-taxonomy.txt",
        ref_seqs = "db/common/ref-seqs.fna",
        ref_aln = "db/common/ref-seqs.aln"
    threads: 1
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["common"]["dbmemory"]
    params:
        url = config["common"]["dburl"],
        ssu = config["common"]["ssu"]
    log:
        "logs/common_download_db.log"
    benchmark:
        "benchmarks/common_download_db.txt"
    shell:
        """
        wget -q -O db/common/db.zip {params.url}
        unzip -q -p -j db/common/db.zip \
            */taxonomy/{params.ssu}_only/99/majority_taxonomy_7_levels.txt \
            > {output.ref_tax} 2> {log}
        unzip -q -p -j db/common/db.zip \
            */rep_set/rep_set_{params.ssu}_only/99/silva_*_99_{params.ssu}.fna \
            > {output.ref_seqs} 2>> {log}
        unzip -q -p -j db/common/db.zip \
            */rep_set_aligned/99/99_alignment.fna.zip | gzip -d \
            > {output.ref_aln} 2>> {log}
        rm db/common/db.zip 2>> {log}
        """

rule common_plot_tax:
    input:
        expand("classifications/{smpls.run}/{method}/{smpls.sample}.{method}.taxmat",
            method = config["methods"], smpls =  smpls.itertuples()
        )
    output:
        report("plots/Phylum.pdf", caption="../report/fig-phylum.rst", category="Classification"),
        report("plots/Class.pdf", caption="../report/fig-class.rst", category="Classification"),
        report("plots/Order.pdf", caption="../report/fig-order.rst", category="Classification"),
        report("plots/Family.pdf", caption="../report/fig-family.rst", category="Classification"),
        report("plots/Genus.pdf", caption="../report/fig-genus.rst", category="Classification")
    threads: 1
    log:
        "logs/common_plot_tax.log"
    benchmark:
        "benchmarks/common_plot_tax.txt"
    conda:
        config["common"]["environment"]
    #singularity:
    #    config["common"]["container1"]
    shell:
        """
        mkdir -p ./plots
        Rscript scripts/barplot.R {input} 2> {log}
        """

rule common_get_precision:
    input:
        expand("classifications/{smpls.run}/{method}/{smpls.sample}.{method}.taxlist",
            method = config["methods"], smpls =  smpls.itertuples()
        )
    output:
        expand("classifications/{smpls.run}/{method}/{smpls.sample}.{method}.precision",
            method = config["methods"], smpls =  smpls.itertuples()
        )
    threads: 1
    log:
        "logs/common_get_precision.log"
    benchmark:
        "benchmarks/common_get_precision.txt"
    shell:
        "scripts/toconsensus.py -l {input} 2> {log}"


rule common_plot_precision:
    input:
        expand("classifications/{smpls.run}/{method}/{smpls.sample}.{method}.precision",
            method = config["methods"], smpls =  smpls.itertuples()
        )
    output:
        report("plots/precision.pdf", caption="../report/fig-precision.rst", category="Precision")
    threads: 1
    log:
        "logs/common_plot_precision.log"
    benchmark:
        "benchmarks/common_plot_precision.txt"
    conda:
        config["common"]["environment"]
    #singularity:
    #    config["common"]["container1"]
    shell:
        """
        mkdir -p ./plots
        Rscript scripts/lineplot.R {input} 2> {log}
        """


rule common_plot_runtime:
    input:
        expand("benchmarks/{method}_classify_{smpls.run}_{smpls.sample}.txt",
            method = config["methods"], smpls =  smpls.itertuples()
        )
    output:
        report("plots/runtime.pdf", caption="../report/fig-runtime.rst", category="Runtime"),
        report("plots/runtime_log.pdf", caption="../report/fig-runtime-log.rst", category="Runtime")
    threads: 1
    log:
        "logs/common_plot_runtime.log"
    benchmark:
        "benchmarks/common_plot_runtime.txt"
    conda:
        config["common"]["environment"]
    #singularity:
    #    config["common"]["container1"]
    shell:
        """
        mkdir -p ./plots
        Rscript scripts/timeplot.R {input} 2> {log}
        """
