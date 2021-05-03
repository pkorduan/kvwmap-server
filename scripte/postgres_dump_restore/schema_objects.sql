WITH schema_objects AS(
	SELECT	'TABLE' 		objekt_typ
			,t.tablename	objekt_name
			,t.schemaname
			,s.n_live_tup::TEXT	objekt_eigenschaft
	FROM    pg_catalog.pg_tables 	t
	JOIN	pg_stat_user_tables		s ON	t.tablename=s.relname AND
											t.schemaname=s.schemaname
	UNION
	SELECT 	'VIEW'
			,v.viewname
			,v.schemaname
			,''
	FROM	pg_views 	v
	UNION
	SELECT	'PROC_FUNC_TRIGGER'
			,p.proname
			,p.pronamespace::regnamespace::TEXT
			,''
	FROM	pg_proc		p
	JOIN	pg_language	l	ON	p.prolang = l.oid
	--no procedures from extensions
	WHERE NOT EXISTS (	SELECT	1
						FROM	pg_catalog.pg_depend	d
						WHERE	d.objid = p.oid
						AND		d.classid::regclass::Text = 'pg_proc'
						AND		d.deptype IN ('e','i')
						)
	--nothing from builtin language
	AND	l.lanispl = true
	UNION
	SELECT	'MAT_VIEW'
			,m.matviewname
			,m.schemaname
			,''
	FROM	pg_matviews	m
)
,db_schemas AS(
	select s.nspname as schema,
		   u.usename as owner
	from pg_catalog.pg_namespace s
	join pg_catalog.pg_user u on u.usesysid = s.nspowner
	order by s.nspname
)

SELECT	s.owner
		,s.schema
		,t.objekt_typ
--		,count(t.objekt_name) over (partition by t.objekt_typ, s.schema ) objekt_count
		,t.objekt_name
--		,t.objekt_eigenschaft
FROM	db_schemas	s
LEFT JOIN	schema_objects	t	ON s.schema=t.schemaname
WHERE s.schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY s.schema, t.objekt_typ, t.objekt_name;
