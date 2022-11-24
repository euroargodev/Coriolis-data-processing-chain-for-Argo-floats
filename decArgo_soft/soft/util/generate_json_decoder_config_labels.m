% ------------------------------------------------------------------------------
% Process file information on configuration labels for a given decoder to
% generate a json version of its content.
%
% SYNTAX :
%  generate_json_decoder_config_labels()
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   15/09/2013 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_decoder_config_labels()

% file information on configuration labels for a given decoder

% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_1.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_3.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_24.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_25.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_27.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_30.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_31.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_32.csv';
decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_105.csv';
decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_121.csv';

% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_201.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_202.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_204.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_205.csv';

% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_301.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_302.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_303.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_206.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_30.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_210.csv';

% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_1001.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_1002.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_1004.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_1008.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_1011.csv';
% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_1015.csv';

% decoderConfLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_configParamNames\_config_param_name_2001.csv';


fprintf('Generating json reference configuration file from input file: %s\n', decoderConfLabelsFileName);

if ~(exist(decoderConfLabelsFileName, 'file') == 2)
   fprintf('ERROR: Configuration information file not found: %s\n', decoderConfLabelsFileName);
   return;
end

% read conf info file
fId = fopen(decoderConfLabelsFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', decoderConfLabelsFileName);
   return;
end
fileContents = textscan(fId, '%s', 'delimiter', ';');
fileContents = fileContents{:};
fclose(fId);

fileContents = regexprep(fileContents, '"', '');

[outputFileList] = create_output_files(decoderConfLabelsFileName);

for idF = 1:length(outputFileList)
   
   fprintf('Creating file: %s\n', outputFileList{idF});
   
   % create the json output files
   outputFileName = outputFileList{idF};
   fidOut = fopen(outputFileName, 'wt');
   if (fidOut == -1)
      fprintf('ERROR: Unable to create json output file: %s\n', outputFileName);
      return;
   end
   
   fprintf(fidOut, '{\n');
   
   nbConfItems = (length(fileContents)-5)/5;
   for idTech = 1:nbConfItems
      
      fprintf(fidOut, '   "CONF_PARAM_%d" :\n', idTech);
      fprintf(fidOut, '   {\n');
      for id = 1:5
         fprintf(fidOut, '      "%s" : "%s"', ...
            char(fileContents{id}), char(fileContents{idTech*5+id}));
         if (id ~= 5)
            fprintf(fidOut, ',\n');
         else
            fprintf(fidOut, '\n');
         end
      end
      fprintf(fidOut, '   }');
      if (idTech ~= nbConfItems)
         fprintf(fidOut, ',\n');
      else
         fprintf(fidOut, '\n');
      end
   end
   
   fprintf(fidOut, '}\n');
   
   fclose(fidOut);
end

return;

% ------------------------------------------------------------------------------
function [o_outputFileList] = create_output_files(a_inputFilePathName)

o_outputFileList = [];

[filePath, fileName, fileExt] = fileparts(a_inputFilePathName);

idFUs = strfind(fileName, '_');
if (length(idFUs) ~= 4)
   fprintf('ERROR: CSV file name is inconsistent (%s)\n', ...
      a_inputFilePathName);
else
   decId = str2num(fileName(idFUs(4)+1:end));
   decIdList = [];
   switch decId
      
      case {1}
         decIdList = [1, 11, 12, 4, 19];
      case {3}
         decIdList = [3];
      case {24}
         decIdList = [24, 17];
      case {25}
         decIdList = [25];
      case {27}
         decIdList = [27, 28, 29];
      case {30}
         decIdList = [30];
      case {31}
         decIdList = [31];
      case {32}
         decIdList = [32];
      case {105}
         decIdList = [105, 106, 107, 109, 110];
      case {121}
         decIdList = [121];
      case {201}
         decIdList = [201, 203];
      case {202}
         decIdList = [202];
      case {204}
         decIdList = [204];
      case {205}
         decIdList = [205];
      case {301}
         decIdList = [301];
      case {302}
         decIdList = [302];
      case {303}
         decIdList = [303];
      case {206}
         decIdList = [206, 207, 208, 209];
      case {210}
         decIdList = [210, 211];
         
      case {1001}
         decIdList = [1001 1005 1007 1009 1010 1016];
      case {1002}
         decIdList = [1002 1003 1006];
      case {1004}
         decIdList = [1004];
      case {1008}
         decIdList = [1008 1013 1014];
      case {1011}
         decIdList = [1011 1012];
      case {1015}
         decIdList = [1015];
         
      case {2001}
         decIdList = [2001 2002];

      otherwise
         fprintf('ERROR: Unknown decId list associate to decId #%d\n', decId);
   end
   
   for idF = 1:length(decIdList)
      o_outputFileList{end+1} = [filePath '/' fileName(1:idFUs(4)) num2str(decIdList(idF)) '.json'];
   end
end

return;
