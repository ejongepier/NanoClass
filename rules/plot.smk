rule tax_plot:
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
        "logs/tax_plot.log"
    benchmark:
        "benchmarks/tax_plot.txt"
    singularity:
        config["plot"]["container"]
    shell:
        """
        mkdir -p ./plots
        export PATH=/opt/conda/envs/R-4.0-conda-only/bin/:$PATH
        Rscript scripts/barplot.R {input}
        """



rule get_accuracy:
    input:
        expand("classifications/{smpls.run}/{method}/{smpls.sample}.{method}.taxlist",
            method = config["methods"], smpls =  smpls.itertuples()
        )
    output:
        expand("classifications/{smpls.run}/{method}/{smpls.sample}.{method}.accuracy",
            method = config["methods"], smpls =  smpls.itertuples()
        )
    threads: 1
    log:
        "logs/get_accuracy.log"
    benchmark:
        "benchmarks/get_accuracy.txt"
    singularity:
        config["plot"]["container"]
    shell:
        """
        scripts/toconsensus.py -l {input}
        """
   

rule accuracy_plot:
    input:
        expand("classifications/{smpls.run}/{method}/{smpls.sample}.{method}.accuracy",
            method = config["methods"], smpls =  smpls.itertuples()
        )
    output:
        report("plots/accuracy.pdf", caption="../report/fig-accuracy.rst", category="Accuracy")
    threads: 1
    log:
        "logs/accuracy_plot.log"
    benchmark:
        "benchmarks/accuracy_plot.txt"
    singularity:
        config["plot"]["container"]
    shell:
        """
        mkdir -p ./plots
        export PATH=/opt/conda/envs/R-4.0-conda-only/bin/:$PATH
        Rscript scripts/lineplot.R {input}
        """



rule runtime_plot:
    input:
        expand("benchmarks/{method}_classify_{smpls.run}_{smpls.sample}.txt",
            method = config["methods"], smpls =  smpls.itertuples()
        )
    output:
        report("plots/runtime.pdf", caption="../report/fig-runtime.rst", category="Runtime"),
        report("plots/runtime_log.pdf", caption="../report/fig-runtime-log.rst", category="Runtime")
    threads: 1
    log:
        "logs/runtime_plot.log"
    benchmark:
        "benchmarks/runtime_plot.txt"
    singularity:
        config["plot"]["container"]
    shell:
        """
        mkdir -p ./plots
        export PATH=/opt/conda/envs/R-4.0-conda-only/bin/:$PATH
        Rscript scripts/timeplot.R {input}
        """

