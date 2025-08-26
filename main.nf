#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    core-unit-bioinformatics/somaticsvcalling
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/core-unit-bioinformatics/somaticsvcalling
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SOMATICSVCALLING  } from './workflows/somaticsvcalling'
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_somaticsvcalling_pipeline'
include { PIPELINE_COMPLETION     } from './subworkflows/local/utils_nfcore_somaticsvcalling_pipeline'
include { getGenomeAttribute      } from './subworkflows/local/utils_nfcore_somaticsvcalling_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOME PARAMETER VALUES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// TODO nf-core: Remove this line if you don't need a FASTA file
//   This is an example of how to use getGenomeAttribute() to fetch parameters
//   from igenomes.config using `--genome`
params.fasta = getGenomeAttribute('fasta')

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    INPUT CHANNELS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Initialize files channels from parameters

ch_fasta              = params.fasta                 ? Channel.fromPath(params.fasta).collect()  : Channel.empty()
ch_fasta_ref          = ch_fasta.map { ch_fasta -> [[id: ch_fasta.baseName], ch_fasta] } //convert to tuple
ch_tandem_repeats     = params.tandem_repeats_bed    ? Channel.fromPath(params.tandem_repeats_bed).collect()  : Channel.empty()
ch_tandem_repeats_bed = ch_tandem_repeats.map { ch_tandem_repeats -> [[id: ch_tandem_repeats.baseName], ch_tandem_repeats] } //convert to tuple
ch_vntr               = params.vntr_bed    ? Channel.fromPath(params.vntr_bed).collect()  : Channel.empty()
ch_vntr_bed           = ch_vntr.map { ch_vntr -> [[id: ch_vntr.baseName], ch_vntr] } //convert to tuple

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow COREUNITBIOINFORMATICS_SOMATICSVCALLING {

    take:
    samplesheet // channel: samplesheet read in from --input
    ch_fasta_ref
    ch_tandem_repeats_bed
    ch_vntr_bed

    main:

    //
    // WORKFLOW: Run pipeline
    //
    SOMATICSVCALLING (
        samplesheet,
        ch_fasta_ref,
        ch_tandem_repeats_bed,
        ch_vntr_bed
    )
    emit:
    multiqc_report = SOMATICSVCALLING.out.multiqc_report // channel: /path/to/multiqc_report.html
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:
    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.input
    )

    //
    // WORKFLOW: Run main workflow
    //
    COREUNITBIOINFORMATICS_SOMATICSVCALLING (
        PIPELINE_INITIALISATION.out.samplesheet,
        ch_fasta_ref,
        ch_tandem_repeats_bed,
        ch_vntr_bed
    )
    //
    // SUBWORKFLOW: Run completion tasks
    //
    PIPELINE_COMPLETION (
        params.email,
        params.email_on_fail,
        params.plaintext_email,
        params.outdir,
        params.monochrome_logs,
        params.hook_url,
        COREUNITBIOINFORMATICS_SOMATICSVCALLING.out.multiqc_report
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
