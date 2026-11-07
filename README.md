# Order Flow

[![CI](https://github.com/MrChartist/order-flow/actions/workflows/ci.yml/badge.svg)](https://github.com/MrChartist/order-flow/actions/workflows/ci.yml)
[![License: PolyForm Noncommercial](https://img.shields.io/badge/license-PolyForm%20Noncommercial-16d98a.svg)](LICENSE)
![Node 22.18+](https://img.shields.io/badge/node-%E2%89%A522.18-informational.svg)

By **[Mr. Chartist](https://mrchartist.com)** · [X](https://x.com/Mr_Chartist) · [YouTube](https://www.youtube.com/mr_chartist) · [Instagram](https://instagram.com/mrchartist) · [LinkedIn](https://www.linkedin.com/in/rohit-mrchartist/) · [GitHub](https://github.com/MrChartist)

A live board of the Indian F&O market. Every underlying is read from its future: the bulls rise above the zero line, the bears fall below it, the whole market squeezes through two tunnels and fans out to a card for each name. Open it at any hour: real sessions from the exchanges' own archive, two recorded sessions and a simulated market keep it moving with no keys, and any API can be plugged in behind it with a few settings.

![Order Flow replaying Friday 6 Nov 2026 from the NSE archive](docs/order-flow-light.webp)

<table>
  <tr>
    <td width="66%"><img src="docs/order-flow-dark.webp" alt="Order Flow, dark theme"></td>
    <td width="34%"><img src="docs/order-flow-phone.webp" alt="Order Flow on a phone"></td>
  </tr>
</table>

![A pinned stock: 5-minute candles, support and resistance, the open-interest zone and why it ranks where it does](docs/order-flow-detail.webp)

<sub>Screenshots: the NSE archive session of 6 Nov 2026 (`npm run dev:archive`).</sub>

**Contents:** [Quick start](#quick-start) · [Your to-do list](#your-to-do-list) · [Reading the board](#reading-the-board) · [Data](#data) · [Connect any API](#connect-any-api) · [Configuration](#configuration) · [Server API](#server-api) · [Security](#security) · [Development](#development) · [Project layout](#project-layout) · [Contributing](#contributing) · [License](#license) · [About](#about)

## Quick start

```bash
npm install
npm run dev:archive      # a real session from the NSE and BSE archive (6 Nov 2026), replayed live
# or
npm run dev:recorded     # a real session recorded minute by minute (30 Oct 2026)
# or
npm run dev              # the simulated demo market
```

Fetch the latest session from the exchanges' archive at any time with `npm run fetch:nse` (no keys).

Open http://127.0.0.1:5195. This starts the server on port 8787 and the page on 5195. No keys or accounts are needed. Requires Node 22.18 or newer.

For production, one process serves the API and the built page:

```bash
npm run build
npm start          # http://127.0.0.1:8787 (npm run start:recorded for the recorded day)
```

## Your to-do list

Pick how far you want to go. Each step stands on its own.

**1. See it working (2 minutes, no keys)**
- [ ] `npm install`
- [ ] `npm run dev:recorded` and open http://127.0.0.1:5195
- [ ] Try the **Nifty 50 / All F&O** switch, the theme switch, and click a card to pin its detail

**2. Replay the latest real session (1 minute, no keys)**
- [ ] `npm run fetch:nse` downloads the latest NSE and BSE F&O bhavcopy and builds a session
- [ ] `npm run dev:archive`: the status line says `NSE archive <date> · replay`

**3. Use your own live data**
- [ ] `cp .env.example .env`
- [ ] Any JSON API: set `MF_PROVIDER=http` and `MF_HTTP_BASE_URL` (see [Connect any API](#connect-any-api)); or Upstox (`upstox`, plus `UPSTOX_ACCESS_TOKEN`); or write a full adapter with [PROVIDERS.md](PROVIDERS.md) and its ready-made prompt for an AI coding assistant
- [ ] `npm run check:provider` and fix anything marked `FIX`
- [ ] `npm run dev`: the status line now names your broker

**4. Keep your own sessions**
- [ ] After a session, `npm run record -- YYYY-MM-DD` saves it to `data/recorded/`
- [ ] `MF_RECORDED_DATE=YYYY-MM-DD npm run dev:recorded` replays it

**5. Put it online, safely**
- [ ] `npm run build`
- [ ] Either keep `HOST=127.0.0.1` behind a reverse proxy with HTTPS and sign-in, or set `HOST=0.0.0.0` **and** `MF_BASIC_AUTH=user:password` (HTTPS in front all the same)
- [ ] Keep `.env` out of git (it already is) and read the [Security](#security) section
- [ ] `npm start`

## Reading the board

| Part | What it shows |
|---|---|
| **Status line** (top left) | The data source (`Demo market · live`, `Upstox`, …), how the market splits (`63 up · 91 flat · 58 down of 217`) and the time the board stands for. While futures are still being read it says `Updating · futures 84 of 217`. |
| **Spread strip** | Every underlying as a dot, placed by its move: the shape of the day at a glance. NIFTY is the diamond. |
| **Chart** | Each name's futures move through the session, from 0% at the open. Bold lines are the biggest movers each side; the white dotted line is NIFTY. A name whose future has not been read yet runs dashed from the open to its spot move until it lands. |
| **Sector pills** | Each sector's median move, leader at the top, laggard at the bottom; the small bar under each is its up/flat/down split. Hover one to light its stocks. |
| **Tunnels** | Every bullish line squeezes through the green tunnel at the top, every bearish one through the red tunnel at the bottom, then fans out to its card. |
| **The bar** | The zero line, carried on between the halves. Flat names end in it. |
| **Tiles** | One per name, ranked by the move. The colour deepens with the size of the move; the dot is the build-up (filled: new positions, hollow: positions closing). A tile flashes when its move changes. |
| **Tall tiles** | The strongest readings each side, with option open interest by strike around spot (puts left, calls right). |
| **Big cards** | The same names in full: the move, the futures price, conviction (how many checks hold), support, resistance and the zone where open interest was added, with 5-minute candles. |
| **Hover / click** | Hover any tile, card or line to light its path and open its detail; click to pin it. |
| **Nifty 50 / All F&O** | The universe: the NIFTY 50 constituents (`src/features/market-flow/nifty50.ts`) or all ~217 F&O underlyings. Remembered per browser. |
| **Theme switch** | White (the default) or dark; your choice is remembered. |

Build-up, from a future's price and open interest together:

| Price | Open interest | Reads as |
|---|---|---|
| up | up | Long build-up |
| up | down | Short covering |
| down | up | Short build-up |
| down | down | Long unwinding |

## Data

The page reads only from its own server. Where the server gets its numbers is a **provider**:

| Provider | `MF_PROVIDER` | Status |
|---|---|---|
| Demo market | `demo` (default) | Built in. A simulated, always-live session for every F&O underlying, priced near the newest real session on disk. |
| NSE archive | `archive` | Built in. Real sessions from the exchanges' public F&O bhavcopy (`npm run fetch:nse`; 6 Nov 2026 ships with the repo), replayed live. `npm run dev:archive`. |
| Recorded sessions | `recorded` | Built in. Real sessions (29 and 30 Oct 2026 ship with the repo) replayed live, minute by minute. `npm run dev:recorded`. |
| Any JSON API | `http` | Built in. Point `MF_HTTP_BASE_URL` at any API; reshape its JSON with an optional map file. See [Connect any API](#connect-any-api). |
| Upstox | `upstox` | Written against Upstox's documented API; verify it with your token (see [PROVIDERS.md](PROVIDERS.md)). |
| Your broker | `<id>` | Copy `server/providers/template.mjs` and follow [PROVIDERS.md](PROVIDERS.md). |

### The demo market

Every number is generated and deterministic: the same session plays out the same way on every machine. It has a market mood, a mood per sector and each stock's own move. Futures carry a basis and an open-interest build-up that agrees with the move most of the time. Option chains are priced with Black-Scholes on a volatility smile, with open interest on round strikes. In market hours it follows the real clock. Outside them it replays the latest session in real time from 09:20 to 15:30 and round again, so the board is always moving. **Demo prices are not real quotes.**

### The NSE archive: real sessions with no keys

`npm run fetch:nse` builds a session from the exchanges' own end-of-day F&O files, then `npm run dev:archive` replays it. The flow:

```
 NSE + BSE archive          parse                  build                       replay
┌──────────────────┐   ┌──────────────┐   ┌─────────────────────────┐   ┌──────────────────┐
│ F&O bhavcopy     │──▶│ one row per  │──▶│ chains: real closing OI │──▶│ data/archive/    │──▶ the board
│ (UDiFF CSV) for  │   │ contract:    │   │  by strike, prev OI,    │   │  <date>.json.gz  │    (archive
│ the day and the  │   │ futures and  │   │  premiums, volume       │   │                  │     provider)
│ day before       │   │ options      │   │ futures: real O/H/L/C,  │   │ same format as a │
└──────────────────┘   └──────────────┘   │  prev close, OI; the    │   │ recorded session │
                                          │  1-minute path rebuilt  │   └──────────────────┘
                                          └─────────────────────────┘
```

- **Download.** NSE's `BhavCopy_NSE_FO_…csv.zip` and BSE's `BhavCopy_BSE_FO_…CSV` for the day (the latest published one by default, or `npm run fetch:nse -- 2026-11-06`) and for the session before it. Files are cached in `data/archive/.cache` (git ignores it).
- **Chains.** Each underlying's nearest live expiry, 30 strikes either side of spot: the real closing open interest, previous open interest (OI minus its change), premiums, previous close and volume in units. Spot is the exchange's underlying price.
- **Futures.** The nearest three months with their real open, high, low, close, previous close and open interest. A bhavcopy is end of day, so the minute path between them is **rebuilt**: it opens at the real open, touches the real high and low and closes at the real close, with a market-wide component every name shares, so the board moves as one market. Open interest moves from the previous OI to the real closing OI. The same file builds the same path on every machine.
- **What is real.** Every closing number, build-up, support, resistance and zone on the board is the exchange's own. Only the shape of the line between the open and the close is rebuilt; use `recorded` (or your own feed) for real minute-by-minute paths.

The demo market reads its price levels from the newest session on disk, so after `npm run fetch:nse` even `npm run dev` sits at real prices. Terms of the data: [data/archive/README.md](data/archive/README.md).

### Recorded sessions

`data/recorded/` holds two real sessions, Thursday 29 and Friday 30 October 2026: every underlying's near and next-month futures, minute by minute with open interest, and its option chain. The `recorded` provider replays one in real time from 09:20 to 15:30 and round again (`MF_RECORDED_DATE` picks the day; the newest by default), so every move, build-up and candle on the board is that day's real one. The chains are a single snapshot taken after Friday's close, shared by both days; each chain's spot follows the day's futures. Where the data came from and its terms: [data/recorded/README.md](data/recorded/README.md). Record your own days with `npm run record`.

### Connecting a broker

```bash
cp .env.example .env
# set MF_PROVIDER=upstox and UPSTOX_ACCESS_TOKEN=...
npm run check:provider      # checks the provider against the contract
npm run dev
```

For any other broker, [PROVIDERS.md](PROVIDERS.md) has the contract, a step-by-step checklist and a prompt you can hand to an AI coding assistant to write the adapter for you.

## Connect any API

The `http` provider connects Order Flow to any JSON API with settings alone: a bridge in front of your broker, a data vendor, your own database or a service you already run.

```bash
MF_PROVIDER=http
MF_HTTP_BASE_URL=http://127.0.0.1:9000
# optional
MF_HTTP_TOKEN=...                                    # sent as Authorization: Bearer ...
MF_HTTP_HEADERS={"x-api-key":"..."}                  # any other headers, as JSON
MF_HTTP_EXPIRIES=/expiries/{symbol}                  # the three paths, as templates
MF_HTTP_CHAIN=/chain/{symbol}?expiry={expiry}
MF_HTTP_FUTURES=/futures/{symbol}?session={session}
MF_HTTP_MAP=./my-api-map.mjs                         # reshape another API's JSON
```

1. **See the shapes.** `node examples/http-api-server.mjs` serves the three routes from the session on disk; open `http://127.0.0.1:9000/chain/NIFTY` to see exactly what Order Flow expects.
2. **Point it at your API.** If your API already answers in those shapes, set `MF_HTTP_BASE_URL` (and the paths, which take `{symbol}`, `{exch}`, `{kind}`, `{apiKey}`, `{expiry}` and `{session}`).
3. **Or map it.** If your API has its own shapes, copy [`examples/http-map.example.mjs`](examples/http-map.example.mjs), change its three small functions, and set `MF_HTTP_MAP`. No provider code to write.
4. **Check it.** `MF_PROVIDER=http npm run check:provider`, then `npm run dev`.

Answers are normalised for you: ISO dates and epoch seconds become milliseconds, `{ data: … }` and `{ result: … }` wrappers are unwrapped, OHLC candle rows are read as they are, candles are sorted, and missing option fields become `null`. Requests are throttled (`MF_HTTP_RPS`, 10 a second by default).

## Configuration

Copy `.env.example` to `.env`.

| Variable | Default | Used by |
|---|---|---|
| `MF_PROVIDER` | `demo` | Server: which provider feeds the board (`demo`, `recorded`, `upstox`, …) |
| `MF_RECORDED_DATE` | newest | Server: the recorded day to replay |
| `MF_ARCHIVE_DATE` | newest | Server: the archive day to replay (`npm run fetch:nse` builds them) |
| `MF_HTTP_BASE_URL` | | `http` provider: your API (see [Connect any API](#connect-any-api) for the other `MF_HTTP_*` settings) |
| `PORT` | `8787` | Server port (the dev page proxies `/api` to it) |
| `HOST` | `127.0.0.1` | Server: who can reach it. `127.0.0.1` is this machine only |
| `MF_BASIC_AUTH` | | Server: `user:password` puts every route behind a password |
| `MF_CORS_ORIGIN` | | Server: one other origin allowed to read the API |
| `MF_DATA_DIR` | `server/data` | Server: today's minute snapshots, for the 15m and 1h windows |
| `UPSTOX_ACCESS_TOKEN` | | Upstox provider |
| `VITE_API_BASE` | same origin | Page: only when the page is hosted apart from the server |

## Server API

All responses are JSON. The page uses these; so can anything else.

| Route | Returns |
|---|---|
| `GET /api/status` | `{ provider: { id, label, alwaysLive }, ready, clock, session, market: { at, date, series }, lastBuild, lastError, universe }` |
| `GET /api/market` | The market file: every underlying's nearest-expiry option chain in a compact form (schema 1, see `server/marketFile.mjs`). Rebuilt every minute while the market moves. `503` until the first build. |
| `GET /api/market/<date>/<HHMM>` | An earlier minute of today's market file. |
| `GET /api/futures/<SYMBOL>?session=YYYY-MM-DD` | `{ symbol, session, months: [{ date, prevClose, prevOi, candles: [{ at, close, oi }] }] }`, nearest month first. |

## Security

Order Flow is private by default.

- **Reach.** The server listens on `127.0.0.1`, so only this machine can open it. To share it, set `HOST=0.0.0.0` **and** `MF_BASIC_AUTH=user:password`, or keep it on `127.0.0.1` behind a reverse proxy (nginx, Caddy, Cloudflare Access) that handles HTTPS and sign-in. With an open host and no password, the server warns at start.
- **HTTPS.** The server speaks plain HTTP. Anything beyond your own machine should go through a proxy with HTTPS, especially with a password on (Basic auth sends it with every request).
- **Read-only.** Only `GET` and `HEAD`, only the routes listed above. Nothing a visitor sends is stored or passed to a shell. Static files are served from `dist/` only; any other path gets the page.
- **Provider quota.** `/api/futures` serves only the current session and keeps each answer for a minute, so a visitor cannot make the server spend your broker's quota on history or in bursts. Chains are read by the server on its own schedule, never on a visitor's request.
- **Browser.** Strict headers on every answer: a Content-Security-Policy allowing only this origin, no framing, no MIME sniffing, no referrer. No cross-origin reads unless `MF_CORS_ORIGIN` names one. The page loads nothing from other sites (fonts and logos are bundled).
- **Secrets.** Broker credentials come from environment variables (`.env`, which git ignores) and are never logged or sent to the page. Provider errors are logged on the server; the page sees a plain message.
- **Robustness.** A malformed request gets an error answer, never a crash; slow clients are timed out.
- **Dependencies.** `npm audit` reports no known vulnerabilities at the time of writing; run it before you deploy.

## Development

```bash
npm test                 # unit and component tests (vitest)
npm run lint             # eslint
npm run check:provider   # the configured provider against the contract
npm run record -- DATE   # record a session from the configured provider
npm run fetch:nse        # build the latest session from the NSE and BSE archive
npm run dev:web          # the page only, if the server is already running
```

## Project layout

```
server/
  index.mjs              the server: collector, API routes, static hosting
  marketFile.mjs         chains → the market file the page reads
  checkProvider.mjs      npm run check:provider
  providers/
    types.mjs            the provider contract
    demo.mjs             the built-in demo market
    recorded.mjs         replays recorded and archive sessions
    http.mjs             any JSON API, by settings and an optional map
    upstox.mjs           Upstox adapter
    template.mjs         start here for another broker
src/
  features/market-flow/  the board: page, diagram, tiles, cards, model, feed
  features/options-scanner/  the market-file model and futures maths it builds on
  lib/marketSession.ts   NSE/BSE sessions and holidays, shared with the server
public/
  underlyings.json       the F&O universe: symbol, lot, kind, sector
  brand/underlyings/     company logos (see below)
data/archive/            sessions built from the NSE and BSE F&O bhavcopy (npm run fetch:nse)
data/recorded/           two real sessions (see its README for source and terms)
examples/                a reference API and a map for the http provider
scripts/                 dev runner, archive builder, session recorder, logo fetchers
```

## Contributing

Pull requests are welcome, especially adapters for more brokers. Read [CONTRIBUTING.md](CONTRIBUTING.md) first; for a new broker, [PROVIDERS.md](PROVIDERS.md) has everything. Report security issues privately, as described in [SECURITY.md](SECURITY.md).

## Logos and fonts

Company marks in `public/brand/underlyings/` come from Wikimedia Commons (freely licensed or below the threshold of originality) and, where Commons has none, from each company's own website icon (`scripts/fetch-site-icons.mjs`). Every mark was reviewed by eye; names without a confident match show a two-letter monogram instead. Marks are trademarks of their owners, shown only to identify the instrument, and are not covered by the Order Flow licence.

The interface is set in the Mr. Chartist website's own type, so the board reads as part of [mrchartist.com](https://mrchartist.com): Chartist Sans for headings, Chartist Sans Flex for text and figures, and Chartist Serif for the one accent word (renamed copies of Plus Jakarta Sans, Google Sans Flex and Instrument Serif, all under the SIL Open Font License 1.1, bundled in `src/assets/fonts/` with their licences). Details in [NOTICE.md](NOTICE.md).

## Disclaimer

Order Flow is an analysis view, not investment advice. In demo mode every number is simulated. Archive sessions carry the exchanges' real closing figures with a rebuilt intraday path. With a broker connected, figures are as accurate as that broker's feed.

## License

Order Flow is **free for personal, non-commercial use** under the [PolyForm Noncommercial License 1.0.0](LICENSE): use it, study it, change it for yourself. **Commercial use** (in a business, a paid product or service, or for trading on behalf of others) needs a separate licence: get in touch through [mrchartist.com](https://mrchartist.com).

Required Notice: Copyright (c) 2026 Mr. Chartist (https://mrchartist.com)

Third-party parts (logos, fonts, recorded data, dependencies) keep their own terms; see [NOTICE.md](NOTICE.md).

## About

Order Flow is made by **Mr. Chartist**, who builds charting and market-analysis tools for Indian traders.

[Website](https://mrchartist.com) · [X](https://x.com/Mr_Chartist) · [YouTube](https://www.youtube.com/mr_chartist) · [Instagram](https://instagram.com/mrchartist) · [LinkedIn](https://www.linkedin.com/in/rohit-mrchartist/) · [GitHub](https://github.com/MrChartist)
