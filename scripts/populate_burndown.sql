SELECT now() INTO @timeStamp;

SELECT @timeStamp as 'Current timestamp'; 

INSERT INTO burndown_data 
    (query_date, sprint, responsible, remaining_hours)
SELECT @timeStamp, t.sprint, 
t.responsible, 
(t.estimated_hours - t.estimated_hours*t.done_ratio/100) AS remaining_hours
FROM tasks AS t
JOIN issue_statuses ON t.status_id = issue_statuses.id
WHERE issue_statuses.is_closed = 0 
AND t.sprint IS NOT NULL 
AND t.responsible IS NOT NULL
AND t.estimated_hours IS NOT NULL; 

