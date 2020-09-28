#!/bin/bash
shellpath=`dirname $0`
rm -rf TransLiG_Out_Dir 2>log_temp
mode="double_stranded_mode"
pair="No_input"
kmer=31
kmermin=21
covmin=30
gap=200
trans_len=200
min_seed_coverage=2
min_seed_entropy=1.5
min_kmer_coverage=1
min_kmer_entropy=0.0
min_junction_coverage=2
seqType="No_input"
left_reads="No_input"
right_reads="No_input"
single_reads="No_input"
Dir=$(pwd)
while getopts "s:l:r:m:p:k:K:c:g:u:o:S:E:C:N:J:t:vh" arg
do
	case $arg in
	s)
	    seqType=$OPTARG
		;;
	l)
	    left_reads=$OPTARG
		;;
	r)
	    right_reads=$OPTARG
		;;
	m)
	    mode=$OPTARG
		;;
	p)
	    pair=$OPTARG
		;;
	k)
	    kmer=$OPTARG
 	   	;;
	K)
	    kmermin=$OPTARG
 	   	;;
	c)
	    covminr=$OPTARG
 	   	;;
  	g)
      	    gap=$OPTARG
		;;
	u)
	    single_reads=$OPTARG
		;;
	o)
	    Dir=$OPTARG
		;;
	S)
	    min_seed_coverage=$OPTARG
		;;
	E)
	    min_seed_entropy=$OPTARG
                ;;
	C)
	    min_kmer_coverage=$OPTARG
                ;;
	N)
	    min_kmer_entropy=$OPTARG
                ;;
	J)
	    min_junction_coverage=$OPTARG
		;;
	t)
	    trans_len=$OPTARG
                ;;
	v)
	    echo "    "
	    echo "** The current version of TransLiG is v1.3 **"
	    echo "    "
	    exit 1
		;;
	h)
	    echo "    "
	    echo "==========================================================================="
	    echo "    "
	    echo "TransLiG v1.3 usage:"
	    echo "    "
	    echo "** Required **"
	    echo "    "
	    echo "-s <string>: type of reads: ( fa or fq )."
	    echo "    "
	    echo "-p <string>: type of sequencing: ( pair or single )."
	    echo "    "
	    echo "If paired_end reads, comma delimited list:"
	    echo "   -l <string>: left reads."
	    echo "   -r <string>: right reads."
	    echo "    "
	    echo "If single_end reads:"
	    echo "   -u <string>: single reads."
	    echo "    "
	    echo "---------------------------------------------------------------------------"
	    echo "    "
	    echo "** Options **"
	    echo "    "
	    echo "-o <string>: name of directory for output, default: ./TransLiG_Out_Dir/"
	    echo "    "
	    echo "-m <string>: strand-specific RNA-Seq reads orientation, default: double_stranded_mode."
	    echo "             if paired_end: RF or FR;"
	    echo "             if single_end: F or R."
	    echo "    "
	    echo "-t <int>: minimum length of transcripts, default: 200."
	    echo "    "
	    echo "-k <int>: length of kmer, default: 31."
	    echo "    "
	    echo "-K <int>: minimum length of kmer used to connect fragmented graphs, default: 21."
	    echo "    "
	    echo "-c <int>: minimum coverage of nodes used to connect fragmented graphs, default: 30."
	    echo "    "
	    echo "-g <int>: gap length of paired reads, default: 200."
	    echo "    "
	    echo "-S <int>: minimum coverage of kmer as a seed, default: 2."
	    echo "    "
	    echo "-E <float>: minimum entropy of kmer as a seed, default: 1.5."
	    echo "    "
	    echo "-C <int>: minimum coverage of kmer used to extend, default: 1."
	    echo "    "
	    echo "-N <float>: minimum entroy of kmer used to extend, default: 0.0."
	    echo "    "
	    echo "-J <int>: minimum of the coverage of a junction, default: 2."
	    echo "    "
	    echo "-v: report the current version of TransLiG and exit."
	    echo "    "
	    echo "** Note **"
	    echo "    "
	    echo "A typical command of TransLiG might be:"
	    echo "    "
	    echo "TransLiG -s fq -p pair -l reads.left.fq -r reads.right.fq"
	    echo "    "
    	    echo "(If your data are strand-strand, it is recommended to set -m option.)"
	    echo "    "
	    echo "==========================================================================="
	    exit 1
		;;
	esac
done
if [ $seqType == "No_input" ]; then
	echo "    "
	echo "** Error: data type is not specified! Please type -h option for help! **"
	echo "    "
	exit 1
fi
if [ "$seqType" != "fq" ] && [ "$seqType" != "fq" ] && [ "$seqType" != "fq.gz" ] &&  [ "$seqType" != "fa.gz" ]; then
	echo "    "
    echo "** Error: Unrecognized data type: $seqType! Please type -h option for help! **"
	echo "    "
    exit 1
fi
if [ $pair == "No_input" ]; then
        echo "    "
        echo "** Error: sequencing type is not specified! Please type -h option for help! **"
        echo "    "
        exit 1
fi
if [ $pair != "pair" -a $pair != "single" ]; then
        echo "    "
        echo "** Error: Unrecognized sequencing type: $pair! Please type -h option for help! **"
        echo "    "
        exit 1
fi
if [ $single_reads == "No_input" ]; then
	if [ $left_reads == "No_input" -o $right_reads == "No_input" ]; then
		echo "    "
        	echo "** Error: RNA-seq data is not correctly specified! Please type -h option for help! **"
		echo "    "
        	exit 1
	fi
fi
if [ $left_reads == "No_input" -a $right_reads == "No_input" ]; then
	if [ $single_reads == "No_input" ]; then
		echo "    "
		echo "** Error: RNA-seq data is not correctly specified! Please type -h option for help! **"
		echo "    "
                exit 1
        fi
fi
echo "Processing data..."
if [ $pair == "pair" ]; then
  if [ $seqType == "fq.gz" ]; then
    if [ $mode == "double_stranded_mode" ]; then
      for i in $(echo $left_reads | sed "s/,/ /g")
      do
        id=$(basename $(basename $i) .fq.gz)
        seqkit fq2fa $i > $id.left.fa
        echo "seqkit fq2fa $i > $id.left.fa"
      done
      for i in $(echo $right_reads | sed "s/,/ /g")
      do
        id=$(basename $(basename $i) .fq.gz)
        seqkit fq2fa $i > $id.right.fa
        echo "seqkit fq2fa $i > $id.right.fa"
      done
    fi
    if [ $mode == "RF" ]; then
      for i in $(echo $left_reads | sed "s/,/ /g")
      do
        id=$(basename $(basename $i) .fq.gz)
        seqkit fq2fa $i | seqkit seq -r -p > $id.left.fa
        echo "seqkit fq2fa $i | seqkit seq -r -p > $id.left.fa"
      done
      for i in $(echo $right_reads | sed "s/,/ /g")
      do
        id=$(basename $(basename $i) .fq.gz)
        seqkit fq2fa $i > $id.right.fa
        echo "seqkit fq2fa $i > $id.right.fa"
      done
    fi
    if [ $mode == "FR" ]; then
      for i in $(echo $left_reads | sed "s/,/ /g")
      do
        id=$(basename $(basename $i) .fq.gz)
        seqkit fq2fa $i > $id.left.fa
        echo "seqkit fq2fa $i > $id.left.fa"
      done
      for i in $(echo $right_reads | sed "s/,/ /g")
      do
        id=$(basename $(basename $i) .fq.gz)
        seqkit fq2fa $i | seqkit seq -r -p > $id.right.fa
        echo "seqkit fq2fa $i | seqkit seq -r -p > $id.right.fa"
      done
    fi
      echo "cat *.left.fa *.right.fa >both.fa"
      cat *.left.fa *.right.fa >both.fa
      rm *.left.fa *.right.fa
  fi
  if [ $seqType == "fa" ]; then
    if [ $mode == "double_stranded_mode" ]; then
    echo "cat $left_reads $right_reads >both.fa"
    cat $left_reads $right_reads >both.fa
    fi
    if [ $mode == "RF" ]; then
    echo "seqkit seq -r -p $left_reads >reads.left.fa"
    seqkit seq -r -p $left_reads >reads.left.fa
    cat reads.left.fa $right_reads >both.fa
    fi
    if [ $mode == "FR" ]; then
    echo "seqkit seq -r -p $right_reads >reads.right.fa"
    seqkit seq -r -p $right_reads >reads.right.fa
    cat $left_reads reads.right.fa >both.fa
    fi
  fi
fi
if [ $pair == "single" ]; then
  if [ $seqType == "fq" ]; then
    if [ $mode == "double_stranded_mode" ]; then
      echo "seqkit fq2fa $single_reads >single.fa"
      seqkit fq2fa $single_reads >single.fa
    fi
    if [ $mode == "F" ]; then
      echo "seqkit fq2fa $single_reads >single.fa"
      seqkit fq2fa $single_reads >single.fa
    fi
    if [ $mode == "R" ]; then
      echo "seqkit fq2fa $single_reads | seqkit seq -r -p >single.fa"
      seqkit fq2fa $single_reads | seqkit seq -r -p  >single.fa
    fi
  fi
  if [ $seqType == "fa" ]; then
    echo "Copying $single_reads ..."
    cp $single_reads single.fa
  fi
fi
echo "Processing complete!"
echo "Constructing Splicing Graph..."
if [ $pair == "pair" ]; then
  if [ $mode == "double_stranded_mode" ]; then
  echo "Assemble --reads both.fa -k $kmer --pair_end --$mode --pair_gap_length $gap --min_seed_coverage $min_seed_coverage --min_seed_entropy $min_seed_entropy --min_kmer_coverage $min_kmer_coverage --min_kmer_entropy $min_kmer_entropy --min_junction_coverage $min_junction_coverage --debug"
  Assemble --reads both.fa -k $kmer --pair_end --$mode --pair_gap_length $gap --min_seed_coverage $min_seed_coverage --min_seed_entropy $min_seed_entropy --min_kmer_coverage $min_kmer_coverage --min_kmer_entropy $min_kmer_entropy --min_junction_coverage $min_junction_coverage --debug 2>Assemble.log
  fi
  if [ $mode == "RF" ]; then
  echo "Assemble --reads both.fa -k $kmer --pair_end --fr_strand 1 --pair_gap_length $gap --min_seed_coverage $min_seed_coverage --min_seed_entropy $min_seed_entropy --min_kmer_coverage $min_kmer_coverage --min_kmer_entropy $min_kmer_entropy --min_junction_coverage $min_junction_coverage --debug"
  Assemble --reads both.fa -k $kmer --pair_end --fr_strand 1 --pair_gap_length $gap --min_seed_coverage $min_seed_coverage --min_seed_entropy $min_seed_entropy --min_kmer_coverage $min_kmer_coverage --min_kmer_entropy $min_kmer_entropy --min_junction_coverage $min_junction_coverage --debug 2>Assemble.log
  fi
  if [ $mode == "FR" ]; then
  echo "Assemble --reads both.fa -k $kmer --pair_end --fr_strand 2 --pair_gap_length $gap --min_seed_coverage $min_seed_coverage --min_seed_entropy $min_seed_entropy --min_kmer_coverage $min_kmer_coverage --min_kmer_entropy $min_kmer_entropy --min_junction_coverage $min_junction_coverage --debug"
  Assemble --reads both.fa -k $kmer --pair_end --fr_strand 2 --pair_gap_length $gap --min_seed_coverage $min_seed_coverage --min_seed_entropy $min_seed_entropy --min_kmer_coverage $min_kmer_coverage --min_kmer_entropy $min_kmer_entropy --min_junction_coverage $min_junction_coverage --debug 2>Assemble.log
  fi
fi
if [ $pair == "single" ]; then
  if [ $mode == "double_stranded_mode" ]; then
  echo "Assemble --reads single.fa -k $kmer --min_seed_coverage $min_seed_coverage --min_seed_entropy $min_seed_entropy --min_kmer_coverage $min_kmer_coverage --min_kmer_entropy $min_kmer_entropy --min_junction_coverage $min_junction_coverage --debug"
  Assemble --reads single.fa -k $kmer --double_stranded_mode --min_seed_coverage $min_seed_coverage --min_seed_entropy $min_seed_entropy --min_kmer_coverage $min_kmer_coverage --min_kmer_entropy $min_kmer_entropy --min_junction_coverage $min_junction_coverage --debug 2>Assemble.log
  fi
  if [ $mode == "F" ]; then
  echo "Assemble --reads single.fa -k $kmer --min_seed_coverage $min_seed_coverage --min_seed_entropy $min_seed_entropy --min_kmer_coverage $min_kmer_coverage --min_kmer_entropy $min_kmer_entropy --min_junction_coverage $min_junction_coverage --debug"
  Assemble --reads single.fa -k $kmer --min_seed_coverage $min_seed_coverage --min_seed_entropy $min_seed_entropy --min_kmer_coverage $min_kmer_coverage --min_kmer_entropy $min_kmer_entropy --min_junction_coverage $min_junction_coverage --debug 2>Assemble.log
  fi
  if [ $mode == "R" ]; then
  echo "Assemble --reads single.fa -k $kmer --min_seed_coverage $min_seed_coverage --min_seed_entropy $min_seed_entropy --min_kmer_coverage $min_kmer_coverage --min_kmer_entropy $min_kmer_entropy --min_junction_coverage $min_junction_coverage --debug"
  Assemble --reads single.fa -k $kmer --min_seed_coverage $min_seed_coverage --min_seed_entropy $min_seed_entropy --min_kmer_coverage $min_kmer_coverage --min_kmer_entropy $min_kmer_entropy --min_junction_coverage $min_junction_coverage --debug 2>Assemble.log
  fi
fi
rm both.fa single.fa 2>log_temp
rm ${PWD}/RawGraphs/raw_graph.list
ls ${PWD}/RawGraphs >graph_list

mkdir RawGraphs_
if [ $mode == "double_stranded_mode" ]; then
connect_graph --rg_list graph_list --rg_path ${PWD}/RawGraphs --mincov $covmin --kmer $kmer --kmer2 $kmermin --ds_mold >log_temp
else
connect_graph --rg_list graph_list --rg_path ${PWD}/RawGraphs --mincov $covmin --kmer $kmer --kmer2 $kmermin >log_temp
fi
rm graph_list

for file_a in ${PWD}/RawGraphs_/*;
do
        temp_file=`basename $file_a`
        echo "Collecting Original Graph:" $temp_file"..."
        TransLiG_iteration ./RawGraphs_/$temp_file ./Trunk.fa ./Junc.fa $trans_len
done
cat ./Trunk.fa ./Junc.fa >Trunk_Junc.fa

if [ $mode == "double_stranded_mode" ]; then
refine Trunk_Junc.fa ds >log_temp
#cat Trunk_Junc.fa result.fa >TransLiG.fa #yu
rm ./Trunk.fa ./Junc.fa Trunk_Junc.fa #result.fa
else
refine Trunk_Junc.fa >log_temp
#cat Trunk_Junc.fa result.fa >TransLiG.fa #yu
rm ./Trunk.fa ./Junc.fa Trunk_Junc.fa #result.fa
fi
rm log_temp
awk '!a[$0]++' TransLiG_temp.fa >Temp.fa
Get_output Temp.fa TransLiG_temp.fa
rm Temp.fa
rm -rf RawGraphs RawGraphs_
mkdir TransLiG_Out_Dir
mv Assemble.log TransLiG_Out_Dir
mv TransLiG_temp.fa TransLiG_Out_Dir/TransLiG.fa

if [ $Dir != $(pwd) ]; then
  mv TransLiG_Out_Dir $Dir
fi
echo "Congratulations! Your job is finished!"

