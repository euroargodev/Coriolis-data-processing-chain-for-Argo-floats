% ------------------------------------------------------------------------------
% Parse input parameters to set global input parameter variables.
%
% SYNTAX :
%  [o_inputError] = parse_input_param_argos(a_varargin)
%
% INPUT PARAMETERS :
%   a_varargin : additional input parameters
%
% OUTPUT PARAMETERS :
%   o_inputError : input error flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_inputError] = parse_input_param_argos(a_varargin)

% output parameters initialization
o_inputError = 0;

% global input parameter information
global g_decArgo_processModeAll;
global g_decArgo_processModeRedecode;
global g_decArgo_inputArgosFile;
global g_decArgo_inputFloatWmo;
global g_decArgo_inputFloatWmoList;
g_decArgo_processModeAll = [];
g_decArgo_processModeRedecode = [];
g_decArgo_inputArgosFile = [];
g_decArgo_inputFloatWmo = [];
g_decArgo_inputFloatWmoList = [];

% global configuration values
global g_decArgo_generateNcTraj;
global g_decArgo_generateNcMultiProf;
global g_decArgo_generateNcMonoProf;
global g_decArgo_generateNcTech;
global g_decArgo_generateNcMeta;

% DOM node of XML report
global g_decArgo_xmlReportDOMNode;

% minimum number of float messages in an Argos file to be processed within the
% 'profile' mode
global g_decArgo_minNumMsgForProcessing;


% check input parameters
processModeInputParam = 0;
argosFileInputParam = 0;
floatWmoInputParam = 0;
floatWmoListInputParam = 0;
if (~isempty(a_varargin))
   if (rem(length(a_varargin), 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
      o_inputError = 1;
      return
   else
      for id = 1:2:length(a_varargin)
         if (strcmpi(a_varargin{id}, 'processmode'))
            if (processModeInputParam == 0)
               processModeInputParam = 1;
               if (strcmpi(a_varargin{id+1}, 'all'))
                  g_decArgo_processModeAll = 1;
                  g_decArgo_processModeRedecode = 0;
               elseif (strcmpi(a_varargin{id+1}, 'profile'))
                  g_decArgo_processModeAll = 0;
                  g_decArgo_processModeRedecode = 0;
               elseif (strcmpi(a_varargin{id+1}, 'redecode'))
                  g_decArgo_processModeAll = 1;
                  g_decArgo_processModeRedecode = 1;
               else
                  fprintf('ERROR: inconsistent input arguments => exit\n');
                  o_inputError = 1;
                  return
               end
               
               % store input parameter in the XML report
               g_decArgo_xmlReportDOMNode = add_element_in_xml_report(g_decArgo_xmlReportDOMNode, 'param_processmode', a_varargin{id+1});
            else
               fprintf('ERROR: inconsistent input arguments => exit\n');
               o_inputError = 1;
               return
            end
         elseif (strcmpi(a_varargin{id}, 'argosfile'))
            if (argosFileInputParam == 0)
               argosFileInputParam = 1;              
               g_decArgo_inputArgosFile = a_varargin{id+1};
               
               % store input parameter in the XML report
               g_decArgo_xmlReportDOMNode = add_element_in_xml_report(g_decArgo_xmlReportDOMNode, 'param_argosfile', a_varargin{id+1});
            else
               fprintf('ERROR: inconsistent input arguments => exit\n');
               o_inputError = 1;
               return
            end
         elseif (strcmpi(a_varargin{id}, 'floatwmo'))
            if ((floatWmoInputParam == 0) && (floatWmoListInputParam == 0))
               floatWmoInputParam = 1;              
               g_decArgo_inputFloatWmo = a_varargin{id+1};
               
               % store input parameter in the XML report
               g_decArgo_xmlReportDOMNode = add_element_in_xml_report(g_decArgo_xmlReportDOMNode, 'param_floatwmo', a_varargin{id+1});
            else
               fprintf('ERROR: inconsistent input arguments => exit\n');
               o_inputError = 1;
               return
            end
         elseif (strcmpi(a_varargin{id}, 'floatwmolist'))
            if ((floatWmoInputParam == 0) && (floatWmoListInputParam == 0))
               floatWmoListInputParam = 1;              
               g_decArgo_inputFloatWmoList = a_varargin{id+1};
               
               % store input parameter in the XML report
               g_decArgo_xmlReportDOMNode = add_element_in_xml_report(g_decArgo_xmlReportDOMNode, 'param_floatwmolist', a_varargin{id+1});
            else
               fprintf('ERROR: inconsistent input arguments => exit\n');
               o_inputError = 1;
               return
            end
         else
            fprintf('WARNING: unexpected input argument (%s) => ignored\n', a_varargin{id});
         end
      end
   end
end

% check mandatory input parameters
if (processModeInputParam == 0)
   fprintf('ERROR: ''processmode'' input param is mandatory => exit\n');
   o_inputError = 1;
   return
end
if (g_decArgo_processModeRedecode == 0)
   if (argosFileInputParam == 0)
      fprintf('ERROR: ''argosfile'' input param is mandatory when ''processmode'' = ''all'' or ''profile'' => exit\n');
      o_inputError = 1;
      return
   end
else
   if ((floatWmoInputParam == 0) && (floatWmoListInputParam == 0))
      fprintf('ERROR: ''floatwmo'' or ''floatwmolist'' input param is mandatory when ''processmode'' = ''redecode'' => exit\n');
      o_inputError = 1;
      return
   end
end
   
% update the XML report
docNode = g_decArgo_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('processmode');
if (g_decArgo_processModeRedecode == 1)
   newChild.appendChild(docNode.createTextNode('redecode'));
elseif (g_decArgo_processModeAll == 1)
   newChild.appendChild(docNode.createTextNode('all'));
else
   newChild.appendChild(docNode.createTextNode('profile'));
end
docRootNode.appendChild(newChild);

if (g_decArgo_processModeRedecode == 1)
   if (~isempty(g_decArgo_inputFloatWmo))
      newChild = docNode.createElement('floatwmo');
      newChild.appendChild(docNode.createTextNode(g_decArgo_inputFloatWmo));
      docRootNode.appendChild(newChild);
   elseif (~isempty(g_decArgo_inputFloatWmoList))
      newChild = docNode.createElement('floatwmolist');
      newChild.appendChild(docNode.createTextNode(g_decArgo_inputFloatWmoList));
      docRootNode.appendChild(newChild);
   end
else
   newChild = docNode.createElement('argosfile');
   newChild.appendChild(docNode.createTextNode(g_decArgo_inputArgosFile));
   docRootNode.appendChild(newChild);
end

% check the Argos input file
if (g_decArgo_processModeRedecode == 0)
   if ~(exist(g_decArgo_inputArgosFile, 'file') == 2)
      fprintf('ERROR: input Argos file (%s) does not exist => exit\n', g_decArgo_inputArgosFile);
      o_inputError = 1;
      return
   end
end

% check the WMO list file
if (g_decArgo_processModeRedecode == 1)
   if (~isempty(g_decArgo_inputFloatWmoList))
      if ~(exist(g_decArgo_inputFloatWmoList, 'file') == 2)
         fprintf('ERROR: input WMO list file (%s) does not exist => exit\n', g_decArgo_inputFloatWmoList);
         o_inputError = 1;
         return
      end
   end
end

% in 'profile' mode, check that the Argos input file contains at least
% g_decArgo_minNumMsgForProcessing float messages
if ((g_decArgo_processModeAll == 0) && (g_decArgo_processModeRedecode == 0))
   % argos input file name
   [pathstr, inputArgosFileName, ext] = fileparts(g_decArgo_inputArgosFile);
   idPos = strfind(inputArgosFileName, '_');
   if (~isempty(idPos))
      floatArgosId = str2num(inputArgosFileName(1:idPos(1)-1));
      
      [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
         argosDataDate, argosDataData] = read_argos_file({g_decArgo_inputArgosFile}, floatArgosId, 31);
      if (length(argosDataDate) < g_decArgo_minNumMsgForProcessing)
         fprintf('INFO: in ''profile'' mode the Argos input file should contain at least %d float messages to be processed\n', ...
            g_decArgo_minNumMsgForProcessing);
         o_inputError = 1;
         return
      end
   end
end

% update the NetCDF output file generation flags
if (g_decArgo_processModeAll == 0)
   g_decArgo_generateNcTraj = 0;
   g_decArgo_generateNcMultiProf = 0;
   g_decArgo_generateNcMonoProf = 2;
   g_decArgo_generateNcTech = 0;
   g_decArgo_generateNcMeta = 0;
end

return
