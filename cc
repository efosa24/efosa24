{ FIXED [Tracking Number] : 
    MIN(
       STR([Step Order]) + '|' + [PRCS_STEP_DESC] + '|' + STR(RANK_UNIQUE([Step Order], 'asc'))
    )
}
