/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
//include { PBMM2_INDEX                        } from '../modules/local/pbmm2/index'
include { SAMTOOLS_MERGE                         } from '../modules/nf-core/samtools/merge/main'
include { PBMM2_ALIGN                            } from '../modules/nf-core/pbmm2/align'
include { SAMTOOLS_FAIDX                         } from '../modules/nf-core/samtools/faidx/main'
include { SAMTOOLS_INDEX as SAMTOOLS_BAI         } from '../modules/nf-core/samtools/index/main'
include { SAMTOOLS_INDEX as SAMTOOLS_CSI         } from '../modules/nf-core/samtools/index/main'
include { SAMTOOLS_REHEADER as BAMSAMPLERENAME   } from '../modules/nf-core/samtools/reheader/main'
include { DELLY_LR                               } from '../modules/local/delly/lr'
include { DELLY_FILTER                           } from '../modules/local/delly/filter'
include { SNIFFLES as SNIFFLES_MOSAIC            } from '../modules/nf-core/sniffles/main'
include { SNIFFLES as SNIFFLES_MOSAIC_VCF        } from '../modules/nf-core/sniffles/main'
include { NANOMONSV_PARSE                        } from '../modules/nf-core/nanomonsv/parse/main'
include { NANOMONSV_GET                          } from '../modules/local/nanomonsv/get/main'
include { SEVERUS                                } from '../modules/nf-core/severus/main'
include { SAVANA                                 } from '../modules/local/savana/main'
include { SVISIONPRO                             } from '../modules/local/svisionpro/main'
include { MULTIQC                                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap                       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc                   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML                 } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText                 } from '../subworkflows/local/utils_nfcore_somaticsvcalling_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SOMATICSVCALLING {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    ch_fasta_ref
    ch_tandem_repeats_bed
    ch_vntr_bed
    ch_access_bed
    ch_svisionpro_model
    

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    // merge bam files from the same sample
    // group channel based on same entries for sample and status
    ch_samplesheet
        .map { meta, bam -> [ [meta.id, meta.status], [meta, bam] ] }
        .groupTuple()
        .map { id, samples ->
            def meta         = samples.collect{ it[0] }[0]
            def bams         = samples.collect{ it[1] }[0]
            [ meta, bams ]
        }
        .set {ch_samplesheet_merge}

    SAMTOOLS_MERGE (
        ch_samplesheet_merge,
        [ null, [] ],
        [ null, [] ],
        [ null, [] ]
    )

    //
    // MODULE: Run pbmm2 alignment
    //
    // optional for future: indexing
    //PBMM2_INDEX (
    //    ch_fasta_ref
    //)
    //ch_versions = ch_versions.mix(PBMM2_INDEX.out.versions)

    // index reference genome
    SAMTOOLS_FAIDX (
        ch_fasta_ref
    )
    ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions)

    //rename BAM input
    BAMSAMPLERENAME (
        SAMTOOLS_MERGE.out.bam
    )
    ch_versions = ch_versions.mix(BAMSAMPLERENAME.out.versions)

    PBMM2_ALIGN (
        BAMSAMPLERENAME.out.bam,
        ch_fasta_ref,
    )
    ch_versions = ch_versions.mix(PBMM2_ALIGN.out.versions)
    ch_aligned_bam = PBMM2_ALIGN.out.bam

    // indexing for downstream processes
    SAMTOOLS_BAI (
        ch_aligned_bam
    )
    SAMTOOLS_CSI (
        ch_aligned_bam
    )
    ch_versions = ch_versions.mix(SAMTOOLS_CSI.out.versions)

    //channel with bam and CSI index (SEVERUS, DELLY, SAVANA)
    ch_bam_csi = ch_aligned_bam
        .join(SAMTOOLS_CSI.out.csi)
    
    ch_bam_csi
        .map { meta, bam, index -> [ meta.id, [meta, bam, index] ] }
        .groupTuple() // group by first item, meta.id
        .map { id, samples ->
            def metas        = samples.collect{ it[0] }
            def merged_meta  = [ id: metas.id[0] ]
            def bams         = samples.collect{ it[1] }
            def index        = samples.collect{ it[2] }
            [ merged_meta, bams, index]
        }
        .set {ch_bams_csi_tumornormal}

    //channel with bam and BAI index (SVISIONPRO)
    ch_bam_bai = ch_aligned_bam
        .join(SAMTOOLS_BAI.out.bai)
    
    ch_bam_bai
        .map { meta, bam, index -> [ meta.id, [meta, bam, index] ] }
        .groupTuple() // group by first item, meta.id
        .map { id, samples ->
            def metas        = samples.collect{ it[0] }
            def merged_meta  = [ id: metas.id[0] ]
            def bams         = samples.collect{ it[1] }
            def index        = samples.collect{ it[2] }
            [ merged_meta, bams, index]
        }
        .set {ch_bams_bai_tumornormal}

    // put reference together with fai file for staging.
    ch_fasta_fai = ch_fasta_ref
        .map { meta, fasta -> [meta, fasta, SAMTOOLS_FAIDX.out.fai] }

    if (params.delly) {
        ch_bams_csi_tumornormal
            .map { meta, bams, index -> [ meta, bams, index, [], [], [] ]}
            .set {ch_delly_input}

        // run delly
        DELLY_LR (
            ch_delly_input,
            ch_fasta_fai
        )
        ch_multiqc_files = ch_multiqc_files.mix(DELLY_LR.out.bcf.collect{it[1]})
        ch_versions = ch_versions.mix(DELLY_LR.out.versions)

        ch_delly_filter_input = DELLY_LR.out.bcf
            .join(DELLY_LR.out.csi)
    
        //run delly filter
        DELLY_FILTER(ch_delly_filter_input)
        ch_multiqc_files = ch_multiqc_files.mix(DELLY_FILTER.out.bcf.collect{it[1]})
        ch_versions = ch_versions.mix(DELLY_FILTER.out.versions)
    }

    if (params.sniffles) {
        // RUN sniffles
        //call candidate SVs in VCF and SNF format
        SNIFFLES_MOSAIC(
            ch_bam_csi,
            ch_fasta_ref,
            ch_tandem_repeats_bed
        )
        ch_versions = ch_versions.mix(SNIFFLES_MOSAIC.out.versions)

        //merge tumor-normal SNF files for multi-sample calling
        SNIFFLES_MOSAIC.out.snf
            .map { meta, snf -> [ meta.id, [meta, snf] ] }
            .groupTuple() // group by first item, meta.id
            .map { id, samples ->
                def metas  = samples.collect{ it[0] }
                def merged_meta = [ id: metas.id[0], status:"" ]
                def snfs   = samples.collect{ it[1] }
                [ merged_meta, snfs, [] ]
            }
            .set {ch_snfs_tumornormal}

        // multi-sample calling
        SNIFFLES_MOSAIC_VCF(
            ch_snfs_tumornormal,
            ch_fasta_ref,
            ch_tandem_repeats_bed
        )
        ch_multiqc_files = ch_multiqc_files.mix(SNIFFLES_MOSAIC_VCF.out.vcf.collect{it[1]})
        ch_versions = ch_versions.mix(SNIFFLES_MOSAIC_VCF.out.versions)
    }

    if (params.nanomonsv) {
        NANOMONSV_PARSE(
            ch_bam_csi,
            ch_fasta_ref
        )
        ch_versions = ch_versions.mix(NANOMONSV_PARSE.out.versions)

        //merge tumor-normal output files for multi-sample calling
        NANOMONSV_PARSE.out.svs
            .join(NANOMONSV_PARSE.out.tbis)
            .join(ch_bam_csi)
            .map { meta, beds, tbis, bams, index -> [ meta.id, [meta, beds, tbis, bams, index] ] }
            .groupTuple() // group by first item, meta.id
            .map { id, samples ->
                def metas  = samples.collect{ it[0] }
                def merged_meta = [ id: metas.id[0], status:"" ]
                def beds   = samples.collect{ it[1] }.flatten()
                def tbis   = samples.collect{ it[2] }.flatten()
                def bams   = samples.collect{ it[3] }.flatten()
                def index   = samples.collect{ it[4] }.flatten()
                [ merged_meta, beds, tbis, bams, index ]
            }
            .set {ch_nanomonsv_tumornormal}

        NANOMONSV_GET(
            ch_nanomonsv_tumornormal,
            ch_fasta_ref    
        )
        ch_versions = ch_versions.mix(NANOMONSV_GET.out.versions)
    }

    if (params.severus) {
        ch_bams_csi_tumornormal
            .map { meta, bams, index -> [meta, bams, index, [] ]}
            .set {ch_severus_input}

        SEVERUS(
            ch_severus_input,
            ch_vntr_bed
        )
        ch_multiqc_files = ch_multiqc_files.mix(SEVERUS.out.all_vcf.collect{it[1]})
        ch_multiqc_files = ch_multiqc_files.mix(SEVERUS.out.somatic_vcf.collect{it[1]})
        ch_versions = ch_versions.mix(SEVERUS.out.versions)

    }

    if (params.savana) {        
        SAVANA(
            ch_bams_csi_tumornormal,
            ch_fasta_fai
        )
        ch_multiqc_files = ch_multiqc_files.mix(SAVANA.out.output.collect{it[1]})
        ch_versions = ch_versions.mix(SAVANA.out.versions)
    }

    if (params.svisionpro) {        
        // put reference together with gzi file for svisionpro
        ch_fasta_gzi = ch_fasta_ref
            .join(SAMTOOLS_FAIDX.out.gzi)
        
        SVISIONPRO(
            ch_bams_bai_tumornormal,
            ch_fasta_gzi,
            ch_access_bed,
            ch_svisionpro_model
        )
    }

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'somaticsvcalling_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
