# Meta-family signup flows: step order, risk gate, and diagnosis

Applies to Muse.ai and any product that delegates account creation to Meta's shared account
and risk infrastructure. Automation quality is not the limiting factor — the egress IP and
fingerprint are.

## Step order the automation must handle, in sequence

1. **Email/phone entry.** Input carries `autocomplete="username webauthn"`; submit is a
   `button[type="submit"]`. Placeholder is locale-dependent (e.g. `手机号或邮箱`).
2. **Email OTP.** Input carries `autocomplete="one-time-code"`. Read the code from the
   disposable inbox (mail.tm); never guess or brute-force it.
3. **Completion page.** Requires first name (`autocomplete="given-name"`), last name
   (`autocomplete="family-name"`), and three date selects
   (`autocomplete="bday-year"`, `bday-month`, `bday-day`). The submit button
   (`data-pel-click="login_birthday_continue_click"`) stays `disabled` until *every* field
   is set — a disabled button after the dates are correct means the name inputs are empty.
4. **Disclosure, then card.** The age-verification hold is a real (refundable) charge, and
   this step sits behind the risk gate below.

## The risk gate

**Signature:** a modal carrying
`data-pel-impression="login_registration_rejected_dialog_impression"`, body text
`你目前无法创建新账户` (zh) / "You currently cannot create a new account." (en).

This fires *after* the form validates and the submit button enables, so it is a server-side
rejection — not a selector bug, not a timing bug. Do not re-run the pipeline hoping for a
different result: each attempt from the same datacenter IP deepens the flag. The only lever
is a residential-proxy egress. Report the block plainly instead of retrying.

## Diagnosing "form never hydrated" in one shot

Dump the real DOM rather than retrying blind:

```javascript
(() => {
  const els = [...document.querySelectorAll('input,select,button,a')].map(x => ({
    tag: x.tagName,
    ph: x.placeholder || '',
    ac: x.autocomplete || '',
    txt: (x.innerText || '').trim().slice(0, 30)
  })).filter(x => x.ph || x.ac || x.txt);
  return JSON.stringify({ url: location.href, title: document.title, els: els.slice(0, 25) }, null, 1);
})()
```

Read three things from the output: the **locale** (placeholder language), the **step**
(email vs. date-selects vs. name inputs), and the **field order** (never assume `nth(0)` is
the month — the DOM order is year, month, day).

## Intermittent hydration

The same fresh profile sometimes lands on the email form and sometimes on a later step.
Navigate explicitly with `page.goto(...)`, reload up to three times before declaring
failure, and branch on what the DOM actually shows instead of assuming the first step.
