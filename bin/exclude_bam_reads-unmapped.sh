#!/bin/bash

#  exclude_bam_reads-unmapped.sh
#  KA


#  ------------------------------------
#  Source external, internal functions into environment
#  ------------------------------------
functions="$(dirname "${BASH_SOURCE}")/functions.sh"
if [[ -f "${functions}" ]]; then
    source "${functions}"
else
    printf "%s\n" "Exiting: functions.sh not found."
    exit 1
fi


check_argument_flagstat() {
    case "$(echo "$(convert_chr_lower "${flagstat}")")" in
        true | t) \
            flagstat=1
            printf "%s\n" "\"Run samtools flagstat\" is TRUE."
            ;;
        false | f) \
            flagstat=0
            printf "%s\n" "\"Run samtools flagstat\" is FALSE."
            ;;
        *) \
            printf "%s\n\n" "Exiting: \"flagstat\" argument must be TRUE or FALSE.\n"
            # exit 1
            ;;
    esac
}


check_etc() {
    #  ------------------------------------
    #  Check depencies, and check and make variable assignments 
    #  ------------------------------------
    #  Check for necessary dependencies; exit if not found
    check_dependency samtools

    #  Evaluate "${safe_mode}"
    check_argument_safe_mode

    #  Check that "${infile}" exists
    check_exists_file "${infile}"

    #  If TRUE exist, then make "${outdir}" if it does not exist; if FALSE,
    #+ then exit if "${outdir}" does not exist
    check_exists_directory TRUE "${outdir}"  #TODO Fix this function

    #  Check on value assigned to "${flagstat}"
    check_argument_flagstat

    #  Check on value assigned to "${threads}"
    check_argument_threads
    
    echo ""

    #  Make additional variable assignments from the arguments
    base="$(basename "${infile}")"
    outfile="${base%.bam}.exclude-unmapped.bam"
}


main() {
    #  ------------------------------------
    #  Run samtools to exclude unmapped reads from .bam infile
    #  ------------------------------------
    echo ""
    echo "Running ${0}... "

    echo "Filtering out unmapped reads..."

    samtools view \
        -@ "${threads}" \
        -b -F 0x4 -F 0x8 \
        "${infile}" \
        -o "${outdir}/${outfile}"
    check_exit $? "samtools"


    #  ------------------------------------
    #  Run flagstat on filtered .bam outfile (optional)
    #  ------------------------------------
    if [[ $((flagstat)) -eq 1 ]]; then
        samtools flagstat \
            -@ "${threads}" \
            "${outdir}/${outfile}" \
                > "${outdir}/${outfile%.bam}.flagstat.txt" &
        check_exit $? "samtools"

        wait
    fi
}


#  ------------------------------------
#  Handle arguments
#  ------------------------------------
help="""
#  ------------------------------------
#  exclude_bam_alignments-unmapped.sh
#  ------------------------------------
Filter out unmapped alignments from a bam infile. Optionally, run samtools
flagstat on the filtered .bam outfile.

Name(s) of outfile(s) will be derived from the infile.

Dependencies:
    - samtools >= #TBD

Arguments:
    -u  use safe mode <lgl; default: FALSE>
    -i  bam infile, including path <chr>
    -o  outfile directory, including path; if not found, will be mkdir'd <chr>  #TODO
    -f  run samtools flagstat on bams <lgl; default: FALSE>
    -t  number of threads <int >= 1; default: 1>
"""

while getopts "u:i:o:f:t:" opt; do
    case "${opt}" in
        u) safe_mode="${OPTARG}" ;;
        i) infile="${OPTARG}" ;;
        o) outdir="${OPTARG}" ;;
        f) flagstat="${OPTARG}" ;;
        t) threads="${OPTARG}" ;;
        *) print_usage ;;
    esac
done

[[ -z "${safe_mode}" ]] && safe_mode=FALSE
[[ -z "${infile}" ]] && print_usage
[[ -z "${outdir}" ]] && print_usage
[[ -z "${flagstat}" ]] && flagstat=FALSE
[[ -z "${threads}" ]] && threads=1


#  ------------------------------------
#  Check depencies, and check and make variable assignments 
#  ------------------------------------
check_etc


#  ------------------------------------
#  Run samtools to exclude unmapped alignments from .bam infile, etc.
#  ------------------------------------
main
