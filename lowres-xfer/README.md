# Get data
  
    ./get-data.sh
    
## Run experiments

```bash
for i in breeng-* smeeng-*; do 
   sbatch -J $i rtg-pipeline.sh  -d $i;
done
```


# Get results

    ./report-mt.sh breeng-* smeeng-*
