% ------------------------------------------------------------------------------
% Add a new element (name, value) in the XML report.
%
% SYNTAX :
%  [o_xmlReportDOMNode] = add_element_in_xml_report(a_xmlReportDOMNode, a_elmtName, a_elmtValue)
%
% INPUT PARAMETERS :
%   a_xmlReportDOMNode : input DOM node of the XML report
%   a_elmtName         : name of the element to add
%   a_elmtValue        : value of the element to add
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%   o_xmlReportDOMNode : updated DOM node of the XML report
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/17/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_xmlReportDOMNode] = add_element_in_xml_report(a_xmlReportDOMNode, a_elmtName, a_elmtValue)

% output parameters initialization
o_xmlReportDOMNode = [];


% add element in the XML report
docNode = a_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;
newChild = docNode.createElement(a_elmtName);
newChild.appendChild(docNode.createTextNode(a_elmtValue));
docRootNode.appendChild(newChild);

o_xmlReportDOMNode = docNode;

return
