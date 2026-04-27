const functions = require("firebase-functions");
const fetch = require("node-fetch");

// ─── CORS helper ─────────────────────────────────────────────────────────────
function setCors(res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");
}

// ─── GEMINI: Main analysis + chat ────────────────────────────────────────────
exports.geminiProxy = functions.https.onRequest(async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") return res.status(204).send("");

  const apiKey = functions.config().gemini.key;
  if (!apiKey) return res.status(500).json({ error: "Gemini key not configured" });

  // req.body should contain: { model, contents, generationConfig, system_instruction? }
  const { model, contents, generationConfig, system_instruction } = req.body;

  const modelName = model || "gemini-2.5-flash";
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent`;

  const body = { contents, generationConfig };
  if (system_instruction) body.system_instruction = system_instruction;

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": apiKey,
      },
      body: JSON.stringify(body),
    });

    const data = await response.json();
    return res.status(response.status).json(data);
  } catch (e) {
    return res.status(500).json({ error: e.toString() });
  }
});

// ─── VISION: Face detection ───────────────────────────────────────────────────
exports.visionProxy = functions.https.onRequest(async (req, res) => {
  setCors(res);
  if (req.method === "OPTIONS") return res.status(204).send("");

  const apiKey = functions.config().vision.key;
  if (!apiKey) return res.status(500).json({ error: "Vision key not configured" });

  // req.body should contain: { image: "<base64 string>" }
  const { image } = req.body;
  if (!image) return res.status(400).json({ error: "Missing image field" });

  const url = `https://vision.googleapis.com/v1/images:annotate?key=${apiKey}`;

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        requests: [
          {
            image: { content: image },
            features: [{ type: "FACE_DETECTION", maxResults: 1 }],
          },
        ],
      }),
    });

    const data = await response.json();
    return res.status(response.status).json(data);
  } catch (e) {
    return res.status(500).json({ error: e.toString() });
  }
});