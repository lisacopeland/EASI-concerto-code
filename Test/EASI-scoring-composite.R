getResponses <- function(participant_id) {
    # Query to get tests and responses:
    responses <- concerto.table.query(
        "SELECT
    'PRFD' AS test,
    r.id,
    r.session_id,
    r.item_id,
    r.value,
    r.score,
    r.label,
    r.timeTaken,
    r.trait,
    r.timeCreated,
    r.submitted,
    r.skipped,
    r.skipReason,
    r.scoreStatus
FROM PRFD_responses r
JOIN (
    SELECT
        prfd.id AS prfd_session_id,
        prp.id AS prp_session_id,
        prs.id AS prs_session_id
    FROM
        (
            SELECT id
            FROM PRFD_sessions
            WHERE participant_id = '{{participant_id}}'
              AND status = 2
            ORDER BY dateAssessment DESC
            LIMIT 1
        ) prfd
    CROSS JOIN
        (
            SELECT id
            FROM PRP_sessions
            WHERE participant_id = '{{participant_id}}'
              AND status = 2
            ORDER BY dateAssessment DESC
            LIMIT 1
        ) prp
    CROSS JOIN
        (
            SELECT id
            FROM PRS_sessions
                        WHERE participant_id = '{{participant_id}}'
              AND status = 2
            ORDER BY dateAssessment DESC
            LIMIT 1
        ) prs
) sessions
    ON r.session_id = sessions.prfd_session_id

UNION ALL

SELECT
    'PRP' AS test,
    r.id,
    r.session_id,
    r.item_id,
    r.value,
    r.score,
    r.label,
    r.timeTaken,
    r.trait,
    r.timeCreated,
    r.submitted,
    r.skipped,
    r.skipReason,
    r.scoreStatus
FROM PRP_responses r
JOIN (
    SELECT
        prfd.id AS prfd_session_id,
        prp.id AS prp_session_id,
        prs.id AS prs_session_id
    FROM
        (
            SELECT id
            FROM PRFD_sessions
                        WHERE participant_id = '{{participant_id}}'
              AND status = 2
            ORDER BY dateAssessment DESC
            LIMIT 1
        ) prfd
    CROSS JOIN
        (
            SELECT id
            FROM PRP_sessions
            WHERE participant_id = '{{participant_id}}'
              AND status = 2
            ORDER BY dateAssessment DESC
            LIMIT 1
        ) prp
    CROSS JOIN
        (
            SELECT id
            FROM PRS_sessions
            WHERE participant_id = '{{participant_id}}'
              AND status = 2
            ORDER BY dateAssessment DESC
            LIMIT 1
        ) prs
) sessions
    ON r.session_id = sessions.prp_session_id

UNION ALL

SELECT
    'PRS' AS test,
    r.id,
    r.session_id,
    r.item_id,
    r.value,
    r.score,
    r.label,
    r.timeTaken,
    r.trait,
    r.timeCreated,
    r.submitted,
    r.skipped,
    r.skipReason,
    r.scoreStatus
FROM PRS_responses r
JOIN (
    SELECT
        prfd.id AS prfd_session_id,
        prp.id AS prp_session_id,
        prs.id AS prs_session_id
    FROM
        (
            SELECT id
            FROM PRFD_sessions
            WHERE participant_id = '{{participant_id}}'
              AND status = 2
            ORDER BY dateAssessment DESC
            LIMIT 1
        ) prfd
    CROSS JOIN
        (
            SELECT id
            FROM PRP_sessions
            WHERE participant_id = '{{participant_id}}'
            AND status = 2
            ORDER BY dateAssessment DESC
            LIMIT 1
        ) prp
    CROSS JOIN
        (
            SELECT id
            FROM PRS_sessions
            WHERE participant_id = '{{participant_id}}'
              AND status = 2
            ORDER BY dateAssessment DESC
            LIMIT 1
        ) prs
) sessions
    ON r.session_id = sessions.prs_session_id",
        list(participant_id = participant_id)
    )
}

getTests <- function() {
    items <- concerto.table.query("SELECT
    'PRFD' AS test,
    id,
    trait,
    itemDifficulty,
    excludeFromScoring,
    optionScore1,
    optionScore2,
    optionScore3,
    optionScore4,
    optionScore5
    minimumAge,
    maximumAge,
    stepDifficulty,
    stimulusId,
    stimulusOrder,
    itemOrder,
    groupId
FROM PRFD_items

UNION ALL

SELECT
    'PRP' AS test,
    id,
    trait,
    itemDifficulty,
    excludeFromScoring,
    optionScore1,
    optionScore2,
    optionScore3,
    optionScore4,
    optionScore5
    minimumAge,
    maximumAge,
    stepDifficulty,
    stimulusId,
    stimulusOrder,
    itemOrder,
    groupId
FROM PRP_items

UNION ALL

SELECT
    'PRS' AS test,
    id,
    trait,
    itemDifficulty,
    excludeFromScoring,
    optionScore1,
    optionScore2,
    optionScore3,
    optionScore4,
    optionScore5
    minimumAge,
    maximumAge,
    stepDifficulty,
    stimulusId,
    stimulusOrder,
    itemOrder,
    groupId
FROM PRS_items")
}

# TODO: child's age in years has to come from the earliest date of assessment

calcScores <- function(responses, items, settings) {
    scoringModuleName <- paste0("EASI-scoring-", "new")

    scoringResult <- concerto.test.run(scoringModuleName, list(
        items = items,
        responses = responses,
        settings = settings,
    ))
    scores <- scoringResult$scores
}

updateScoreTable <- function(participantId, scores, sessionIds) {
    scoresTable <- paste0("PRAXIS", "_scores")
    concerto.table.query("DELETE FROM {{scoresTable}} WHERE participant_id='{{participant_id}}'", list(scoresTable = scoresTable, participant_id = participantId))

    if (is.list(scores) && length(scores) > 0) {
        insertSql <- concerto.table.insertParams("INSERT INTO {{scoresTable}} (prp_session_id, prs_session_id, prfd_session_id, name, value, timeCreated, participant_id) VALUES ", list(scoresTable = scoresTable))
        scoreValuesSqlArray <- NULL
        for (scoreName in names(scores)) {
            scoreValuesSql <- concerto.table.insertParams("('{{prp_session_id}}', '{{prs_session_id}}', '{{prfd_session_id}}', '{{name}}', IF('{{value}}'='', NULL, '{{value}}'), NOW(), '{{participant_id}}')", list(
                prp_session_id = sessionIds[["PRP"]],
                prs_session_id = sessionIds[["PRS"]],
                prfd_session_id = sessionIds[["PRFD"]],
                name = scoreName,
                value = scores[[scoreName]],
                participant_id = participantId
            ))
            scoreValuesSqlArray <- c(scoreValuesSqlArray, scoreValuesSql)
        }

        insertSql <- paste0(insertSql, paste0(scoreValuesSqlArray, collapse = ","))
        concerto.table.query(insertSql)
    }
}

# you get settings, participant_id, compositeGroup

responses <- getResponses(settings$participant_id)

requiredTests <- c("PRFD", "PRP", "PRS")

if (
    is.null(responses) ||
        !all(requiredTests %in% unique(responses$test))
) {
    return(list())
}

# get the settings
settingsTable <- paste0("PRAXIS", "_settings")
settingsNew <- concerto.table.query(
    "SELECT * FROM {{settingsTable}}",
    list(settingsTable = settingsTable)
)

settings$scoreSettings <- list()
for (i in seq_len(nrow(settingsNew))) {
    row <- as.list(settingsNew[i, ])
    row$id <- NULL
    names(row) <- tolower(names(row))
    settings$scoreSettings[[i]] <- row
}

items <- getTests()

scores <- calcScores(responses, items, settings)

sessionIds <- tapply(
    responses$session_id,
    responses$test,
    unique
)

updateScoreTable(settings$participant_id, scores, sessionIds)
