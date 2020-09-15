rule minimap_download_db:
    output:
        ref_tax = "db/minimap/ref-taxonomy.txt",
        ref_seqs = "db/minimap/ref-seqs.fna"
    threads: 1
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["minimap"]["dbmemory"]
    params:
        url = config["minimap"]["url"]
    singularity:
        config["container"]
    log:
        "logs/minimap_download_db.log"
    benchmark:
        "benchmarks/minimap_download_db.txt"
    shell:
        """
        wget -O db/minimap/db.zip {params.url}
        unzip -p -j db/minimap/db.zip \
            */taxonomy/16S_only/99/majority_taxonomy_7_levels.txt \
            > {output.ref_tax}
        unzip -p -j db/minimap/db.zip \
            */rep_set/rep_set_16S_only/99/silva_132_99_16S.fna \
            > {output.ref_seqs}
        rm db/minimap/db.zip
        """


rule minimap_classify:
    input:
        target = rules.minimap_download_db.output.ref_seqs,
        query = "data/{run}/nanofilt/{sample}.subsampled.fastq.gz"
    output:
        "classifications/{run}/minimap/{sample}.minimap.bam"
    threads: 
        config["minimap"]["threads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["minimap"]["memory"]
    singularity:
        config["container"]
    params:
        extra = "-K 25M --no-kalloc --print-qname -aLx map-ont"
    log:
        "logs/minimap_classify_{run}_{sample}.log"
    benchmark:
        "benchmarks/minimap_classify_{run}_{sample}.txt"
    shell:
        """
        minimap2 {params.extra} -t {threads} {input.target} {input.query} | \
            samtools sort -@{threads} -o {output} - 2> {log}
        """


rule minimap_bam2out:
    input:
        "classifications/{run}/minimap/{sample}.minimap.bam"
    output:
        "classifications/{run}/minimap/{sample}.minimap.out"
    singularity:
        config["container"]
    threads: 1
    params:
       "-F 2308"
    log:
        "logs/minimap_bam2out_{run}_{sample}.log"
    benchmark:
        "benchmarks/minimap_bam2out_{run}_{sample}.txt"
    shell:
        """
        samtools view {params} {input} | \
        cut -f 1,3 > {output}
        """


rule minimap_tomat:
    input:
        out = "classifications/{run}/minimap/{sample}.minimap.out",
        db = "db/minimap/ref-taxonomy.txt"
    output:
        taxlist = "classifications/{run}/minimap/{sample}.minimap.taxlist",
        taxmat = "classifications/{run}/minimap/{sample}.minimap.taxmat",
        otumat = "classifications/{run}/minimap/{sample}.minimap.otumat"
    singularity:
        config["container"]
    threads: 1
    log:
        "logs/minimap_tomat_{run}_{sample}.log"
    benchmark:
        "benchmarks/minimap_tomat_{run}_{sample}.txt"
    shell:
        """
        scripts/tomat.py -b {input.out} -t {input.db}
        """
