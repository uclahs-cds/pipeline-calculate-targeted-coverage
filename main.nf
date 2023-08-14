#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Include processes and workflows here  // './module/validation'
include { run_validate_PipeVal } from './external/pipeline-Nextflow-module/modules/PipeVal/validate/main'
include { run_depth_SAMtools } from './module/get_depth_samtools'
include { convert_depth_to_bed } from './module/depth_to_bed'
include { run_merge_BEDtools } from './module/merge_intervals_bedtools'
include { run_CollectHsMetrics_picard } from './module/run_HS_metrics.nf'
include { run_BedToIntervalList_picard as run_BedToIntervalList_picard_target } from './module/run_HS_metrics.nf'
include { run_BedToIntervalList_picard as run_BedToIntervalList_picard_bait } from './module/run_HS_metrics.nf'

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
            target_bed: ${params.target_bed}
            bait_bed: ${params.bait_bed}
            target_interval_list: ${params.target_interval_list}
            bait_interval_list: ${params.bait_interval_list}
            reference_dict: ${params.reference_dict}

        - output:
            output_dir: ${params.output_dir}
            output_log_dir: ${params.log_output_dir}

        - options:
            save_intermediate_files: ${params.save_intermediate_files}

        Tools Used:
            samtools: ${params.docker_image_samtools}
            bedtools: ${params.docker_image_bedtools}
            picard: ${params.docker_image_picard}
            pipeval: ${params.docker_image_validate}


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

        input_ch_bam.map{ it ->
            ['file-input', it]
            }
            .set { input_ch_validate }

    // Validation process
    run_validate_PipeVal(
        input_ch_validate
        )

    run_validate_PipeVal.out.validation_result.collectFile(
        name: 'input_validation.txt', newLine: true,
        storeDir: "${params.workflow_output_dir}/validation"
        )

    //Get intervalLists
    //if you already have the interval list use that, otherwise, generate interval list from BedToIntervalList process
    if ( params.target_interval_list ) {
        input_ch_target_intervals = params.target_interval_list
    }
    else {
        run_BedToIntervalList_picard_target(
            params.target_bed,
            params.reference_dict,
            'target'
            )
        input_ch_target_intervals = run_BedToIntervalList_picard_target.out.interval_list
        }

    if ( params.bait_interval_list ) {
        input_ch_bait_intervals = params.bait_interval_list
        }
    else if ( params.bait_bed ){
        run_BedToIntervalList_picard_bait(
            params.bait_bed,
            params.reference_dict,
            'bait'
            )
        input_ch_bait_intervals = run_BedToIntervalList_picard_bait.out.interval_list
        }
    else {
        input_ch_bait_intervals = input_ch_target_intervals
        }

    // Calculate Metrics
    run_CollectHsMetrics_picard(
        input_ch_bam,
        input_ch_target_intervals,
        input_ch_bait_intervals
        )

    // Calculate Coverage
    run_depth_SAMtools(
        input_ch_bam,
        params.target_bed,
        )

    convert_depth_to_bed(
        run_depth_SAMtools.out.tsv,
        )

    run_merge_BEDtools(
        convert_depth_to_bed.out.bed,
        )

}
