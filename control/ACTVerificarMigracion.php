<?php
/**
*@package pXP
*@file gen-ACTAgencia.php
*@author  (Ismael Valdivia)
*@date 20-08-2020 12:00:00
*@description Clase que recibe los parametros enviados por la vista para mandar a la capa de Modelo
*/

class ACTVerificarMigracion extends ACTbase{

	function verificarMigracion(){
		$this->objFunc=$this->create('MODVerificarMigracion');
		$this->res=$this->objFunc->verificarMigracion($this->objParam);
		$this->res->imprimirRespuesta($this->res->generarJson());
	}

}

?>
