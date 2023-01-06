library(shroomDK)
library(dplyr)

#' The BONK airdrop had some failed transactions. We are parsing all receivers of the airdrop
#' and comparing their received BONK with the proportional amounts they should have gotten 
#' as holders of specific NFTs. 

# Airdrop Recipients ----
recipients_query <- {
  "
with recipients as (SELECT tx_id, tx_from as giver, tx_to as receiver, amount, mint from 
  solana.core.fact_transfers
  where tx_from = '9AhKqLR67hwapvG8SA2JFXaCshXc9nALJjpKaHZrsbkw'
  and mint = 'DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263'
  and block_timestamp > '2022-12-24'
)
 
SELECT receiver, COUNT(*) as n_airdrops, SUM(amount) as claimed_token_volume
FROM recipients
GROUP BY receiver
  "
}

# Get API key at https://sdk.flipsidecrypto.xyz/shroomdk free 
api_key = readLines("api_key.txt")

bonk_receivers <- auto_paginate_query(recipients_query, api_key = api_key)
bonk_receivers <- bonk_receivers %>% 
  arrange(CLAIMED_TOKEN_VOLUME) 

# Loop Through Files and get target data frame ----

nft_holders_at_snapshot <- data.frame()
for(i in list.files("airdrop_files/", full.names = TRUE)){
  temp <- readLines(i)
  df_freq <- as.data.frame(table(temp))
  colnames(df_freq) <- c("address","count")
  df_freq$category <- gsub("airdrop_files/|\\.txt","",i)
  
  nft_holders_at_snapshot <- rbind.data.frame(nft_holders_at_snapshot, df_freq)
}

# CLEAN NAMES ----

# Solana addresses cannot have quotes or commas in them...

busted_index <- grepl("\"|,",nft_holders_at_snapshot$address)
nft_holders_at_snapshot$address <- gsub("\"|,","", nft_holders_at_snapshot$address)

# Identify Target Allocation ----

# "Each collection out of the 40 was supposed to receive 500B Bonk, 
# divided equally to each NFT Holder. so if there were 10000 NFTS, each one would get 50M."

# Group by Category 
# Identify total count within category
# Allocation count / total_count * 500 (multiply by billion at the end)

nft_holders_at_snapshot <- nft_holders_at_snapshot %>% 
  group_by(category) %>% 
  mutate(total_in_category = sum(count))

# The names of the files claim to have counts but the actual count is rarely different
write.csv(x = unique(nft_holders_at_snapshot[, c("category", "total_in_category")]), 
          file = "named_count_vs_actual.csv")

nft_holders_at_snapshot <- nft_holders_at_snapshot %>% 
  group_by(category) %>% 
  mutate(allocation_billions = 500 * count/total_in_category)

# Exceptions:
# Developers: 5T (10x the 500 base)
# Art Collectors: 10T  (this is 20x base)
# Openbook: 15T (30x base)

nft_holders_at_snapshot$allocation_billions[grepl("devs -", nft_holders_at_snapshot$category)] <- {
  nft_holders_at_snapshot$allocation_billions[grepl("devs -", nft_holders_at_snapshot$category)] * 10
}

nft_holders_at_snapshot$allocation_billions[grepl("art -", nft_holders_at_snapshot$category)] <- {
  nft_holders_at_snapshot$allocation_billions[grepl("art -", nft_holders_at_snapshot$category)] * 20
}
nft_holders_at_snapshot$allocation_billions[grepl("openbook -", nft_holders_at_snapshot$category)] <- {
  nft_holders_at_snapshot$allocation_billions[grepl("openbook -", nft_holders_at_snapshot$category)] * 30
}

write.csv(nft_holders_at_snapshot, "nft_qualifier_nonunique_address.csv")

# Swap dev names 

dev_names <- read.csv("dev_name_swap.csv", header = FALSE)

for(i in 1:nrow(dev_names)){
  nft_holders_at_snapshot$address <- gsub(dev_names$V1[i], dev_names$V2[i], nft_holders_at_snapshot$address )
}

# Identify Allocation across Categories ----

target_recipients <- nft_holders_at_snapshot %>% 
  group_by(address) %>%
  summarise(total_allocation_billions = sum(allocation_billions)*1e9) 

# Merge to actual_receivers ----

final_bonk <- merge(bonk_receivers, target_recipients,
                    by.x = "RECEIVER", by.y = "address", 
                    all.x = TRUE, all.y = TRUE)

final_bonk <- final_bonk %>% mutate(
  label = case_when(
    is.na(CLAIMED_TOKEN_VOLUME) & !is.na(total_allocation_billions) ~ "Did not Receive Drop",
    !is.na(CLAIMED_TOKEN_VOLUME) & is.na(total_allocation_billions) ~ "Received w/o NFT qualification",
    CLAIMED_TOKEN_VOLUME == total_allocation_billions ~ "Received Exact Drop!",
    CLAIMED_TOKEN_VOLUME > total_allocation_billions ~ "Received More than Expected",
    CLAIMED_TOKEN_VOLUME < total_allocation_billions ~ "Missing a piece of their drop"
  )
)

final_bonk[is.na(final_bonk)] <- 0
final_bonk$discrepancy <- final_bonk$CLAIMED_TOKEN_VOLUME - final_bonk$total_allocation_billions
write.csv(final_bonk, "bonk_review_labeled.csv")


fb <- final_bonk %>% group_by(label) %>% 
  summarise(
    total_received = sum(CLAIMED_TOKEN_VOLUME),
    total_owed = sum(total_allocation_billions),
    diff =  sum(CLAIMED_TOKEN_VOLUME) - sum(total_allocation_billions)
  )

write.csv(fb, "discrepancy.csv")
