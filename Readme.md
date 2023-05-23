# MetaFX

**MetaFX** (METAgenomic Feature eXtraction) is a toolkit for feature construction and classification of metagenomic samples.

The idea behind **MetaFX** is to introduce feature extraction algorithm specific for metagenomics short reads data. It is capable of processing hundreds of samples 1-10 Gb each. The distinct property of suggest approach is the construction of meaningful features, which can not only be used to train classification model, but also can be further annotated and biologically interpreted.

## Deprecation note

This version of MetaFX is deprecated since 23.05.2023 and moved to [https://github.com/ctlab/metafx_old](https://github.com/ctlab/metafx_old).

[New version](https://github.com/ctlab/metafx) with many more supported features and improvements is available. Consider trying it!

----

![idea](./img/idea.png)

**MetaFX** documentation is available on the GitHub [wiki page](https://github.com/ivartb/metafx/wiki).<br/>
Here is a short version of it.

## Table of contents
<!--ts-->
  * [Installation](#installation)
  * [Running instructions](#running-instructions) 
    * [Input files](#input-files)
    * [Output files](#output-files)
    * [Options and Parameters](#options-and-parameters)
  * [Contact](#contact)
  * [License](#license)
  * [See also](#see-also)
<!--te-->

## Installation

#### Requirements:
* JRE 1.8 or higher
* python3
* python libraries for classification problem:
    * [NumPy](https://numpy.org/)
    * [Pandas](https://pandas.pydata.org/)
    * [Matplotlib](https://matplotlib.org/)
    * [scikit-learn](https://scikit-learn.org/stable/index.html)
    * [PyTorch](https://pytorch.org/)

Should you choose to build contigs via third-party [SPAdes](https://cab.spbu.ru/software/spades/) software, please follow their [installation instructions](https://github.com/ablab/spades#sec2) (not recommended for first-time use).

To run MetaFX you need scripts from the `bin/` folder. Consider adding it to the `PATH` variable. The main script to run is `metafx.sh`. 

Scripts have been tested under *Ubuntu 18.04 LTS*, but should generally work on Linux/MacOS.

## Running instructions

To run **_MetaFX_** use the following syntax:

```metafx.sh [<Launch options>] [<Input parameters>]```

Full description of launch options and input parameters can be found below in section [Options and Parameters](#options-and-parameters).

For detailed step-by-step running instructions, please refer to the [Wiki page](https://github.com/ivartb/metafx/wiki#step-by-step-example). It analyzes 54 gut samples from Inflammatory Bowel Disease dataset as a part of [iHMP project](https://doi.org/10.1038/s41586-019-1238-8).  The same analysis with the same results can be reproduced with one command.

From now on we suppose, that `metafx.sh` script is in the current directory and `bin/` folder has been added to the system `PATH`. To download the samples, run the following commands:

```
cd data/
for i in `tail -n +2 Class_labels.txt | cut -f2` ; do
  wget https://ibdmdb.org/tunnel/static/HMP2/WGS/1818/${i}.tar
  tar -xf ${i}.tar
done
cd ../
```
As a result in `data/` folder there will be 54 samples with paired-end reads in format `<sample>_[R1|R2].fastq.gz`.

The following command will run the pipeline on the test dataset and produce the same outputs as the step-by-step solution. 

```
./metafx.sh -p 32 -m 128G -w workDir \
  -k 31 \
  -i data/*.fastq.gz \
  -b 4 \
  --min-samples 1 --max-samples 10 \
  --class1 data/cd_filelist.txt \
  --class2 data/uc_filelist.txt \
  --class3 data/nonibd_filelist.txt
```

#### Input files

**MetaFX** accepts input sequence files of FASTQ and FASTA formats. Input files can also be compressed with gzip of bzip2.

Metadata files with samples split by categories should contain one sample name per line without path and extensions.

#### Output files

When **MetaFX** finishes, working directory will contain following results:

* `kmer-counter-many/kmers/<sample>.kmers.bin` – files with k-mers from each sample in binary format
* `unique_kmers_class[1|2|3]/kmers/filtered_G.kmers.bin` – files with group-specific k-mers in binary format for each class and different minimal number of samples containing such k-mers (_G_ values).
* `components_class[1|2|3]/components.bin` – file with graph components for each class selected as features in binary format. _G_ value for extracting components is selected automatically for each class. For user-defined fine tuning please refer to step-by-step pipeline.
* `features_class[1|2|3]/vectors/<sample>.breadth`– numeric feature vectors for each class in each sample. Value for feature is calculated as mean breadth coverage of component by samples' k-mers.
* `contigs_class[1|2|3]/seq-builder-many/sequences/component.seq.fasta` – contigs in FASTA format forming features' components for each class. Suitable for annotation and biological interpretation.

#### Options and Parameters

Input parameters for ***MetaFX***:
* **-k, --k &lt;N&gt;**<br/>
K-mer size (in nucleotides, maximum value is 31). (Mandatory)
* **-i, --reads &lt;files&gt;**<br/>
List of reads files from single environment. FASTQ, FASTA files are acceptable, gzip- and bzip2-compressed files are allowed too. Files can be set by bash regexp, for example `-i dir/*.fastq`. (Mandatory)
* **-b, --maximal-bad-frequence &lt;N&gt;**<br/>
Maximal frequency for a k-mer to be assumed erroneous. (Optional, default value 1)
* **--min-samples &lt;N&gt;**<br/>
K-mer is considered group-specific if it presents in at least *G* samples of that group. *G* iterates in range [`--min-samples`; `--max-samples`]. (Optional, default value 1)
* **--max-samples &lt;N&gt;**<br/>
K-mer is considered group-specific if it presents in at least *G* samples of that group. *G* iterates in range [`--min-samples`; `--max-samples`]. (Optional, default value 1)
* **--class1 &lt;file&gt;**<br/>
Text file with names from the _first_ group of samples. Only file names without path and extensions. (Mandatory)
* **--class2 &lt;file&gt;**<br/>
Text file with names from the _second_ group of samples. Only file names without path and extensions. (Mandatory)
* **--class3 &lt;file&gt;**<br/>
Text file with names from the _third_ group of samples. Only file names without path and extensions. (Optional, if absent program runs in 2-class mode)


Launch options:
* **-p, --available-processors &lt;N&gt;**<br/>
Available processors. By default *MetaFX* uses all available processors.
* **-m, --memory &lt;MEM&gt;**<br/>
Memory to use (values with suffix, for example: 1500M, 4G, etc.). By default *MetaFX* uses 90% of free memory.<br/>
* **-w, --work-dir &lt;DIR&gt;**<br/>
Working directory. The default working directory is `workDir/` in the current directory.
* **-h, --help**<br/>
Print help message.

## Contact

Please report any problems directly to the GitHub [issue tracker](https://github.com/ivartb/metafx/issues).

Also, you can send your feedback to [abivanov@itmo.ru](mailto:abivanov@itmo.ru).

Authors:
* **Software:** *Artem Ivanov* ([ITMO University](http://en.itmo.ru/en/))
* **Supervisor:** [*Vladimir Ulyantsev*](https://ulyantsev.com) ([ITMO University](http://en.itmo.ru/en/))


## License

The MIT License (MIT)


## See also

* [MetaFast](https://github.com/ctlab/metafast/) – a toolkit for comparison of metagenomic samples.
* [MetaCherchant](https://github.com/ctlab/metacherchant) – a tool for analysing genomic environment within a metagenome.
* [RECAST](https://github.com/ctlab/recast) – a tool for sorting reads per their origin in metagenomic time series.
