% ------------------------------------------------------------------------------
% Process file information on technical labels for a given decoder to generate a
% json version of its content.
%
% SYNTAX :
%  generate_json_decoder_tech_labels()
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
%   05/09/2013 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_decoder_tech_labels()

% file information on technical labels for a given decoder
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_12.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_19.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_4.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_30.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_31.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_32.csv';

% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_105.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_201.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_203.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_205.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_209.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_301.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_302.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_210.csv';

% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1001.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1002.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1003.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1004.csv';
decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1007.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1009.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1010.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1011.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1012.csv';

% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_2001.csv';
% decoderTechLabelsFileName = 'C:\Users\jprannou\_RNU\DecArgo_info\_techParamNames\_tech_param_name_2002.csv';


if ~(exist(decoderTechLabelsFileName, 'file') == 2)
   fprintf('ERROR: Technical information file not found: %s\n', decoderTechLabelsFileName);
   return;
end

% read tech info file
fId = fopen(decoderTechLabelsFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', decoderTechLabelsFileName);
   return;
end
fileContents = textscan(fId, '%s', 'delimiter', ';');
fileContents = fileContents{:};
fclose(fId);

fileContents = regexprep(fileContents, '"', '');

[outputFileList] = create_output_files(decoderTechLabelsFileName);

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
   
   nbTechItems = (length(fileContents)-5)/5;
   for idTech = 1:nbTechItems
      
      fprintf(fidOut, '   "TECH_PARAM_%d" :\n', idTech);
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
      if (idTech ~= nbTechItems)
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
         decIdList = [1, 11, 3];
      case {12}
         decIdList = [12, 24, 17];
      case {4}
         decIdList = [4];
      case {19}
         decIdList = [19, 25, 27, 28, 29];
      case {30}
         decIdList = [30];
      case {31}
         decIdList = [31];
      case {32}
         decIdList = [32];
      case {105}
         decIdList = [105, 106, 107, 109];
      case {201}
         decIdList = [201, 202];
      case {203}
         decIdList = [203];
      case {205}
         decIdList = [204, 205, 206, 207, 208];
      case {209}
         decIdList = [209];
      case {210}
         decIdList = [210, 211];
      case {301}
         decIdList = [301];
      case {302}
         decIdList = [302 303];
         
      case {1001}
         decIdList = [1001 1005];
      case {1002}
         decIdList = [1002 1006 1008];
      case {1003}
         decIdList = [1003];
      case {1004}
         decIdList = [1004];
      case {1007}
         decIdList = [1007];
      case {1009}
         decIdList = [1009];
      case {1010}
         decIdList = [1010];
      case {1011}
         decIdList = [1011];
      case {1012}
         decIdList = [1012];
         
      case {2001}
         decIdList = [2001];
      case {2002}
         decIdList = [2002];

         
      otherwise
         fprintf('ERROR: Unknown decId list associate to decId #%d\n', decId);
   end
   
   for idF = 1:length(decIdList)
      o_outputFileList{end+1} = [filePath '/' fileName(1:idFUs(4)) num2str(decIdList(idF)) '.json'];
   end
end

return;
