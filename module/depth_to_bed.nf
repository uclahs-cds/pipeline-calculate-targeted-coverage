/*
*   Module/process description here
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/
process convert_depth_to_bed {
    container params.docker_image_validate

    // label "resource_allocation_tool_name_command_name" samtools_depth ??

    publishDir path: "${workflow_output_dir}/intermediate/${task.process.replace(':','/')}-${task.index}",
        pattern: "*.bed",
        mode: "copy",
        enabled: params.save_intermediate_files

    publishDir path: "${params.log_output_dir}",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }

    // Additional directives here
    
    input: 
        path input_tsv
        val workflow_output_dir

    output:
        path "*.bed", emit: bed
        path ".command.*"

    script:
    """
    set -euo pipefail

    cat $input_tsv | \
    awk 'BEGIN {OFS="\t"} {chr = \$1; start=\$2-1; stop=\$2; depth=\$3; print chr,start,stop,depth}' \
        | sort -k1,1 -k2,2n \
        > ${params.sample_id}.depth_per_base.bed
    """
}
