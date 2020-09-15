rule plot_post_filtering:
    input:
        "data/{run}/nanofilt/{sample}.filtered.fastq.gz"
    output:
        "plots/{run}/nanofilt/{sample}.filtered.pdf"
    log:
        "logs/plot_post_filtering_{run}_{sample}.log"
    benchmark:
        "benchmarks/plot_post_filtering_{run}_{sample}.txt"
    threads: 1
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["plot"]["memory"]
    params:
        downsample = config["plot"]["downsample"]
    singularity:
        config["container"]
    shell:
        """
        pistis --fastq {input} --output {output} \
          --downsample {params.downsample} 2> {log}
        """


rule stats_post_filtering:
    input:
        "data/{run}/nanofilt/{sample}.filtered.fastq.gz"
    output:
        "stats/{run}/nanofilt/{sample}.filtered.txt"
    log:
        "logs/stats_post_filtering_{run}_{sample}.log"
    benchmark:
        "benchmarks/stats_post_filtering_{run}_{sample}.log"
    threads:
        config["stats"]["threads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["stats"]["memory"]
    singularity:
        config["container"]
    shell:
        """
        NanoStat --fastq {input} --name {output} --threads {threads} 2> {log}
        """
