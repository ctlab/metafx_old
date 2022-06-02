#!/bin/bash

echo "Running: $0 $@"

pwd=`dirname "$0"`

usage="METAgenomic Feature eXtraction toolkit

$(basename "$0") [<Launch options>] [<Input parameters>]

Launch options:
    -h, --help                          show help message and exit
    -p, --available-processors <int>    number of threads to use [default: all]
    -m, --memory <MEM>                  memory to use (values with suffix, for example: 1500M, 4G, etc.) [default: 90% of free RAM]
    -w, --work-dir <dirname>            working directory [default: workDir/]
    
Input parameters:
    -k, --k <int>                       k-mer size (in nucleotides, maximum value is 31) [mandatory]
    -i, --reads <filenames>             list of reads files from single environment. FASTQ, FASTA, gzip- and bzip2-compressed [mandatory]
    -b, --maximal-bad-frequence <int>   maximal frequency for a k-mer to be assumed erroneous [default: 1]
    --min-samples <int>                 k-mer is considered group-specific if it presents in at least G samples of that group. G iterates in range [--min-samples; --max-samples] [default: 1]
    --max-samples <int>                 k-mer is considered group-specific if it presents in at least G samples of that group. G iterates in range [--min-samples; --max-samples] [default: 1]
    --class1 <filename>                 text file with names from the first group of samples (without path and extensions) [mandatory]
    --class2 <filename>                 text file with names from the second group of samples (without path and extensions) [mandatory]
    --class3 <filename>                 text file with names from the third group of samples (without path and extensions) [optional, if absent program runs in 2-class mode]"

w="workDir"
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
    echo "$usage"
    exit 0
    ;;
    -k|--k)
    k="$2"
    shift # past argument
    shift # past value
    ;;
    -b|--maximal-bad-frequence)
    b="$2"
    shift
    shift
    ;;
    -i|--reads)
    shift
    i=""
    while [[ $1 ]] && [ ${1:0:1} != "-" ] 
    do
        i+="$1 "
        shift
    done
    ;;
    --min-samples)
    minSamples="$2"
    shift
    shift
    ;;
    --max-samples)
    maxSamples="$2"
    shift
    shift
    ;;
    --class1)
    class1="$2"
    shift
    shift
    ;;
    --class2)
    class2="$2"
    shift
    shift
    ;;
    --class3)
    class3="$2"
    shift
    shift
    ;;
    
    -m|--memory)
    m="$2"
    shift
    shift
    ;;
    -p|--available-processors)
    p="$2"
    shift
    shift
    ;;
    -w|--work-dir)
    w="$2"
    shift
    shift
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters



cmd="metafast.sh "
if [[ $k ]]; then
    cmd+="-k $k "
fi
if [[ $m ]]; then
    cmd+="-m $m "
fi
if [[ $p ]]; then
    cmd+="-p $p "
fi



# ==== Step 1 ====
cmd1=$cmd
cmd1+="-t kmer-counter-many "
if [[ ${b} ]]; then
    cmd1+="-b ${b} "
fi
if [[ ${i} ]]; then
    cmd1+="-i ${i} "
fi
cmd1+="-w ${w}/kmer-counter-many/"

echo "$cmd1"
$cmd1
if [[ $? -eq 0 ]]; then
    echo "Step 1 finished successfully!"
else
    echo "Error during step 1!"
    exit -1
fi


# ==== Step 2 ====
cmd2=$cmd
cmd2+="-t unique-kmers-multi "
if [[ ${minSamples} ]]; then
    cmd2+="--min-samples ${minSamples} "
fi
if [[ ${maxSamples} ]]; then
    cmd2+="--max-samples ${maxSamples} "
fi
if [[ ${class3} ]]; then 
    # 3 class
    cmd2_1=$cmd2
    cmd2_2=$cmd2
    cmd2_3=$cmd2
    
    # ==== Step 2_1 ====
    if [[ ${class1} ]]; then
        tmp=$(sed -e "s/^/${w}\/kmer-counter-many\/kmers\//" ${class1} | sed -e "s/$/.kmers.bin/" | tr "\n" " ")
        cmd2_1+="-i $tmp "
    fi
    if [[ ${class2} ]]; then
        tmp=$(sed -e "s/^/${w}\/kmer-counter-many\/kmers\//" ${class2} ${class3} | sed -e "s/$/.kmers.bin/" | tr "\n" " ")
        cmd2_1+="--filter-kmers $tmp "
    fi
    cmd2_1+="-w ${w}/unique_kmers_class1/"
    
    echo "${cmd2_1}"
    ${cmd2_1}
    if [[ $? -eq 0 ]]; then
        echo "Processed files for class 1 in step 2"
    else
        echo "Error processing class 1 during step 2!"
        exit -1
    fi
    
    # ==== Step 2_2 ====
    tmp=$(sed -e "s/^/${w}\/kmer-counter-many\/kmers\//" ${class2} | sed -e "s/$/.kmers.bin/" | tr "\n" " ")
    cmd2_2+="-i $tmp "
    tmp=$(sed -e "s/^/${w}\/kmer-counter-many\/kmers\//" ${class1} ${class3} | sed -e "s/$/.kmers.bin/" | tr "\n" " ")
    cmd2_2+="--filter-kmers $tmp "
    
    cmd2_2+="-w ${w}/unique_kmers_class2/"
    
    echo "${cmd2_2}"
    ${cmd2_2}
    if [[ $? -eq 0 ]]; then
        echo "Processed files for class 2 in step 2"
    else
        echo "Error processing class 2 during step 2!"
        exit -1
    fi
    
    # ==== Step 2_3 ====
    tmp=$(sed -e "s/^/${w}\/kmer-counter-many\/kmers\//" ${class3} | sed -e "s/$/.kmers.bin/" | tr "\n" " ")
    cmd2_3+="-i $tmp "
    tmp=$(sed -e "s/^/${w}\/kmer-counter-many\/kmers\//" ${class1} ${class2} | sed -e "s/$/.kmers.bin/" | tr "\n" " ")
    cmd2_3+="--filter-kmers $tmp "
    
    cmd2_3+="-w ${w}/unique_kmers_class3/"
    
    echo "${cmd2_3}"
    ${cmd2_3}
    if [[ $? -eq 0 ]]; then
        echo "Processed files for class 3 in step 2"
    else
        echo "Error processing class 3 during step 2!"
        exit -1
    fi
    
    echo "Step 2 finished successfully!"
    
else
    # 2 class
    cmd2_1=$cmd2
    cmd2_2=$cmd2
    
    # ==== Step 2_1 ====
    if [[ ${class1} ]]; then
        tmp=$(sed -e "s/^/${w}\/kmer-counter-many\/kmers\//" ${class1} | sed -e "s/$/.kmers.bin/" | tr "\n" " ")
        cmd2_1+="-i $tmp "
    fi
    if [[ ${class2} ]]; then
        tmp=$(sed -e "s/^/${w}\/kmer-counter-many\/kmers\//" ${class2} | sed -e "s/$/.kmers.bin/" | tr "\n" " ")
        cmd2_1+="--filter-kmers $tmp "
    fi
    cmd2_1+="-w ${w}/unique_kmers_class1/"
    
    echo "${cmd2_1}"
    ${cmd2_1}
    if [[ $? -eq 0 ]]; then
        echo "Processed files for class 1 in step 2"
    else
        echo "Error processing class 1 during step 2!"
        exit -1
    fi
    
    # ==== Step 2_2 ====
    tmp=$(sed -e "s/^/${w}\/kmer-counter-many\/kmers\//" ${class2} | sed -e "s/$/.kmers.bin/" | tr "\n" " ")
    cmd2_2+="-i $tmp "
    tmp=$(sed -e "s/^/${w}\/kmer-counter-many\/kmers\//" ${class1} | sed -e "s/$/.kmers.bin/" | tr "\n" " ")
    cmd2_2+="--filter-kmers $tmp "
    
    cmd2_2+="-w ${w}/unique_kmers_class2/"
    
    echo "${cmd2_2}"
    ${cmd2_2}
    if [[ $? -eq 0 ]]; then
        echo "Processed files for class 2 in step 2"
    else
        echo "Error processing class 2 during step 2!"
        exit -1
    fi
    
    echo "Step 2 finished successfully!"
    
fi

# ==== Step 3 ====
cmd3=$cmd
cmd3+="-t component-extractor "
cmd3_1=$cmd3
cmd3_2=$cmd3

# ==== Step 3_1 ====
tmp=1
if [[ ${minSamples} ]]; then
    tmp=${minSamples}
fi
G1=$(bash get_G.sh ${w}/unique_kmers_class1/log ${tmp})

if [[ ${class1} ]]; then
    cmd3_1+="--pivot ${w}/unique_kmers_class1/kmers/filtered_${G1}.kmers.bin "
fi
tmp=$(sed -e "s/^/${w}\/kmer-counter-many\/kmers\//" ${class1} | sed -e "s/$/.kmers.bin/" | tr "\n" " ")
cmd3_1+="-i $tmp "

cmd3_1+="-w ${w}/components_class1/"

echo "${cmd3_1}"
${cmd3_1}
if [[ $? -eq 0 ]]; then
    echo "Processed files for class 1 in step 3"
else
    echo "Error processing class 1 during step 3!"
    exit -1
fi


# ==== Step 3_2 ====
tmp=1
if [[ ${minSamples} ]]; then
    tmp=${minSamples}
fi
G2=$(bash get_G.sh ${w}/unique_kmers_class2/log ${tmp})

if [[ ${class2} ]]; then
    cmd3_2+="--pivot ${w}/unique_kmers_class2/kmers/filtered_${G2}.kmers.bin "
fi
tmp=$(sed -e "s/^/${w}\/kmer-counter-many\/kmers\//" ${class2} | sed -e "s/$/.kmers.bin/" | tr "\n" " ")
cmd3_2+="-i $tmp "

cmd3_2+="-w ${w}/components_class2/"

echo "${cmd3_2}"
${cmd3_2}
if [[ $? -eq 0 ]]; then
    echo "Processed files for class 2 in step 3"
else
    echo "Error processing class 2 during step 3!"
    exit -1
fi
    
if [[ ${class3} ]]; then
    cmd3_3=$cmd3
    # ==== Step 3_3 ====
    tmp=1
    if [[ ${minSamples} ]]; then
        tmp=${minSamples}
    fi
    G3=$(bash get_G.sh ${w}/unique_kmers_class3/log ${tmp})
    
    if [[ ${class3} ]]; then
        cmd3_3+="--pivot ${w}/unique_kmers_class3/kmers/filtered_${G3}.kmers.bin "
    fi
    tmp=$(sed -e "s/^/${w}\/kmer-counter-many\/kmers\//" ${class3} | sed -e "s/$/.kmers.bin/" | tr "\n" " ")
    cmd3_3+="-i $tmp "
    
    cmd3_3+="-w ${w}/components_class3/"
    
    echo "${cmd3_3}"
    ${cmd3_3}
    if [[ $? -eq 0 ]]; then
        echo "Processed files for class 3 in step 3"
    else
        echo "Error processing class 3 during step 3!"
        exit -1
    fi
fi

echo "Step 3 finished successfully!"


# ==== Step 4 ====
cmd4=$cmd
cmd4+="-t features-calculator "
cmd4_1=$cmd4
cmd4_2=$cmd4

# ==== Step 4_1 ====
if [[ ${class1} ]]; then
    cmd4_1+="-cm ${w}/components_class1/components.bin "
fi
cmd4_1+="-ka ${w}/kmer-counter-many/kmers/*.kmers.bin "
cmd4_1+="--selected ${w}/unique_kmers_class1/kmers/filtered_${G1}.kmers.bin "
cmd4_1+="-w ${w}/features_class1/"

echo "$cmd4_1"
${cmd4_1}
if [[ $? -eq 0 ]]; then
    echo "Processed files for class 1 in step 4"
else
    echo "Error processing class 1 during step 4!"
    exit -1
fi

# ==== Step 4_2 ====
if [[ ${class2} ]]; then
    cmd4_2+="-cm ${w}/components_class2/components.bin "
fi
cmd4_2+="-ka ${w}/kmer-counter-many/kmers/*.kmers.bin "
cmd4_2+="--selected ${w}/unique_kmers_class2/kmers/filtered_${G2}.kmers.bin "
cmd4_2+="-w ${w}/features_class2/"

echo "$cmd4_2"
${cmd4_2}
if [[ $? -eq 0 ]]; then
    echo "Processed files for class 2 in step 4"
else
    echo "Error processing class 2 during step 4!"
    exit -1
fi

if [[ ${class3} ]]; then
    cmd4_3=$cmd4
    # ==== Step 4_3 ====
    if [[ ${class3} ]]; then
        cmd4_3+="-cm ${w}/components_class3/components.bin "
    fi
    cmd4_3+="-ka ${w}/kmer-counter-many/kmers/*.kmers.bin "
    cmd4_3+="--selected ${w}/unique_kmers_class3/kmers/filtered_${G3}.kmers.bin "
    cmd4_3+="-w ${w}/features_class3/"

    echo "$cmd4_3"
    ${cmd4_3}
    if [[ $? -eq 0 ]]; then
        echo "Processed files for class 3 in step 4"
    else
        echo "Error processing class 3 during step 4!"
        exit -1
    fi
fi

echo "Step 4 finished successfully!"


# ==== Step 5 ====
cmd5=$cmd
cmd5+="-t comp2seq "
cmd5_1=$cmd5
cmd5_2=$cmd5

# ==== Step 5_1 ====
if [[ ${class1} ]]; then
    cmd5_1+="-cf ${w}/components_class1/components.bin "
fi
cmd5_1+="-w ${w}/contigs_class1/"

echo "$cmd5_1"
${cmd5_1}
if [[ $? -eq 0 ]]; then
    echo "Processed files for class 1 in step 5"
else
    echo "Error processing class 1 during step 5!"
    exit -1
fi

# ==== Step 5_2 ====
if [[ ${class2} ]]; then
    cmd5_2+="-cf ${w}/components_class2/components.bin "
fi
cmd5_2+="-w ${w}/contigs_class2/"

echo "$cmd5_2"
${cmd5_2}
if [[ $? -eq 0 ]]; then
    echo "Processed files for class 2 in step 5"
else
    echo "Error processing class 2 during step 5!"
    exit -1
fi

if [[ ${class3} ]]; then
    cmd5_3=$cmd5
    # ==== Step 5_3 ====
    if [[ ${class3} ]]; then
        cmd5_3+="-cf ${w}/components_class3/components.bin "
    fi
    cmd5_3+="-w ${w}/contigs_class3/"

    echo "$cmd5_3"
    ${cmd5_3}
    if [[ $? -eq 0 ]]; then
        echo "Processed files for class 3 in step 5"
    else
        echo "Error processing class 3 during step 5!"
        exit -1
    fi
fi

echo "Step 5 finished successfully!"


echo "MetaFX finished successfully!"
exit 0