% ------------------------------------------------------------------------------
% Read the NKE meta-data JSON file provided from NKE and store useful
% information in meta-data structure.
%
% SYNTAX :
%  [o_metaStruct] = get_meta_data_nke(a_metaDataFileName, a_metaStruct, a_floatNum)
%
% INPUT PARAMETERS :
%   a_metaDataFileName : NKE meta-data JSON file
%   a_metaStruct       : input meta-data structure
%   a_floatNum         : float WMO number
%
% OUTPUT PARAMETERS :
%   o_metaStruct : output meta-data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/10/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaStruct] = get_meta_data_nke(a_metaDataFileName, a_metaStruct, a_floatNum)

% output parameters initialization
o_metaStruct = a_metaStruct;


% read meta-data file
% nkeMetaData = loadjson(a_metaDataFileName); % the provided files are not in a correct JSON format

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

% expected meta-data
nkeMetaData = [ ...
   {'PLATFORM_MAKER'} {''} {'PLATFORM_MAKER'};
   {'FLOAT_SERIAL_NO'} {''} {'FLOAT_SERIAL_NO'};
   {'PLATFORM_FAMILY'} {''} {'PLATFORM_FAMILY'};
   {'PTT'} {''} {'IMEI'};
   {'PLATFORM_TYPE'} {''} {'PLATFORM_TYPE'};
   {'WMO_INST_TYPE'} {''} {'WMO_INST_TYPE'};
   {'BATTERY_TYPE'} {''} {'BATTERY_TYPE'};
   {'BATTERY_PACKS'} {''} {'BATTERY_PACKS'};
   {'CONTROLLER_BOARD_TYPE_PRIMARY'} {''} {'CONTROLLER_BOARD_TYPE_PRIMARY'};
   {'CONTROLLER_BOARD_SERIAL_NO_PRIMARY'} {''} {'CONTROLLER_BOARD_SERIAL_NO_PRIMARY'};
   {'FIRMWARE_VERSION'} {''} {'FIRMWARE_VERSION'}];

% collect expected meta-data
for idL = 1:length(data)
   line = data{idL};
   
   idF1 = strfind(line, '": "');
   if (~isempty(idF1))
      name = line(1:idF1(1));
      idF2 = strfind(name, '"');
      if (length(idF2) == 2)
         name = name(idF2(1)+1:idF2(2)-1);
         value = line(idF1(1)+length('": "')-1:end);
         idF3 = strfind(value, '"');
         if (length(idF3) == 2)
            value = value(idF3(1)+1:idF3(2)-1);
            idF4 = strfind(value, ':');
            if (~isempty(idF4))
               value = value(idF4(end)+1:end);
            end

            idF = find(strcmp(name, nkeMetaData(:, 1)));
            if (~isempty(idF))
               nkeMetaData(idF, 2) = {value};
            end
         end
      end
   end
end

% check collected meta-data
for idL = 1:size(nkeMetaData, 1)
   valueNke = nkeMetaData{idL, 2};
   if (~isempty(value))
      fieldName = nkeMetaData{idL, 3};
      if (isfield(a_metaStruct, fieldName))
         valueBdd = a_metaStruct.(fieldName);
         if (~isempty(valueBdd))
            if (~strcmp(valueBdd, valueNke))
               fprintf('WARNING: Float #%d: NKE META-DATA CHECK: ''%s'' differ in BDD (''%s'') and in NKE meta-data (''%s'') - check consistency\n', ...
                  a_floatNum, fieldName, valueBdd, valueNke);
            end
         else
            o_metaStruct.(fieldName) = valueNke;
            fprintf('INFO: Float #%d: NKE META-DATA CHECK: ''%s'' set to NKE value (''%s'')\n', ...
               a_floatNum, fieldName, valueNke);
         end
      end
   end
end

return
