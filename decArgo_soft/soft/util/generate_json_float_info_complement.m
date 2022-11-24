% ------------------------------------------------------------------------------
% Generate json float information files for floats declared in the Coriolis data
% base but not decoded by the Argos Matlab decoder.
%
% SYNTAX :
%  generate_json_float_info_complement()
%
% INPUT PARAMETERS :
%  
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/02/2014 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_info_complement()

% meta-data file exported from Coriolis data base
% floatMetaFileName = 'C:\users\RNU\Argo\work\floats_info_complement_PRV.txt';
floatMetaFileName = 'C:\users\RNU\Argo\work\floats_info_complement_NOT_PRV.txt';
floatMetaFileName = 'C:\users\RNU\Argo\work\meta_tmp_20140513.txt';
floatMetaFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\meta_PRV_from_VB_REFERENCE_20150217.txt';


fprintf('Generating json info files from input file: %s\n', floatMetaFileName);

% directory of individual json float information files
outputDirName = ['C:\Users\jprannou\_RNU\DecArgo_soft\work\json_unused_float_info_files_' datestr(now, 'yyyymmddTHHMMSS')];


if ~(exist(floatMetaFileName, 'file') == 2)
   fprintf('ERROR: Meta-data file not found: %s\n', floatMetaFileName);
   return
end

% read meta file
fId = fopen(floatMetaFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', floatMetaFileName);
   return
end
fileContents = textscan(fId, '%s', 'delimiter', '\t');
fileContents = fileContents{:};
fclose(fId);

fileContents = regexprep(fileContents, '"', '');

metaData = reshape(fileContents, 5, size(fileContents, 1)/5)';

% get the mapping structure
infoBddStruct = get_info_bdd_struct();
infoBddStructNames = fieldnames(infoBddStruct);

% process the meta-data to fill the structure
% wmoList = str2num(cell2mat(metaData(:, 1))); % works only if all raws have the sme number of digits
% dimLevlist = str2num(cell2mat(metaData(:, 3))); % works only if all raws have the sme number of digits
wmoList = metaData(:, 1);
for id = 1:length(wmoList)
   if (isempty(str2num(wmoList{id})))
      fprintf('%s is not a valid WMO number\n', wmoList{id});
      return
   end
end
S = sprintf('%s*', wmoList{:});
wmoList = sscanf(S, '%f*');
floatList = unique(wmoList);

% create the directory of json output files
if ~(exist(outputDirName, 'dir') == 7)
   mkdir(outputDirName);
end

for idFloat = 1:length(floatList)
   
   fprintf('%3d/%3d %d', idFloat, length(floatList), floatList(idFloat));
   
   % initialize the structure to be filled
   infoStruct = get_info_init_struct();

   infoStruct.PLATFORM_NUMBER = num2str(floatList(idFloat));
   
   % direct conversion data
   idForWmo = find(wmoList == floatList(idFloat));
   for idBSN = 1:length(infoBddStructNames)
      infoBddStructValue = infoBddStruct.(infoBddStructNames{idBSN});
      if (~isempty(infoBddStructValue))
         idF = find(strcmp(metaData(idForWmo, 5), infoBddStructValue) == 1, 1);
         if (~isempty(idF))
            infoStruct.(infoBddStructNames{idBSN}) = metaData{idForWmo(idF), 4};
         end
      end
   end
   
   % PTT / IMEI specific processing
   idF = find(strcmp(metaData(idForWmo, 5), 'PTT') == 1, 1);
   if (~isempty(idF))
      if (strcmp(infoStruct.TRANS_SYSTEM, 'ARGOS'))
         infoStruct.PTT = metaData{idForWmo(idF), 4};
      elseif (strcmp(infoStruct.TRANS_SYSTEM, 'IRIDIUM'))
         infoStruct.IMEI = metaData{idForWmo(idF), 4};
      end
   end
   
   % retrieve FLOAT_TYPE
   floatType = getfield(infoStruct, 'FLOAT_TYPE');
   if (isempty(floatType))
      fprintf('ERROR: FLOAT_TYPE (from PLATFORM_TYPE) is missing for float %d - no json file generated\n', ...
         floatList(idFloat));
      continue
   end
      
   % set the DECODER_ID field
   if ((strncmp(floatType, 'PROVOR', length('PROVOR')) == 1) || ...
         (strncmp(floatType, 'ARVOR', length('ARVOR')) == 1))
      
      % retrieve DAC_FORMAT_ID
      dacFormatId = getfield(infoStruct, 'DAC_FORMAT_ID');
      if (isempty(dacFormatId))
         fprintf('ERROR: DAC_FORMAT_ID (from PR_VERSION) is missing for float %d - no json file generated\n', ...
            floatList(idFloat));
         continue
      end
      
      switch (dacFormatId)
         case {'4.2', '4.21', '4.22', '4.23', '4.4', '4.41', '4.42', '4.43', '4.44', '4.45', '4.5', '4.51', '5.4', '5.41', '5.42', '5.6', '5.61', '5.7', '5.71', '5.72', '5.8', '5.9', '5.91', '5.92', '6.01'}
            
            dataCenter = getfield(infoStruct, 'DATA_CENTRE');
            dataCenterExecutive = getfield(infoStruct, 'DATA_CENTRE_EXECUTIVE');
            if (~isempty(dataCenter))
               if (strcmp(dataCenter, 'IF') == 1)
                  infoStruct.DECODER_ID = 1;
               else
                  if (~isempty(dataCenterExecutive))
                     if (strcmp(dataCenterExecutive, 'IF') == 1)
                        infoStruct.DECODER_ID = 1;
                     else
                        infoStruct.DECODER_ID = -1;
                     end
                  else
                     if (strcmp(dataCenter, 'KO') == 1)
                        infoStruct.DECODER_ID = 1;
                     else
                        infoStruct.DECODER_ID = -1;
                     end
                  end
               end
            else
               infoStruct.DECODER_ID = 1;
            end
            
         otherwise
            infoStruct.DECODER_ID = -1;
      end
   else
      infoStruct.DECODER_ID = -1;
   end
   
   % generate the json file
   if (infoStruct.DECODER_ID == -1) && (~isempty(infoStruct.PTT))
      fprintf('=> JSON\n');

      outputFileName = [outputDirName '/' sprintf('%d_%s_info.json', ...
         floatList(idFloat), infoStruct.PTT)];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         fprintf('ERROR: Unable to create json output file: %s\n', outputFileName);
         return
      end
      
      launchDateStrIn = infoStruct.LAUNCH_DATE;
      launchDateStrOut = [launchDateStrIn(7:10) ...
         launchDateStrIn(4:5) ...
         launchDateStrIn(1:2) ...
         launchDateStrIn(12:13) ...
         launchDateStrIn(15:16) ...
         launchDateStrIn(18:19)];

      fprintf(fidOut, '{\n');
      fprintf(fidOut, '   "WMO" : "%s",\n', infoStruct.PLATFORM_NUMBER);
      fprintf(fidOut, '   "PTT" : "%s",\n', infoStruct.PTT);
      fprintf(fidOut, '   "FLOAT_TYPE" : "%s",\n', infoStruct.FLOAT_TYPE);
      fprintf(fidOut, '   "DECODER_VERSION" : "%s",\n', infoStruct.DAC_FORMAT_ID);
      fprintf(fidOut, '   "DECODER_ID" : "%d",\n', infoStruct.DECODER_ID);
      fprintf(fidOut, '   "LAUNCH_DATE" : "%s",\n',  launchDateStrOut);
      fprintf(fidOut, '   "LAUNCH_LON" : "%s",\n',  infoStruct.LAUNCH_LONGITUDE);
      fprintf(fidOut, '   "LAUNCH_LAT" : "%s"\n',  infoStruct.LAUNCH_LATITUDE);
      fprintf(fidOut, '}\n');
      
      fclose(fidOut);
   else
      fprintf('=> NOTHING\n');
   end
end

fprintf('done\n');

return

% ------------------------------------------------------------------------------
function [o_infoStruct] = get_info_bdd_struct()

% output parameters initialization
o_infoStruct = struct( ...
   'PLATFORM_NUMBER', '', ...
   'PTT', '', ...
   'IMEI', '', ...
   'TRANS_SYSTEM', 'TRANS_SYSTEM', ...
   'FLOAT_TYPE', 'PLATFORM_TYPE', ...
   'DAC_FORMAT_ID', 'PR_VERSION', ...
   'DECODER_ID', '', ...
   'DATA_CENTRE', 'DATA_CENTRE', ...
   'DATA_CENTRE_EXECUTIVE', 'DATA_CENTRE_EXECUTIVE', ...
   'LAUNCH_DATE', 'PR_LAUNCH_DATETIME', ...
   'LAUNCH_LATITUDE', 'PR_LAUNCH_LATITUDE', ...
   'LAUNCH_LONGITUDE', 'PR_LAUNCH_LONGITUDE');

return

% ------------------------------------------------------------------------------
function [o_infoStruct] = get_info_init_struct()

% output parameters initialization
o_infoStruct = struct( ...
   'PLATFORM_NUMBER', '', ...
   'PTT', '', ...
   'IMEI', '', ...
   'TRANS_SYSTEM', '', ...
   'FLOAT_TYPE', '', ...
   'DAC_FORMAT_ID', '', ...
   'DECODER_ID', '', ...
   'DATA_CENTRE', '', ...
   'DATA_CENTRE_EXECUTIVE', '', ...
   'LAUNCH_DATE', '', ...
   'LAUNCH_LATITUDE', '', ...
   'LAUNCH_LONGITUDE', '');

return
