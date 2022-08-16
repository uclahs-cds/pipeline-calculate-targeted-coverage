#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Include processes and workflows here
include { run_validate_PipeVal } from './module/validation'
include { run_depth_SAMtools } from './module/get_depth_samtools'
include { convert_depth_to_bed } from './module/depth_to_bed'
include { run_merge_BEDtools } from './module/merge_intervals_bedtools'

// Log info here
log.info """\
        ======================================
        T A R G E T E D - C O V E R A G E
        ======================================
        Boutros Lab

        Current Configuration:
        - pipeline:
            name: ${workflow.manifest.name}
            version: ${workflow.manifest.version}

        - input:
            sample_id: ${params.sample_id}
            input.bam: ${params.input.bam}
            input_bed: ${params.input_bed}

        - output: 
            output_dir: ${params.output_dir}
            output_log_dir: ${params.output_log_dir}

        - options:
            save_intermediate_files: ${params.save_intermediate_files}

        Tools Used:
            samtools: ${params.docker_image_samtools}
            bedtools: ${params.docker_image_bedtools}

        ------------------------------------
        Starting workflow...
        ------------------------------------
        """
        .stripIndent()

// Channels here
// Decription of input channel


// Main workflow here
workflow {

    Channel
        .from( params.input.bam )
        .multiMap { it -> 
            bam: it
            }
        .set { input_ch_bam }

    // Validation process
    // run_validate_PipeVal(
    //     input_ch_input_csv.BAM
    //     )

    // Workflow or process
    run_depth_SAMtools(
        input_ch_bam,
        params.input_bed
        )
    
    convert_depth_to_bed(
        run_depth_SAMtools.out.tsv
        )

    run_merge_BEDtools(
        convert_depth_to_bed.out.bed
        )

}
