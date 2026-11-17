---
name: check_minimum_before_send
description: "Check minimums before any transfer"
---
# Check minimums before any transfer

## Check all three minimums

- Check the minimum deposit, the minimum withdrawal, and the minimum order size before you send any transfer or place any trade.

- Read each minimum from the official page or from a screenshot the user sent, and never read it from memory.

- Apply this check to every transfer, including a deposit, a withdrawal, a trade, and a priced mint.

- Run the check even for a tiny amount, and treat it the same as a large one.

## Read the live value

- Open the deposit screen to read the deposit minimum, open the withdrawal screen to read the withdrawal minimum, and open the trading rules for the pair to read the order minimum.

- Record each verified minimum together with its source and the time you checked it, and report those three values before you send anything.

- Read the live value on every run, and never write a fixed minimum number into a note or a message as a lasting fact.

- Treat every minimum as changeable, and recheck it when the amount, the asset, or the destination changes.

## Stop when a minimum is unverified

- Stop and ask the user when you cannot verify a minimum from an official source, and do not send anything until the answer arrives.

- Ask the user to read the minimum from the official screen and send it to you, and never guess the number yourself.

- Treat a deposit sent below the minimum as lost, because the exchange does not credit it.

- Never send an amount at or below an unverified minimum.

## Available connectors

- Use `muse.connector_search` to find other connectors and `muse.skill_search` to find related skills.

- If nothing here fits, look on the web for a maintained API or MCP server and set it up with [Custom Connectors and MCPs](/opt/muse/skills/custom-connector-setup/SKILL.md), or build a custom connector.
