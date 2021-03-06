/*
*Hector Jesus De La Garza Ponce 	619971
*Oziel Alonzo Garza Lopez 			805074

*Libreria tablasVarProc.c
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tablasVarProc.h"
#include "uthash.h"

/*
* Función: agregarVariablesLocales
* Parámetros: directorioObjetos *objetos, char *objeto, char *funcion, char *nombre, unsigned short tipo, unsigned long direccion
* Descripción: Funcion encargada de agregar al directorio de variables globales de una funcion una nueva variable,
			   y si esta ya esta declarada marcar el error correspondiente
* Salida: Regresa un directorioObjetos actualizado con la nueva variable insertada
*/
directorioObjetos* agregarVariablesLocales(directorioObjetos *objetos, char *objeto, char *funcion, char *nombre, unsigned short tipo, unsigned long direccion) {
		
		//Variables auxiliares
		directorioObjetos *exiteObjeto;
		directorioProcedimientos *existeProcedimiento;
		directorio *temp;

		//Buscar el objeto en el directorio
		HASH_FIND_STR(objetos, objeto, exiteObjeto);
		if (exiteObjeto) {
				//Buscar la funcion en el directorio
				HASH_FIND_STR(exiteObjeto->procedimientos, funcion, existeProcedimiento);
				if (existeProcedimiento) {
					//Checar si la variable ya existe
					HASH_FIND_STR(existeProcedimiento->variablesLocales, nombre, temp);
					if (temp==NULL) {
							//Agregar la nueva variable al directorio
							temp = (directorio*)malloc(sizeof(directorio));
							strcpy(temp->nombre, nombre);
							temp->tipo = tipo;
							temp->direccion = direccion;
							HASH_ADD_STR(existeProcedimiento->variablesLocales, nombre, temp);  
							return objetos;   
					} else {
							printf("Error Variable %s ya esta delcarada \n", nombre);
							exit(1);
					}
				} else {
					printf("Error Funcion %s no se encuentra declarada \n", funcion);
					exit(1);
				}
		} else {
			printf("Error Clase %s no se encuentra declarada \n", objeto);
			exit(1);
		}
}

/*
* Función: buscarVariablesLocales
* Parámetros: directorioObjetos *objetos, char *objeto, char *funcion, char *nombre
* Descripción: Funcion encargada de buscar en la tabla de variables de una funcion, y regresa solo
			   el directorio de la variable de la variable solicitada, si no se encuentra marcar un error
* Salida: Regresa un directorio el cual contiene la variable buscada
*/
directorio* buscarVariablesLocales(directorioObjetos *objetos, char *objeto, char *funcion, char *nombre) {
		
		//Variables auxiliares
		directorioObjetos *exiteObjeto;
		directorioProcedimientos *existeProcedimiento;
		directorio *temp;

		//Buscar el objeto en el directorio
		HASH_FIND_STR(objetos, objeto, exiteObjeto);
		if (exiteObjeto) {
				//Buscar la funcion en el directorio
				HASH_FIND_STR(exiteObjeto->procedimientos, funcion, existeProcedimiento);
				if (existeProcedimiento) {
					//Checar si la variable ya existe
					HASH_FIND_STR(existeProcedimiento->variablesLocales, nombre, temp);
					if (temp == NULL) {
						//Primero buscamos en nuestra variables locales, si es null el resultado debemos buscar en globales
						return NULL;
					} else {
							return temp;
					}
				} else {
					printf("Error Funcion: %s no declarada\n", funcion);
					exit(1);
				}
		} else {
			printf("Error Clase: %s no declarada\n", objeto);
			exit(1);
		}
}

/*
* Función: agregarVariablesObjeto
* Parámetros: directorioObjetos *objetos, char *objeto, char *funcion, char *nombre
* Descripción: Funcion para agregar los objetos locales al directorio de funciones especificado
			   marcando con un error si la variable ya fue declarada
* Salida: Regresa un directorioObjetos con los nuevos datos actualizados
*/
directorioObjetos* agregarVariablesObjeto(directorioObjetos *objetos, char *objetoActual, char *funcionActual, char *nombreVariable, char *nombreClase) {
		
		//Variables auxiliares
		directorio *temp;
		directorioObjetos *exiteObjeto;
		directorioProcedimientos *existeProcedimiento;

		//Buscar el objeto en el directorio
		HASH_FIND_STR(objetos, objetoActual, exiteObjeto);
		if (exiteObjeto) {
				//Buscar la funcion en el directorio
				HASH_FIND_STR(exiteObjeto->procedimientos, funcionActual, existeProcedimiento);
				if (existeProcedimiento) {
					//Checar si la variable ya existe
					HASH_FIND_STR(existeProcedimiento->variablesLocales, nombreVariable, temp);
					if (temp==NULL) {
							//Agregar la nueva variable al directorio
							temp = (directorio*)malloc(sizeof(directorio));
							strcpy(temp->nombre, nombreVariable);
							temp->tipo = 4;
							temp->direccion = -1;
							strcpy(temp->clase, nombreClase);
							HASH_ADD_STR(existeProcedimiento->variablesLocales, nombre, temp);  
							return objetos;   
					} else {
							printf("Error Variable %s ya esta delcarada \n", nombreVariable);
							exit(1);
					}
				} else {
					printf("Error Funcion %s no se encuentra declarada \n", funcionActual);
					exit(1);
				}
		} else {
			printf("Error Clase %s no se encuentra declarada \n", objetoActual);
			exit(1);
		}
}

/*
* Función: agregarParametros
* Parámetros: directorioObjetos *objetos, char *objeto, char *funcion, int tipo, int cantidadParametros, int direccionParametros
* Descripción: Funcion encargada de agregar los parametros a una funcion dentro del objeto seleccionado
* Salida: Regresa un directorioObjetos con los nuevos datos actualizados
*/
directorioObjetos* agregarParametros(directorioObjetos *objetos, char *objeto, char *funcion, int tipo, int cantidadParametros, int direccionParametros) {
		
		//Variables auxiliares
		directorioObjetos *exiteObjeto;
		directorioProcedimientos *existeProcedimiento;
		directorioParametros *temp;

		//Buscar el objeto en el directorio
		HASH_FIND_STR(objetos, objeto, exiteObjeto);
		if (exiteObjeto) {
				//Buscar la funcion en el directorio
				HASH_FIND_STR(exiteObjeto->procedimientos, funcion, existeProcedimiento);
				if (existeProcedimiento) {
					//Checar si la variable ya existe
					HASH_FIND_INT(existeProcedimiento->parametros, &cantidadParametros, temp);
					if (temp==NULL) {
							//Agregar la nueva variable al directorio de parametros
							temp = (directorioParametros*)malloc(sizeof(directorioParametros));
							temp->numeroParametro = cantidadParametros;
							temp->tipo = tipo;
							temp->direccion = direccionParametros;
							HASH_ADD_INT(existeProcedimiento->parametros, numeroParametro, temp);
							return objetos;   
					} else {
							printf("Error al momento de grabar contadores erroneo\n");
							exit(1);
					}
				} else {
					printf("Error Funcion %s no se encuentra declarada \n", funcion);
					exit(1);
				}
		} else {
			printf("Error Clase %s no se encuentra declarada \n", objeto);
			exit(1);
		}
}

/*
* Función: checarParametro
* Parámetros: directorioObjetos *objetos, char *objeto, char *funcion, int tipo, int cantidadParametros, int direccionParametros
* Descripción: Funcion encargada de verificar que una variable o dato corresponda con el tipo de parametro de una funcion
			   de coincidir regresara la direccion del parametro para ser igualado a la variable o dato
* Salida: Regresa la direccion de parametro, si no son del mismo tipo marcara error
*/
int checarParametro(directorioObjetos *objetos, char *objeto, char *funcion, int numeroParametro, int tipo) {
		
		//Variables auxiliares
		directorioObjetos *exiteObjeto;
		directorioProcedimientos *existeProcedimiento;
		directorioParametros *temp;

		//Buscar el objeto en el directorio
		HASH_FIND_STR(objetos, objeto, exiteObjeto);
		if (exiteObjeto) {
				//Buscar la funcion en el directorio
				HASH_FIND_STR(exiteObjeto->procedimientos, funcion, existeProcedimiento);
				if (existeProcedimiento) {
					//Checar si la variable ya existe
					HASH_FIND_INT(existeProcedimiento->parametros, &numeroParametro, temp);
					if (temp == NULL) {
						//Marcar error si la variable no tiene ninguna relacion con el parametro
						printf("Error Funcion: %s no contiene el parametro numero %i \n", funcion, numeroParametro);
						exit(1);
					} else {
						//Checar que los tipos de datos sean iguales
						if (temp->tipo != tipo){
							//El dato no es el declarado anteriormente
							printf("Error Funcion: %s el parametro # %i no concuerda con el declarado \n", funcion, numeroParametro);
							exit(1);
						} else {
							//Valor es compatible
							return temp->direccion;
						}
					}
				} else {
					printf("Error Funcion: %s no declarada\n", funcion);
					exit(1);
				}
		} else {
			printf("Error Clase: %s no declarada\n", objeto);
			exit(1);
		}
}

/*
* Función: agregarVariablesGlobales
* Parámetros: directorioObjetos *objetos, char *objeto, char *nombre, unsigned short tipo, unsigned long direccion
* Descripción: Funcion para agregar las variables globales al objeto que se le llamo.
* Salida: Regresa el directorioObjetos con la nueva variable global ya insertada en el directorio
*/
directorioObjetos* agregarVariablesGlobales(directorioObjetos *objetos, char *objeto, char *nombre, unsigned short tipo, unsigned long direccion) {
	   
		//Variables auxiliares
		directorioObjetos *existe;
		directorio *temp;

		//Buscar el objeto en el directorio
		HASH_FIND_STR(objetos, objeto, existe); 
		if (existe) {
				//Checar si la variable ya existe
				HASH_FIND_STR(existe->variablesGlobales, nombre, temp);
				if (temp==NULL) {
						//Agregar la nueva variable al directorio
						temp = (directorio*)malloc(sizeof(directorio));
						strcpy(temp->nombre, nombre);
						temp->tipo = tipo;
						temp->direccion = direccion;
						HASH_ADD_STR(existe->variablesGlobales, nombre, temp);  
						return objetos;   
				} else {
						printf("Error Variable %s ya esta delcarada \n", nombre);
						exit(1);
				}
		} else {
				printf("Error Clase %s no se encuentra declarada \n", objeto);
				exit(1);
		}
}

/*
* Función: buscarVariablesGlobales
* Parámetros: directorioObjetos *objetos, char *objeto, char *nombre
* Descripción: Funcion para buscar en la tabla de variables globales de funcion, solo regresa el directorio de la variable para ser usada
* Salida: Regresa el directorio de la variable para poder tener acceso a todos sus atributos
*/
directorio* buscarVariablesGlobales(directorioObjetos *objetos, char *objeto, char *nombre) {
		
		//Variables auxiliares
		directorioObjetos *existe;
		directorio *temp;

		//Buscar el objeto en el directorio
		HASH_FIND_STR(objetos, objeto, existe); 
		if (existe) {
				//Checar si la variable ya existe
				HASH_FIND_STR(existe->variablesGlobales, nombre, temp);
				//Si ya existe manejar el error y terminar compilacion
				if (temp == NULL) {
					printf("Error Variable %s no esta delcarada \n", nombre);
					exit(1);
				} else {
					//Si la variable existe regresar el directorio de la variable
					return temp;
				}
		} else {
			printf("Error Clase %s no se encuentra declarada \n", objeto);
			exit(1);
		}
}

/*
* Función: agregarVariablesRetorno
* Parámetros: directorio *retornos, char *nombre, unsigned short tipo, int direccion
* Descripción: Funcion para agregar las variables globales (retorno) al directorio de retornos, si esta ya estaba ignora la insercion
* Salida: Regresa el directorio de retornos con la nueva variable ya agregada
*/
directorio* agregarVariablesRetorno(directorio *retornos, char *nombre, unsigned short tipo, int direccion){
		
		//Variable ausxiliar
		directorio *temp;

		//Buscar la constante en el directorio
		HASH_FIND_STR(retornos, nombre, temp);  
		if (temp==NULL) {
				//Agregar la nueva constante al directorio
				temp = (directorio*)malloc(sizeof(directorio));
				strcpy(temp->nombre, nombre);
				temp->direccion = direccion;
				temp->tipo = tipo;
				HASH_ADD_STR(retornos, nombre, temp);  
				return retornos;    
		}else {
			//No hacer nada, porque ya esta grabada
			return retornos;
		}
}

/*
* Función: buscarVariablesRetorno
* Parámetros: directorio *retornos, char *nombre
* Descripción: Funcion para buscar en la tabla de retorno globales de funcion, solo regresa el directorio de la variable para ser usada
* Salida: Regresa el directorio de retornos de la variable para poder accesar todos sus atributos
*/
directorio* buscarVariablesRetorno(directorio *retornos, char *nombre){	
		//Variable auxiliar
		directorio *temp;

		//Buscar el objeto en el directorio
		HASH_FIND_STR(retornos, nombre, temp);  
		if (temp==NULL) {
			//SI no existe solo regresamos NULL
			return NULL;
		} else {
			//Regresamos al apuntador al directorio del objeto
			return temp;
		}       
}

/*
* Función: agregarFuncion
* Parámetros: directorioObjetos *objetos, char *objeto, char *nombre
* Descripción: Funcion para agregar las funciones al directorio de objetos.
* Salida: Regresa el directorioObjetos con la nueva funcion del objeto
*/
directorioObjetos* agregarFuncion(directorioObjetos *objetos, char *objeto, char *nombre) {
		
		//Variables auxiliares
		directorioProcedimientos *temp;
		directorioObjetos *existe;  

		//Buscar el objeto en el directorio
		HASH_FIND_STR(objetos, objeto, existe);  
		if (existe) {
				//Checar si la funcion ya existe
				HASH_FIND_STR(existe->procedimientos, nombre, temp);
				if (temp==NULL) {
						//Agregar la nueva funcion al directorio
						temp = (directorioProcedimientos*)malloc(sizeof(directorioProcedimientos));
						strcpy(temp->nombre, nombre);                      
						temp->variablesLocales = NULL;
						HASH_ADD_STR(existe->procedimientos, nombre, temp); 
						return objetos;   
				} else {
					printf("Error Funcion %s ya se encuentra declarada \n", nombre);
					exit(1);
				}
		} else {
				printf("Error Clase %s no se encuentra declarada \n", objeto);
				exit(1);
		}
}

/*
* Función: buscarFuncion
* Parámetros: directorioObjetos *objetos, char *objeto, char *nombre
* Descripción: Funcion para buscar una funcion en el directorio del objeto
* Salida: Regresa el directorioProcedimientos de la funcion encontrada
*/
directorioProcedimientos* buscarFuncion(directorioObjetos *objetos, char *objeto, char *nombre) {
		
		//Variables auxiliares
		directorioProcedimientos *temp;
		directorioObjetos *existe;

		//Buscar el objeto en el directorio
		HASH_FIND_STR(objetos, objeto, existe);  
		if (existe) {
				//Checar si la funcion ya existe
				HASH_FIND_STR(existe->procedimientos, nombre, temp);
				if (temp == NULL) {
					//La funcion no esta declarada en el objeto
					printf("Error Funcion %s no declarada\n", nombre);
					exit(1);
				} else {
					//Si existe regresamos el directorioProcedmientos
					return temp;
				}
		} else {
			printf("Clase: %s Funcion: %s\n",objeto, nombre);
			printf("Error Clase %s no se encuentra declarada \n", objeto);
			exit(1);
		}
}

/*
* Función: herenciaObjetos
* Parámetros: directorioObjetos *objetos, char *nombreHijo, char *nombrePadre
* Descripción: Funcion para heredar la estructura y variables de objetos
* Salida: Regresa una copia de directorioObjetos del padre y la asocia a un hijo
*/
directorioObjetos* herenciaObjetos(directorioObjetos *objetos, char *nombreHijo, char *nombrePadre){
	//Variable auxiliar
	directorioObjetos *objetoPadre;
	directorioObjetos *objetoHijo;
	directorio *globalesHeredadas;
	directorioProcedimientos *funcionesHeredadas;

	//variables para el recorrido de las funciones
	directorioObjetos *objetosTemp;
	directorioProcedimientos *funcionesTemp;
	directorio *variablesTemp;
	directorioParametros *parametrosNew;

	//Variables nuevas para herencia
	directorioObjetos *objetosNew;
	directorioProcedimientos *funcionesNew;
	directorio *variablesNew;
	directorioParametros *parametrosTemp;

	//Obtenemos la clase padre de la que hereda el objeto
	objetoPadre = buscarObjeto(objetos, nombrePadre);

	//Creamos el objetoHijo y rellenamos sus datos
	objetoHijo = (directorioObjetos*)malloc(sizeof(directorioObjetos));
	strcpy(objetoHijo->nombre, nombreHijo);

	//Agregamos las variables decimales
	for(variablesTemp = objetoPadre->variablesGlobales; variablesTemp != NULL; variablesTemp=(directorio*)(variablesTemp->hh.next)){

		//Agregar la nueva variable al directorio
		variablesNew = (directorio*)malloc(sizeof(directorio));

		//Copiado de datos
		strcpy(variablesNew->nombre, variablesTemp->nombre);
		variablesNew->tipo = variablesTemp->tipo;
		variablesNew->direccion = variablesTemp->direccion;

		if (variablesTemp->dimensionada != 0) {
			variablesNew->dimensionada = variablesTemp->dimensionada;
			variablesNew->m1 = variablesTemp->m1;
			variablesNew->tamanio = variablesTemp->tamanio;
			variablesNew->lsuperior1 = variablesTemp->lsuperior1;
			variablesNew->lsuperior2 = variablesTemp->lsuperior2;
		}

		//Agregamos el apuntador
		HASH_ADD_STR(objetoHijo->variablesGlobales, nombre, variablesNew);
	}

	//Agregamos las funciones
	for(funcionesTemp = objetoPadre->procedimientos; funcionesTemp != NULL; funcionesTemp=(directorioProcedimientos*)(funcionesTemp->hh.next)){

		//Cramos la nueva funcion para agregar
		funcionesNew = (directorioProcedimientos*)malloc(sizeof(directorioProcedimientos));

		//Rellenaremos de la funcion sus locales
		for(variablesTemp = funcionesTemp->variablesLocales; variablesTemp != NULL; variablesTemp=(directorio*)(variablesTemp->hh.next)){

			//Agregar la nueva variable al directorio
			variablesNew = (directorio*)malloc(sizeof(directorio));

			//Copiado de datos
			strcpy(variablesNew->nombre, variablesTemp->nombre);
			variablesNew->tipo = variablesTemp->tipo;
			variablesNew->direccion = variablesTemp->direccion;

			if (variablesTemp->dimensionada != 0) {
				variablesNew->dimensionada = variablesTemp->dimensionada;
				variablesNew->m1 = variablesTemp->m1;
				variablesNew->tamanio = variablesTemp->tamanio;
				variablesNew->lsuperior1 = variablesTemp->lsuperior1;
				variablesNew->lsuperior2 = variablesTemp->lsuperior2;
			}

			//Agregarlo a la nueva estructura
			HASH_ADD_STR(funcionesNew->variablesLocales, nombre, variablesNew);
		}

		//Rellenamos la funcion sus parametros
		for(parametrosTemp = funcionesTemp->parametros; parametrosTemp != NULL; parametrosTemp=(directorioParametros*)(parametrosTemp->hh.next)){

			//Agregar la nueva variable al directorio
			parametrosNew = (directorioParametros*)malloc(sizeof(directorioParametros));

			//Copiado de datos
			parametrosNew->numeroParametro = parametrosTemp->numeroParametro;
			parametrosNew->tipo = parametrosTemp->tipo;
			parametrosNew->direccion = parametrosTemp->direccion;

			//Agregarlo a la nueva estructura
			HASH_ADD_INT(funcionesNew->parametros, numeroParametro, parametrosNew);
		}
		
		//LLenamos los datos
		strcpy(funcionesNew->nombre, funcionesTemp->nombre);
		funcionesNew->regresa = funcionesTemp->regresa;
		funcionesNew->permiso = funcionesTemp->permiso;
		funcionesNew->direccionCuadruplo = funcionesTemp->direccionCuadruplo;

		//Agregamos los datos a las funciones 
		//Copiado de funciones completado
		HASH_ADD_STR(objetoHijo->procedimientos, nombre, funcionesNew);
	}

	//Agregamos el nuevo objeto con sus variables
	HASH_ADD_STR(objetos, nombre, objetoHijo);

	//Validamos que se haya hecho una insercion correcta si no marcar error
	buscarObjeto(objetos, nombreHijo);

	return objetos;
}

/*
* Función: agregarObjeto
* Parámetros: directorioObjetos *objetos, char *nombre
* Descripción: Funcion para agregar objetos al directorioObjetos (clases)
* Salida: Regresa el directorioObjetos con el nuevo objeto asociado a ella
*/
directorioObjetos* agregarObjeto(directorioObjetos *objetos, char *nombre){
		//Variable auxiliar
		directorioObjetos *temp;

		//Buscar el objeto en el directorio
		HASH_FIND_STR(objetos, nombre, temp);  
		if (temp==NULL) {
				//Agregar el nuevo objeto al directorio
				temp = (directorioObjetos*)malloc(sizeof(directorioObjetos));
				strcpy(temp->nombre, nombre);
				temp->variablesGlobales = NULL;
				temp->procedimientos = NULL;
				HASH_ADD_STR(objetos, nombre, temp);  
				return objetos;    
		} else {		
			printf("Error Clase %s ya se encuentra declarada \n", nombre);
			exit(1);
		}       
}

/*
* Función: buscarObjeto
* Parámetros: directorioObjetos *objetos, char *nombre
* Descripción: Funcion encargada de buscar el objeto seleccionado, si no marcar error
* Salida: Regresa el directorioObjetos del objeto solicitado 
*/
directorioObjetos* buscarObjeto(directorioObjetos *objetos, char *nombre){
		
		//Variable auxiliar
		directorioObjetos *temp;

		//Buscar el objeto en el directorio
		HASH_FIND_STR(objetos, nombre, temp);  
		if (temp==NULL) {
			//Si no existe el objeto marcar error
			printf("Error Clase %s no se encuentra declarada \n", nombre);
			exit(1);
		} else {
			//Regresamos al apuntador al directorio del objeto
			return temp;
		}       
}

/*
* Función: agregarConstante
* Parámetros: directorio *constantes, char *nombre, unsigned short tipo, int direccion
* Descripción: Funcion para agregar una constante a la tabla de constantes y asignarle una direccion si ya esta en la tabla la ignora
* Salida: Regresa el directorio de constantes ya actualizado
*/
directorio* agregarConstante(directorio *constantes, char *nombre, unsigned short tipo, int direccion){
		
		//Variable ausxiliar
		directorio *temp;

		//Buscar la constante en el directorio
		HASH_FIND_STR(constantes, nombre, temp);  
		if (temp==NULL) {
				//Agregar la nueva constante al directorio
				temp = (directorio*)malloc(sizeof(directorio));
				strcpy(temp->nombre, nombre);
				temp->direccion = direccion;
				temp->tipo = tipo;
				HASH_ADD_STR(constantes, nombre, temp);  
				return constantes;    
		}else {
			//No hacer nada, porque ya esta grabada
			return constantes;
		}
}

/*
* Función: buscarConstante
* Parámetros: directorio *constantes, char *nombre
* Descripción: Funcion encargada de buscar una constante en el directorio de constantes, si no la encuentra regresa NULL
* Salida: Regresa el directorio de la variable con todos sus atributos
*/
directorio* buscarConstante(directorio *constantes, char *nombre){
		
		//Variable auxiliar
		directorio *temp;

		//Buscar el objeto en el directorio
		HASH_FIND_STR(constantes, nombre, temp);  
		if (temp==NULL) {
			//SI no existe solo regresamos NULL
			return NULL;
		} else {
			//Regresamos al apuntador al directorio del objeto
			return temp;
		}       
}

/*
* Función: imprimirObjetos
* Parámetros: directorioObjetos *objetos, directorio *constantes, directorio *retornos
* Descripción: Funcion encargada de desplegar los elementos del directorio de objetos asi como los elementos
			   del directorio de funciones y variables que esten asociados
* Salida: ninguna
*/
void imprimirObjetos(directorioObjetos *objetos, directorio *constantes, directorio *retornos) {
			
			directorioObjetos *o;
			directorioProcedimientos *s;
			directorio *p;
			directorioParametros *param;

			//Imprimir variables constantes
			printf("\nVariable constantes\n");
			for(p=constantes; p!= NULL; p=(struct directorio*)(p->hh.next)) {
					printf("Nombre de la variable: %s , tipo: %i , direccion: %lu \n", p->nombre, p->tipo, p->direccion);
			}

			//Imprimir variables retorno
			printf("\nVariable retorno\n");
			for(p=retornos; p!= NULL; p=(struct directorio*)(p->hh.next)) {
					printf("Nombre de la variable: %s , tipo: %i , direccion: %lu \n", p->nombre, p->tipo, p->direccion);
			}

			//Imprimir tabla de objetos
			for(o = objetos; o != NULL; o=(directorioObjetos*)(o->hh.next)){
				printf("\nNombre del objeto: %s \n", o->nombre);
				//Imprimir variables globales (main)
				for(p=o->variablesGlobales; p!= NULL; p=(struct directorio*)(p->hh.next)) {
						printf("Sus variables globales son \n");
						printf("Nombre de la variable: %s , tipo: %i , direccion: %lu \n", p->nombre, p->tipo, p->direccion);
				}

				//Imprimir procedimientos del objeto y sus tablas de variables
				printf("\nSus procedimientos son: \n");
				for(s=o->procedimientos; s!= NULL; s=(directorioProcedimientos*)(s->hh.next)) {
						printf("Nombre del procedimiento: %s \n", s->nombre);

						printf("Sus parametros son \n");
						for(param = s->parametros; param != NULL; param =(struct directorioParametros*)(param->hh.next)) {
							printf("Numero de parametro: %i , tipo: %i \n", param->numeroParametro, param->tipo);
						}

						printf("Sus variables son \n");
						for(p=s->variablesLocales; p!= NULL; p=(struct directorio*)(p->hh.next)) {
								printf("Nombre de la variable: %s , tipo: %i , direccion: %lu \n", p->nombre, p->tipo, p->direccion);
						}
				}
			}
}

/*
* Función: generarDatos
* Parámetros: directorioObjetos *objetos, directorio *constantes, directorio *retornos
* Descripción: Funcion para escribir en un archivo los elementos del directorio de objetos
			   asi como los elementos del directorio de funciones y variables que esten asociados. 
			   El archivo se almacenará en disco.
* Salida: ninguna
*/
void generarDatos(directorioObjetos *objetos, directorio *constantes, directorio *retornos) {
	
	//Estructuras auxiliares
	directorioObjetos *o;
	directorioProcedimientos *s;
	directorio *p;
	directorio *c;
	directorioParametros *dp;
	
	//Crear el archivo y guardarlo en carpeta raiz
	FILE *fp;
	fp = fopen("GAlaDos-MaqVirtual/obj/datos.txt", "w");
	fprintf(fp,  "<?xml version='1.0'?>\n");
	fprintf(fp,  "<GALaDos>\n");

			//Imprimir tabla de objetos
			for(o = objetos; o != NULL; o=(directorioObjetos*)(o->hh.next)){
				fprintf(fp,  "<%s>\n", o->nombre);
						

				//Imprimir variables globales (main)
				fprintf(fp,  "<variablesGlobales>\n");
				for(p=o->variablesGlobales; p!= NULL; p=(struct directorio*)(p->hh.next)) {						
							fprintf(fp,  "<variableGlobal>\n");
							fprintf(fp,  "<direccion>%lu</direccion>\n", p->direccion);
							fprintf(fp,  "<nombre>%s</nombre>\n", p->nombre);
							fprintf(fp,  "<tipo>%i</tipo>\n", p->tipo);
							if( p->dimensionada > 0){
								fprintf(fp,  "<dimensionada>%i</dimensionada>\n", p->dimensionada);
								fprintf(fp,  "<tamanio>%i</tamanio>\n", p->tamanio);								
							}
							fprintf(fp,  "</variableGlobal>\n");
				}
				fprintf(fp,  "</variablesGlobales>\n");
				

				//Imprimir procedimientos del objeto y sus tablas de variables
				fprintf(fp,  "<procedimientos>\n");
				for(s=o->procedimientos; s!= NULL; s=(directorioProcedimientos*)(s->hh.next)) {
						fprintf(fp,  "<%s>\n", s->nombre);
							fprintf(fp,  "<regresa>%i</regresa>\n", s->regresa);
							fprintf(fp,  "<permiso>%i</permiso>\n", s->permiso);
							fprintf(fp,  "<direccionCuadruplo>%i</direccionCuadruplo>\n", s->direccionCuadruplo);
						fprintf(fp,  "<parametros>\n");
						for(dp=s->parametros; dp!= NULL; dp=(struct directorioParametros*)(dp->hh.next)) {
							fprintf(fp,  "<parametro>\n");
							fprintf(fp,  "<numeroParametro>%i</numeroParametro>\n", dp->numeroParametro);							
							fprintf(fp,  "<tipo>%i</tipo>\n", dp->tipo);
							fprintf(fp,  "</parametro>\n");
						}
						fprintf(fp,  "</parametros>\n");	
						fprintf(fp,  "<variablesLocales>\n");
						for(p=s->variablesLocales; p!= NULL; p=(struct directorio*)(p->hh.next)) {
							fprintf(fp,  "<variableLocal>\n");
							fprintf(fp,  "<direccion>%lu</direccion>\n", p->direccion);
							fprintf(fp,  "<nombre>%s</nombre>\n", p->nombre);
							fprintf(fp,  "<tipo>%i</tipo>\n", p->tipo);
							if( p->dimensionada > 0){
								fprintf(fp,  "<dimensionada>%i</dimensionada>\n", p->dimensionada);
								fprintf(fp,  "<tamanio>%i</tamanio>\n", p->tamanio);								
							}
							fprintf(fp,  "</variableLocal>\n");
						}
						fprintf(fp,  "</variablesLocales>\n");
						fprintf(fp,  "</%s>\n", s->nombre);
				}
				fprintf(fp,  "</procedimientos>\n");
				fprintf(fp,  "</%s>\n", o->nombre);						       
			}	
			//Imprimir la tabla de constantes (para todos los objetos)
			fprintf(fp,  "<constantes>\n");
						for(c=constantes; c!= NULL; c=(struct directorio*)(c->hh.next)) {
							fprintf(fp,  "<constante>\n");
							fprintf(fp,  "<direccion>%lu</direccion>\n", c->direccion);
							fprintf(fp,  "<valor>%s</valor>\n", c->nombre);
							fprintf(fp,  "<tipo>%i</tipo>\n", c->tipo);
							fprintf(fp,  "</constante>\n");
						}
						fprintf(fp,  "</constantes>\n");

			//Imprimir variables retornos para todos los metodos
			fprintf(fp,  "<variablesRetornos>\n");
				for(p=retornos; p!= NULL; p=(struct directorio*)(p->hh.next)) {						
							fprintf(fp,  "<variableRetorno>\n");
							fprintf(fp,  "<direccion>%lu</direccion>\n", p->direccion);
							fprintf(fp,  "<nombre>%s</nombre>\n", p->nombre);
							fprintf(fp,  "<tipo>%i</tipo>\n", p->tipo);
							fprintf(fp,  "</variableRetorno>\n");
				}
			fprintf(fp,  "</variablesRetornos>\n");

		fprintf(fp,  "</GALaDos>\n");
}	