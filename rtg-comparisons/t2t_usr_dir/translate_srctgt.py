# coding=utf-8
"""Data generators for translation data-sets."""

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function


# Dependency imports

from tensor2tensor.data_generators import problem
from tensor2tensor.data_generators import translate
from tensor2tensor.utils import registry


TRAIN_SET = [
    ["a-remote-url/dummy.txt", ("train.src", "train.tgt")]
]

DEV_SET = [
    ["a-remote-url/dummy.txt", ("dev.src", "dev.tgt")]
]


@registry.register_problem
class TranslateSrcTgt32k(translate.TranslateProblem):
    """Problem spec for a Translate Task"""


    @property
    def approx_vocab_size(self):
        return 32000

    @property
    def vocab_filename(self):
        return "vocab.%d" % self.approx_vocab_size

    def source_data_files(self, dataset_split):
        train = dataset_split == problem.DatasetSplit.TRAIN
        return TRAIN_SET if train else DEV_SET

@registry.register_problem
class TranslateSrcTgt8k(TranslateSrcTgt32k):
    """Problem spec for a Translate Task"""

    @property
    def approx_vocab_size(self):
        return 8000  # 32768
