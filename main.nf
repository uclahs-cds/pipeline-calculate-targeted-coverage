#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Include processes and workflows here  // './module/validation' 
include { run_validate_PipeVal } from './external/pipeline-Nextflow-module/modules/PipeVal/validate/main'
include { run_depth_SAMtools } from './module/get_depth_samtools'
include { convert_depth_to_bed } from './module/depth_to_bed'
include { run_merge_BEDtools } from './module/merge_intervals_bedtools'
include { run_BedToIntervalList_picard ; run_CollectHsMetrics_picard } from './module/run_HS_metrics.nf'

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
            picard: ${params.docker_image_picard}

        ------------------------------------
        Starting workflow...
        ------------------------------------
        """
        .stripIndent()

// Channels here
// Decription of input channel


// Main workflow here
workflow {
    coverage_output_dir = "${params.output_dir}/targeted-coverage"
    Channel
        .from( params.input.bam )
        .multiMap { it -> 
            bam: it
            }
        .set { input_ch_bam }

    Channel
        input_ch_bam.map{ it ->
            ['file-input', it]
            }
        .set { input_ch_validate }

    Channel
        .from( params.input_bed )
        .multiMap { it ->
            bed: it
            }
        .set { input_ch_bed }

    // Validation process
    run_validate_PipeVal(
        input_ch_validate
        )

    // Calculate Metrics
    run_BedToIntervalList_picard(
        input_ch_bed,
        coverage_output_dir
        )
    
    // add logic accepting external bait file
    params.bait_interval_list = run_BedToIntervalList_picard.out.interval_list

    run_CollectHsMetrics_picard(
        input_ch_bam,
        run_BedToIntervalList_picard.out.interval_list,
        params.bait_interval_list,
        coverage_output_dir
        )

    // Calculate Coverage
    run_depth_SAMtools(
        input_ch_bam,
        params.input_bed,
        coverage_output_dir
        )
    
    convert_depth_to_bed(
        run_depth_SAMtools.out.tsv,
        coverage_output_dir
        )

    run_merge_BEDtools(
        convert_depth_to_bed.out.bed,
        coverage_output_dir
        )

}
