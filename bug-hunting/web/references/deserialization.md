# Insecure Deserialization Reference

## Attack Surface Signals
- Serialized data in cookies, hidden inputs, API bodies:
  - Java: Base64 starting with `rO0AB...` or hex `ac ed 00 05`.
  - PHP: Strings starting with `O:4:"User":...`, `a:2:{...}`.
  - Python: `pickle` / `cPickle` payloads (base64 `gAN...` or `cos
system...`), PyYAML `!!python/object`.
  - .NET: `ViewState`, `BinaryFormatter`, `TypeNameHandling.All` in JSON.NET.
  - Ruby: `Marshal.load` (`...`), YAML `--- !ruby/object:...`.

## Exploitation Patterns & Gadget Chains
1. **Java Deserialization**:
   - Sinks: `ObjectInputStream.readObject()`, RMI, JMX, Spring HTTPInvoker.
   - Tooling: `ysoserial` generating gadget chains (CommonsCollections, Spring, Jackson, Rome).
2. **PHP Object Injection (POP Chains)**:
   - Sinks: `unserialize()` triggering magic methods (`__destruct`, `__wakeup`, `__toString`, `__call`).
   - Tooling: `PHPGGC` for Laravel, Symfony, Guzzle, Monolog gadget generation.
3. **Python Pickle**:
   - Sinks: `pickle.loads()`, `yaml.load()` (without SafeLoader).
   - Exploit: Class with `__reduce__` method returning `(os.system, ('command',))`.
4. **.NET Deserialization**:
   - Sinks: `BinaryFormatter`, `NetDataContractSerializer`, `LosFormatter`, JSON.NET with `$type`.
   - Tooling: `ysoserial.net` (TypeConfuseDelegate, ActivitySurrogateSelector, ObjectDataProvider).

## Exploit Chains
- **Serialized Cookie / Body → Gadget Execution → Pre-Auth Remote Code Execution**.
