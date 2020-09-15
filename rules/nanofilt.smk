rule nanofilt:
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
        "logs/nanofilt_{run}_{sample}.log"
    benchmark:
        "benchmarks/nanofilt_{run}_{sample}.txt"
    singularity:
        config["container"]
    shell:
        """
        gzip -d -c {input} | \
        NanoFilt --length {params.min_len} --maxlength {params.max_len} | \
        gzip > {output} 2> {log}
        """

rule subsample:
    input:
        "data/{run}/nanofilt/{sample}.filtered.fastq.gz"
    output:
        "data/{run}/nanofilt/{sample}.subsampled.fastq.gz"
    threads: 1
    priority: 50
    params:
        config["subsample"]["samplesize"]
    log:
        "logs/subsample_{run}_{sample}.log"
    benchmark:
        "benchmarks/subsample_{run}_{sample}.txt"
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

