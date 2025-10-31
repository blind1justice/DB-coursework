CREATE VIEW video_analytics AS
SELECT 
    v.id,
    v.title,
    v.description,
    v.duration,
    v.status,
    v.created_at,
    u.username as channel_name,
    u.id as channel_owner_id,
    COUNT(DISTINCT r.id) as total_reactions,
    COUNT(DISTINCT CASE WHEN r.type = 'like' THEN r.id END) as likes_count,
    COUNT(DISTINCT CASE WHEN r.type = 'dislike' THEN r.id END) as dislikes_count,
    COUNT(DISTINCT c.id) as comments_count,
    COUNT(DISTINCT pv.id) as playlists_count,
    (COUNT(DISTINCT r.id) + COUNT(DISTINCT c.id) * 2) as engagement_score
FROM Videos v
JOIN Channels ch ON v.channel_id = ch.id
JOIN Users u ON ch.user_id = u.id
LEFT JOIN Reactions r ON v.id = r.video_id
LEFT JOIN Comments c ON v.id = c.video_id
LEFT JOIN PlaylistsVideos pv ON v.id = pv.video_id
WHERE v.status = 'processed'
GROUP BY v.id, v.title, v.description, v.duration, v.status, v.created_at, u.username, u.id;

CREATE VIEW user_activity_overview AS
SELECT 
    u.id as user_id,
    u.username,
    u.email,
    u.created_at as registration_date,
    COUNT(DISTINCT ch.id) as channels_owned,
    COUNT(DISTINCT v.id) as videos_uploaded,
    COUNT(DISTINCT r.id) as reactions_given,
    COUNT(DISTINCT c.id) as comments_written,
    COUNT(DISTINCT s.id) as subscriptions_active,
    COUNT(DISTINCT p.id) as playlists_created,
    MAX(GREATEST(COALESCE(v.created_at, '1970-01-01'), 
                 COALESCE(r.created_at, '1970-01-01'),
                 COALESCE(c.created_at, '1970-01-01'))) as last_activity_date,
    CASE 
        WHEN MAX(v.created_at) >= NOW() - INTERVAL '7 days' THEN 'high'
        WHEN MAX(v.created_at) >= NOW() - INTERVAL '30 days' THEN 'medium'
        ELSE 'low'
    END as activity_level
FROM Users u
LEFT JOIN Channels ch ON u.id = ch.user_id
LEFT JOIN Videos v ON ch.id = v.channel_id
LEFT JOIN Reactions r ON u.id = r.user_id
LEFT JOIN Comments c ON u.id = c.user_id
LEFT JOIN Subscriptions s ON u.id = s.subscriber_id
LEFT JOIN Playlists p ON u.id = p.user_id
GROUP BY u.id, u.username, u.email, u.created_at;

CREATE VIEW moderation_queue AS
SELECT 
    r.id as report_id,
    r.reason,
    r.status as report_status,
    r.created_at as report_date,
    u_reporter.username as reporter_name,
    u_reporter.id as reporter_id,
    v.id as video_id,
    v.title as video_title,
    v.description as video_description,
    v.status as video_status,
    u_owner.username as video_owner,
    u_owner.id as video_owner_id,
    ch.id as channel_id,
    COUNT(DISTINCT r_similar.id) as similar_reports_count,
    ARRAY_AGG(DISTINCT r_similar.reason) FILTER (WHERE r_similar.id IS NOT NULL) as all_report_reasons,
    COUNT(DISTINCT CASE WHEN r_similar.reason IS NOT NULL THEN r_similar.reason END) as distinct_reason_types,
    (SELECT COUNT(*) FROM Reactions react WHERE react.video_id = v.id) as video_reactions_count,
    (SELECT COUNT(*) FROM Comments com WHERE com.video_id = v.id) as video_comments_count
FROM Reports r
JOIN Users u_reporter ON r.reporter_id = u_reporter.id
JOIN Videos v ON r.video_id = v.id
JOIN Channels ch ON v.channel_id = ch.id
JOIN Users u_owner ON ch.user_id = u_owner.id
LEFT JOIN Reports r_similar ON r.video_id = r_similar.video_id 
                           AND r_similar.status = 'pending'
                           AND r_similar.id != r.id
WHERE r.status = 'pending'
GROUP BY r.id, r.reason, r.status, r.created_at, u_reporter.username, u_reporter.id,
         v.id, v.title, v.description, v.status, u_owner.username, u_owner.id, ch.id;

select * from video_analytics;
select * from user_activity_overview;
select * from moderation_queue mq;