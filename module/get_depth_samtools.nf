/*
*   Module/process description here
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/
process run_depth_SAMtools {
    container params.docker_image_samtools

    publishDir path: "${params.workflow_output_dir}/intermediate/${task.process.replace(':','/')}-${task.index}",
        pattern: "*.tsv",
        mode: "copy",
        enabled: params.save_intermediate_files

    publishDir path: "${params.log_output_dir}/process-log/",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }
    
    input: 
        path input_BAM
        path input_bed

    output:
        path "*.tsv", emit: tsv
        path ".command.*"

    script:
    """
    set -euo pipefail

    samtools \
        depth \
        $input_BAM \
        -b $input_bed \
        -a \
        --min-BQ ${params.min_base_quality} \
        -o ${params.sample_id}.depth_per_base.tsv
    """
}
