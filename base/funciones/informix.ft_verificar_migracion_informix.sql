CREATE OR REPLACE FUNCTION informix.ft_verificar_migracion_informix (
  p_administrador integer,
  p_id_usuario integer,
  p_tabla varchar,
  p_transaccion varchar
)
RETURNS varchar AS
$body$
/**************************************************************************
 SISTEMA:		Sistema de Planillas
 FUNCION: 		informix.ft_verificar_migracion_informix
 DESCRIPCION:   Verifica si en la migracion hubo algun error
 AUTOR: 		Ismael Valdivia
 FECHA:	        20/08/2020
 COMENTARIOS:
***************************************************************************/


DECLARE

	v_nro_requerimiento    	integer;
	v_parametros           	record;
	v_id_requerimiento     	integer;
	v_resp		            varchar;
	v_nombre_funcion        text;
	v_mensaje_error         text;

    v_datos_migracion		record;
    v_mensaje_correo      varchar;
    v_texto				varchar;
    v_correos				varchar;
    v_existe_error		integer;
    v_mensaje				varchar;

BEGIN

    v_nombre_funcion = 'informix.ft_verificar_migracion_informix ';
    v_parametros = pxp.f_get_record(p_tabla);

	/*********************************
 	#TRANSACCION:  'INF_VERIFI_IME'
 	#DESCRIPCION:	Verifica si hubo algun error en la migracion
 	#AUTOR:		Ismael Valdivia
 	#FECHA:		20/08/2020
	***********************************/

	if(p_transaccion='INF_VERIFI_IME')then

        begin

     		 v_correos = 'gvelasquez@boa.bo,ismael.valdivia@boa.bo';

                /*Verificamos si existe alguna funcion con error*/
                select count(migra.id_migracion)
                       into v_existe_error
                from informix.tmigracion migra
                where migra.estado_reg = 'activo' and migra.tipo_ultimo_resultado = 'error';

           IF (v_existe_error > 0) then

            for v_datos_migracion in (
                                      select list(migra.ultimo_mensaje) as ultimo_mensaje,
                                             list(migra.nombre_funcion) as nombre_funcion,
                                             list(migra.tipo) as tipo
                                      from informix.tmigracion migra
                                      where migra.estado_reg = 'activo' and migra.tipo_ultimo_resultado = 'error'
                                  )
              loop
                          v_mensaje_correo := '<p><b>Error(es):</b> '||v_datos_migracion.ultimo_mensaje||'.</p>
                                               <p><b>Funcion(es):</b> '||v_datos_migracion.nombre_funcion||'.</p>
                                               <p><b>Tipo:</b> '||v_datos_migracion.tipo||'.</p>';

              end loop;
                           INSERT INTO param.talarma (descripcion,
                                                      acceso_directo,
                                                      fecha,
                                                      id_funcionario,
                                                      tipo,
                                                      titulo,
                                                      id_usuario,
                                                      titulo_correo,
                                                      correos,
                                                      documentos,
                                                      estado_envio,
                                                      estado_comunicado,
                                                      pendiente,
                                                      estado_notificacion,
                                                      id_usuario_reg
                                                      )
                                                      values
                                                     (v_mensaje_correo,
                                                     NULL,
                                                     now()::date,
                                                     null,
                                                     'notificacion',
                                                     'Error de Migracion',
                                                     p_id_usuario,
                                                     'Error en la funcion de Migracion Informix',
                                                     v_correos,
                                                     NULL,
                                                     'exito',
                                                     'borrador',
                                                     'no',
                                                     NULL,
                                                     p_id_usuario
                                                     );
               v_mensaje = 'Se envió correo electronico con el detalle del error';


            else
               v_mensaje = 'No se encontro ningun Error';

            end if;

            v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Proceso de migracion desde informix ejecutado con exito.');
            v_resp = pxp.f_agrega_clave(v_resp,'mensaje',v_mensaje);
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

ALTER FUNCTION informix.ft_verificar_migracion_informix (p_administrador integer, p_id_usuario integer, p_tabla varchar, p_transaccion varchar)
  OWNER TO postgres;
