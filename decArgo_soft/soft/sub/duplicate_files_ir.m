% ------------------------------------------------------------------------------
% Duplicate a list of files from a directory to another one.
%
% SYNTAX :
%  [o_ok] = duplicate_files_ir(a_listFileNames, a_inputDir, a_outputDir)
%
% INPUT PARAMETERS :
%   a_listFileNames : names of the files to duplicate
%   a_inputDir      : input directory
%   a_outputDir     : output directory
%
% OUTPUT PARAMETERS :
%   o_ok : copy operation report flag (1 if ok, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/18/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = duplicate_files_ir(a_listFileNames, a_inputDir, a_outputDir)

% output parameters initialization
o_ok = 1;

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_janFirst1950InMatlab;


% copy the files of the list
for idFile = 1:length(a_listFileNames)
   fileNameIn = a_listFileNames{idFile};
   filePathNameIn = [a_inputDir '/' fileNameIn];

   fileNameOut = fileNameIn;

   % specific
   switch(g_decArgo_floatNum)
      case 2903802
         idF1 = strfind(fileNameIn, '.');
         floatId = fileNameIn(1:idF1(1)-1);
         if (~strcmp(floatId, 'f8636'))
            continue
         end
         cyNumPrev = str2double(fileNameIn(idF1(1)+1:idF1(2)-1));
         fileDateStr = fileNameIn(idF1(2)+1:idF1(3)-1);
         fileDateRef = datenum('20250706T230408', 'yyyymmddTHHMMSS') - g_decArgo_janFirst1950InMatlab;
         if (strcmp(fileDateStr, '20250618T025934') || strcmp(fileDateStr, '20250618T025936'))
            cyNum = 2;
         elseif (strcmp(fileDateStr, '20250618T042652'))
            cyNum = 3;
         elseif (strcmp(fileDateStr, '20250618T114032'))
            cyNum = 4;
         elseif (strcmp(fileDateStr, '20250618T125800') || strcmp(fileDateStr, '20250618T125802'))
            cyNum = 5;
         elseif (strcmp(fileDateStr, '20250618T181632') || strcmp(fileDateStr, '20250618T181634'))
            cyNum = 6;
         elseif (strcmp(fileDateStr, '20250618T193544'))
            cyNum = 7;
         elseif (strcmp(fileDateStr, '20250618T235006'))
            cyNum = 8;
         elseif (strcmp(fileDateStr, '20250619T005336') || strcmp(fileDateStr, '20250619T005338'))
            cyNum = 9;
         elseif (strcmp(fileDateStr, '20250622T201420'))
            cyNum = 10;
         elseif (strcmp(fileDateStr, '20250622T212400'))
            cyNum = 11;
         elseif (strcmp(fileDateStr, '20250706T230406') || strcmp(fileDateStr, '20250706T230408'))
            cyNum = 12;
         else
            fileDate = datenum(fileDateStr, 'yyyymmddTHHMMSS') - g_decArgo_janFirst1950InMatlab;
            if (fileDate > fileDateRef)
               cyNum = cyNumPrev + 12;
            else
               cyNum = cyNumPrev;
            end
         end

         fileNameOut(idF1(1)+1:idF1(2)-1) = sprintf('%03d', cyNum);
   end

   filePathNameOut = [a_outputDir '/' fileNameOut];
   if (copy_file(filePathNameIn, filePathNameOut) == 0)
      o_ok = 0;
      return
   end
end

return
