CREATE OR REPLACE FUNCTION informix.ft_migracion_ime (
  p_administrador integer,
  p_id_usuario integer,
  p_tabla varchar,
  p_transaccion varchar
)
RETURNS varchar AS
$body$
/**************************************************************************
 SISTEMA:		Sistema de Planillas
 FUNCION: 		informix.ft_migracion
 DESCRIPCION:   Funcion que gestiona las operaciones basicas (inserciones, modificaciones, eliminaciones de la tabla 'plani.tobligacion_columna'
 AUTOR: 		 (jrivera)
 FECHA:	        14-07-2014 20:28:37
 COMENTARIOS:
***************************************************************************
 HISTORIAL DE MODIFICACIONES:

 DESCRIPCION:
 AUTOR:
 FECHA:
***************************************************************************/

DECLARE

	v_nro_requerimiento    	integer;
	v_parametros           	record;
	v_id_requerimiento     	integer;
	v_resp		            varchar;
	v_nombre_funcion        text;
	v_mensaje_error         text;
	v_id_obligacion_columna	integer;
    v_registros				record;
    v_consulta				varchar;
    v_fecha_migracion		date;
    v_fecha					date;

BEGIN

    v_nombre_funcion = 'informix.ft_migracion_ime';
    v_parametros = pxp.f_get_record(p_tabla);

	/*********************************
 	#TRANSACCION:  'INF_PROCEMIGRA_UPD'
 	#DESCRIPCION:	Procesa la migracion desde informix
 	#AUTOR:		jrivera
 	#FECHA:		14-07-2014 20:28:37
	***********************************/

	if(p_transaccion='INF_PROCEMIGRA_UPD')then

        begin
        	v_resp = 'exito';
            --v_fecha = '07/11/2019'::date;
            v_fecha = now()::date;


            --raise exception 'la fecha es: %',v_fecha;


        	--migrar las tablas parametricas en orden sin fecha solo las tablas que no se actualziarn hasta la fecha actual
            for v_registros in (select *
            					from informix.tmigracion
                                where estado_reg = 'activo' and tipo= 'parametrica' and fecha_ultima_migracion < v_fecha
                                --and orden= 1
                                order by orden asc) loop
            	raise notice 'Funnnnncion:%',v_registros.nombre_funcion;

                --raise exception 'select % ( % )',v_registros.nombre_funcion ,p_id_usuario;
                execute 'select ' || v_registros.nombre_funcion || '(' || p_id_usuario || ')' into v_resp;

              --raise exception 'la respuesta es: %',v_resp;

               if (v_resp != 'exito') then

                	v_consulta = 'update informix.tmigracion
                    set fecha_ultimo_intento_migracion = ''' || v_fecha || '''::date,
                    fecha_hora_ultimo_intento = ''' || v_fecha || '''::date,
                    tipo_ultimo_resultado = ''error'',
                    fecha_mod=now(),
                    ultimo_mensaje = ''' || v_resp || '''
                    where nombre_tabla = ''' || v_registros.nombre_tabla || '''';

                    execute(v_consulta);

                	EXIT;
                else

                	execute 'update informix.tmigracion
                    set fecha_ultima_migracion =  ''' || v_fecha || '''::date,
                    fecha_ultimo_intento_migracion = ''' || v_fecha || '''::date,
                    fecha_hora_ultimo_intento = ''' || v_fecha || '''::date,
                    tipo_ultimo_resultado = ''exito'',
                    fecha_mod=now(),
                    ultimo_mensaje = ''exito''
                    where nombre_tabla = ''' || v_registros.nombre_tabla || '''';
                end if;

            end loop;


            --raise exception 'llega despues de migrar las tablas parametricas 1';
            --migrar las  tablas transaccionales en orden y por fecha desde la ultima vez que se ejecuto correctamente hasta la fecha del dia anterior
			if (v_resp = 'exito') then
                for v_registros in (select *,(v_fecha  - interval '1 day')::date as fecha_migracion_final
                                    from informix.tmigracion
                                    where estado_reg = 'activo' and tipo= 'transaccional' and fecha_ultima_migracion < (v_fecha  - interval '1 day')::date
                                    order by orden asc) loop

                    v_fecha_migracion = v_registros.fecha_ultima_migracion + interval '1 day';

                    while v_fecha_migracion <= v_registros.fecha_migracion_final loop

                    	--v_fecha_migracion = (v_fecha  - interval '1 day')::date;

                    	--raise exception 'v_fecha_migracion: %, v_registros.fecha_migracion_final: %',v_fecha_migracion,v_registros.fecha_migracion_final;

                		--execute 'select ' || v_registros.nombre_funcion || '(' || p_id_usuario || ','''|| v_fecha_migracion ||''')' into v_resp;
                       execute 'select informix.f_migra_boleto(' || p_id_usuario || ','''|| v_fecha_migracion ||''')' into v_resp;
					--	execute 'select informix.f_migra_boleto_rango_horas(' || p_id_usuario || ','''|| v_fecha_migracion ||''')' into v_resp;
                		 if (v_resp != 'exito') then
                            execute 'update informix.tmigracion
                            set fecha_ultimo_intento_migracion = ''' || v_fecha_migracion || ''',
                            fecha_hora_ultimo_intento =  ''' || v_fecha || '''::date,
                            tipo_ultimo_resultado = ''error'',
                            fecha_mod=now(),
                            ultimo_mensaje = ''' || v_resp || '''
                            where nombre_tabla = ''' || v_registros.nombre_tabla || '''';
                            EXIT;

                            --raise exception 'Entra al IF, error';
                        else
                            execute 'update informix.tmigracion
                            set fecha_ultima_migracion = ''' || v_fecha_migracion || ''',
                            fecha_ultimo_intento_migracion = ''' || v_fecha_migracion || ''',
                            fecha_hora_ultimo_intento =  ''' || v_fecha || '''::date,
                            tipo_ultimo_resultado = ''exito'',
                            fecha_mod=now(),
                            ultimo_mensaje = ''exito''
                            where nombre_tabla = ''' || v_registros.nombre_tabla ||'''';

                            --raise exception 'NO Entra al IF, exito ';
                        end if;

                        v_fecha_migracion = v_fecha_migracion + interval '1 day';

                    end loop;
                end loop;
            end if;



			--Definicion de la respuesta
			v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Proceso de migracion desde informix ejecutado con exito.');

            --Devuelve la respuesta
            return v_resp;

		end;


	else

    	raise exception 'Transaccion inexistente: %',p_transaccion;

	end if;

EXCEPTION

	WHEN OTHERS THEN
		v_resp='';
		v_resp = pxp.f_agrega_clave(v_resp,'mensaje',SQLERRM);
		v_resp = pxp.f_agrega_clave(v_resp,'codigo_error',SQLSTATE);
		v_resp = pxp.f_agrega_clave(v_resp,'procedimientos',v_nombre_funcion);
		raise exception '%',v_resp;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION informix.ft_migracion_ime (p_administrador integer, p_id_usuario integer, p_tabla varchar, p_transaccion varchar)
  OWNER TO postgres;
