import gzip
from Bio import SeqIO
import argparse
import os
import multiprocessing

def iterator(seq, k):
    s = set()
    for i in range(0, len(seq)-k+1):
        s.add(seq[i:i+k])
    return s

def load_kmers(f):
    kmers = set()
    for line in open(f):
        if line.split()[0] != "Kmer":
            kmers.add(line.split()[0])
    return kmers

def filter_read(s, kmers, f):
    cnt = len(s & kmers)
    if cnt > 0:
        print(">"+str(cnt), file=f)
        print(s, file=f)

def filter_reads(reads_files):
    print("Started", reads_files, flush=True)
    fnames = [os.path.join(args.w, os.path.basename(reads_files).split('.')[0]+"_"+kmers[0]+'.fasta') for kmers in kmers_groups]
    out_files = [open(fname, 'w') for fname in fnames]
    k=args.k
    i=0
    with gzip.open(reads_files, 'rt') as handle:
        for record in SeqIO.parse(handle, "fastq"):
            seq = record.seq
            rev = seq.reverse_complement()
            s = set()
            s.update(iterator(seq, k))
            s.update(iterator(rev, k))

            for i, kmers in enumerate(kmers_groups):
                filter_read(s, kmers[1], out_files[i])

            i += 1
            if i % 1000000 == 0:
                print(i, "reads processed for", reads_files, flush=True)
    for f in out_files:
        f.close()
    print("Finished", reads_files, flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Extracts reads containing specified k-mers')
    parser.add_argument('-k', '--k', type=int, required=True, dest='k', help='k-mers length')
    parser.add_argument('-p', '--threads', type=int, default=1, dest='p', help='# of threads to use (Default: 1)')
    parser.add_argument('-w', '--workdir', default="reads_with_kmers", dest='w', help='working directory for results')
    parser.add_argument('--kmers', nargs='+', required=True, dest='kmers', help='Files with unique k-mers for each category')
    parser.add_argument('-i', '--reads', nargs='+', required=True, dest='reads', help='list of reads files')
    args = parser.parse_args()

    kmers_groups = [("class_"+str(pos), load_kmers(i)) for pos, i in enumerate(args.kmers)]
    print("Unique k-mers loaded", flush=True)

    with multiprocessing.Pool(args.p) as pool:
        results = [pool.apply_async(filter_reads, [sample]) for sample in args.reads]
        for r in results:
            r.get()
