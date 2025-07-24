[Qualifying Flag] =
IF ([Process Step] = "Investigation" OR [Process Step] = "Triage complete")
   AND [Step] = "Triage"
THEN 1
ELSE 0
END
#####################
[Qualified Tracking Number] =
{ FIXED [Tracking Number] : MAX([Qualifying Flag]) }
###############
[Final Step Result] =
IF [Qualified Tracking Number] = 1 THEN
   IF { FIXED [Tracking Number] :
        MAX(IF [Process Step] = "Investigation" THEN 1 ELSE 0 END) } = 1
   THEN "Investigation"
   ELSE "Triage complete"
   END
ELSE NULL
END
###################
    IF 
   // Check if any row for this Tracking Number has Investigation or Triage complete 
   // AND the Step = Triage
   { FIXED [Tracking Number] : 
     MAX(
         IF ([Process Step] = "Investigation" OR [Process Step] = "Triage complete")
            AND [Step] = "Triage"
         THEN 1 
         ELSE 0 
         END
     )
   } = 1
THEN
   // Prefer "Investigation" if it's present
   IF { FIXED [Tracking Number] : 
         MAX(
             IF [Process Step] = "Investigation" THEN 1 ELSE 0 END
         ) 
      } = 1
   THEN "Investigation"
   ELSE "Triage complete"
   END
ELSE NULL
END
