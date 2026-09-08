package com.mrc.config;

import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathFactory;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStreamReader;
import java.io.StringReader;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;

public class AppConfig {


    // private static final String CONFIG_FILE = "C:\\Users\\95301\\Desktop\\CONNECTION_LOCAL.XML";
    private static final String CONFIG_FILE = "C:\\App\\config\\CONNECTION.XML";

    private static final byte[] DES_IV = {
            (byte) 0x12, (byte) 0x34, (byte) 0x56, (byte) 0x78,
            (byte) 0x90, (byte) 0xAB, (byte) 0xCD, (byte) 0xEF
    };

    private String passphraseCode;
    private final Map<String, String> serverConfig = new HashMap<>();
    private final Map<String, String> connectionStrings = new HashMap<>();

    public AppConfig() throws Exception {
        Document doc = loadDocument();
        XPath xpath = XPathFactory.newInstance().newXPath();

        loadPassphraseCode(doc, xpath);
        loadSection(doc, xpath, "//Configuration/ServerConfig", serverConfig, false);
        loadSection(doc, xpath, "//Configuration/ConnectionStrings", connectionStrings, true);
    }

    private void loadPassphraseCode(Document doc, XPath xpath) throws Exception {
        Node node = (Node) xpath.evaluate("//Configuration/PassphraseCode/add[@key='code']", doc, XPathConstants.NODE);
        if (node != null) {
            passphraseCode = getAttribute(node, "value");
        }
    }

    private Document loadDocument() throws Exception {
        String xml = readConfigFile();
        if (xml == null || xml.trim().isEmpty()) {
            throw new RuntimeException("CONNECTION.XML not found");
        }

        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        factory.setNamespaceAware(false);
        factory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
        factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
        factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
        DocumentBuilder builder = factory.newDocumentBuilder();
        return builder.parse(new InputSource(new StringReader(xml)));
    }

    private String readConfigFile() throws Exception {
        File file = new File(CONFIG_FILE);
        if (!file.exists()) {
            throw new FileNotFoundException("Config file not found: " + file.getAbsolutePath());
        }
        return readFile(file);
    }

    private String readFile(File file) throws Exception {
        try (FileInputStream is = new FileInputStream(file);
             InputStreamReader reader = new InputStreamReader(is, StandardCharsets.UTF_8)) {
            StringBuilder sb = new StringBuilder();
            char[] buf = new char[4096];
            int n;
            while ((n = reader.read(buf)) != -1) {
                sb.append(buf, 0, n);
            }
            return sb.toString();
        }
    }

    private void loadSection(Document doc, XPath xpath, String sectionPath,
                             Map<String, String> target, boolean isConnectionString) throws Exception {
        NodeList sections = (NodeList) xpath.evaluate(sectionPath, doc, XPathConstants.NODESET);
        if (sections == null || sections.getLength() == 0) {
            return;
        }

        for (int i = 0; i < sections.getLength(); i++) {
            Node section = sections.item(i);
            NodeList children = section.getChildNodes();
            for (int j = 0; j < children.getLength(); j++) {
                Node child = children.item(j);
                if (!"add".equals(child.getNodeName())) {
                    continue;
                }
                String key = getAttribute(child, "key");
                String value = getAttribute(child, "value");
                if (key == null) {
                    continue;
                }

                if (isConnectionString) {
                    String passphrase = getAttribute(child, "passphrase");
                    target.put(key, buildConnectionString(value, passphrase));
                } else {
                    target.put(key, value);
                }
            }
        }
    }

    private String getAttribute(Node node, String name) {
        Node attr = node.getAttributes().getNamedItem(name);
        return attr != null ? attr.getNodeValue() : null;
    }

    private String buildConnectionString(String template, String passphrase) {
        if (template == null) {
            return null;
        }
        String dbServer = serverConfig.get("DBServer");
        if (dbServer == null) {
            dbServer = "";
        }
        String passwordPart = passphrase != null ? "password=" + decrypt(passphrase) : "";
        return template.replace("{0}", dbServer).replace("{1}", passwordPart);
    }

    private String decrypt(String input) {
        if (input == null || input.trim().isEmpty()) {
            return "";
        }
        try {
            if (passphraseCode == null || passphraseCode.length() < 8) {
                return "";
            }
            byte[] key = passphraseCode.substring(0, 8).getBytes(StandardCharsets.UTF_8);
            byte[] encrypted = Base64.getDecoder().decode(input);

            Cipher cipher = Cipher.getInstance("DES/CBC/PKCS5Padding");
            SecretKeySpec keySpec = new SecretKeySpec(key, "DES");
            IvParameterSpec ivSpec = new IvParameterSpec(DES_IV);
            cipher.init(Cipher.DECRYPT_MODE, keySpec, ivSpec);

            byte[] decrypted = cipher.doFinal(encrypted);
            return new String(decrypted, StandardCharsets.UTF_8);
        } catch (Exception e) {
            return "";
        }
    }

    public String getConnectionString(String name) {
        return connectionStrings.get(name);
    }

    public String getServerConfig(String key) {
        return serverConfig.get(key);
    }

    public String getDbUrl() {
        return getConnectionString("BPSS");
    }

}
