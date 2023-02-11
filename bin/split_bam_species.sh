#!/bin/bash

#  split_bam_by_species.sh
#  KA


check_dependency() {
    what="""
    check_dependency()
    ------------------
    Check if program is available in \"\${PATH}\"; exit if not
    
    :param 1: program to be checked <chr>
    :return: NA
    """
    if [[ -z "${1}" ]]; then
        printf "%s\n" "${what}"
    else
        command -v "${1}" &>/dev/null ||
            {
                printf "%s\n" "Exiting: \"${1}\" not found in \"\${PATH}\"."
                printf "%s\n\n" "         Check your env or install \"${1}\"?"
                # exit 1
            }
    fi
}


check_argument_safe_mode() {
    what="""
    check_argument_safe_mode()
    --------------------------
    Run script in \"safe mode\" (\`set -Eeuxo pipefail\`) if specified
    
    :param 1: run script in safe mode: TRUE or FALSE <lgl> [default: FALSE]
    :return: NA

    #TODO Check that param is not empty or inappropriate format/string
    """
    case "$(convert_chr_lower "${1}")" in
        true | t) \
            printf "%s\n" "-u: \"Safe mode\" is TRUE."
            set -Eeuxo pipefail
            ;;
        false | f) \
            printf "%s\n" "\"Safe mode\" is FALSE." ;;
        *) \
            printf "%s\n" "Exiting: \"Safe mode\" must be TRUE or FALSE."
            # exit 1
            ;;
    esac
}


check_exists_file() {
    what="""
    check_exists_file()
    -------------------
    Check that a file exists; exit if it doesn't
    
    :param 1: file, including path <chr>
    :return: NA

    #TODO Check that param is not an inappropriate format/string
    """
    if [[ -z "${1}" ]]; then
        printf "%s\n" "${what}"
    elif [[ ! -f "${1}" ]]; then
        printf "%s\n\n" "Exiting: File \"${1}\" does not exist."
        # exit 1
    else
        :
    fi
}


check_exists_directory() {
    what="""
    check_exists_directory()
    ------------------------
    Check that a directory exists; if it doesn't, then either make it or exit
    
    :param 1: create directory if not found: TRUE or FALSE <lgl>
    :param 2: directory, including path <chr>
    :return: NA

    #TODO Check that params are not empty or inappropriate formats/strings
    """
    case "$(convert_chr_lower "${1}")" in
        true | t) \
            [[ -d "${2}" ]] ||
                {
                    printf "%s\n" "${2} doesn't exist; mkdir'ing it."
                    mkdir -p "${2}"
                }
            ;;
        false | f) \
            [[ -d "${2}" ]] ||
                {
                    printf "%s\n" "Exiting: ${2} does not exist."
                    exit 1
                }
            ;;
        *) \
            printf "%s\n" "Exiting: param 1 is not \"TRUE\" or \"FALSE\"."
            printf "%s\n" "${what}"
            exit 1
            ;;
    esac
}


check_argument_threads() {
    what="""
    check_argument_threads()
    ---------------
    Check the value assigned to variable for threads/cores in script

    :param 1: value assigned to variable for threads/cores <int >= 1>
    :return: NA

    #TODO Checks...
    """
    case "${1}" in
        '' | *[!0-9]*) \
            printf "%s\n" "Exiting: argument must be an integer >= 1."
            # exit 1
            ;;
        *) : ;;
    esac
}


split_with_samtools() {
    what="""
    split_with_samtools()
    ---------------------
    Use samtools to filter a bam file such that it contains only chromosome(s)
    specified with ${0} argument -s

    :param 1: threads <int >= 1>
    :param 2: bam infile, including path <chr>
    :param 3: chromosomes to retain <chr>
    :param 4: bam outfile, including path <chr>
    :return: param 2 filtered to include only param 3 in param 4

    #TODO Checks...
    """
    samtools view -@ "${1}" -h "${2}" ${3} -o "${4}"
}


convert_chr_lower() {
    what="""
    convert_chr_lower()
    -------------------
    Convert alphabetical characters in a string to lowercase letters
    
    :param 1: string <chr>
    :return: converted string (stdout) <chr>
    """
    if [[ -z "${1}" ]]; then
        printf "%s\n" "${what}"
    else
        string_in="${1}"
        string_out="$(printf %s "${string_in}" | tr '[:upper:]' '[:lower:]')"

        echo "${string_out}"
    fi
}


print_usage() {
    what="""
    print_usage()
    -------------
    Print the script's help message and exit

    :param 1: help message assigned to a variable within script <chr>
    :return: help message (stdout) <chr>

    #TODO Checks...
    """
    echo "${1}"
    exit 1
}


check_etc() {
    #  ------------------------------------
    #  Check and make variable assignments 
    #  ------------------------------------
    #  Check for necessary dependencies; exit if not found
    check_dependency samtools

    #  Evaluate "${safe_mode}"
    check_argument_safe_mode "${safe_mode}"

    #  Check that "${infile}" exists
    check_exists_file "${infile}"

    #  If TRUE exist, then make "${outdir}" if it does not exist; if FALSE,
    #+ then exit if "${outdir}" does not exist
    check_exists_directory FALSE "${outdir}"

    #  Check on the specified value for "${split}"
    case "$(echo "${split}" | tr '[:upper:]' '[:lower:]')" in
        sc_all | sc_no_mito | sc_vii | sc_xii | sc_vii_xii | sc_mito | \
        kl_all | virus_20s) \
            :
            ;;
        *) \
            message="""
            Exiting: -s \"\${split}\" must be one of the following:
              - SC_all
              - SC_no_Mito
              - SC_VII
              - SC_XII
              - SC_VII_XII
              - SC_Mito
              - KL_all
              - virus_20S
            """
            printf "%s\n\n" "${message}"
            exit 1
            ;;
    esac

    #  Check on value assigned to "${threads}"
    check_argument_threads "${threads}"

    #TODO Not sure if I want this assignment in this function...
    #  Make additional variable assignments from the arguments
    outfile="$(basename "${infile}")"

    echo ""
}


main() {
    #  ------------------------------------
    #  Run samtools to split the bam by species/chromosome
    #  ------------------------------------

    echo ""
    echo "Running ${0}... "

    # #TEST
    # threads=1
    # infile="exp_alignment_STAR/files_bams/5781_G1_IN_mergedAligned.sortedByCoord.out.bam"
    # chr="VII XII"
    # SC_all="exp_alignment_STAR/files_bams/5781_G1_IN_mergedAligned.sortedByCoord.out.split_SC_VII_XII.bam"

    if [[ "$(echo "$(convert_chr_lower "${split}")")" == "sc_all" ]]; then
        chr="I II III IV V VI VII VIII IX X XI XII XIII XIV XV XVI Mito"
    elif [[ "$(echo "$(convert_chr_lower "${split}")")" == "sc_no_mito" ]]; then
        chr="I II III IV V VI VII VIII IX X XI XII XIII XIV XV XVI"
    elif [[ "$(echo "$(convert_chr_lower "${split}")")" == "sc_vii" ]]; then
        chr="VII"
    elif [[ "$(echo "$(convert_chr_lower "${split}")")" == "sc_xii" ]]; then
        chr="XII"
    elif [[ "$(echo "$(convert_chr_lower "${split}")")" == "sc_vii_xii" ]]; then
        chr="VII XII"
    elif [[ "$(echo "$(convert_chr_lower "${split}")")" == "sc_mito" ]]; then
        chr="Mito"
    elif [[ "$(echo "$(convert_chr_lower "${split}")")" == "kl_all" ]]; then
        chr="A B C D E F"
    elif [[ "$(echo "$(convert_chr_lower "${split}")")" == "virus_20s" ]]; then
        chr="20S"
    else
        chr=""
        printf "%s\n\n" "Exiting: -s is not one of the species options."
        # exit 1
    fi

    split_with_samtools \
        "${threads}" \
        "${infile}" \
        "${chr}" \
        "${outdir}/${outfile%.bam}.${split}.bam"
}


#  ------------------------------------
#  Handle arguments, assign variables
#  ------------------------------------
help="""
#  ------------------------------------
#  split_bam_by_species.sh
#  ------------------------------------
Take user-input bam files containing alignments to S. cerevisiae, K. lactis,
and 20 S narnavirus, and split them into distinct bam files for each species,
with three splits for S. cerevisiae: all S. cerevisiae chromosomes not
including chromosome M, all S. cerevisiae including chromosome M, and S.
cerevisiae chromosome M only.

Names of chromosomes in bam infiles must be in the following format:
  - S. cerevisiae (SC)
    - I
    - II
    - III
    - IV
    - V
    - VI
    - VII
    - VIII
    - IX
    - X
    - XI
    - XII
    - XIII
    - XIV
    - XV
    - XVI
    - Mito

  - K. lactis (KL)
    - A
    - B
    - C
    - D
    - E

  - 20 S narnavirus
    - 20S

(That is, chrI, chrII, chrA, etc. format is not accepted.)

The split bam files are saved to a user-defined out directory.

Dependencies:
    - samtools >= version #TBD

Arguments:
    -u  safe_mode  use safe mode: TRUE or FALSE <lgl> [default: FALSE]
    -i  infile     bam infile, including path <chr>
    -o  outdir     outfile directory, including path; if not found, will be
                   mkdir'd <chr>
    -s  split      what to split out; options: SC_all, SC_no_Mito, SC_VII,
                   SC_XII, SC_VII_XII, SC_Mito, KL_all, virus_20S <chr>
                   [default: SC_all]

                       SC_all  return all SC chromosomes, including Mito
                   SC_no_Mito  return all SC chromosomes, excluding Mito
                       SC_VII  return only SC chromosome VII
                       SC_XII  return only SC chromosome XII
                   SC_VII_XII  return only SC chromosomes VII and XII
                      SC_Mito  return only SC chromosome Mito
                       KL_all  return all KL chromosomes
                    virus_20S  return only 20S narnavirus

    -t  threads    number of threads <int >= 1; default: 1>
"""

while getopts "u:i:o:s:t:" opt; do
    case "${opt}" in
        u) safe_mode="${OPTARG}" ;;
        i) infile="${OPTARG}" ;;
        o) outdir="${OPTARG}" ;;
        s) split="${OPTARG}" ;;
        t) threads="${OPTARG}" ;;
        *) print_usage "${help}" ;;
    esac
done

[[ -z "${safe_mode}" ]] && safe_mode=FALSE
[[ -z "${infile}" ]] && print_usage "${help}"
[[ -z "${outdir}" ]] && print_usage "${help}"
[[ -z "${split}" ]] && split="SC_all"
[[ -z "${threads}" ]] && threads=1

#TEST (undated)
# safe_mode=FALSE
# infile="${HOME}/tsukiyamalab/kalavatt/2022_transcriptome-construction/results/2022-1025/align_process_fastqs/bam/5781_G1_IN_merged.bam"
# outdir="${HOME}/tsukiyamalab/kalavatt/2022_transcriptome-construction/results/2022-1025/align_process_fastqs/bam"
# split="SC_all"
# threads=1
#
# echo "${safe_mode}"
# echo "${infile}"
# echo "${outdir}"
# echo "${split}"
# echo "${threads}"
#
# ls -lhaFG "${infile}"
# ls -lhaFG "${outdir}"


#  ------------------------------------
#  Check dependencies, and check and make variable assignments 
#  ------------------------------------
check_etc


#  ------------------------------------
#  Run samtools to split bam infiles
#  ------------------------------------
main