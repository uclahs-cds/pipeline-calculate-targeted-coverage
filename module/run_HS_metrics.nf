/*
*   Module/process description here
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/


process run_BedToIntervalList_picard {
    container params.docker_image_picard

    publishDir path: "${params.workflow_output_dir}/intermediate/${task.process.replace(':','/')}-${task.index}",
        pattern: "*.interval_list",
        mode: "copy",
        enabled: params.save_intermediate_files

    publishDir path: "${params.log_output_dir}",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }

    input: 
        path input_bed
        path reference_dict

    output:
        path "*.interval_list", emit: interval_list
        path ".command.*"

    script:
    """
    set -euo pipefail

    java -jar /usr/local/share/picard-slim-${params.picard_version}-0/picard.jar \
        BedToIntervalList \
        --INPUT $input_bed \
        --OUTPUT ${params.sample_id}.target.interval_list \
        --SEQUENCE_DICTIONARY $reference_dict \
        --SORT false
    """

}

process run_CollectHsMetrics_picard {
    container params.docker_image_picard

    publishDir path: "${params.workflow_output_dir}/QC/${task.process.replace(':','/')}-${task.index}",
        pattern: "*.txt",
        mode: "copy",
        enabled: true

    publishDir path: "${params.log_output_dir}",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }
    
    input: 
        path input_bam
        path target_interval_list, stageAs: 'target_intervals.interval_list'
        path bait_interval_list, stageAs: 'bait_intervals.interval_list'

    output:
        path "*.txt", emit: txt
        path ".command.*"

    script:
    """
    set -euo pipefail

    java -jar /usr/local/share/picard-slim-${params.picard_version}-0/picard.jar \
        CollectHsMetrics \
        --BAIT_INTERVALS $bait_interval_list \
        --INPUT $input_bam \
        --TARGET_INTERVALS $target_interval_list \
        --OUTPUT ${params.sample_id}.HsMetrics.txt \
        --TMP_DIR ${params.work_dir}
    """
}
