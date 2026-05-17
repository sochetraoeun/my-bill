#!/usr/bin/env node
/**
 * Fetches Cambodia MEF USD/KHR reference and writes it to Firestore
 * (project my-bill-1a987), document settings/exchange_rate.
 *
 * Auth: service account JSON via FIREBASE_SERVICE_ACCOUNT (raw JSON string)
 * or GOOGLE_APPLICATION_CREDENTIALS (path to the JSON file).
 *
 * Optional: SCRAPERAPI_KEY — use ScraperAPI proxy when the MEF host blocks your runner.
 */

const crypto = require("crypto");
const fs = require("fs");
const https = require("https");

// --- Firebase / MEF (my_bill Firebase project: see firebase.json / lib/firebase_options.dart) ---
const PROJECT_ID = "my-bill-1a987";
const SETTINGS_DOC_PATH = "settings/exchange_rate";

const MEF_URL =
  process.env.EXCHANGE_RATE_API_URL?.trim() ||
  "https://data.mef.gov.kh/api/v1/realtime-api/exchange-rate";

// ---------------------------------------------------------------------------

function httpsRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const req = https.request(
      url,
      {
        method: options.method || "GET",
        headers: options.headers || {},
      },
      (res) => {
        const chunks = [];
        res.on("data", (c) => chunks.push(c));
        res.on("end", () => {
          const body = Buffer.concat(chunks).toString("utf8");
          resolve({ status: res.statusCode, headers: res.headers, body });
        });
      },
    );
    req.on("error", reject);
    if (options.body) req.write(options.body);
    req.end();
  });
}

function base64urlEncode(input) {
  return Buffer.from(input)
    .toString("base64")
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function loadServiceAccount() {
  const inline = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (inline && inline.trim()) {
    return JSON.parse(inline);
  }
  const path = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (path && path.trim()) {
    return JSON.parse(fs.readFileSync(path.trim(), "utf8"));
  }
  throw new Error(
    "Missing credentials: set FIREBASE_SERVICE_ACCOUNT (JSON) or GOOGLE_APPLICATION_CREDENTIALS (file path).",
  );
}

async function getAccessToken(credentials) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64urlEncode(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = base64urlEncode(
    JSON.stringify({
      iss: credentials.client_email,
      scope: "https://www.googleapis.com/auth/datastore",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );
  const toSign = `${header}.${payload}`;
  const sign = crypto.createSign("RSA-SHA256");
  sign.update(toSign);
  const sigBuf = sign.sign(credentials.private_key);
  const signature = base64urlEncode(sigBuf);
  const jwt = `${toSign}.${signature}`;

  const body = new URLSearchParams({
    grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
    assertion: jwt,
  }).toString();

  const { status, body: text } = await httpsRequest(
    "https://oauth2.googleapis.com/token",
    {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body,
    },
  );

  if (status !== 200) {
    throw new Error(`OAuth token error ${status}: ${text?.slice(0, 400)}`);
  }
  const json = JSON.parse(text);
  if (!json.access_token) {
    throw new Error(
      `No access_token in OAuth response: ${text?.slice(0, 300)}`,
    );
  }
  return json.access_token;
}

/** Same resolution as lib/services/exchange_rate_service.dart */
function findUsdRow(decoded) {
  if (!decoded || typeof decoded !== "object") return null;
  const data = decoded.data;
  if (Array.isArray(data)) {
    for (const row of data) {
      if (row && typeof row === "object" && row.currency_id === "USD") {
        return row;
      }
    }
    return null;
  }
  if (
    data &&
    typeof data === "object" &&
    !Array.isArray(data) &&
    data.currency_id === "USD"
  ) {
    return data;
  }
  if (decoded.currency_id === "USD") {
    return decoded;
  }
  if (Array.isArray(decoded)) {
    for (const row of decoded) {
      if (row && typeof row === "object" && row.currency_id === "USD") {
        return row;
      }
    }
  }
  return null;
}

function pickRate(row) {
  const raw = row.average ?? row.bid ?? row.ask;
  if (raw == null) return null;
  const n = typeof raw === "number" ? raw : parseFloat(String(raw).trim());
  if (!Number.isFinite(n) || n <= 0) return null;
  if (n < 1000 || n > 20000) return null;
  return n;
}

function toFirestoreFields(obj) {
  const fields = {};
  for (const [key, v] of Object.entries(obj)) {
    if (v === undefined || v === null) continue;
    if (typeof v === "string") {
      fields[key] = { stringValue: v };
    } else if (typeof v === "number") {
      fields[key] = Number.isInteger(v)
        ? { integerValue: String(v) }
        : { doubleValue: v };
    } else if (typeof v === "boolean") {
      fields[key] = { booleanValue: v };
    } else if (v instanceof Date) {
      fields[key] = { timestampValue: v.toISOString() };
    }
  }
  return fields;
}

function buildFirestoreUrl(projectId, docPath) {
  const encodedPath = docPath.split("/").map(encodeURIComponent).join("%2F");
  return `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${encodedPath}`;
}

async function upsertFirestoreDocument(accessToken, fields) {
  const url = buildFirestoreUrl(PROJECT_ID, SETTINGS_DOC_PATH);
  const fieldNames = Object.keys(fields);
  const mask = fieldNames
    .map((f) => `updateMask.fieldPaths=${encodeURIComponent(f)}`)
    .join("&");
  const patchUrl = `${url}?${mask}`;

  let status;
  let text;
  ({ status, body: text } = await httpsRequest(patchUrl, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fields }),
  }));

  if (status === 404) {
    const parent = buildFirestoreUrl(PROJECT_ID, "settings");
    const docId = SETTINGS_DOC_PATH.split("/").pop();
    const createUrl = `${parent}?documentId=${encodeURIComponent(docId)}`;
    ({ status, body: text } = await httpsRequest(createUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ fields }),
    }));
  }

  if (status !== 200) {
    throw new Error(`Firestore write ${status}: ${text?.slice(0, 600)}`);
  }
}

async function fetchMefJson() {
  const scraperKey = process.env.SCRAPERAPI_KEY?.trim();
  const targetUrl = scraperKey
    ? `http://api.scraperapi.com?api_key=${encodeURIComponent(scraperKey)}&url=${encodeURIComponent(MEF_URL)}`
    : MEF_URL;

  const { status, body } = await httpsRequest(targetUrl, {
    headers: { accept: "application/json" },
  });

  if (status !== 200) {
    throw new Error(`MEF/scraper HTTP ${status}: ${body?.slice(0, 400)}`);
  }

  let json;
  try {
    json = JSON.parse(body);
  } catch {
    throw new Error("Invalid JSON from MEF/scraper.");
  }
  return json;
}

async function main() {
  try {
    console.log("1. Fetching MEF exchange rate...");
    const json = await fetchMefJson();

    const row = findUsdRow(json);
    if (!row) {
      console.log("Full JSON:", JSON.stringify(json).slice(0, 2000));
      throw new Error("USD rate row not found in response.");
    }

    const khrPerUsd = pickRate(row);
    if (khrPerUsd == null) {
      throw new Error("Could not parse a valid KHR/USD rate.");
    }

    console.log(`   OK — KHR per 1 USD: ${khrPerUsd}`);

    const now = new Date();
    const formatter = new Intl.DateTimeFormat("en-CA", {
      timeZone: "Asia/Phnom_Penh",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    });
    const recordDate = formatter.format(now);

    const numOrSkip = (x) => {
      const n = typeof x === "number" ? x : parseFloat(String(x ?? "").trim());
      return Number.isFinite(n) ? n : undefined;
    };

    const payload = {
      khrPerUsd,
      recordDate,
      currency: String(row.currency ?? ""),
      currencyId: String(row.currency_id ?? ""),
      symbol: String(row.symbol ?? ""),
      unit: String(row.unit ?? ""),
      validDate: String(row.valid_date ?? ""),
      sourceCreatedAt: String(row.created_at ?? ""),
      fetchedAt: now,
      source: "mef.gov.kh",
    };
    const bid = numOrSkip(row.bid);
    const ask = numOrSkip(row.ask);
    const average = numOrSkip(row.average);
    if (bid !== undefined) payload.bid = bid;
    if (ask !== undefined) payload.ask = ask;
    if (average !== undefined) payload.average = average;

    console.log(
      "2. Writing to Firestore",
      `${PROJECT_ID}/${SETTINGS_DOC_PATH} ...`,
    );

    const credentials = loadServiceAccount();
    if (credentials.project_id && credentials.project_id !== PROJECT_ID) {
      console.warn(
        `Warning: service account project_id (${credentials.project_id}) differs from script PROJECT_ID (${PROJECT_ID}).`,
      );
    }

    const token = await getAccessToken(credentials);
    const fields = toFirestoreFields(payload);
    await upsertFirestoreDocument(token, fields);

    console.log("   Firestore updated successfully.");
  } catch (error) {
    console.error("CRITICAL FAILURE:", error.message);
    process.exit(1);
  }
}

main();
