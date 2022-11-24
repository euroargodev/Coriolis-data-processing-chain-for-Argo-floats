% ------------------------------------------------------------------------------
% check meta-data VS data base contents.
%
% SYNTAX :
%  check_meta_data_apx_apf11(a_metaData)
%
% INPUT PARAMETERS :
%   a_metaData : meta data recovered from float transmitted files
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/05/2018 - RNU - creation
% ------------------------------------------------------------------------------
function check_meta_data_apx_apf11(a_metaData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% json meta-data
global g_decArgo_jsonMetaData;

% file to store BDD update
global g_decArgo_bddUpdateCsvFileName;
global g_decArgo_bddUpdateCsvFileId;

% configuration values
global g_decArgo_dirOutputCsvFile;


% retrieve decoded meta-data and associated JSON meta-data
decValueList = [];
jsonValueList = [];
dimLevelList = [];
paramCodeList = [];
paramIdList = [];
for idM = 1:length(a_metaData)
   
   metaData = a_metaData(idM);
   if (metaData.techParamId > 0)
      switch (metaData.metaConfigLabel)
         
         case 'CTD_MODEL'
            sensorStruct = g_decArgo_jsonMetaData.SENSOR;
            sensorFields = fields(sensorStruct);
            sensorCell = struct2cell(sensorStruct);
            itemList = [{'CTD_PRES'} {'CTD_TEMP'} {'CTD_CNDC'}];
            for idI = 1:length(itemList)
               idF = find(strcmp(sensorCell, itemList{idI}));
               if (~isempty(idF))
                  decValue = metaData.techParamValue;
                  jsonValue = '';
                  number = str2num(regexprep(sensorFields{idF}, 'SENSOR_', ''));
                  if (isfield(g_decArgo_jsonMetaData.SENSOR_MODEL, ['SENSOR_MODEL_' num2str(number)]))
                     jsonValue = g_decArgo_jsonMetaData.SENSOR_MODEL.(['SENSOR_MODEL_' num2str(number)]);
                  end
                  dimLevel = idI;
                  
                  decValueList{end+1} = decValue;
                  jsonValueList{end+1} = jsonValue;
                  paramCodeList{end+1} = metaData.techParamCode;
                  paramIdList = [paramIdList metaData.techParamId];
                  dimLevelList = [dimLevelList dimLevel];
               end
            end
            
         case 'CTD_PRES_SERIAL_NUMBER'
            sensorStruct = g_decArgo_jsonMetaData.SENSOR;
            sensorFields = fields(sensorStruct);
            sensorCell = struct2cell(sensorStruct);
            idF = find(strcmp(sensorCell, 'CTD_PRES'));
            if (~isempty(idF))
               decValue = metaData.techParamValue;
               jsonValue = '';
               number = str2num(regexprep(sensorFields{idF}, 'SENSOR_', ''));
               if (isfield(g_decArgo_jsonMetaData.SENSOR_SERIAL_NO, ['SENSOR_SERIAL_NO_' num2str(number)]))
                  jsonValue = g_decArgo_jsonMetaData.SENSOR_SERIAL_NO.(['SENSOR_SERIAL_NO_' num2str(number)]);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'CTD_TEMP_SERIAL_NUMBER'
            sensorStruct = g_decArgo_jsonMetaData.SENSOR;
            sensorFields = fields(sensorStruct);
            sensorCell = struct2cell(sensorStruct);
            idF = find(strcmp(sensorCell, 'CTD_TEMP'));
            if (~isempty(idF))
               decValue = metaData.techParamValue;
               jsonValue = '';
               number = str2num(regexprep(sensorFields{idF}, 'SENSOR_', ''));
               if (isfield(g_decArgo_jsonMetaData.SENSOR_SERIAL_NO, ['SENSOR_SERIAL_NO_' num2str(number)]))
                  jsonValue = g_decArgo_jsonMetaData.SENSOR_SERIAL_NO.(['SENSOR_SERIAL_NO_' num2str(number)]);
               end
               dimLevel = 2;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'CTD_CNDC_SERIAL_NUMBER'
            sensorStruct = g_decArgo_jsonMetaData.SENSOR;
            sensorFields = fields(sensorStruct);
            sensorCell = struct2cell(sensorStruct);
            idF = find(strcmp(sensorCell, 'CTD_CNDC'));
            if (~isempty(idF))
               decValue = metaData.techParamValue;
               jsonValue = '';
               number = str2num(regexprep(sensorFields{idF}, 'SENSOR_', ''));
               if (isfield(g_decArgo_jsonMetaData.SENSOR_SERIAL_NO, ['SENSOR_SERIAL_NO_' num2str(number)]))
                  jsonValue = g_decArgo_jsonMetaData.SENSOR_SERIAL_NO.(['SENSOR_SERIAL_NO_' num2str(number)]);
               end
               dimLevel = 3;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'CTD_PRES_CALIB_DATE'
            sensorStruct = g_decArgo_jsonMetaData.SENSOR;
            sensorFields = fields(sensorStruct);
            sensorCell = struct2cell(sensorStruct);
            idF = find(strcmp(sensorCell, 'CTD_PRES'));
            if (~isempty(idF))
               decValue = metaData.techParamValue;
               jsonValue = '';
               number = str2num(regexprep(sensorFields{idF}, 'SENSOR_', ''));
               if (isfield(g_decArgo_jsonMetaData.PREDEPLOYMENT_CALIB_COMMENT, ['PREDEPLOYMENT_CALIB_COMMENT_' num2str(number)]))
                  jsonValue = g_decArgo_jsonMetaData.PREDEPLOYMENT_CALIB_COMMENT.(['PREDEPLOYMENT_CALIB_COMMENT_' num2str(number)]);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'CTD_TEMP_CALIB_DATE'
            sensorStruct = g_decArgo_jsonMetaData.SENSOR;
            sensorFields = fields(sensorStruct);
            sensorCell = struct2cell(sensorStruct);
            idF = find(strcmp(sensorCell, 'CTD_TEMP'));
            if (~isempty(idF))
               decValue = metaData.techParamValue;
               jsonValue = '';
               number = str2num(regexprep(sensorFields{idF}, 'SENSOR_', ''));
               if (isfield(g_decArgo_jsonMetaData.PREDEPLOYMENT_CALIB_COMMENT, ['PREDEPLOYMENT_CALIB_COMMENT_' num2str(number)]))
                  jsonValue = g_decArgo_jsonMetaData.PREDEPLOYMENT_CALIB_COMMENT.(['PREDEPLOYMENT_CALIB_COMMENT_' num2str(number)]);
               end
               dimLevel = 2;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'CTD_CNDC_CALIB_DATE'
            sensorStruct = g_decArgo_jsonMetaData.SENSOR;
            sensorFields = fields(sensorStruct);
            sensorCell = struct2cell(sensorStruct);
            idF = find(strcmp(sensorCell, 'CTD_CNDC'));
            if (~isempty(idF))
               decValue = metaData.techParamValue;
               jsonValue = '';
               number = str2num(regexprep(sensorFields{idF}, 'SENSOR_', ''));
               if (isfield(g_decArgo_jsonMetaData.PREDEPLOYMENT_CALIB_COMMENT, ['PREDEPLOYMENT_CALIB_COMMENT_' num2str(number)]))
                  jsonValue = g_decArgo_jsonMetaData.PREDEPLOYMENT_CALIB_COMMENT.(['PREDEPLOYMENT_CALIB_COMMENT_' num2str(number)]);
               end
               dimLevel = 3;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'OPTODE_SERIAL_NUMBER'
            sensorStruct = g_decArgo_jsonMetaData.SENSOR;
            sensorFields = fields(sensorStruct);
            sensorCell = struct2cell(sensorStruct);
            idF = find(strcmp(sensorCell, 'OPTODE_DOXY'));
            if (~isempty(idF))
               decValue = metaData.techParamValue;
               jsonValue = '';
               number = str2num(regexprep(sensorFields{idF}, 'SENSOR_', ''));
               if (isfield(g_decArgo_jsonMetaData.SENSOR_SERIAL_NO, ['SENSOR_SERIAL_NO_' num2str(number)]))
                  jsonValue = g_decArgo_jsonMetaData.SENSOR_SERIAL_NO.(['SENSOR_SERIAL_NO_' num2str(number)]);
               end
               dimLevel = 101;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'AANDERAA_OPTODE_PHASE_COEF_0'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OPTODE'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE, 'PhaseCoef0'))
                  jsonValue = sprintf('%e', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE.PhaseCoef0);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'AANDERAA_OPTODE_PHASE_COEF_1'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OPTODE'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE, 'PhaseCoef1'))
                  jsonValue = sprintf('%e', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE.PhaseCoef1);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'AANDERAA_OPTODE_PHASE_COEF_2'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OPTODE'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE, 'PhaseCoef2'))
                  jsonValue = sprintf('%e', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE.PhaseCoef2);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'AANDERAA_OPTODE_PHASE_COEF_3'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OPTODE'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE, 'PhaseCoef3'))
                  jsonValue = sprintf('%e', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE.PhaseCoef3);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'AANDERAA_OPTODE_COEF_0'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OPTODE'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE, 'SVUFoilCoef0'))
                  jsonValue = sprintf('%e', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef0);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'AANDERAA_OPTODE_COEF_1'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OPTODE'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE, 'SVUFoilCoef1'))
                  jsonValue = sprintf('%e', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef1);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'AANDERAA_OPTODE_COEF_2'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OPTODE'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE, 'SVUFoilCoef2'))
                  jsonValue = sprintf('%e', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef2);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'AANDERAA_OPTODE_COEF_3'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OPTODE'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE, 'SVUFoilCoef3'))
                  jsonValue = sprintf('%e', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef3);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'AANDERAA_OPTODE_COEF_4'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OPTODE'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE, 'SVUFoilCoef4'))
                  jsonValue = sprintf('%e', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef4);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'AANDERAA_OPTODE_COEF_5'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OPTODE'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE, 'SVUFoilCoef5'))
                  jsonValue = sprintf('%e', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef5);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'AANDERAA_OPTODE_COEF_6'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OPTODE'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE, 'SVUFoilCoef6'))
                  jsonValue = sprintf('%e', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef6);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'OCR_SERIAL_NUMBER'
            sensorStruct = g_decArgo_jsonMetaData.SENSOR;
            sensorFields = fields(sensorStruct);
            sensorCell = struct2cell(sensorStruct);
            sensorNames = [{'RADIOMETER_DOWN_IRR380'} {'RADIOMETER_DOWN_IRR412'} {'RADIOMETER_DOWN_IRR490'} {'RADIOMETER_PAR'}];
            for idS = 1:length(sensorNames)
               idF = find(strcmp(sensorCell, sensorNames{idS}));
               if (~isempty(idF))
                  decValue = metaData.techParamValue;
                  jsonValue = '';
                  number = str2num(regexprep(sensorFields{idF}, 'SENSOR_', ''));
                  if (isfield(g_decArgo_jsonMetaData.SENSOR_SERIAL_NO, ['SENSOR_SERIAL_NO_' num2str(number)]))
                     jsonValue = g_decArgo_jsonMetaData.SENSOR_SERIAL_NO.(['SENSOR_SERIAL_NO_' num2str(number)]);
                  end
                  dimLevel = 200 + idS;
                  
                  decValueList{end+1} = decValue;
                  jsonValueList{end+1} = jsonValue;
                  paramCodeList{end+1} = metaData.techParamCode;
                  paramIdList = [paramIdList metaData.techParamId];
                  dimLevelList = [dimLevelList dimLevel];
               end
            end
            
         case 'OCR_A0_LAMBDA_380'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OCR'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR, 'A0Lambda380'))
                  jsonValue = sprintf('%.1f', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR.A0Lambda380);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'OCR_A0_LAMBDA_412'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OCR'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR, 'A0Lambda412'))
                  jsonValue = sprintf('%.1f', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR.A0Lambda412);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'OCR_A0_LAMBDA_490'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OCR'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR, 'A0Lambda490'))
                  jsonValue = sprintf('%.1f', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR.A0Lambda490);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'OCR_A0_PAR'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OCR'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR, 'A0PAR'))
                  jsonValue = sprintf('%.1f', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR.A0PAR);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'OCR_A1_LAMBDA_380'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OCR'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR, 'A1Lambda380'))
                  jsonValue = sprintf('%e', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR.A1Lambda380);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'OCR_A1_LAMBDA_412'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OCR'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR, 'A1Lambda412'))
                  jsonValue = sprintf('%e', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR.A1Lambda412);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'OCR_A1_LAMBDA_490'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OCR'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR, 'A1Lambda490'))
                  jsonValue = sprintf('%e', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR.A1Lambda490);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'OCR_A1_PAR'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OCR'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR, 'A1PAR'))
                  jsonValue = sprintf('%e', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR.A1PAR);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'OCR_LM_LAMBDA_380'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OCR'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR, 'LmLambda380'))
                  jsonValue = sprintf('%.3f', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR.LmLambda380);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'OCR_LM_LAMBDA_412'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OCR'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR, 'LmLambda412'))
                  jsonValue = sprintf('%.3f', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR.LmLambda412);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'OCR_LM_LAMBDA_490'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OCR'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR, 'LmLambda490'))
                  jsonValue = sprintf('%.3f', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR.LmLambda490);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'OCR_LM_PAR'
            if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT, 'OCR'))
               decValue = metaData.techParamValue;
               jsonValue = '';
               if (isfield(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR, 'LmPAR'))
                  jsonValue = sprintf('%.3f', g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.OCR.LmPAR);
               end
               dimLevel = 1;
               
               decValueList{end+1} = decValue;
               jsonValueList{end+1} = jsonValue;
               paramCodeList{end+1} = metaData.techParamCode;
               paramIdList = [paramIdList metaData.techParamId];
               dimLevelList = [dimLevelList dimLevel];
            end
            
         case 'FLBB_SERIAL_NUMBER'
            sensorStruct = g_decArgo_jsonMetaData.SENSOR;
            sensorFields = fields(sensorStruct);
            sensorCell = struct2cell(sensorStruct);
            sensorNames = [{'FLUOROMETER_CHLA'} {'BACKSCATTERINGMETER_BBP700'} {'FLUOROMETER_CDOM'}];
            for idS = 1:length(sensorNames)
               idF = find(strcmp(sensorCell, sensorNames{idS}));
               if (~isempty(idF))
                  decValue = metaData.techParamValue;
                  jsonValue = '';
                  number = str2num(regexprep(sensorFields{idF}, 'SENSOR_', ''));
                  if (isfield(g_decArgo_jsonMetaData.SENSOR_SERIAL_NO, ['SENSOR_SERIAL_NO_' num2str(number)]))
                     jsonValue = g_decArgo_jsonMetaData.SENSOR_SERIAL_NO.(['SENSOR_SERIAL_NO_' num2str(number)]);
                  end
                  dimLevel = 300 + idS;
                  
                  decValueList{end+1} = decValue;
                  jsonValueList{end+1} = jsonValue;
                  paramCodeList{end+1} = metaData.techParamCode;
                  paramIdList = [paramIdList metaData.techParamId];
                  dimLevelList = [dimLevelList dimLevel];
               end
            end
            
         otherwise
            decValue = metaData.techParamValue;
            jsonValue = '';
            if (isfield(g_decArgo_jsonMetaData, metaData.techParamCode))
               jsonValue = g_decArgo_jsonMetaData.(metaData.techParamCode);
            end
            dimLevel = 1;
            
            decValueList{end+1} = decValue;
            jsonValueList{end+1} = jsonValue;
            paramCodeList{end+1} = metaData.techParamCode;
            paramIdList = [paramIdList metaData.techParamId];
            dimLevelList = [dimLevelList dimLevel];
      end
   end
end

% compare data
for idP = 1:length(decValueList)
   updateNeeded = 0;
   decValue = decValueList{idP};
   jsonValue = jsonValueList{idP};
   paramCode = paramCodeList{idP};
   paramId = paramIdList(idP);
   dimLevel = dimLevelList(idP);
   if (isempty(jsonValue))
      fprintf('WARNING: Float #%d Cycle #%d: Meta-data ''%s'': value (''%s'') is missing in BDD - BDD contents should be updated\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         paramCode, ...
         decValue);
      updateNeeded = 1;
   elseif (~strcmp(jsonValue, decValue))
      fprintf('WARNING: Float #%d Cycle #%d: Meta-data ''%s'': BDD value (''%s'') and decoded value (''%s'') differ - BDD contents should be updated\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         paramCode, ...
         jsonValue, ...
         decValue);
      updateNeeded = 1;
   end
   if (updateNeeded)
      if (g_decArgo_bddUpdateCsvFileId == -1)
         % output CSV file creation
         g_decArgo_bddUpdateCsvFileName = [g_decArgo_dirOutputCsvFile '/data_to_update_bdd_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
         g_decArgo_bddUpdateCsvFileId = fopen(g_decArgo_bddUpdateCsvFileName, 'wt');
         if (g_decArgo_bddUpdateCsvFileId == -1)
            fprintf('ERROR: Float #%d Cycle #%d: Unable to create CSV output file: %s\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               g_decArgo_bddUpdateCsvFileName);
            return
         end
         
         header = 'PLATFORM_CODE;TECH_PARAMETER_ID;DIM_LEVEL;CORIOLIS_TECH_METADATA.PARAMETER_VALUE;TECH_PARAMETER_CODE';
         fprintf(g_decArgo_bddUpdateCsvFileId, '%s\n', header);
      end
      
      fprintf(g_decArgo_bddUpdateCsvFileId, '%d;%d;%d;%s;%s\n', ...
         g_decArgo_floatNum, ...
         paramId, dimLevel, decValue, paramCode);
   end
end

return
