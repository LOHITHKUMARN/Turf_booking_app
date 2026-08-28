# 🏟️ Turf — Multi-Role Sports Venue & Tournament Ecosystem

[![Node.js](https://img.shields.io/badge/Node.js-v18+-green.svg?style=for-the-badge&logo=node.js)](https://nodejs.org/)
[![Express](https://img.shields.io/badge/Express-4.x-black.svg?style=for-the-badge&logo=express)](https://expressjs.com/)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248.svg?style=for-the-badge&logo=mongodb)](https://www.mongodb.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.8+-02569B.svg?style=for-the-badge&logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg?style=for-the-badge&logo=dart)](https://dart.dev/)
[![Socket.io](https://img.shields.io/badge/Socket.IO-Real--Time-010101.svg?style=for-the-badge&logo=socket.io)](https://socket.io/)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28.svg?style=for-the-badge&logo=firebase)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

**Turf** is an enterprise-grade, full-stack ecosystem engineered to streamline and elevate sports venue operations and community sports engagement. The platform synchronizes **four specialized Flutter mobile applications** through a high-performance **Node.js/Express REST API and Socket.IO real-time engine**, delivering dedicated, role-tailored experiences for Players, Turf Owners, On-Ground Staff, and Platform Administrators.

---

## 📑 Table of Contents

1. [Ecosystem Architecture](#-ecosystem-architecture)
2. [The "Power of Four" Client Applications](#-the-power-of-four-client-applications)
   - [1. Turf Customer (B2C)](#1-turf-customer-b2c--explore--play)
   - [2. Turf Owner (B2B)](#2-turf-owner-b2b--manage--scale)
   - [3. Turf Staff (Operations)](#3-turf-staff-operations--live-field-management)
   - [4. Turf Admin (Governance)](#4-turf-admin-governance--platform-oversight)
3. [Backend Core & Real-Time Engine](#-backend-core--real-time-engine)
4. [Database & Data Models](#-database--data-models)
5. [REST API Reference](#-rest-api-reference)
6. [Security & Role-Based Access Control (RBAC)](#-security--role-based-access-control-rbac)
7. [Repository Structure](#-repository-structure)
8. [Installation & Getting Started](#-installation--getting-started)
9. [Portfolio / Resume Project Showcase](#-portfolio--resume-showcase)
10. [Authors & License](#-authors--license)

---

## 🏛️ Ecosystem Architecture

```
                                  ┌────────────────────────┐
                                  │   Global Admin App     │
                                  │    (Flutter Admin)     │
                                  └───────────┬────────────┘
                                              │
 ┌────────────────────────┐                   │                   ┌────────────────────────┐
 │   Customer Mobile App  │◄──────────────────┼──────────────────►│   Venue Owner Mobile   │
 │   (Players/Captains)   │                   │                   │     (B2B Dashboard)    │
 └───────────┬────────────┘                   │                   └───────────┬────────────┘
             │                                │                               │
             │           ┌────────────────────▼────────────────────┐          │
             └──────────►│        Unified Node.js REST API         │◄─────────┘
                         │     (Express + Socket.IO + JWT)         │
                         └────────────────────┬────────────────────┘
                                              ▲
                                              │
                         ┌────────────────────┼────────────────────┐
                         │                    │                    │
             ┌───────────┴────────────┐       │       ┌────────────┴───────────┐
             │    Staff Mobile App    │       │       │    MongoDB Database    │
             │   (Operations / QR)    │       │       │ (15 Structured Models) │
             └────────────────────────┘       │       └────────────────────────┘
                                              ▼
                                 ┌─────────────────────────┐
                                 │ Firebase Cloud Messages │
                                 │      (FCM Engine)       │
                                 └─────────────────────────┘
```

---

## 📱 The "Power of Four" Client Applications

Turf separates operational concerns into four standalone Flutter mobile applications, ensuring optimal workflows without feature bloat.

---

### 1. Turf Customer (B2C) — *Explore & Play*
*The gateway for athletes, casual players, and tournament teams.*

* **Dynamic Slot Booking:** Real-time visibility into available court slots with instant reservation and instant confirmation.
* **Tournament Discovery:** Smart filtering across sports categories (Football, Cricket, Badminton), cities, dates, and prize pools.
* **Team Registration:** Captains can create squads, add player rosters, and enroll directly into verified tournaments.
* **Live Fixture Viewer:** Interactive brackets and real-time live score monitoring.
* **Review & Rating System:** Transparent rating system with user reviews for venues.
* **Modern UI Experience:** Glassmorphism accents, dynamic carousels, cached image loading, and Google Fonts typography.

---

### 2. Turf Owner (B2B) — *Manage & Scale*
*The operational and business command center for sports facility proprietors.*

* **Turf & Slot Controller:** Create, modify, and schedule slots with customizable pricing based on peak/off-peak hours.
* **Tournament Hub:** Host community or competitive tournaments, manage entry fees, set prize pools, and automatically generate tournament brackets/fixtures.
* **Team Approval Workflow:** Review incoming team rosters, verify payment receipts, and approve/reject registrations.
* **Financial Analytics & Payouts:** Real-time revenue reports, lifetime earnings breakdown, and automated payout requests to Platform Admin.
* **Staff Announcements:** Broadcast real-time announcements directly to field staff via Socket.IO.

---

### 3. Turf Staff (Operations) — *Live Field Management*
*A high-efficiency tool for on-ground turf managers and referees.*

* **Digital Attendance & Shifts:** Clock-in and clock-out tracking for ground staff.
* **QR Ticket Scanner & Check-in:** Rapid verification of digital booking vouchers at venue gates.
* **Walk-In Booking Desk:** Handle on-the-spot bookings, offline cash collections, and equipment rentals.
* **Live Sideline Scoring:** Live score updates, set/period increments, and match winner submissions with real-time sync.
* **Incident & Maintenance Reporting:** Instant ticketing system to report damaged turf, broken floodlights, or urgent repairs straight to the venue owner.

---

### 4. Turf Admin (Governance) — *Platform Oversight*
*The platform operator's master panel for compliance and financial integrity.*

* **Venue & Tournament Auditing:** Review new turf applications and inspect tournament submissions before approving for public listing.
* **Payout Processing:** Audit financial payouts, verify bank details, and execute owner disbursements.
* **System Audit Logging:** Comprehensive tracking of all administrative actions with timestamped audit trails.
* **User & Role Governance:** Role modification, user suspension, and dispute resolution.

---

## ⚡ Backend Core & Real-Time Engine

The central backend is engineered with **Node.js** and **Express.js**, prioritizing low latency, data consistency, and enterprise security.

* **Real-Time Communication:** **Socket.IO** rooms for real-time live scores, match notifications, and venue broadcasts.
* **Push Notification Engine:** Integrated **Firebase Cloud Messaging (FCM)** for booking confirmations, tournament schedule updates, and payment alerts.
* **Dynamic Slot Engine:** High-concurrency slot generation algorithm that prevents race conditions and double-bookings.
* **Input Validation:** Strict request body validation powered by **Zod** to prevent malformed payloads.
* **Media Handling:** **Multer** integration for secure file uploads (turf photos, tournament banners, avatar images).

---

## 🗄️ Database & Data Models

Built on **MongoDB Atlas** with **Mongoose ORM**, containing 15 specialized models:

| Model | Purpose / Description |
| :--- | :--- |
| `User` | Stores profile, role (Customer, Owner, Staff, Admin), credentials, and FCM tokens |
| `Turf` | Venue configuration, location, sport types, amenities, rules, and gallery images |
| `Slot` | Generated time slots, pricing, availability state, and lock timestamps |
| `Booking` | Reservations, payment records, QR verification codes, and booking status |
| `Tournament` | Competitions, registration windows, formats (Knockout/League), rules, and prizes |
| `TournamentTeam` | Team roster, captain details, payment confirmation, and participation status |
| `TournamentMatch` | Match schedules, team pairings, live scores, round info, and referee reports |
| `Payout` | Owner withdrawal requests, amounts, bank info, and admin transaction receipts |
| `Announcement` | Direct broadcast messages from Venue Owners to their assigned ground staff |
| `Attendance` | Digital staff attendance logs, shift records, and operational timestamps |
| `Maintenance` | Turf maintenance requests, priority tags, status updates, and repair logs |
| `Incident` | Emergency reports, player injuries, or facility disputes logged by staff |
| `Review` | Player reviews, 1-5 star ratings, and feedback for sports venues |
| `AdminAuditLog` | Immutable record of all administrative approvals, edits, and financial actions |
| `RefreshToken` | Secure rotation tokens for long-lived session management |

---

## 🔌 REST API Reference

### 🔐 Authentication (`/api/auth`)
* `POST /api/auth/register` — Register a new account (Customer, Owner, Staff).
* `POST /api/auth/login` — Authenticate and receive JWT access and refresh tokens.
* `POST /api/auth/refresh` — Rotate and obtain a new access token.
* `GET /api/auth/me` — Fetch current authenticated user profile.

### 👤 Customer Endpoints (`/api/customer`)
* `GET /api/customer/turfs` — Browse active venues with geo/sport filters.
* `GET /api/customer/turfs/:id/slots` — Get live slot availability for a date.
* `POST /api/customer/bookings` — Create a new slot booking.
* `GET /api/customer/bookings/my` — Retrieve current user's booking history.

### 🏟️ Owner Endpoints (`/api/owner`)
* `POST /api/owner/turfs` — Create a new turf listing.
* `PUT /api/owner/turfs/:id` — Update venue pricing, timing, and facilities.
* `POST /api/owner/slots/generate` — Bulk-generate recurring slots.
* `GET /api/owner/payouts` — View payout history and account balance.
* `POST /api/owner/payouts/request` — Submit a payout withdrawal request.
* `POST /api/owner/announcements` — Broadcast announcement to staff.

### 🏆 Tournament Endpoints (`/api/tournaments`)
* `GET /api/tournaments` — List public tournaments.
* `POST /api/tournaments` — Create a tournament (Owner).
* `POST /api/tournaments/:id/register` — Register a team and submit roster.
* `POST /api/tournaments/:id/generate-fixtures` — Auto-generate brackets/fixtures.
* `GET /api/tournaments/:id/fixtures` — Fetch tournament schedule and bracket tree.
* `PUT /api/tournaments/matches/:matchId/score` — Update live match scores (Staff/Owner).

### 👷 Staff Endpoints (`/api/staff`)
* `POST /api/staff/attendance/clock-in` — Record digital shift clock-in.
* `POST /api/staff/attendance/clock-out` — Record digital shift clock-out.
* `POST /api/staff/verify-booking` — Validate QR ticket code.
* `POST /api/staff/maintenance` — Submit facility maintenance ticket.
* `POST /api/staff/incident` — File an incident/safety report.

### 🛡️ Admin Endpoints (`/api/admin`)
* `GET /api/admin/payouts` — Review all pending owner payout requests.
* `PUT /api/admin/payouts/:id/approve` — Approve and mark payout as disbursed.
* `GET /api/admin/audit-logs` — Access immutable system audit trails.
* `PUT /api/admin/tournaments/:id/approve` — Verify and publish a tournament.

---

## 🔒 Security & Role-Based Access Control (RBAC)

1. **Authentication:** Stateless JWTs signed with RSA/HMAC with short-lived expiration and database-backed refresh token rotation.
2. **Password Security:** Salted and hashed passwords using `bcrypt` (10 rounds).
3. **Role Gatekeepers:** Express middleware chain (`authenticate`, `requireRole(['owner', 'admin'])`) guarding every sensitive resource.
4. **Header Security:** `helmet` for HTTP response hardening and CSP policies.
5. **No Secrets in VCS:** All API keys, database credentials, and service account configs are loaded via `.env` and excluded via `.gitignore`.

---

## 📂 Repository Structure

```text
Turf_booking_app/
├── backend/                        # Centralized Node.js REST API
│   ├── src/
│   │   ├── config/                 # Database, Firebase & Environment setup
│   │   │   └── serviceAccountKey.example.json
│   │   ├── controllers/            # Route controllers & business logic
│   │   ├── middlewares/            # Auth, RBAC, Validation & Error handlers
│   │   ├── models/                 # 15 Mongoose Schema Definitions
│   │   ├── routes/                 # Express route modules
│   │   ├── services/               # Notification & Socket services
│   │   └── app.js                  # Express app initialization
│   ├── tests/                      # Integration & unit test suites
│   ├── package.json
│   └── seed.js                     # Sample database seed script
│
├── turf_customer/                  # Flutter App — Players & Booking
│   ├── lib/
│   │   ├── features/               # Tournaments, Booking, Home, Profile
│   │   ├── models/                 # Data parsing & serializers
│   │   ├── providers/              # State management
│   │   └── main.dart
│   └── pubspec.yaml
│
├── turf_owner/                     # Flutter App — Venue Owners & Analytics
│   ├── lib/
│   │   ├── features/               # Turf Manager, Payouts, Fixtures
│   │   ├── providers/
│   │   └── main.dart
│   └── pubspec.yaml
│
├── turf_staff/                     # Flutter App — Match Scoring & Operations
│   ├── lib/
│   │   ├── features/               # Live Scoring, Attendance, QR Scanner
│   │   ├── providers/
│   │   └── main.dart
│   └── pubspec.yaml
│
├── turf_admin/                     # Flutter App — Platform Governance
│   ├── lib/
│   │   ├── features/               # Audit Logs, Payout Approvals
│   │   └── main.dart
│   └── pubspec.yaml
│
├── .gitignore                      # Comprehensive multi-stack ignore rules
├── TURF_README.md
└── README.md                       # Main Documentation
```

---

## 🚀 Installation & Getting Started

### Prerequisites
* **Node.js**: `v18.0.0` or higher
* **Flutter SDK**: `v3.8.0` or higher
* **MongoDB**: Local instance or MongoDB Atlas URI
* **Firebase Project**: (Optional) for push notifications

---

### 1. Backend Setup

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Configure Environment Variables:**
   Create a `.env` file in `backend/`:
   ```env
   PORT=5000
   MONGO_URI=mongodb+srv://<username>:<password>@cluster0.mongodb.net/turf_db?retryWrites=true&w=majority
   JWT_SECRET=your_super_secret_jwt_key_here
   JWT_REFRESH_SECRET=your_super_secret_refresh_key_here
   JWT_EXPIRES_IN=1h
   JWT_REFRESH_EXPIRES_IN=7d
   ```

4. **(Optional) Configure Firebase FCM:**
   Copy `backend/src/config/serviceAccountKey.example.json` to `backend/src/config/serviceAccountKey.json` and fill in your Firebase credentials.

5. **Seed the database (Optional):**
   ```bash
   node seed.js
   ```

6. **Start the API Server:**
   ```bash
   # Development mode with hot-reload
   npm run dev

   # Production mode
   npm start
   ```

---

### 2. Flutter Mobile Apps Setup

For any of the four client apps (`turf_customer`, `turf_owner`, `turf_staff`, `turf_admin`):

1. **Navigate to the target app:**
   ```bash
   cd turf_customer
   # or cd turf_owner / turf_staff / turf_admin
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Configure API Base URL:**
   Open `lib/core/constants/api_constants.dart` and set your backend host URL:
   ```dart
   // For local development on Android Emulator:
   const String kBaseUrl = 'http://10.0.2.2:5000/api';

   // For physical device testing over LAN:
   // const String kBaseUrl = 'http://192.168.1.XX:5000/api';
   ```

4. **Run the application:**
   ```bash
   flutter run
   ```

5. **Build APK for Release:**
   ```bash
   flutter build apk --split-per-abi
   ```

---

## 💼 Portfolio / Resume Showcase

> **Turf — Full-Stack Multi-Role Sports Venue Ecosystem**
> * **Architecture:** Designed and built a synchronized ecosystem featuring **4 specialized Flutter mobile apps** (Customer, Owner, Staff, Admin) backed by a unified **Node.js/MongoDB REST API**.
> * **Real-Time Scalability:** Implemented **Socket.IO** rooms for live sidelines match scoring and venue broadcasts, combined with **Firebase Cloud Messaging (FCM)** for automated transactional alerts.
> * **Complex Business Logic:** Built an anti-collision slot reservation engine (3,000+ slots), automated tournament bracket generator (Knockout/League), and owner payout ledger.
> * **Security & Quality:** Engineered strict RBAC middleware, JWT session rotation, Zod payload validation, and digital QR ticket verification.
> * **Tech Stack:** Flutter, Dart, Node.js, Express.js, MongoDB, Mongoose, Socket.IO, Firebase FCM, Provider, JWT, Bcrypt.

---

## 📄 License & Contact

This project is licensed under the **MIT License**.

Developed by **[Lohith Kumar N](https://github.com/LOHITHKUMARN)**  
*Contributions, feature requests, and feedback are always welcome!*
