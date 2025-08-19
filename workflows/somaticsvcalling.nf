/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
//include { PBMM2_INDEX                        } from '../modules/local/pbmm2/index'
include { PBMM2_ALIGN                            } from '../modules/nf-core/pbmm2/align'
include { SAMTOOLS_FAIDX                         } from '../modules/nf-core/samtools/faidx/main'
include { SAMTOOLS_REHEADER as BAMSAMPLERENAME   } from '../modules/nf-core/samtools/reheader/main'
include { TABIX_TABIX as BAMINDEX                } from '../modules/nf-core/tabix/tabix/main'
include { DELLY_LR                               } from '../modules/local/delly/lr'
include { DELLY_FILTER                           } from '../modules/local/delly/filter'
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

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

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

    //rename BAM input
    BAMSAMPLERENAME (
        ch_samplesheet
    )

    if (params.align) {
        PBMM2_ALIGN (
            BAMSAMPLERENAME.out.bam,
            ch_fasta_ref,
        )
        ch_versions = ch_versions.mix(PBMM2_ALIGN.out.versions)

        ch_aligned_bam = PBMM2_ALIGN.out.bam
        ch_aligned_csi = PBMM2_ALIGN.out.csi
    } else {
        ch_aligned_bam = BAMSAMPLERENAME.out.bam
        BAMINDEX (
            ch_aligned_bam
        )
        ch_aligned_csi = BAMINDEX.out.csi
    }

    //format it for delly_lr input; also put together tumor/normal samples as single tuple
    ch_aligned_bam
        .join(ch_aligned_csi)
        .map { meta, bam, csi -> [ meta.id, [meta, bam, csi] ] }
        .groupTuple() // group by first item, meta.id
        .map { id, samples ->
            def metas  = samples.collect{ it[0] }
            def merged_meta = [ id: metas.id[0] ]
            def bams   = samples.collect{ it[1] }
            def csis   = samples.collect{ it[2] }
            [ merged_meta, bams, csis, [], [], [] ]
        }
        .set {ch_bams}

    ch_fasta_fai = ch_fasta_ref
        .join(SAMTOOLS_FAIDX.out.fai)

    // run delly
    DELLY_LR (
        ch_bams,
        ch_fasta_fai
    )

    //run delly filter

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
