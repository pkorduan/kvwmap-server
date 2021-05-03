WITH parameters AS(
	SELECT	oid			schemaoid
			,nspname	schemaname
			,'OID'::Text searchstring
	FROM	pg_namespace
	WHERE	nspname NOT IN ('pg_catalog', 'information_schema')
)
SELECT 	'VIEW'			as objtype
		,v.viewname		as objname
		,p.schemaname
FROM	pg_views 	v
JOIN	parameters	p	on	v.schemaname = p.schemaname
WHERE	upper(v.definition) LIKE '%' || p.searchstring || '%'
UNION
SELECT	'PROC_FUNC_TRIGGER'
		,proname
		,para.schemaname
FROM	pg_proc		p
JOIN	parameters	para	ON	p.pronamespace = para.schemaoid
WHERE	upper(p.prosrc) LIKE '%' || para.searchstring || '%'
UNION
SELECT	'MAT_VIEW'
		,m.matviewname
		,p.schemaname
FROM	pg_matviews	m
JOIN	parameters	p	ON	m.schemaname = p.schemaname
WHERE	upper(m.definition) LIKE '%' || p.searchstring || '%'

ORDER by 3,1,2
;
