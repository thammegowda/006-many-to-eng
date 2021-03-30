

# Preprocessing:
- Unescape XML / HTML
- Normalize puntuations
- Tokenize using SacreMoses
    - I fixed some issues with Indian languages regarding Virama and Nuktha
- Dont escape XML chars
- Aggressive hyphen split



# Cleaning
 - URLs
 - Web page stuff: HTML, CSS, Javascript
 - Copy
 - Abnormal sentence ratios
 - deduplicate 
 - remove test / held-out sentences 
 
 
#  Setup 
```
pip install git+
```