rule qiime_download_db:
    output:
        ref_tax = "db/qiime/ref-taxonomy.txt",
        ref_seqs = "db/qiime/ref-seqs.fna"
    threads: 1
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["qiime"]["dbmemory"]
    params:
        url = config["qiime"]["url"]
    singularity:
        config["container"]
    log:
        "logs/qiime_download_db.log"
    benchmark:
        "benchmarks/qiime_download_db.txt"
    shell:
        """
        mkdir -p db/qiime/
        wget -O db/qiime/db.zip {params.url}
        unzip -p -j db/qiime/db.zip \
            */taxonomy/16S_only/99/majority_taxonomy_7_levels.txt \
            > {output.ref_tax}
        unzip -p -j db/qiime/db.zip \
            */rep_set/rep_set_16S_only/99/silva_132_99_16S.fna \
            > {output.ref_seqs}
        rm db/qiime/db.zip
        """

rule qiime_import_query:
    input:
        fasta = rules.prep_fasta_query.output
    output:
        "classifications/{run}/qiime/{sample}.seqs.qza"
    threads:
        1
    singularity:
        config["qiime"]["container"]
    log:
        "logs/qiime_import_query_{run}_{sample}.log"
    benchmark:
        "benchmarks/qiime_import_query_{run}_{sample}.txt"
    shell:
        """
        qiime tools import \
            --type 'FeatureData[Sequence]' \
            --input-path {input.fasta} \
            --output-path {output} \
            2>&1 | tee -a {log}
        """

rule qiime_import_refseq:
    input:
        "db/qiime/ref-seqs.fna"
    output:
        "db/qiime/ref-seqs.qza"
    threads: 1
    singularity:
        config["qiime"]["container"]
    log:
        "logs/qiime_import_refseq.log"
    benchmark:
        "benchmarks/qiime_import_refseq.txt"
    shell:
        """
        qiime tools import \
            --type 'FeatureData[Sequence]' \
            --input-path {input} \
            --output-path {output} \
            2>&1 | tee -a {log}
        """

rule qiime_import_taxonomy:
    input:
        "db/qiime/ref-taxonomy.txt"
    output:
        "db/qiime/ref-taxonomy.qza"
    threads: 1
    singularity:
        config["qiime"]["container"]
    log:
        "logs/qiime_import_taxonomy.log"
    benchmark:   
        "benchmarks/qiime_import_taxonomy.txt"
    shell:
        """
        qiime tools import \
            --type FeatureData[Taxonomy] \
            --input-format HeaderlessTSVTaxonomyFormat \
            --input-path {input} \
            --output-path {output} \
            2>&1 | tee -a {log}
        """

rule qiime_classify:
    input:
        query="classifications/{run}/qiime/{sample}.seqs.qza",
        taxo="db/qiime/ref-taxonomy.qza",
        ref_seqs="db/qiime/ref-seqs.qza"
    output:
        qza = "classifications/{run}/qiime/{sample}.qiime.qza",
        path = temp(directory("classifications/{run}/qiime/{sample}/")),
        out = "classifications/{run}/qiime/{sample}.qiime.out"
    threads:
        config["qiime"]["threads"]
    singularity:
        config["qiime"]["container"]
    log:
        "logs/qiime_classify_{run}_{sample}.log"
    benchmark:
        "benchmarks/qiime_classify_{run}_{sample}.txt"
    shell:
        """
        qiime feature-classifier classify-consensus-vsearch \
            --i-query {input.query} \
            --i-reference-reads {input.ref_seqs} \
            --i-reference-taxonomy {input.taxo} \
            --o-classification {output.qza} \
            --p-threads {threads} \
            --p-top-hits-only \
            2>&1 | tee -a {log}
        qiime tools export \
            --input-path {output.qza} \
            --output-path {output.path}
        mv {output.path}/taxonomy.tsv {output.out}
        """


rule qiime_taxlist:
    input:
        "classifications/{run}/qiime/{sample}.qiime.out",
    output:
        "classifications/{run}/qiime/{sample}.qiime.taxlist"
    threads: 1
    singularity:
        config["container"]
    log:
        "logs/qiime_tomat_{run}_{sample}.log"
    benchmark:
        "benchmarks/qiime_tomat_{run}_{sample}.txt"
    shell:
        """
        cut -f 1,2 {input} | grep -P -v '\\tUnassigned$' | \
        awk -F '\\t|;' -v OFS='\\t' '{{ \
            if (NR == 1)
                print "#readid","Domain","Phylum","Class","Order","Family","Genus";
            else
                 print $1, $2, $3, $4, $5, $6, $7 \
        }}' | sed "s/D_[[:digit:]]__//g" > {output}
        """

rule qiime_tomat:
    input:
        list = "classifications/{run}/qiime/{sample}.qiime.taxlist",
    output:
        taxmat = "classifications/{run}/qiime/{sample}.qiime.taxmat",
        otumat = "classifications/{run}/qiime/{sample}.qiime.otumat"
    threads: 1
    singularity:
        config["container"]
    log:
        "logs/qiime_tomat_{run}_{sample}.log"
    benchmark:
        "benchmarks/qiime_tomat_{run}_{sample}.txt"
    shell:
        """
        scripts/tomat.py -l {input.list}
        """

