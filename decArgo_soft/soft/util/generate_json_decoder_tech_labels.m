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
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_12.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_19.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_4.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_30.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_31.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_32.csv';

% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_105.csv';
decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_111.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_121.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_122.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_124.csv';

% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_201.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_203.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_205.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_209.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_301.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_302.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_210.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_213.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_212.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_214.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_215.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_216.csv';

% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1001.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1002.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1003.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1004.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1007.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1009.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1010.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1011.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1012.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1013.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1014.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1015.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1016.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1021.csv';

% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1101.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1102.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1103.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1105.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1110.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1201.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1314.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_1321.csv';

% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_2001.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_2002.csv';
% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_2003.csv';

% decoderTechLabelsFileName = 'F:\NEW_20190125\_RNU\DecArgo_info\_techParamNames\_tech_param_name_3001.csv';


if ~(exist(decoderTechLabelsFileName, 'file') == 2)
   fprintf('ERROR: Technical information file not found: %s\n', decoderTechLabelsFileName);
   return
end

% read tech info file
fId = fopen(decoderTechLabelsFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', decoderTechLabelsFileName);
   return
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
      return
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

return

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
         decIdList = [105, 106, 107, 109, 110, 112];
      case {111}
         decIdList = [111, 113];
      case {121}
         decIdList = [121];
      case {122}
         decIdList = [122, 123];
      case {124}
         decIdList = [124];

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
      case {212}
         decIdList = [212];
      case {213}
         decIdList = [213];
      case {214}
         decIdList = [214, 217];
      case {215}
         decIdList = [215];
      case {216}
         decIdList = [216];
         
      case {301}
         decIdList = [301];
      case {302}
         decIdList = [302, 303];
         
      case {1001}
         decIdList = [1001, 1005];
      case {1002}
         decIdList = [1002, 1006, 1008];
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
      case {1013}
         decIdList = [1013];
      case {1014}
         decIdList = [1014];
      case {1015}
         decIdList = [1015];
      case {1016}
         decIdList = [1016];
      case {1021}
         decIdList = [1021, 1022];
         
      case {1101}
         decIdList = [1101];
      case {1102}
         decIdList = [1102, 1108, 1109, 1113];
      case {1103}
         decIdList = [1103, 1104, 1106, 1107];
      case {1105}
         decIdList = [1105, 1111];
      case {1110}
         decIdList = [1110, 1112];
         
      case {1314}
         decIdList = [1314];
         
      case {1321}
         decIdList = [1121, 1321, 1322];

      case {1201}
         decIdList = [1201];
         
      case {2001}
         decIdList = [2001];
      case {2002}
         decIdList = [2002];
      case {2003}
         decIdList = [2003];
         
      case {3001}
         decIdList = [3001];
         
      otherwise
         fprintf('ERROR: Unknown decId list associate to decId #%d\n', decId);
   end
   
   for idF = 1:length(decIdList)
      o_outputFileList{end+1} = [filePath '/' fileName(1:idFUs(4)) num2str(decIdList(idF)) '.json'];
   end
end

return
