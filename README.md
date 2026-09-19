# 🏙️ Nagar-Drishti (নগর-দৃষ্টি)

**AI-Powered Civic Issue Reporting & Resolution Tracking System**

> “See a problem. Report it. Track it. Solve it.”

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![TensorFlow Lite](https://img.shields.io/badge/TensorFlow%20Lite-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white)](https://www.tensorflow.org/lite)
[![FastAPI / Node.js](https://img.shields.io/badge/Backend-FastAPI%20%7C%20Node.js-009688?style=for-the-badge)](#)
[![PostgreSQL + PostGIS](https://img.shields.io/badge/Database-PostgreSQL%20%2B%20PostGIS-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://postgis.net)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

**Project Type**: Pure Software (Mobile + Web)  
**Platforms**: Android (primary) + Web Admin Dashboard  
**Alignment**: Smart Bangladesh Vision 2041 · SDG 11 (Sustainable Cities & Communities)

---

## 📌 One-line Pitch

Nagar-Drishti turns a citizen’s smartphone into a real-time civic issue reporting and resolution tracking system using on-device AI, GPS, and a geospatial admin dashboard.

---

## 🚨 The Problem

Citizens face everyday issues (potholes, garbage, waterlogging, broken streetlights…) but reporting is slow, location is unclear, duplicates flood the system, and there is almost no real-time visibility or feedback loop for authorities.

---

## 💡 The Solution

1. Citizen takes a photo → **On-device AI** classifies the issue  
2. GPS auto-captures location  
3. Report is submitted (works offline, syncs later)  
4. Backend detects possible duplicates via geospatial clustering  
5. Admin sees the issue on a live GIS map  
6. Work is assigned → resolved → citizen verifies

**Core Loop**  
Citizen sees → AI understands → System locates → Authority acts → Citizen verifies

---

## ✨ Key Features

### Citizen Mobile App (Flutter)
- Phone OTP login
- One-tap “Report an Issue”
- On-device AI classification (TFLite + MobileNetV2)
- Automatic GPS + Bengali voice-to-text description
- Offline-first reporting + auto-sync
- My Reports status tracking
- Push notifications (Firebase Cloud Messaging)
- Area heatmap view

### Admin Web Dashboard
- Live GIS map (OpenStreetMap / Google Maps)
- Color-coded status (Critical / In Progress / Resolved)
- Heatmap of problem hotspots
- Work assignment & SLA tracking
- Analytics & performance metrics
- Duplicate report grouping

---

## 🏗️ System Architecture (High-level)

---

## 🤖 AI / ML Pipeline

- **Task**: Image classification (Pothole, Garbage, Waterlogging, Streetlight, Normal Road, etc.)
- **Approach**: Transfer Learning with **MobileNetV2**
- **Deployment**: Converted to **TensorFlow Lite** → runs entirely on-device
- **Benefits**: Low latency, works offline, reduces server load & data cost

---

## 🔁 Duplicate Detection

Reports that are:
- Same issue category
- Within ~10 meters
- Close in time

…are grouped into a single cluster with an upvote/priority count (DBSCAN or simple spatial threshold as first version).

---

## 🛠️ Tech Stack

| Layer              | Technology                          |
|--------------------|-------------------------------------|
| Mobile             | Flutter + Dart                      |
| On-device AI        | TensorFlow Lite + MobileNetV2       |
| Backend            | FastAPI or Node.js (Express)        |
| Database           | PostgreSQL + PostGIS                |
| Storage            | AWS S3 / Firebase Storage           |
| Notifications      | Firebase Cloud Messaging            |
| Maps               | OpenStreetMap / Google Maps         |
| Auth               | Phone OTP                           |

---

## 🗓️ Development Roadmap (6 Months)

| Month | Focus                              |
|-------|------------------------------------|
| 1     | Planning, Figma UI/UX, ERD         |
| 2     | Backend API + Basic Flutter UI     |
| 3     | AI model training + TFLite integration |
| 4     | Admin Dashboard + Maps             |
| 5     | Campus pilot (50–100 users) + polish |
| 6     | Documentation, demo video, pitch   |

---

## 🎓 Campus Pilot Plan

1. Install APK on 50–100 students  
2. Report real campus issues (lights, garbage, roads, etc.)  
3. Admin tracks on dashboard  
4. Measure: AI accuracy, duplicates, resolution time, user satisfaction  

This becomes strong proof-of-concept data for judges and city corporations.

---

## 💰 Estimated Budget (MVP)

- Google Play Console: ~$25  
- Domain: ~$12  
- Cloud / Maps / Training: Free tier  
**Total**: ≈ ৳4,000 – ৳5,000

---

## 🚀 Scalability Vision

University Campus → Municipality → City Corporation → National Civic Data Platform  
Possible integration with A2I / government digital services.

---

## 🏆 Why This Project Stands Out

- **100% software** – no Arduino / sensors required  
- **Edge AI** (on-device inference)  
- Geospatial intelligence + duplicate clustering  
- Full citizen verification loop  
- Decision-support analytics for authorities  
- Extremely low cost & high scalability  

---

## 📂 Suggested Repository Structure


---

## 🎤 60-Second Pitch

Nagar-Drishti is an AI-powered civic issue reporting platform.  
A citizen takes a photo → on-device AI classifies the problem → GPS captures the location → the report appears on an admin GIS dashboard.  
Duplicates are automatically grouped. Authorities assign and track work. Citizens verify the fix.  

Pure software. Starts on a university campus. Scales to an entire city.

---

## 📄 License

MIT License – feel free to use, modify, and build upon this project.

---

**Project North Star**  
Nagar-Drishti is not just a complaint app.  
It is a **civic intelligence platform** that turns citizen observations into structured, location-aware, actionable data.

Citizen sees → AI understands → System locates → Authority acts → Citizen verifies.

---

*Made with ❤️ for Smart Bangladesh*
