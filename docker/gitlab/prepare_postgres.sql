-- Applied to a thin clone before any testing

LOAD 'auto_explain';
ALTER SYSTEM SET auto_explain.log_min_duration='1s';
ALTER SYSTEM SET auto_explain.log_triggers='on';
ALTER SYSTEM SET auto_explain.log_buffers='on';
ALTER SYSTEM SET auto_explain.log_analyze='on';

SELECT pg_reload_conf();
