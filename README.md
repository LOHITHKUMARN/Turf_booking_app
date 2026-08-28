# 🏟️ Turf — The Complete Sports Venue Ecosystem

**Turf** is a production-grade, full-stack ecosystem designed to revolutionize sports venue management. This unified platform synchronizes **four specialized Flutter applications** through a centralized **Node.js REST API**, providing a seamless, real-time experience for everyone from players to global administrators.

---

## 🚀 Ecosystem Overview

Turf is built on a "Power of Four" mobile strategy, ensuring every stakeholder has a tailored experience.

### 👤 1. Turf Customer (B2C) - [Explore & Play]
*The primary interface for athletes and sports enthusiasts.*
- **Tournament Discovery**: Browse upcoming local tournaments with smart filters (Sport, City, Date).
- **Match Registration**: Form teams and register for tournaments directly through the app.
- **Smart Booking**: Check real-time turf availability and book slots in seconds.
- **Premium Design**: Vibrant HSL-tailored color palettes with polished glassmorphism effects.
- **Dynamic UX**: Seamless transitions and micro-animations for an interactive feel.

### 🏟️ 2. Turf Owner (B2B) - [Manage & Grow]
*Empowering venue owners to oversee facilities and tournament operations.*
- **Tournament Hub**: Create and manage tournaments, approve team entries, and generate fixtures automatically.
- **Live Monitoring**: Track active tournament progress and verify on-ground results.
- **Financial Dashboard**: Detailed revenue analytics, payout history, and automated payout requests to Admin.
- **Real-Time Staff Sync**: Broadcast announcements and updates directly to your on-ground staff via Socket.IO.

### 👷 3. Turf Staff (Operations) - [The Verification Tool]
*A specialized tool for on-site staff to manage live matches and entries.*
- **Match Verification**: View a dedicated feed of scheduled and live matches assigned to your specific turf.
- **Real-Time Scoring**: Update match scores and winner status directly from the sidelines.
- **Assigned Workflow**: Log in and instantly see the events happening at your designated facility.
- **Safe State Handling**: Robust JSON parsing ensures match data remains visible even with complex backend relationships.

### 🌐 4. Turf Admin (Global) - [Platform Governance]
*The central audit and control center for the platform operator.*
- **Payout Management**: Dedicated dashboard to review, approve, and process payout requests from owners.
- **Tournament Auditing**: Review pending tournaments and approve them for public listing.
- **System Hardening**: Integrated audit logs and Sentry error tracking for production reliability.
- **User Governance**: Full control over user accounts and role-based permissions.

---

## 🛠️ Technical Architecture

### **Backend (The Core Engine)**
A high-performance REST API built with **Node.js** and **Express**.
- **Database**: MongoDB Atlas with Mongoose ORM for flexible schema management.
- **Real-Time**: Integrated **Socket.IO** for instant score updates and announcements.
- **Push Notifications**: **Firebase Cloud Messaging (FCM)** for booking confirmations and results.
- **Security**: JWT-based authentication with descriptive, situation-specific error feedback.
- **Stability**: Integrated Sentry error tracking and Zod-based request validation.

### **Mobile (The Client Layer)**
Four tailored apps built using the **Flutter** framework.
- **State Management**: Provider-based architecture for reactive UI updates.
- **Reliable Data**: Advanced `fromJson` patterns to handle populated Mongoose references as both IDs and Objects.
- **UX Excellence**: Optimized input types (email/number keyboards) and smooth keyboard action flows (Next/Done).

---

## 🚦 Installation & Getting Started

### **1. Backend**
```bash
cd backend
npm install
# Configure .env (MONGO_URI, JWT_SECRET, SENTRY_DSN, FIREBASE_TOKEN)
npm run dev
```

### **2. Mobile Apps**
```bash
# Navigate to the desired app (e.g., turf_customer)
cd turf_customer
flutter pub get
# Ensure your API URL matches in lib/core/constants/api_constants.dart
flutter run
```

---

## 📂 Project Structure
```text
turf/
├── backend/            # Centralized REST API & Real-time Services
├── turf_customer/      # App for Players & Tournament Registration
├── turf_owner/         # App for Venue Owners & Fixture Management
├── turf_staff/         # App for Match Scoring & Verification
├── turf_admin/         # App for Global Governance & Payouts
└── README.md           # Unified Documentation
```

---

Developed with ❤️ by the **Turf Engineering Team**.
