<?php
/**
*@package pXP
*@file gen-MODVerificarMigracion.php
*@author  (Ismael Valdivia)
*@date 20-08-2020 12:00:00
*@description Clase que envia los parametros requeridos a la Base de datos para la ejecucion de las funciones, y que recibe la respuesta del resultado de la ejecucion de las mismas
*/

class MODVerificarMigracion extends MODbase{

	function __construct(CTParametro $pParam){
		parent::__construct($pParam);
	}

	function verificarMigracion(){
		//Definicion de variables para ejecucion del procedimientp
		$this->procedimiento='informix.ft_verificar_migracion_informix';
		$this->transaccion='INF_VERIFI_IME';
		$this->tipo_procedimiento='IME';//tipo de transaccion

		$this->setParametro('fecha','fecha','varchar');
		//Ejecuta la instruccion
		$this->armarConsulta();
		$this->ejecutarConsulta();

		//Devuelve la respuesta
		return $this->respuesta;
	}

}
?>
