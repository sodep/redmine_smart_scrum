DROP VIEW user_stories;
CREATE VIEW user_stories AS 
select i.id as id,i.project_id as project_id,i.subject as subject,i.description,i.status_id,i.assigned_to_id,i.done_ratio,i.estimated_hours,
s.name as status_name,
cv_sprint.value as sprint,
cv_market.value as market,
cv_urgency.value as urgency,
cv_size.value as size,
cv_tech.value as tech,
u.login as login,
p.name as project_name,
i.fixed_version_id as fixed_version_id

from issues i 
join issue_statuses s on i.status_id=s.id
join projects p on p.id=i.project_id
join trackers t on t.id=i.tracker_id
left join custom_values cv_sprint on (cv_sprint.customized_id=i.id and cv_sprint.custom_field_id=(select id from custom_fields where name='Sprint'))
left join custom_values cv_market on (cv_market.customized_id=i.id and cv_market.custom_field_id=(select id from custom_fields where name='Market value'))
left join custom_values cv_urgency on (cv_urgency.customized_id=i.id and cv_urgency.custom_field_id=(select id from custom_fields where name='Urgency'))
left join custom_values cv_size on (cv_size.customized_id=i.id and cv_size.custom_field_id=(select id from custom_fields where name='Size'))
left join custom_values cv_tech on (cv_tech.customized_id=i.id and cv_tech.custom_field_id=(select id from custom_fields where name='Technical value'))
left join users u on u.id=i.assigned_to_id
where t.name='User story'
order by i.id;
