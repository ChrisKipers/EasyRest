public class XMLParser {
	public static Map<String, Object> getMapFromXMLString(String xml) {
		DOM.Document doc = new DOM.Document();
		doc.load(xml);
		DOM.XMLNode root = doc.getRootElement();
		return getMapFromNode(root);
	}
	
	private static Map<String, Object> getMapFromNode(Dom.XMLNode xmlNode) {
		Map<String, Object> nodeResults = new Map<String, Object>();
		if (xmlNode.getNodeType() == DOM.Xmlnodetype.ELEMENT) {
			if (String.isNotBlank(xmlNode.getText())) {
				nodeResults.put(xmlNode.getName(),xmlNode.getText());
			} else {
				List<Object> childrenMaps = new List<Object>();
				for (Dom.XMLNode child : xmlNode.getChildElements()) {
					childrenMaps.add(getMapFromNode(child));
				}
				nodeResults.put(xmlNode.getName(),childrenMaps);
			}
		}
		return nodeResults;
	}
}