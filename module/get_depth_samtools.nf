/*
*   Module/process description here
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/
process run_depth_SAMtools {
    container params.docker_image_samtools

    // label "resource_allocation_tool_name_command_name" samtools_depth ??

    publishDir path: "${params.output_dir}/${task.process.replace(':','/')}-${task.index}",
        pattern: "*.bed",
        mode: "copy",
        enabled: params.save_intermediate.files

    publishDir path: "${params.log_output_dir}",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }

    // Additional directives here
    
    input: 
        path input_BAM
        path target_file


    output:
        // path("${variable_name}.command_name.file_extension"), emit: output_ch_tool_name_command_name
        path "*.bed", emit: bed
        path ".command.*"

    script:
    """
    set -euo pipefail

    samtools \
        depth \
        $input_BAM
        -b $target_file \
        -a \
        --min-BQ ${params.min_base_quality}
        -o ${variable_name}.command_name.tsv \
        // This is NOT a bed file yet. To convert to bedfile need to add a start column using awk:
        | \
        awk 'BEGIN {OFS="\t"} {chr = $1; start=$2-1; stop=$2; depth=$3; print chr,start,stop,depth}' \
        sort -k1,1 -k2,2n \ sort the bedfile for good measure
        > ${variable_name}.command_name.bed \\ this bedfile is now acceptable to bedtools
    """
}
