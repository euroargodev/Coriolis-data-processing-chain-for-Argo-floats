% ------------------------------------------------------------------------------
% Generate JSON meta-data file of a float.
%
% SYNTAX :
%  [o_ok] = generate_json_file(a_outputFileName, a_metaStruct)
%
% INPUT PARAMETERS :
%   a_outputFileName : JSON file name to be generated
%   a_metaStruct     : float meta-data to be stored in the file
%
% OUTPUT PARAMETERS :
%   o_ok : operation report flag (1 if ok, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/15/2014 - RNU - creation
%   09/01/2017 - RNU - RT version added
% ------------------------------------------------------------------------------
function [o_ok] = generate_json_file(a_outputFileName, a_metaStruct)

% output parameters initialization
o_ok = 1;


% create file
fidOut = fopen(a_outputFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create json output file: %s\n', a_outputFileName);
   o_ok = 0;
   return
end

% fill file
fprintf(fidOut, '{\n');

metaStruct = a_metaStruct;
metaStructNames = fieldnames(metaStruct);
for idBSN = 1:length(metaStructNames)
   fprintf(fidOut, '   "%s" : ', char(metaStructNames(idBSN)));
   fieldVal = metaStruct.(metaStructNames{idBSN});
   if (strcmp(metaStructNames{idBSN}, 'CALIBRATION_COEFFICIENT') == 1)
      if (isempty(fieldVal) || (isa(fieldVal, 'struct')))
         fprintf(fidOut, '[ \n');
         if (~isempty(fieldVal))
            fprintf(fidOut, '      {\n');
            fieldSubVal = fieldnames(fieldVal);
            for idDim1 = 1:size(fieldSubVal, 1)
               fprintf(fidOut, '      "%s" :\n', ...
                  fieldSubVal{idDim1});
               fprintf(fidOut, '         {\n');
               fieldSubVal2 = fieldnames(fieldVal.(fieldSubVal{idDim1}));
               for idDim2 = 1:size(fieldSubVal2, 1)
                  fprintf(fidOut, '            "%s" : %s', ...
                     fieldSubVal2{idDim2}, ...
                     fieldVal.(fieldSubVal{idDim1}).(fieldSubVal2{idDim2}));
                  if (idDim2 < size(fieldSubVal2, 1))
                     fprintf(fidOut, ',\n');
                  else
                     fprintf(fidOut, '\n');
                  end
               end
               if (idDim1 < size(fieldSubVal, 1))
                  fprintf(fidOut, '         },\n');
               else
                  fprintf(fidOut, '         }\n');
               end
            end
            fprintf(fidOut, '      }\n');
         end
         if (idBSN < length(metaStructNames))
            fprintf(fidOut, '   ],\n');
         else
            fprintf(fidOut, '   ]\n');
         end
      end
   elseif (strcmp(metaStructNames{idBSN}, 'RT_OFFSET') == 1)
      if (isempty(fieldVal) || (isa(fieldVal, 'struct')))
         fprintf(fidOut, '[ \n');
         if (~isempty(fieldVal))
            fprintf(fidOut, '      {\n');
            fieldSubVal = fieldnames(fieldVal);
            for idDim1 = 1:size(fieldSubVal, 1)
               fprintf(fidOut, '      "%s" :\n', ...
                  fieldSubVal{idDim1});
               fprintf(fidOut, '         {\n');
               fieldSubVal2 = fieldnames(fieldVal.(fieldSubVal{idDim1}));
               for idDim2 = 1:size(fieldSubVal2, 1)
                  fprintf(fidOut, '            "%s" : "%s"', ...
                     fieldSubVal2{idDim2}, ...
                     fieldVal.(fieldSubVal{idDim1}).(fieldSubVal2{idDim2}));
                  if (idDim2 < size(fieldSubVal2, 1))
                     fprintf(fidOut, ',\n');
                  else
                     fprintf(fidOut, '\n');
                  end
               end
               if (idDim1 < size(fieldSubVal, 1))
                  fprintf(fidOut, '         },\n');
               else
                  fprintf(fidOut, '         }\n');
               end
            end
            fprintf(fidOut, '      }\n');
         end
         if (idBSN < length(metaStructNames))
            fprintf(fidOut, '   ],\n');
         else
            fprintf(fidOut, '   ]\n');
         end
      end
   else
      if (isa(fieldVal, 'char'))
         if (idBSN < length(metaStructNames))
            fprintf(fidOut, '"%s", \n', char(fieldVal));
         else
            fprintf(fidOut, '"%s" \n', char(fieldVal));
         end
      else
         if (isempty(fieldVal) || (isa(fieldVal, 'cell')))
            fprintf(fidOut, '[ \n');
            for idDim2 = 1:size(fieldVal, 2)
               fprintf(fidOut, '      {\n');
               for idDim1 = 1:size(fieldVal, 1)
                  fieldSubVal = char(fieldVal{idDim1, idDim2});
                  if (size(fieldVal, 2) == 1)
                     fprintf(fidOut, '      "%s_%d" : "%s"', ...
                        char(metaStructNames(idBSN)), ...
                        idDim1, ...
                        fieldSubVal);
                  else
                     fprintf(fidOut, '      "%s_%d_%d" : "%s"', ...
                        char(metaStructNames(idBSN)), ...
                        idDim1, ...
                        idDim2, ...
                        fieldSubVal);
                  end
                  if (idDim1 < size(fieldVal, 1))
                     fprintf(fidOut, ',\n');
                  else
                     fprintf(fidOut, '\n');
                  end
               end
               if (idDim2 < size(fieldVal, 2))
                  fprintf(fidOut, '      },\n');
               else
                  fprintf(fidOut, '      }\n');
               end
            end
            if (idBSN < length(metaStructNames))
               fprintf(fidOut, '   ],\n');
            else
               fprintf(fidOut, '   ]\n');
            end
         else
            fprintf('ERROR\n');
         end
      end
   end
end

fprintf(fidOut, '}\n');

fclose(fidOut);

return
