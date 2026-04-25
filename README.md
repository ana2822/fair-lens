# FairLens — AI Governance & Bias Detection Platform

> **FairLens detects, explains, and fixes bias in AI systems before it affects real-world decisions.**
> Upload any CSV dataset — hiring, loans, medical, HR — and get a full fairness audit with legal risk mapping, Gemini AI explanation, and a debiased dataset, all in under 60 seconds.

---

## 🚀 Live Demo

**[▶ Open FairLens Live](https://fairlens-app.web.app)**

No sign-up required. Click **"Try Live Demo"** on the login screen — it pre-loads a sample hiring dataset and shows real bias analysis instantly.

---

## 📹 Demo Video

**[▶ Watch 3-Minute Demo](https://youtube.com/your-link-here)**

Shows the full loop: upload CSV → bias score → Gemini explanation → auto fix → PDF download.

---

## 🔍 What It Does

Amazon's hiring AI penalized CVs containing the word "women's" — trained on 10 years of biased historical data. FairLens catches exactly this kind of bias before it ships.

**The full pipeline:**

```
Upload CSV → Real bias computation → Gemini AI explanation
    → Legal risk mapping → Auto-fix → PDF audit report
```

All in under 60 seconds. No code. No data science degree required.

---

## ✨ Key Features

| Feature | What It Does |
|---|---|
| **Bias Detection** | Computes Disparate Impact Ratio & Statistical Parity from your actual data |
| **Legal Risk Mapping** | Auto-maps bias to EEOC, GDPR Art.22, EU AI Act, India AI Guidelines |
| **Gemini AI Explanation** | Plain-English analysis of what the bias means and how to fix it |
| **Red-Team Loop** | Sends biased text to Gemini live — shows the LLM amplifying the bias |
| **Auto Fix** | Remove or anonymize biased columns, download debiased CSV |
| **Face Bias Audit** | Google Cloud Vision API — real detection confidence disparity across groups |
| **PDF Report** | Full legally-formatted audit report with AI-BOM and computed metrics |
| **Gov Dashboard** | Real-time risk monitoring for enterprise/government compliance teams |

---

## 🎯 Google Services Used

| Service | How Used |
|---|---|
| **Gemini 2.5 Flash** | Bias analysis, plain-English explanation, red-team adversarial testing |
| **Google Cloud Vision API** | Face bias detection — real `detectionConfidence` scores across demographic groups |
| **Firebase Auth** | Google Sign-In, Email/Password, Demo Mode |
| **Cloud Firestore** | Per-user audit history storage |
| **Firebase Hosting** | Live web deployment |
| **Firebase Analytics** | Usage tracking |

---

## 🏁 Problem Statement Alignment

> *"Computer programs now make life-changing decisions... if they learn from flawed or unfair historical data, they will repeat and amplify those exact same discriminatory mistakes."*
> — Google Solution Challenge 2026

| Problem | FairLens Solution |
|---|---|
| Decisions about jobs, loans, medical care | Auto-detects hiring, loan, medical dataset types |
| Learning from flawed historical data | Real Disparate Impact math on your actual CSV |
| Repeat and amplify mistakes | Red-Team: proves LLM bias amplification live |
| Inspect datasets and models | CSV + Text + Face bias modules |
| Measure, flag, fix | Score 0–100, severity alerts, auto-fix + debiased CSV |
| Before impacting real people | PDF audit report for pre-deployment compliance |

---

## 💻 Run Locally

### Prerequisites
- Flutter 3.x (`flutter --version`)
- Chrome browser

### Setup

```bash
git clone https://github.com/your-username/fairlens
cd fairlens

# Install dependencies
flutter pub get

# Add your API keys
cp .env.example .env
# Edit .env and add:
# GEMINI_KEY=your_gemini_api_key
# VISION_KEY=your_google_vision_api_key

# Run
flutter run -d chrome
```

### API Keys Needed
1. **Gemini API Key** — [Get it at Google AI Studio](https://aistudio.google.com/app/apikey) (free)
2. **Vision API Key** — [Google Cloud Console](https://console.cloud.google.com) → Enable Cloud Vision API → Create credentials (1,000 free requests/month)

---

## 📊 What's Real (Not Simulated)

| Feature | Status |
|---|---|
| CSV bias math (Disparate Impact, Statistical Parity) | ✅ Real computation on your data |
| Gemini AI analysis | ✅ Real API call |
| Red-team adversarial LLM output | ✅ Real Gemini API call |
| Face detection confidence scores | ✅ Real Google Vision API |
| Legal risk mapping | ✅ Real (hardcoded law database) |
| PDF report numbers | ✅ All from real AnalysisReport object |
| Gov dashboard live score | ⚡ Timer-animated (seeded from real data) |

---

## 🏗️ Architecture

```
lib/
├── models/
│   └── bias_detector.dart       ← Core: Disparate Impact, Statistical Parity
├── services/
│   ├── gemini_service.dart      ← Gemini AI + Red-Team adversarial testing
│   ├── vision_service.dart      ← Google Vision face bias detection
│   ├── pdf_service.dart         ← HTML audit report export
│   ├── auth_service.dart        ← Firebase Auth + Demo Mode
│   └── firebase_service.dart    ← Firestore history
└── screens/ (12 screens)
    ├── login_screen.dart         ← Demo-first entry point
    ├── home_screen.dart          ← Landing + CSV upload
    ├── analysis_screen.dart      ← Core: 5-tab bias audit
    ├── gov_dashboard_screen.dart ← Enterprise monitoring
    ├── text_bias_screen.dart     ← NLP bias + Red-Team
    └── face_bias_screen.dart     ← Vision API face bias
```

---

## ❓ FAQ for Judges

**"How is this different from IBM AIF360?"**
AIF360 is a Python library for data scientists. FairLens is a complete platform that any compliance officer can use in a browser — no code, no setup, with legal mapping and AI explanation built in.

**"How accurate is your bias detection?"**
We use the EEOC four-fifths rule (Disparate Impact < 0.8 = flagged) — the same standard used by U.S. employment law. It's not our threshold, it's the legal threshold.

**"What if the CSV has no gender column?"**
FairLens auto-detects sensitive columns by keyword matching (gender, sex, race, caste, age, religion, location) — no manual configuration needed.

**"How do you handle privacy?"**
Data never leaves the browser — analysis runs client-side. Only aggregated scores (not raw data) are saved to Firestore. PII scrubbing is built into the Text Bias module.

---

## 👥 Team

**Team FairLens** — Google Solution Challenge 2026

---

## 📄 License

MIT License — see [LICENSE](LICENSE)
