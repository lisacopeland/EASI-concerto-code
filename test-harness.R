# test-amle.R

concerto <- new.env()

concerto.log <- function(...) {
    cat(..., "\n")
}

concerto.table.insertParams <- function(sql, params = list(), connection = NULL) {
    for (name in names(params)) {
        value <- if (is.na(params[[name]])) "" else as.character(params[[name]])
        sql <- gsub(
            paste0("{{", name, "}}"),
            value,
            sql,
            fixed = TRUE
        )
    }

    cat("\nGenerated SQL:\n")
    cat(sql)
    cat("\n\n")

    sql
}

accuracyItemIds <- seq(from = 1, to = 70, by = 3)

scoreStatus <- sample(
    c("scored", "not scored"),
    size = length(accuracyItemIds),
    replace = TRUE
)

value <- ifelse(
    scoreStatus == "scored",
    sample(0:2, length(accuracyItemIds), replace = TRUE),
    NA
)

# put scoreStatus back to scoreStatus to calc values with nonscored values
responses <- data.frame(
    item_id = accuracyItemIds,
    trait = rep("Accuracy", length(accuracyItemIds)),
    scoreStatus = "scored",
    value = value,
    score = value,
    skipped = FALSE
)

items <- data.frame(
    id = accuracyItemIds,
    itemDifficulty = c(
        -2.42,
        -1.05,
        -1.28,
        -1.22,
        -0.95,
        0.03,
        -0.21,
        0.37,
        -1.04,
        0.03,
        -1.10,
        -0.55,
        0.73,
        0.32,
        1.56,
        0.37,
        1.46,
        0.43,
        0.47,
        0.08,
        1.30,
        0.74,
        1.48,
        0.44
    ),
    trait = rep("Accuracy", 24),
    excludeFromScoring = rep(0, 24),
    scoreMapType = rep(NA_character_, 24),
    type = rep("options", 24),
    optionLabel1 = rep("2", 24),
    optionValue1 = rep(2, 24),
    optionLabel2 = rep("1", 24),
    optionValue2 = rep(1, 24),
    optionLabel3 = rep("0", 24),
    optionValue3 = rep(0, 24),
    stepDifficulty = rep("[0, 0.02, -0.02]", 24)
)

test <- list(
    code = "TPD"
)

session <- list(
    id = 74
)

settings <- list(
    initialAbilityEstimate = 0,
    includeTraitInScoreName = TRUE,
    childsAge = 5,
    canGoBack = FALSE,
    scoreSettings = list(
        list(
            trait = "Accuracy",
            stepDifficulty = c(0, 0.02, -0.02),
            b0 = -6.41941,
            b1 = 2.09146,
            b2 = -0.20452,
            b3 = 0.007227,
            sd = 1.1034
        )
    )
)

expectedMeasures <- c(
    `0` = -4.93,
    `1` = -3.77,
    `2` = -3.10,
    `3` = -2.70,
    `4` = -2.40,
    `5` = -2.16,
    `6` = -1.96,
    `7` = -1.79,
    `8` = -1.63,
    `9` = -1.49,
    `10` = -1.35,
    `11` = -1.23,
    `12` = -1.11,
    `13` = -1.00,
    `14` = -0.89,
    `15` = -0.79,
    `16` = -0.69,
    `17` = -0.60,
    `18` = -0.50,
    `19` = -0.41,
    `20` = -0.32,
    `21` = -0.23,
    `22` = -0.14,
    `23` = -0.05,
    `24` = 0.03,
    `25` = 0.12,
    `26` = 0.21,
    `27` = 0.29,
    `28` = 0.38,
    `29` = 0.47,
    `30` = 0.56,
    `31` = 0.64,
    `32` = 0.74,
    `33` = 0.83,
    `34` = 0.93,
    `35` = 1.03,
    `36` = 1.13,
    `37` = 1.24,
    `38` = 1.36,
    `39` = 1.48,
    `40` = 1.61,
    `41` = 1.76,
    `42` = 1.92,
    `43` = 2.11,
    `44` = 2.33,
    `45` = 2.60,
    `46` = 2.99,
    `47` = 3.65,
    `48` = 4.81
)

roundLikeJavaScript <- function(value, digits = 0) {
    multiplier <- 10^digits
    floor(value * multiplier + 0.5) / multiplier
}

source("TestNodePort/EASI-test__response_processing__code.R")

selectedItems <- items
itemResponses <- lapply(
    seq_len(nrow(responses)),
    function(i) {
        as.list(responses[i, , drop = FALSE])
    }
)
response <- list(
    buttonPressed = "next",
    isTimeout = "0",
    submitId = "1",
    retryTimeTaken = "0",
    itemResponses = itemResponses
)
response <- createSql(response, selectedItems, test, session, settings)

quit(save = "no")
