// Don't overwrite global params.modules, create a copy instead and use that within the main script.
def modules = params.modules.clone()

def msa_mafft_options     = modules['msa_mafft']
def msa_nextalign_options = modules['msa_nextalign']
def iqtree_options        = modules['phylogenetic_iqtree']
def pangolin_options      = modules['pangolin']
def alleles_options       = modules['alleles']
def tree_snps_options     = modules['tree_snps']
def reroot_tree_options   = modules['reroot_tree']
def shiptv_tree_options   = modules['shiptv']
def filter_gisaid_options = modules['filters_gisaid']
def filter_msa_options    = modules['filters_msa']
def get_subtree_options   = modules['subtree']
def nextclade_options     = modules['nextclade']

include { PANGOLIN_LINEAGES       } from '../modules/nf-core/software/pangolin/main'   addParams( options: pangolin_options        )
include { NEXTALIGN_MSA           } from '../modules/nf-core/software/nextalign/main'  addParams( options: msa_mafft_options       )
include { CAT_SEQUENCES           } from '../modules/nf-core/software/cat/main'
include { FILTERS_GISAID          } from '../modules/local/filters_gisaid'             addParams( options: filter_gisaid_options   )
include { FILTERS_MSA             } from '../modules/local/filter_msa'                 addParams( options: filter_msa_options      )
include { IQTREE_PHYLOGENETICTREE } from '../modules/nf-core/software/iqtree/main'     addParams( options: iqtree_options          )
include { SHIPTV_VISUALIZATION    } from '../modules/nf-core/software/shiptv/main'     addParams( options: shiptv_tree_options     )
include { FILTERS_SHIPTV_METADATA } from '../modules/local/filter_column_shiptv'       addParams( options: shiptv_tree_options     )
include { PRUNE_DOWN_TREE         } from '../modules/local/prune_down_tree'            addParams( options: get_subtree_options     )
include { SEQUENCES_NEXTCLADE     } from '../modules/local/get_sequences_nextclade'    addParams( options: nextclade_options       )
include { NEXTCLADE               } from '../modules/nf-core/software/nextclade/main'  addParams( options: nextclade_options       )
include { AA_SUBSTITUTION         } from '../modules/local/aa_sub_nextclade'           addParams( options: nextclade_options       )


workflow PHYLOGENETIC_GISAID {

    ch_gisaid_sequences = Channel.fromPath(params.gisaid_sequences)
    ch_gisaid_metadata  = Channel.fromPath(params.gisaid_metadata)
    ch_ref_sequence     = Channel.fromPath(params.reference_fasta)
    ch_consensus_seqs   = Channel.fromPath(params.input)

    PANGOLIN_LINEAGES         (ch_consensus_seqs)
    FILTERS_GISAID            (ch_gisaid_sequences, ch_gisaid_metadata, PANGOLIN_LINEAGES.out.report)
    CAT_SEQUENCES             (FILTERS_GISAID.out.fasta, ch_consensus_seqs, ch_ref_sequence)
    NEXTALIGN_MSA             (CAT_SEQUENCES.out.merged_sequences, ch_ref_sequence)
    FILTERS_MSA               (NEXTALIGN_MSA.out.fasta, PANGOLIN_LINEAGES.out.report, FILTERS_GISAID.out.filtered_metadata)
    IQTREE_PHYLOGENETICTREE   (FILTERS_MSA.out.fasta)
    PRUNE_DOWN_TREE           (IQTREE_PHYLOGENETICTREE.out.treefile, PANGOLIN_LINEAGES.out.report, FILTERS_MSA.out.metadata)
    FILTERS_SHIPTV_METADATA   (PRUNE_DOWN_TREE.out.metadata)
    SHIPTV_VISUALIZATION      (IQTREE_PHYLOGENETICTREE.out.treefile, PRUNE_DOWN_TREE.out.leaflist, FILTERS_SHIPTV_METADATA.out.metadata)
    if (!params.skip_nextclade){
        SEQUENCES_NEXTCLADE       (SHIPTV_VISUALIZATION.out.metadata_tsv, CAT_SEQUENCES.out.merged_sequences)
        NEXTCLADE                 (SEQUENCES_NEXTCLADE.out.fasta, 'csv')
        AA_SUBSTITUTION           (NEXTCLADE.out.csv)
    }


}