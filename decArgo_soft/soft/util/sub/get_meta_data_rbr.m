% ------------------------------------------------------------------------------
% Read the RBR meta-data ASCII file provided from RBR and store useful
% information in meta-data structure.
%
% SYNTAX :
%  [o_metaStruct] = get_meta_data_rbr(a_metaDataFileName, a_metaStruct, a_floatNum)
%
% INPUT PARAMETERS :
%   a_metaDataFileName : RBR meta-data ASCII file
%   a_metaStruct       : input meta-data structure
%   a_floatNum         : float WMO number
%
% OUTPUT PARAMETERS :
%   o_metaStruct : output meta-data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/08/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaStruct] = get_meta_data_rbr(a_metaDataFileName, a_metaStruct, a_floatNum)

% output parameters initialization
o_metaStruct = a_metaStruct;


% open the file and read the data
fId = fopen(a_metaDataFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_metaDataFileName);
   return
end
data = [];
while (1)
   line = fgetl(fId);
   if (line == -1)
      break
   end
   data{end+1} = line;
end
fclose(fId);

% add useful information to the meta-data structure
usefulList = [ ...
   {'CTD_PRES'} ...
   {'CTD_TEMP'} ...
   {'CTD_CNDC'} ...
   {'PRES'} ...
   {'TEMP'} ...
   {'PSAL'} ...
   ];
for idL = 1:length(data)
   line = data{idL};
   
   idF = strfind(line, ':');
   if (~isempty(idF))
      labels = split(line(1:idF(1)-1), ' ');
      if (ismember(labels{1}, usefulList))
         fieldName = [labels{1} '_' labels{2}];
         fieldValue = strtrim(line(idF(1)+1:end));
         if (any(strfind(fieldName, '_ACCURACY')) || any(strfind(fieldName, '_RESOLUTION')))
            idF2 = strfind(fieldValue, ' ');
            fieldValue = fieldValue(1:idF2(1)-1);
         end
         o_metaStruct.(fieldName) = fieldValue;
      end
   end
end

% check consistency of information that will not be used in "update_meta_data.m"
% compare RBR file data with BDD data
ctdSensorList = [ ...
   {'CTD_PRES'} ...
   {'CTD_TEMP'} ...
   {'CTD_CNDC'} ...
   ];
sensorMetaList = [ ...
   {'SENSOR_MAKER'} ...
   {'SENSOR_MODEL'} ...
   {'SENSOR_SERIAL_NO'} ...
   ];
for idS = 1:length(ctdSensorList)
   sensorName = ctdSensorList{idS};
   
   % look for current sensor name in meta-data sensor list
   if (isfield(o_metaStruct, 'SENSOR'))
      sensorNames = o_metaStruct.SENSOR;
      sensorNum = -1;
      for id = 1:length(sensorNames)
         if (strcmp(sensorName, sensorNames{id}))
            sensorNum = id;
            break
         end
      end
      if (sensorNum > 0)
         for idM = 1:length(sensorMetaList)
            metaName = sensorMetaList{idM};
            if (isfield(o_metaStruct, metaName) && isfield(o_metaStruct, [sensorName '_' metaName]))
               metaDb = o_metaStruct.(metaName);
               metaDb = metaDb{sensorNum};
               metaFile = o_metaStruct.([sensorName '_' metaName]);
               if (~strcmp(metaDb, metaFile))
                  fprintf('ERROR: Float #%d: Sensor ''%s'': ''%s'' differ in BDD (''%s'') and in RBR file (''%s'') - check consistency\n', ...
                     a_floatNum, sensorName, metaName, metaDb, metaFile);
               end
            end
         end
      end
   end
end

return
