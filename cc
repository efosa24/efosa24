IF { FIXED [Tracking Number] : MAX(
     IF [Process Step] = "Investigation" THEN "Investigation"
     ELSEIF [Process Step] = "Triage complete" THEN "Triage complete"
     ELSE NULL END) } = "Investigation"
THEN "Investigation"
ELSEIF { FIXED [Tracking Number] : MAX(
     IF [Process Step] = "Triage complete" THEN "Triage complete"
     ELSE NULL END) } = "Triage complete"
THEN "Triage complete"
ELSE "Other"
END
