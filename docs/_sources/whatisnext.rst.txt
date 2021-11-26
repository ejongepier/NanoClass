##===================================================
## optional: filtering
##===================================================

## Many filtering options, see: https://docs.qiime2.org/2020.2/tutorials/filtering/
## As an example: retain only cyanobacteria excluding chloroplasts

qiime taxa filter-table \
  --i-table dada2/dada2-table.qza \
  --i-taxonomy taxonomy/dada2-$DBPREFIX-taxonomy.qza \
  --p-include cyanobacteria \
  --p-exclude chloroplast \
  --o-filtered-table dada2/dada2-table-filtered.qza

qiime taxa filter-seqs \
  --i-sequences dada2/dada2-reprseqs.qza \
  --i-taxonomy taxonomy/dada2-$DBPREFIX-taxonomy.qza \
  --p-include cyanobacteria \
  --p-exclude chloroplast \
  --o-filtered-sequences dada2/dada2-reprseqs-filtered.qza

qiime taxa barplot \
  --i-table dada2/dada2-table-filtered.qza \
  --i-taxonomy taxonomy/dada2-$DBPREFIX-taxonomy.qza \
  --m-metadata-file $META \
  --o-visualization taxonomy/dada2-$DBPREFIX-taxplot-filtered.qzv



##===================================================
## optional: exporting
##===================================================

## You can continue your analyses in qiime2, or swich to e.g. R
## To go to a different platform you can export the data and extract it form the qza zip archives

## export representative sequences
qiime tools export \
  --input-path dada2/dada2-reprseqs.qza \
  --output-path exports

mv exports/dna-sequences.fasta exports/dada2-reprseqs.fa && gzip exports/dada2-reprseqs.fa

## export abundance table
qiime tools export \
  --input-path dada2/dada2-table.qza \
  --output-path exports

biom convert --to-tsv \
  --input-fp exports/feature-table.biom \
  --output-fp exports/dada2-table.tsv

rm exports/feature-table.biom

## export taxonomy
qiime tools export \
  --input-path taxonomy/dada2-$DBPREFIX-taxonomy.qza \
  --output-path exports

mv exports/taxonomy.tsv exports/dada2-$DBPREFIX-taxonomy.tsv

## Or you can directly read the qiime2 qzv's directly into R using qiimer package
## https://github.com/jbisanz/qiime2R



