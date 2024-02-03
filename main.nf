#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Include processes and workflows here  // './module/validation'
include { run_validate_PipeVal } from './external/pipeline-Nextflow-module/modules/PipeVal/validate/main'
include { run_depth_SAMtools as run_depth_SAMtools_target; run_depth_SAMtools as run_depth_SAMtools_off_target} from './module/get_depth_samtools'
include { convert_depth_to_bed as convert_depth_to_bed_off_target } from './module/depth_to_bed'
include { convert_depth_to_bed as convert_depth_to_bed_target } from './module/depth_to_bed'
include { run_merge_BEDtools } from './module/merge_intervals_bedtools'
include { run_CollectHsMetrics_picard } from './module/run_HS_metrics.nf'
include { run_BedToIntervalList_picard as run_BedToIntervalList_picard_target; run_BedToIntervalList_picard as run_BedToIntervalList_picard_bait } from './module/run_HS_metrics.nf'
include { run_slop_BEDtools as run_slop_BEDtools_expand_targets } from './module/filter_off_target_depth.nf'
include { run_slop_BEDtools as run_slop_BEDtools_expand_dbSNP } from './module/filter_off_target_depth.nf'
include { run_intersect_BEDtools } from './module/filter_off_target_depth.nf'
include { run_depth_filter } from './module/filter_off_target_depth.nf'
include { merge_bedfiles_BEDtools } from './module/merge_bedfiles_bedtools.nf'

include { generate_checksum_PipeVal as generate_sha512sum } from './external/pipeline-Nextflow-module/modules/PipeVal/generate-checksum/main.nf' addParams(
   options: [
      output_dir: "${params.workflow_output_dir}/output/",
      log_output_dir: "${params.log_output_dir}/process-log/",
      docker_image_version: params.pipeval_version,
      main_process: "./",
      checksum_alg: "sha512"
      ]
   )

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
            genome_sizes: ${params.genome_sizes}
            reference_dbSNP: ${params.reference_dbSNP}

        - output:
            output_dir: ${params.output_dir}
            output_log_dir: ${params.log_output_dir}

        - options:
            save_intermediate_files: ${params.save_intermediate_files}
            collect_metrics: ${params.collect_metrics}
            target_depth: ${params.target_depth}
            off_target_depth: ${params.off_target_depth}
            output_enriched_target_file: ${params.output_enriched_target_file}
            min_read_depth: ${params.min_read_depth}
            dbSNP_slop: ${params.dbSNP_slop}
            off_target_slop: ${params.off_target_slop}

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
            .set { input_ch_bam }

    // Validation process
    run_validate_PipeVal(
        input_ch_bam
        )

    run_validate_PipeVal.out.validation_result.collectFile(
        name: 'input_validation.txt', newLine: true,
        storeDir: "${params.workflow_output_dir}/validation"
        )

    checksum_ch = Channel.empty()

    // Calculate HsMetrics
    if ( params.collect_metrics ) {

        //Get intervalLists (only needed for collectHsMetrics)
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


        run_CollectHsMetrics_picard(
            input_ch_bam,
            input_ch_target_intervals,
            input_ch_bait_intervals,
            params.reference_fasta,
            params.genome_sizes
            )
    }


    // Calculate per-base read depth in targeted regions (optional)

    if ( params.target_depth ) {

        run_depth_SAMtools_target(
            input_ch_bam,
            params.target_bed,
            'target'
            )

        convert_depth_to_bed_target(
            run_depth_SAMtools_target.out.tsv,
            'target'
            )

        run_merge_BEDtools(
            convert_depth_to_bed_target.out.bed,
            )
        
        checksum_ch = checksum_ch.mix(run_merge_BEDtools.out.bed.flatten())

        }

    
    
    // Calculate Off-target Depth
    if ( params.off_target_depth || params.output_enriched_target_file) {

        // calculate depth at all dbSNP loci
        run_depth_SAMtools_off_target(
            input_ch_bam,
            params.reference_dbSNP,
            'genome-wide-dbSNP'
            )
        
        convert_depth_to_bed_off_target(
            run_depth_SAMtools_off_target.out.tsv,
            'genome-wide-dbSNP'
            )

        // Remove targeted regions from off-target depth calculations, taking into account slop if given
        run_slop_BEDtools_expand_targets(
            params.target_bed,
            params.genome_sizes,
            params.off_target_slop,
            'target'
            )
        
        run_intersect_BEDtools(
            run_slop_BEDtools_expand_targets.out.bed,
            convert_depth_to_bed_off_target.out.bed
            )
        
        checksum_ch = checksum_ch.mix(run_intersect_BEDtools.out.bed.flatten())

        // Combine target coordinates with enrighed off-target coordinates
        if ( params.output_enriched_target_file ) {

             // Apply minimum read-depth filter if one is provided
            if ( params.min_read_depth > 0) {
                run_depth_filter(
                    convert_depth_to_bed_off_target.out.bed
                    )

                run_slop_BEDtools_expand_dbSNP(
                    run_depth_filter.out.bed,
                    params.genome_sizes,
                    params.dbSNP_slop,
                    'off-target-dbSNP'
                    )
                
                // merge off-target coordinates with target coordinates

                // run_merge_BEDops is replaced by merge_bedfiles_BEDtools

                merge_bedfiles_BEDtools(
                    params.target_bed,
                    run_slop_BEDtools_expand_dbSNP.out.bed
                    )
                
                checksum_ch = checksum_ch.mix(merge_bedfiles_BEDtools.out.bed.flatten())

                }

                }

            }
        
        generate_sha512sum(checksum_ch)
        
    }
