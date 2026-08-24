# do I want to first should check if this has been calculated before - look at scores for composites and see if these
# session ids have been used to calc the composite scores?

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

requiredTests <- c("PRFD", "PRP", "PRS")

if (
    is.null(responses) ||
        !all(requiredTests %in% unique(responses$test))
) {
    return(list())
}

# query to get test items:
items <- concerto.table.query("SELECT
    'PRFD' AS test,
    id,
    trait,
    itemDifficulty,
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
    minimumAge,
    maximumAge,
    stepDifficulty,
    stimulusId,
    stimulusOrder,
    itemOrder,
    groupId
FROM PRS_items")
