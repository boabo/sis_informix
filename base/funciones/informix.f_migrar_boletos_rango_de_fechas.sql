CREATE OR REPLACE FUNCTION informix.f_migrar_boletos_rango_de_fechas (
  p_fecha_inicio date,
  p_fecha_fin date
)
RETURNS varchar AS
$body$
DECLARE
  v_nombre_funcion   	text;
  v_resp				varchar;

  v_fecha				date;


  
BEGIN
  v_nombre_funcion = 'informix.f_migrar_boletos_rango_de_fechas';

  	for v_fecha in (select i::date
	               from generate_series(p_fecha_inicio, p_fecha_fin - interval '0 day', '1 day'::interval) i)
    loop
    	PERFORM informix.f_migra_boleto(1,v_fecha);
    end loop;

    return 'Migración completada satisfactoriamente';
EXCEPTION
	WHEN OTHERS THEN
			--update a la tabla informix.migracion

            return 'Ha ocurrido un error en la funcion ' || v_nombre_funcion || '.';


END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION informix.f_migrar_boletos_rango_de_fechas (p_fecha_inicio date, p_fecha_fin date)
  OWNER TO postgres;
