"First: " + 
{ FIXED [Complaint Number]: 
    MIN(IF [PRCS_STEP_START_DTTM] = 
        { FIXED [Complaint Number]: MIN([PRCS_STEP_START_DTTM]) }
    THEN [PRCS_STEP_DESC] END)
} + 
" | " +
ATTR([PRCS_STEP_DESC]) + " → " +
IF LOOKUP(ATTR([Complaint Number]), 0) <> LOOKUP(ATTR([Complaint Number]), 1) THEN
    "Closed"
ELSE
    LOOKUP(ATTR([PRCS_STEP_DESC]), 1)
END
#################

IF LOOKUP(ATTR([Complaint Number]), 0) <> LOOKUP(ATTR([Complaint Number]), 1) THEN
    "Closed"
ELSE
    LOOKUP(ATTR([PRCS_STEP_DESC]), 1)
END
###########
ATTR([PRCS_STEP_DESC]) + " → " +
IF LOOKUP(ATTR([Complaint Number]), 0) <> LOOKUP(ATTR([Complaint Number]), 1) THEN
    "Closed"
ELSE
    LOOKUP(ATTR([PRCS_STEP_DESC]), 1)
END
