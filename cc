IF { FIXED [Tracking Number] :
     MAX(
       IF [Step] = "Triage" AND [Process Step] = "Investigation"
       THEN "Investigation"
       ELSEIF [Step] = "Triage" AND [Process Step] = "Triage complete"
       THEN "Triage complete"
       ELSE NULL
     )
   } = "Investigation"
THEN "Investigation"

ELSEIF { FIXED [Tracking Number] :
         MAX(
           IF [Step] = "Triage" AND [Process Step] = "Triage complete"
           THEN "Triage complete"
           ELSE NULL
         )
       } = "Triage complete"
THEN "Triage complete"

ELSE NULL

