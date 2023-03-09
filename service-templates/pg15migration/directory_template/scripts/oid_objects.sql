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
AND     upper(v.definition) NOT LIKE '%AS OID%'
UNION
SELECT	'PROC_FUNC_TRIGGER'
		,proname
		,para.schemaname
FROM	pg_proc		p
JOIN	parameters	para	ON	p.pronamespace = para.schemaoid
JOIN    pg_language     l	ON	p.prolang = l.oid
WHERE	upper(p.prosrc) LIKE '%' || para.searchstring || '%'

--no procedures from extensions
AND NOT EXISTS (	SELECT  1
                        FROM    pg_catalog.pg_depend    d
                        WHERE   d.objid = p.oid
                        AND     d.classid::regclass::Text = 'pg_proc'
                        AND     d.deptype IN ('e','i')
                 )
--nothing from builtin language
AND     l.lanispl = true

UNION
SELECT	'MAT_VIEW'
		,m.matviewname
		,p.schemaname
FROM	pg_matviews	m
JOIN	parameters	p	ON	m.schemaname = p.schemaname
WHERE	upper(m.definition) LIKE '%' || p.searchstring || '%'

ORDER by 3,1,2
;
