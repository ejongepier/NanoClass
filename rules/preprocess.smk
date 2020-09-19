rule prep_porechop:
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
    log:
        "logs/prep_porechop_{run}_{sample}.log"
    benchmark:
        "benchmarks/prep_porechop_{run}_{sample}.txt"
    shell:
        """
        porechop --input {input} \
          --output {output} \
          --threads {threads} \
          --check_reads {params.check_reads} \
          --discard_middle \
          --format "fastq.gz" 2> {log}
        """

rule prep_nanofilt:
    input:
        "data/{run}/porechopped/{sample}.trimmed.fastq.gz"
    output:
        "data/{run}/nanofilt/{sample}.filtered.fastq.gz"
    threads: 1
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["nanofilt"]["memory"]
    priority: 50
    params:
        min_len = config["nanofilt"]["minlen"],
        max_len = config["nanofilt"]["maxlen"],
    log:
        "logs/prep_nanofilt_{run}_{sample}.log"
    benchmark:
        "benchmarks/prep_nanofilt_{run}_{sample}.txt"
    singularity:
        config["container"]
    shell:
        """
        gzip -d -c {input} | \
        NanoFilt --length {params.min_len} --maxlength {params.max_len} | \
        gzip > {output} 2> {log}
        """

rule prep_subsample:
    input:
        "data/{run}/nanofilt/{sample}.filtered.fastq.gz"
    output:
        "data/{run}/nanofilt/{sample}.subsampled.fastq.gz"
    threads: 1
    priority: 50
    params:
        config["subsample"]["samplesize"]
    log:
        "logs/prep_subsample_{run}_{sample}.log"
    benchmark:
        "benchmarks/prep_subsample_{run}_{sample}.txt"
    singularity:
        config["container"]
    shell:
        """
        seqtk sample {input} {params} | gzip -c > {output}
        """

rule prep_fasta_query:
    input:
        "data/{run}/nanofilt/{sample}.subsampled.fastq.gz"
    output:
        "data/{run}/nanofilt/{sample}.subsampled.fasta"
    threads: 1
    priority: 50
    singularity:
        config["container"]
    shell:
        """
        zcat {input} | sed -n '1~4s/^@/>/p;2~4p' > {output}
        """

rule prep_nanofilt_plot:
    input:
        "data/{run}/nanofilt/{sample}.filtered.fastq.gz"
    output:
        report("plots/{run}/nanofilt/{sample}.filtered.pdf", caption="../report/fig-nanofilt.rst", category="Read-processing")
    log:
        "logs/prep_nanofilt_plot_{run}_{sample}.log"
    benchmark:
        "benchmarks/prep_nanofilt_plot_{run}_{sample}.txt"
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


rule prep_nanofilt_stats:
    input:
        "data/{run}/nanofilt/{sample}.filtered.fastq.gz"
    output:
        "stats/{run}/nanofilt/{sample}.filtered.txt"
    log:
        "logs/prep_nanofilt_stats_{run}_{sample}.log"
    benchmark:
        "benchmarks/prep_nanofilt_stats_{run}_{sample}.log"
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


