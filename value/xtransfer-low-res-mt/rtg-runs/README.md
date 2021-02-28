# Run experiments

1. Make sure the `data` and the 500-eng model symbolic links are valid

2. Run all the experiments using rtg

```bash
for i in  sien-* neen-*; do  sbatch -J $i rtg-pipeline.sh -d $i; done
```