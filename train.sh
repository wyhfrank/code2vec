#!/usr/bin/env bash
###########################################################
# Change the following values to train a new model.
# type: the name of the new model, only affects the saved file name.
# dataset: the name of the dataset, as was preprocessed using preprocess.sh
# test_data: by default, points to the validation set, since this is the set that
#   will be evaluated after each training iteration. If you wish to test
#   on the final (held-out) test set, change 'val' to 'test'.
type=fake_clone
dataset_name=fake_clone
data_root=data/${dataset_name}
feature_dir=${data_root}/feature/
input_dir=${data_root}/input_data/
source_dir=${data_root}/source/
model_dir=models/${type}/

mkdir -p ${model_dir}
set -e
python3 -u code2vec.py --feature_dir ${feature_dir} --input_dir ${input_dir} --source_dir ${source_dir} --save ${model_dir}/saved_model