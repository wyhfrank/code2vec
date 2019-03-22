#!/usr/bin/env bash
###########################################################
# Change the following values to preprocess a new dataset.
# SOURCE_DIR, VAL_DIR and TEST_DIR should be paths to      
#   directories containing sub-directories with .java files
#   each of {SOURCE_DIR, VAL_DIR and TEST_DIR} should have sub-dirs,
#   and data will be extracted from .java files found in those sub-dirs).
# DATASET_NAME is just a name for the currently extracted 
#   dataset.                                              
# MAX_CONTEXTS is the number of contexts to keep for each 
#   method (by default 200).                              
# WORD_VOCAB_SIZE, PATH_VOCAB_SIZE, TARGET_VOCAB_SIZE -   
#   - the number of words, paths and target words to keep 
#   in the vocabulary (the top occurring words and paths will be kept). 
#   The default values are reasonable for a Tesla K80 GPU 
#   and newer (12 GB of board memory).
# NUM_THREADS - the number of parallel threads to use. It is 
#   recommended to use a multi-core machine for the preprocessing 
#   step and set this value to the number of cores.
# PYTHON - python3 interpreter alias.

SOURCE_DIR=data/fake_clone/source
DATASET_NAME=fake_clone
RAW_OUTPUT_DIR=data/${DATASET_NAME}/feature/raw
OUTPUT_NAME_BASE=data/${DATASET_NAME}/feature/

MAX_CONTEXTS=200
WORD_VOCAB_SIZE=1301136
PATH_VOCAB_SIZE=911417
TARGET_VOCAB_SIZE=261245
NUM_THREADS=64
PYTHON=python3
###########################################################

COLLECTED_FEATURE_FILE=${RAW_OUTPUT_DIR}/feature.raw.txt
EXTRACTOR_JAR=JavaExtractor/JPredict/target/JavaExtractor-0.0.1-SNAPSHOT.jar


rm -rf ${RAW_OUTPUT_DIR}
#mkdir -p data
mkdir -p ${RAW_OUTPUT_DIR}

echo "Extracting paths from source files..."
#${PYTHON} JavaExtractor/extract.py --dir ${SOURCE_DIR} --max_path_length 8 --max_path_width 2 --num_threads ${NUM_THREADS} --jar ${EXTRACTOR_JAR} | shuf > ${COLLECTED_FEATURE_FILE}
find ${SOURCE_DIR} -name "*.java" | xargs -P ${NUM_THREADS} -I@ sh -c "java -cp ${EXTRACTOR_JAR} JavaExtractor.App --file @ --max_path_length 8 --max_path_width 2 | tee @.c2v_feature >> ${COLLECTED_FEATURE_FILE}"
echo "Finished extracting paths from source files"

TARGET_HISTOGRAM_FILE=${RAW_OUTPUT_DIR}/histo.tgt.c2v
ORIGIN_HISTOGRAM_FILE=${RAW_OUTPUT_DIR}/histo.ori.c2v
PATH_HISTOGRAM_FILE=${RAW_OUTPUT_DIR}/histo.path.c2v

echo "Creating histograms from the training data"
cat ${COLLECTED_FEATURE_FILE} | cut -d' ' -f1 | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${TARGET_HISTOGRAM_FILE}
cat ${COLLECTED_FEATURE_FILE} | cut -d' ' -f2- | tr ' ' '\n' | cut -d',' -f1,3 | tr ',' '\n' | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${ORIGIN_HISTOGRAM_FILE}
cat ${COLLECTED_FEATURE_FILE} | cut -d' ' -f2- | tr ' ' '\n' | cut -d',' -f2 | awk '{n[$0]++} END {for (i in n) print i,n[i]}' > ${PATH_HISTOGRAM_FILE}


find ${SOURCE_DIR} -name "*.java.c2v_feature" | ${PYTHON} preprocess_my.py \
  --max_contexts ${MAX_CONTEXTS} --word_vocab_size ${WORD_VOCAB_SIZE} --path_vocab_size ${PATH_VOCAB_SIZE} \
  --target_vocab_size ${TARGET_VOCAB_SIZE} --word_histogram ${ORIGIN_HISTOGRAM_FILE} \
  --path_histogram ${PATH_HISTOGRAM_FILE} --target_histogram ${TARGET_HISTOGRAM_FILE} --output_name ${OUTPUT_NAME_BASE}

#${PYTHON} preprocess.py --train_data ${COLLECTED_FEATURE_FILE} \
#  --max_contexts ${MAX_CONTEXTS} --word_vocab_size ${WORD_VOCAB_SIZE} --path_vocab_size ${PATH_VOCAB_SIZE} \
#  --target_vocab_size ${TARGET_VOCAB_SIZE} --word_histogram ${ORIGIN_HISTOGRAM_FILE} \
#  --path_histogram ${PATH_HISTOGRAM_FILE} --target_histogram ${TARGET_HISTOGRAM_FILE} --output_name ${OUTPUT_NAME_BASE}
    
# If all went well, the raw data files can be deleted, because preprocess.py creates new files 
# with truncated and padded number of paths for each example.
#rm ${COLLECTED_FEATURE_FILE} ${VAL_DATA_FILE} ${TEST_DATA_FILE} ${TARGET_HISTOGRAM_FILE} ${ORIGIN_HISTOGRAM_FILE} ${PATH_HISTOGRAM_FILE}

