# Este script ejecuta el modelo GR2M de forma semidistribuida (subcuencas), utilizando los paquetes
# 'airGR' y 'rgrass7'. La topolog�a de la cuenca se identifica autom�ticamente a partir del raster
# de Flow Direction, utilizando el algorithm de acumulaci�n ponderada del flujo (Weighted Flow
# Accumulation). La calibraci�n de los par�metros del modelo GR2M (X1 y X2) se realiza de forma autom�tica
# mediante el algoritmo de optimizaci�n global Shuffle Complex Evolution (SCE-UA) usando el paquete
# 'rtop'. Se requiere instalar previamente GRASS v.7 (https://grass.osgeo.org/download/software/) y
# habilitar la extensi�n 'r.accumulate' con el comando 'g.extension'.

# �Harold LLauca
# Email: hllauca@gmail.com

rm(list=ls())    # Remover variables anteriores
options(warn=-1) # Suprimir warnings
cat('\f')        # Limpiar consola


## Configuraci�n del modelo GR2M SemiDistribuido
#===============================================

  ## DATOS DE ENTRADA AL MODELO
  Location     <- 'D:/GR2M_PERU/GR2M_SemiDistr_Pacifico/Chosica'
  File.Data    <- 'Inputs_Basins.csv'
  File.Shape   <- 'Chosica.shp'
  File.Raster  <- 'FlowDirection.tif'

  
  ## PERIODO DE EJECUCI�N DEL MODELO
  WarmUp.Ini   <- '01/1981'
  WarmUp.End   <- '12/1981'
  RunModel.Ini <- '01/1982'
  RunModel.End <- '12/2002'
  
  
  ## PAR�METROS DEL MODELO
  Model.HRU    <- rep('F',3)    # Regi�n de calibraci�n de cada subcuenca
  Model.Param  <- c(200, 0.2)   # Par�metros X1 y X2 para cada regi�n
  No.OptimHRU  <- NULL          # HRUs que no se optimizar�n (NULL de no existir)
  
  
  ## OPTIMIZACI�N AUTOM�TICA DEL MODELO
  Optim        <- TRUE         # Realizar optimizaci�n?
  Optim.Max    <- 500          # M�x n�mero de iteraciones
  Optim.Eval   <- 'NSE'        # Criterio de desempe�o (NSE, lnNSE, R, RMSE, KGE)
  Optim.Basin  <- 3            # Subcuenca pto. de control
  Optim.Remove <- TRUE         # Elimina Qsim en la subcuenca no deseada
  Model.ParMin <- c(1, 0.01)   # M�nimos valores de X1 y X2
  Model.ParMax <- c(2000, 2)   # M�ximos valores de X1 y X2

  

###################################################################################################
########################################## NO MODIFICAR ###########################################
###################################################################################################
# Directorio de trabajo
  setwd(Location)
  
# Condicional para la optimizaci�n
if (Optim == TRUE){
  
# Optimizar par�metros X1 y X2 del modelo GR2M semidistribuido
#=============================================================
  
  # Cargar funci�n
  source(file.path(Location,'1_FUNCIONES','Optim_GR2M_SemiDistr.R'))
  
  # Ejecutar optimizaci�n de par�metros del modelo GR2M semidistribuido
  x <- Optim_GR2M_SemiDistr(Parameters=Model.Param,
                            Parameters.Min=Model.ParMin,
                            Parameters.Max=Model.ParMax,
                            Max.Optimization=Optim.Max,
                            Optimization=Optim.Eval,
                            HRU=Model.HRU,
                            WorkDir=Location,
                            Raster=File.Raster,
                            Shapefile=File.Shape,
                            Input=File.Data,
                            WarmIni=WarmUp.Ini,
                            WarmEnd=WarmUp.End,
							              RunIni=RunModel.Ini,
                            RunEnd=RunModel.End,
                            IdBasin=Optim.Basin,
                            Remove=Optim.Remove,
                            No.Optim=No.OptimHRU)

	# Extraer resultados
	Model.Param <- x$par
	print(1-x$value)
}

 
# Ejecutar modelo GR2M semidistribuido
#=====================================
  
  # Cargar funci�n
  source(file.path(Location,'1_FUNCIONES','Run_GR2M_SemiDistr.R'))

  # Ejecutar modelo GR2M semidistribuido
  y  <- Run_GR2M_SemiDistr(Parameters=Model.Param,
                           HRU=Model.HRU,
                           WorkDir=Location,
                           Raster=File.Raster,
                           Shapefile=File.Shape,
                           Input=File.Data,
						   WarmIni=WarmUp.Ini,
                           WarmEnd=WarmUp.End,
                           RunIni=RunModel.Ini,
                           RunEnd=RunModel.End,
                           IdBasin=Optim.Basin,
                           Remove=Optim.Remove,
                           Plot=TRUE)
  
  
  # Guardar caudales generados en cada subcuenca (en formato .csv)
  dir.create(file.path(Location, '5_OUTPUT'), recursive=T, showWarnings=F)
  Qout           <- data.frame(y$Dates, y$Qsim)
  colnames(Qout) <- c('Fecha', paste0('Qsim-', 1:length(Model.HRU)))
  write.table(Qout, file=file.path(Location,'5_OUTPUT','Results_GR2M_Semidistr_Qsim.csv'),
              sep=',', row.names=F)