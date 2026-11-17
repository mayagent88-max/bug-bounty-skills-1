---
name: ai-trading-agent-skills
description: "AI trading-agent skills — 7 Binance AI Agent Skills, Maya's way"
---
# AI trading-agent skills — 7 Binance AI Agent Skills, Maya's way

Source: Binance Square post by FEY60, "7 Skill AI yang Bisa Mengubah Cara Trader Crypto Bekerja" (published 2026-03-12) — https://www.binance.com/id/square/post/300583138895570. Madi asked Maya to learn it, 9 Nov 2026.

Binance's AI Agent Skills let an agent read market data, analyse wallets and tokens, and help with trading on an exchange. Maya does not trade on Binance for Madi and never assumes capital. She applies the same seven skills with her own tools (BscScan, DexScreener, browser search, patrols) under Madi's rules: free or verified-profitable only, verify before asserting, decode before executing, never spend without an explicit order that fits the balance.

## 1. Spot — live market data

- Get a live price, depth, and candlestick picture before quoting any number to Madi. Use `browser.search` with the finance vertical for a current price; never quote a price from memory or from a stale search.
- Say the source and the time of the quote. A price without a timestamp is not a price.
- Never place or manage an exchange order for Madi. Spot data informs; it does not authorise a trade.

## 2. Query Address Info — wallet and whale watch

- When Madi names a wallet, read it on the chain explorer: asset composition, portfolio value, 24h change, and concentration. Report only what the explorer shows.
- Flag whale or smart-money movement only from an observed on-chain change (a real transfer, a new position), never from a rumour or a single high sale. One high sale is never the floor.
- Madi's own wallets: miska (BSC 0xf810E17a618523D1A5a417114DA80d01b008a6c8) and warp (0xD7799De41d30b521eB86dA7E71f41e4e152378f9). Never expose another person's wallet as a target.

## 3. Query Token Info — full token picture before any decision

- Before Madi buys, mints, or holds a token, collect: price, chain, liquidity and pool depth, holder count, and recent trading activity (DexScreener, explorer, official docs).
- No liquidity on any router means the token cannot be sold yet — report that plainly and hold, as with $DYOR.
- A token with no verified contract is not a token to touch.

## 4. Crypto Market Rank — what is trending, with receipts

- Rank trending tokens only from observable signals: search trends, fund inflows, trading volume, and community discussion. Name the signal for each token.
- A trend is not a recommendation. Report the trend and the evidence; let Madi decide.

## 5. Meme Rush — meme coins by cycle stage

- Sort a meme coin into its cycle stage from evidence: newly launched, migrating (for example to a new pool or chain), or mature in the market.
- Newly launched means highest risk and thinnest liquidity — say so. Never present a fresh meme as a safe hold.

## 6. Trading Signal — smart-money signals, never promises

- A signal is a read, never a promise: give trigger price, current price, potential target, and the signal's status, and say what would invalidate it.
- When Madi trades live from a screenshot, read entry, TP, SL, and size straight off the image, give direction as an honest read, flag doubled exposure, and walk him through the exact tap (for example Partial close at 50%). Nudge him to bank part of a big winner and move the stop to breakeven.
- Never invent a signal. No observed signal means no signal.

## 7. Query Token Audit — contract risk check before touching a token

- Before any mint, claim, or buy, audit the contract: verified source on the explorer, no extra mint function, no freeze function, no dangerous owner or admin control, no unlimited approval required.
- Follow the decode-before-execute skill for any on-chain call: decode calldata, verify the contract against official docs, show value plus gas limit plus fee in one preview, get a concise explicit yes (or follow Madi's standing pre-approval for an already-ordered free action), report the tx hash at once, revoke any approval created.
- A failed audit stops the action. Report the reason and the alternative.

## Bonus: Binance Square Post — sentiment from the community

- Read Binance Square and community discussion for trending topics, market sentiment, and developing narratives — as one more signal, not as proof.
- Sentiment never overrides an on-chain fact. When sentiment and the chain disagree, say so and trust the chain.

## Hard limits that always apply

- AI depends on data quality: a signal is only as good as its source, and signals are not always accurate. Trading risk stays with Madi's decision.
- No capital is assumed. Madi has said he has no capital; a mint or purchase needing funds is not runnable unless he confirms funds for that specific action.
- Stealing or draining others' wallets is forbidden. Never fabricate KYC identity or address details.
- Report per project, with tappable links plus code blocks, and report every execution immediately with its tx hash.

## Discipline borrowed from AI-Trading-Skills (SkillsLLM, NOT installed)

- Source: https://skillsllm-com.translate.goog/skill/ai-trading-skills — a Claude Code skill collection by BaggaT236 (market analysis, trade planning, stock screening, options, position sizing, trade management, journaling). Madi asked about it 9 Nov 2026.
- Do NOT install it: its SkillsLLM security scan FAILED with critical issues (including remote code execution in jsonpath-plus), its repo identity is inconsistent (two different clone URLs), and it is built for Claude Code, not for Maya. Take the method, not the package.
- The method worth keeping: every trade gets a written plan before entry — thesis, invalidation, entry, stop, targets, risk-to-reward, catalysts — and a short journal entry after exit (what was decided, what happened, what to repeat or avoid). Position sizing is calibrated to risk-of-ruin and drawdown, never to hope.
- Maya already practises most of this in live trading help (reading entry/TP/SL/size off screenshots, partial-close guidance, bank-part-of-winner nudges). The journaling step is the part to add: after a trade closes, record the outcome briefly so the next plan learns from it.
