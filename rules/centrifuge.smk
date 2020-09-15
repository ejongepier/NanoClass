rule centrifuge_download_taxonomy:
    output:
        name_table = "db/centrifuge/taxonomy/names.dmp",
        tax_tree = "db/centrifuge/taxonomy/nodes.dmp",
    threads: 1
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["centrifuge"]["dbmemory"]
    singularity:
        config["container"]
    log:
        "logs/centrifuge_download_taxonomy.log"
    benchmark:
        "benchmarks/centrifuge_download_taxonomy.txt"
    shell:
        """
        centrifuge-download -o db/centrifuge/taxonomy taxonomy 2> {log}
        """


rule centrifuge_download_db:
    output:
        ref_seqs = "db/centrifuge/data/SILVA_132_SSURef_Nr99_tax_silva.rna.fasta",
        taxmap = "db/centrifuge/data/taxmap_embl_ssu_ref_nr99_132.txt"
    threads:
        1
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["centrifuge"]["dbmemory"]
    params:
        seq_url = config["centrifuge"]["sequrl"],
        taxmap_url = config["centrifuge"]["taxmapurl"]
    singularity:
        config["container"]
    log:
        "logs/centrifuge_download_db.log"
    benchmark:
        "benchmarks/centrifuge_download_db.txt"
    shell:
        """
        wget {params.seq_url} -O - | gzip -d -c - > {output.ref_seqs} 2> {log}
        wget {params.taxmap_url} -O - | gzip -d -c - > {output.taxmap} 2>> {log} 
        """


rule centrifuge_rna_to_dna:
    input:
        "db/centrifuge/data/SILVA_132_SSURef_Nr99_tax_silva.rna.fasta"
    output:
        "db/centrifuge/data/SILVA_132_SSURef_Nr99_tax_silva.fasta"
    threads: 1
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["centrifuge"]["dbmemory"]
    params:
        old_base = "U",
        new_base = "T",
#    singularity:
#        config["container"]
    log:
        "logs/centrifuge_rna_to_dna.log"
    benchmark:
        "benchmarks/centrifuge_rna_to_dna.txt"
    wrapper:
        "0.65.0/bio/pyfastaq/replace_bases"


rule centrifuge_convert:
    input:
        taxmap = rules.centrifuge_download_db.output.taxmap,
    output:
        map = "db/centrifuge/seqid2taxid.map",
    threads: 1
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["centrifuge"]["dbmemory"]
    singularity:
        config["container"]
    log:
        "logs/centrifuge_convert.log"
    benchmark:
        "benchmarks/centrifuge_convert.txt"
    shell:
        """
        awk '{{print $1\".\"$2\".\"$3\"\t\"$(NF)}}' {input.taxmap} > {output.map} 2> {log}
        """


rule centrifuge_build_db:
    input:
        name_table = rules.centrifuge_download_taxonomy.output.name_table,
        tax_tree = rules.centrifuge_download_taxonomy.output.tax_tree, 
        map = rules.centrifuge_convert.output.map,
        ref_seqs = "db/centrifuge/data/SILVA_132_SSURef_Nr99_tax_silva.fasta"
    output:
        touch("db/centrifuge/CENTRIFUGE_DB_BUILD")
    threads:
        config["centrifuge"]["dbthreads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["centrifuge"]["dbmemory"]
    params:
        prefix = "db/centrifuge/silva_16s"
    singularity:
        config["container"]
    log:
        "logs/centrifuge_build_db.log"
    benchmark:
        "benchmarks/centrifuge_build_db.txt"
    shell:
        """
        centrifuge-build \
          --threads {threads} \
          --conversion-table {input.map} \
          --taxonomy-tree {input.tax_tree} \
          --name-table {input.name_table} \
          {input.ref_seqs} \
          {params.prefix} 2> {log}
        """


rule centrifuge_classify:
    input:
        rules.centrifuge_build_db.output,
        fastq = "data/{run}/nanofilt/{sample}.subsampled.fastq.gz",
        ref_seqs = "db/centrifuge/data/SILVA_132_SSURef_Nr99_tax_silva.fasta"
    output:
        report = temp("classifications/{run}/centrifuge/{sample}.report.tsv"),
        classification = "classifications/{run}/centrifuge/{sample}.centrifuge.out",
    threads:
        config["centrifuge"]["threads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["centrifuge"]["memory"]
    params:
        index_prefix = "db/centrifuge/silva_16s"
    singularity:
        config["container"]
    log:
        "logs/centrifuge_classify_{run}_{sample}.log"
    benchmark:
        "benchmarks/centrifuge_classify_{run}_{sample}.txt"
    shell:
        """
        centrifuge -x {params.index_prefix} \
          -U {input.fastq} \
          --threads {threads} \
          --report-file {output.report} \
          -S  {output.classification} \
          --met-stderr 2> {log}
        """


rule centrifuge_tomat:
    input:
        out = "classifications/{run}/centrifuge/{sample}.centrifuge.out",
        ref_seqs = "db/centrifuge/data/SILVA_132_SSURef_Nr99_tax_silva.fasta"
    output:
        taxlist = "classifications/{run}/centrifuge/{sample}.centrifuge.taxlist",
        taxmat = "classifications/{run}/centrifuge/{sample}.centrifuge.taxmat",
        otumat = "classifications/{run}/centrifuge/{sample}.centrifuge.otumat"
    threads: 1
    singularity:
        config["container"]
    log:
        "logs/centrifuge_tomat_{run}_{sample}.log"
    benchmark:
        "benchmarks/centrifuge_tomat_{run}_{sample}.txt"
    shell:
        """
        scripts/tomat.py -c {input.out} -f {input.ref_seqs}
        """

