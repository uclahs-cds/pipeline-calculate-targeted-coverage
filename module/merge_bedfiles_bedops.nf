/*
*   Module/process description here
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/
process run_merge_BEDops {
    container params.docker_image_bedops

    publishDir path: "${params.workflow_output_dir}/output/",
        pattern: "*.bed",
        mode: "copy"

    publishDir path: "${params.log_output_dir}/process-log/",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }
    
    input: 
        path target_bed
        path off_target_bed

    output:
        path "*.bed", emit: bed
        path ".command.*"

    script:
    """
    set -euo pipefail

    bedops \
        --merge \
        $target_bed \
        $off_target_bed \
        > ${params.sample_id}.target_with_enriched_off-target_intervals.bed
    """
}
