IF 
{ FIXED [Tracking Number] : 
    MAX(
        IF [Step] = "Triage" AND [Process Step] = "Investigation" THEN 2
        ELSEIF [Step] = "Triage" AND [Process Step] = "Triage complete" THEN 1
        ELSE 0
        END
    )
} = 2 THEN "Investigation"

ELSEIF 
{ FIXED [Tracking Number] : 
    MAX(
        IF [Step] = "Triage" AND [Process Step] = "Triage complete" THEN 1
        ELSE 0
        END
    )
} = 1 THEN "Triage complete"

ELSE NULL
