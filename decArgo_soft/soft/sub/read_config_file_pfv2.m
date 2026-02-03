% ------------------------------------------------------------------------------
% Read configuration from XML file.
%
% SYNTAX :
%   [o_confLabels, o_confValues] = read_config_file_pfv2(a_fileName)
%
% INPUT PARAMETERS :
%   a_fileName : configuration file path name
%
% OUTPUT PARAMETERS :
%   o_confLabels : list of configuration labels
%   o_confValues : list of configuration values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/09/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_confLabels, o_confValues] = read_config_file_pfv2(a_fileName)

% output parameters initialization
o_confLabels = [];
o_confValues = [];

% current float WMO number
global g_decArgo_floatNum;


% parse the XML data into a Matlab structure
configStruct = parse_xml_2_struct(a_fileName);
if (isempty(configStruct))
   fprintf('ERROR: Float #%d: Unable to parse file %s\n', ...
      g_decArgo_floatNum, ...
      a_fileName);
   return
end

% retrieve configuration parameters from Matlab structure
[o_confLabels, o_confValues] = read_config_struct(configStruct);

return

% ------------------------------------------------------------------------------
% Extract configuration labels and values from Matlab structure.
%
% SYNTAX :
%   [o_confLabels, o_confValues] = read_config_struct(a_configStruct)
%
% INPUT PARAMETERS :
%   a_configStruct : input Matlab structure
%
% OUTPUT PARAMETERS :
%   o_confLabels : list of configuration labels
%   o_confValues : list of configuration values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/09/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_confLabels, o_confValues] = read_config_struct(a_configStruct)

% output parameters initialization
o_confLabels = [];
o_confValues = [];

% tables to temporary store structure contents
global tabLabel;
global tabName;
global tabValue;

tabLabel = [];
tabName = [];
tabValue = [];

% recursively read Matlab structure
read_struct(a_configStruct, 1);

% remove unused 'SETTING' entry
tabLabel(:, 1) = [];
tabName(:, 1) = [];
tabValue(:, 1) = [];

% generate configuration labels and associated values
tabFlag = zeros(size(tabLabel));
for idL = 1:size(tabLabel, 1)
   for idC = 1:size(tabLabel, 2)
      if (isempty(tabLabel{idL, idC}))
         tabFlag(idL, idC) = 1;
      else
         tabFlag(idL, idC) = 1;
         break
      end
   end
end

for idC = 1:size(tabLabel, 2)
   prevLabel = '';
   for idL = 1:size(tabLabel, 1)
      if (~isempty(tabLabel{idL, idC}))
         prevLabel = tabLabel{idL, idC};
      elseif (tabFlag(idL, idC))
         tabLabel{idL, idC} = prevLabel;
      end
   end
end

for idL = 1:size(tabLabel, 1)
   path = '';
   for idC = 1:size(tabLabel, 2)
      path = [path tabLabel{idL, idC} '-'];
      if (~isempty(tabName{idL, idC}))
         names = tabName{idL, idC};
         values = tabValue{idL, idC};
         for idP = 1:length(names)
            o_confLabels{end+1} = [path(1:end-1) '.' names{idP}];
            o_confValues{end+1} = values{idP};
         end
         break
      end
   end
end

return

% ------------------------------------------------------------------------------
% Recursively read the Matlab structure.
%
% SYNTAX :
%   read_struct(a_configStruct, a_lev)
%
% INPUT PARAMETERS :
%   a_configStruct : input structure
%   a_lev          : depth level of current structure
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/09/2024 - RNU - creation
% ------------------------------------------------------------------------------
function read_struct(a_configStruct, a_lev)

global tabLabel;
global tabName;
global tabValue;

for id1 = 1:length(a_configStruct)
   confStruct = a_configStruct(id1);
   if (strcmp(confStruct.Name, '#text'))
      continue
   end
   tabLabel{end+1, a_lev} = confStruct.Name;
   tabName{size(tabLabel, 1), a_lev} = '';
   tabValue{size(tabLabel, 1), a_lev} = '';
   
   for idAtt = 1:length(confStruct.Attributes)
      att = confStruct.Attributes(idAtt);
      attName = att.Name;
      attValue = att.Value;
      tabName{size(tabLabel, 1), a_lev} = [tabName{size(tabLabel, 1), a_lev} {attName}];
      tabValue{size(tabLabel, 1), a_lev} = [tabValue{size(tabLabel, 1), a_lev} {attValue}];
   end

   for id2 = 1:length(a_configStruct.Children)
      read_struct(a_configStruct.Children(id2), a_lev+1);
   end
end

return