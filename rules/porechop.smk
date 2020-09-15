rule porechop:
    input:
        "data/{run}/basecalled/{sample}.passed.fastq.gz"
    output:
        "data/{run}/porechopped/{sample}.trimmed.fastq.gz"
    threads:
        config["porechop"]["threads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["porechop"]["memory"]
    priority: 50
    singularity:
        config["container"]
    params:
        check_reads = config["porechop"]["checkreads"]
#    wildcard_constraints:
#        sample = '\w+',
#        run = '\w+'
    log:
        "logs/porechop_{run}_{sample}.log"
    benchmark:
        "benchmarks/porechop_{run}_{sample}.txt"
    shell:
        """
        porechop --input {input} \
          --output {output} \
          --threads {threads} \
          --check_reads {params.check_reads} \
          --discard_middle \
          --format "fastq.gz" 2> {log}
        """

