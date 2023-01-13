# Topic: Solana BONK token airdrop post-mortem.

BONK is Solana's latest DOGE-style meme token. During the airdrop to 10,000s of addresses, 
some transactions unfortunately failed. Flipside Crypto's Data Science team supported the BONK
team in reproducing their snapshots and identifying addresses that did not receive their intended 
BONK. 

This repo holds all the code behind the post-mortem. For a deeper dive into the context, 
you can check out the report on our [research site](https://science.flipsidecrypto.xyz/research/) at [bonk-post-mortem](https://science.flipsidecrypto.xyz/bonk-post-mortem/).

If you aren't interested in code and want the shortest summary of the situation, you can check out the
email sized [bonk-post-mortem](https://flipsidecrypto.beehiiv.com/p/bonk-post-mortem) on our research beehiiv and subscribe to get (summaries of) the best crypto research direct to your inbox.

# Reproduce Analysis

All analysis is reproducible using the R programming language. You'll need (1) an shroomDK 
API key to copy our SQL queries and extract data from the [FlipsideCrypto data app](https://next.flipsidecrypto.xyz/); and (2) renv to get the exact package versions we used. 

## shroomDK

shroomDK is an R package that accesses the FlipsideCrypto REST API; it is also available for Python.
You pass SQL code as a string to our API and get up to 1M rows of data back!

Check out the [documentation](https://docs.flipsidecrypto.com/shroomdk-sdk/get-started) and get your free API Key today.

## renv 

renv is a package manager for the R programming language. It ensures analysis is fully reproducible by tracking the exact package versions used in the analysis.

`install.packages('renv')`

## Instructions 

To replicate this analysis please do the following:

1. Clone this repo.
2. Save your API key into a .txt file as 'api_key.txt' (this exact naming allows the provided .gitignore to ignore your key and keep it off github).
3. Open the SOL-BONK-REVIEW R Project file in your R IDE (we recommend, RStudio).
4. Confirm you have renv installed. 
5. Restore the R environment using `renv::restore()` while in the SOL-BONK-REVIEW R Project.
6. You can now run sol_bonk_airdrop_review.R and/or bonk-post-mortem.Rmd. 

If any errors arise, double check you have saved your API key in the expected file name and format.

